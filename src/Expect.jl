##This file is part of Expect.jl; MIT licensed
##https://gitlab.com/wavexx/Expect.jl
##Author: Yuri D'Elia (@wavexx)
## Exports
module Expect
export ExpectProc, interact, expect!, with_timeout!, raw!, sendeof
export ExpectTimeout, ExpectEOF

## Imports
import Base.Libc: strerror
import Base: Process, TTY, wait, wait_readnb, wait_readbyte
import Base: kill, process_running, process_exited, success
import Base: write, print, println, flush, eof, close
import Base: read, readbytes!, readuntil
import Base: isopen, bytesavailable, readavailable

## UNIX/tty support lib
@static if Sys.isunix()
    const LIBEXJL = joinpath(@__DIR__, "../deps/libexjl.so")

    function _set_cloexec(fd::RawFD)
        ccall((:exjl_set_cloexec, LIBEXJL), Cint, (Cint,), fd)
    end

    function _sendeof(tty::TTY)
        flush(tty) # flush any pending buffer in jl/uv
        ccall((:exjl_sendeof, LIBEXJL), Cint, (Ptr{Nothing},), tty)
    end
end


## Types
struct ExpectTimeout <: Exception end
struct ExpectEOF <: Exception end

mutable struct ExpectProc <: IO
    proc::Process
    timeout::Real
    encode::Function
    decode::Function
    in_stream::IO
    out_stream::IO
    before
    match
    buffer::Vector{UInt8}

    function ExpectProc(cmd::Cmd, timeout::Real; env::Base.EnvDict=ENV, encoding="utf8", pty=true)
        # TODO: only utf8 is currently supported
        @assert encoding == "utf8"
        encode = x->collect(transcode(UInt8, x))
        decode = x->transcode(String, copy(x))

        in_stream, out_stream, proc = _spawn(cmd, env, pty)
        new(proc, timeout, encode, decode,
            in_stream, out_stream,
            nothing, nothing, [])
    end
end


## Support functions
function raw!(tty::TTY, raw::Bool)
    # UV_TTY_MODE_IO (cfmakeraw) is only available with libuv 1.0 and not
    # directly supported by jl_tty_set_mode (JL_TTY_MODE_RAW still performs NL
    # conversion).
    UV_TTY_MODE_NORMAL = 0
    UV_TTY_MODE_IO = 2
    mode = raw ? UV_TTY_MODE_IO : UV_TTY_MODE_NORMAL
    ret = ccall(:uv_tty_set_mode, Cint, (Ptr{Nothing},Cint), tty.handle, mode)
    ret == 0
end

function raw!(proc::ExpectProc, raw::Bool)
    if !isa(proc.out_stream, TTY)
        # pipes are always raw
        return raw
    else
        raw!(proc.out_stream, raw)
    end
end


function _spawn(cmd::Cmd, env::Base.EnvDict, pty::Bool)
    env = copy(ENV)
    env["TERM"] = "dumb"
    setenv(cmd, env)

    if pty && Sys.isunix()
        O_RDWR = Base.Filesystem.JL_O_RDWR
        O_NOCTTY = Base.Filesystem.JL_O_NOCTTY

        fdm = RawFD(ccall(:posix_openpt, Cint, (Cint,), O_RDWR|O_NOCTTY))
        fdm == RawFD(-1) && error("openpt failed: $(strerror())")
        ttym = TTY(fdm; readable=true)
        in_stream = out_stream = ttym

        rc = _set_cloexec(fdm)
        rc != 0 && error("ioctl failed: $(strerror())")

        rc = ccall(:grantpt, Cint, (Cint,), fdm)
        rc != 0 && error("grantpt failed: $(strerror())")

        rc = ccall(:unlockpt, Cint, (Cint,), fdm)
        rc != 0 && error("unlockpt failed: $(strerror())")

        pts = ccall(:ptsname, Ptr{UInt8}, (Cint,), fdm)
        pts == C_NULL && error("ptsname failed: $(strerror())")

        fds = RawFD(ccall(:open, Cint, (Ptr{UInt8}, Cint), pts, O_RDWR|O_NOCTTY))
        fds == RawFD(-1) && error("open failed: $(strerror())")
        if raw!(out_stream, true) == false
            ccall(:close, Cint, (Cint,), fds)
            error("raw! failed: $(strerror())")
        end

        local proc::Process
        try
            proc = run(cmd, (fds, fds, fds), wait=false)
        catch ex
            ccall(:close, Cint, (Cint,), fds)
            close(ttym)
            rethrow(ex)
        end

        @async begin
            wait(proc)
            close(ttym)
            ccall(:close, Cint, (Cint,), fds)
        end

        Base.start_reading(in_stream)
    else
        pipe = Pipe()
        proc = open(cmd, "r", pipe)
        out_stream = Base.pipe_writer(pipe)
        in_stream = Base.pipe_reader(proc)
    end

    return (in_stream, out_stream, proc)
end


# Process management
kill(proc::ExpectProc, signum::Integer=15) = kill(proc.proc, signum)
wait(proc::ExpectProc) = wait(proc.proc)
process_running(proc::ExpectProc) = process_running(proc.proc)
process_exited(proc::ExpectProc) = process_exited(proc.proc)
success(proc::ExpectProc) = success(proc.proc)

# Writing functions
flush(proc::ExpectProc) = flush(proc.out_stream)
close(proc::ExpectProc) = close(proc.out_stream)

function sendeof(proc::ExpectProc)
    if typeof(proc.out_stream) <: TTY
        return _sendeof(proc.out_stream) == 0
    else
        close(proc.out_stream)
        return true
    end
end

write(proc::ExpectProc, buf::Vector{UInt8}) = write(proc.out_stream, buf)
write(proc::ExpectProc, buf::AbstractString) = write(proc, proc.encode(buf))
print(proc::ExpectProc, x::AbstractString) = write(proc, x)
println(proc::ExpectProc, x::AbstractString) = write(proc, string(x, "\n"))
# resolve method ambiguity
const ContiguousString = Union{String,SubString{String}}
write(proc::ExpectProc, buf::ContiguousString) = write(proc, proc.encode(buf))
print(proc::ExpectProc, x::ContiguousString) = write(proc, x)
println(proc::ExpectProc, x::ContiguousString) = write(proc, string(x, "\n"))

# Reading functions
function _timed_wait(func::Function, proc::ExpectProc; timeout::Real=proc.timeout)
    if isinf(timeout)
        return func()
    end
    thunk = current_task()
    timer = Timer(timeout) do _
        Base.throwto(thunk, ExpectTimeout())
    end
    local ret
    try
        ret = func()
    finally
        close(timer)
    end
    return ret
end

function eof(proc::ExpectProc; timeout::Real=proc.timeout)
    _timed_wait(proc; timeout=timeout) do
        eof(proc.in_stream)
    end
end

function wait_readnb(proc::ExpectProc, nb::Int; timeout::Real=proc.timeout)
    _timed_wait(proc; timeout=timeout) do
        wait_readnb(proc.in_stream, nb)
    end
end

function wait_readbyte(proc::ExpectProc, c::UInt8; timeout::Real=proc.timeout)
    _timed_wait(proc; timeout=timeout) do
        wait_readbyte(proc.in_stream, c)
    end
end

read(proc::ExpectProc, ::Type{UInt8}; timeout::Real=proc.timeout) =
    _timed_wait(proc; timeout=timeout) do
        read(proc.in_stream, UInt8)
    end

readbytes!(proc::ExpectProc, b::AbstractVector{UInt8}, nb=length(b); timeout::Real=proc.timeout) =
    _timed_wait(proc; timeout=timeout) do
        readbytes!(proc.in_stream, b, nb)
    end

readuntil(proc::ExpectProc, delim::AbstractString; timeout::Real=proc.timeout, keep::Bool=false) =
    _timed_wait(proc; timeout=timeout) do
        readuntil(proc.in_stream, delim, keep=keep)
    end

isopen(proc::ExpectProc) = isopen(proc.in_stream)
bytesavailable(proc::ExpectProc) = bytesavailable(proc.in_stream)
readavailable(proc::ExpectProc) = readavailable(proc.in_stream)


# Expect
function _expect_search(buf::AbstractString, str::AbstractString)
    pos = findfirst(str, buf)
    return pos == nothing ? nothing : (buf[pos], pos)
end

function _expect_search(buf::AbstractString, regex::Regex)
    m = match(regex, buf)
    return m == nothing ? nothing : (m.match, m.offset:(m.offset+length(m.match)-1))
end

function _expect_search(buf::AbstractString, vec::Vector)
    for idx=1:length(vec)
        ret = _expect_search(buf, vec[idx])
        if ret != nothing
            return idx, ret[1], ret[2]
        end
    end
    return nothing
end

function expect!(proc::ExpectProc, vec; timeout::Real=proc.timeout)
    proc.match = nothing
    pos = 0:-1
    idx = 0
    while true
        if bytesavailable(proc.in_stream) > 0
            proc.buffer = vcat(proc.buffer, readavailable(proc.in_stream))
        end
        if length(proc.buffer) > 0
            buffer = try proc.decode(proc.buffer); finally; end
            if buffer != nothing
                ret = _expect_search(buffer, vec)
                if ret != nothing
                    idx, proc.match, pos = ret
                    break
                end
            end
        end
        if !isopen(proc.in_stream)
            throw(ExpectEOF())
        end
        wait_readnb(proc, 1; timeout=timeout)
    end
    proc.before = proc.decode(proc.buffer[1:pos[1]-1])
    proc.buffer = proc.buffer[pos[end]+1:end]
    return idx
end

function expect!(proc::ExpectProc, regex::Regex; timeout::Real=proc.timeout)
    expect!(proc, [regex]; timeout=timeout)
    proc.before
end

function expect!(proc::ExpectProc, str::AbstractString; timeout::Real=proc.timeout)
    # TODO: this is worth implementing efficiently
    expect!(proc, [str]; timeout=timeout)
    proc.before
end


# Helpers
function with_timeout!(func::Function, proc::ExpectProc, timeout::Real)
    orig = proc.timeout
    proc.timeout = timeout
    local ret
    try
        ret = func()
    finally
        proc.timeout = orig
    end
    return ret
end

function interact(func::Function, cmd::Cmd, args...; kwargs...)
    proc = ExpectProc(cmd, args...; kwargs...)
    try
        func(proc)
    catch err
        kill(proc)
        rethrow(err)
    finally
        close(proc)
    end

    # wait+kill performed by success itself
    success(proc)
end


end
