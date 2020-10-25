# This file is part of the HORIZONS.jl package
# The HORIZONS.jl package is licensed under the MIT "Expat" License
# Copyright (c) 2017: Jorge Pérez.

#The following methods implement some functionality from JPL's Horizons telnet interface
#For more detailed info about JPL HORIZONS system, visit http://ssd.jpl.nasa.gov/?horizons

# The following code is based on the smb_spk_ele script, as was retrieved from:
# ftp://ssd.jpl.nasa.gov/pub/ssd/SCRIPTS/smb_spk_ele
# Date retrieved: Jul 19, 2017
# Credit: Jon D. Giorgini, NASA-JPL
# Jon.D.Giorgini@jpl.nasa.gov

# TODO: add method with each element as a separate argument in function call

function smb_spk_ele(flag::String, small_body::ObjectName, start_time::StartStopTime,
        stop_time::StartStopTime, elements::String, email::String="joe@your.domain.name",
        file_name::String=""; kwargs...)

    smb_spk_ele(flag, small_body, DateTime(start_time), DateTime(stop_time), elements, email, file_name; kwargs...)
end

function smb_spk_ele(flag::String, small_body::ObjectName, start_time::StartStopTime,
        stop_time::StartStopTime, epoch::T, ec::T, qr::T, tp::T, om::T, w::T, inc::T,
        email::String="joe@your.domain.name", file_name::String="";
        kwargs...) where {T<:Real}

    elements = "EPOCH= $epoch EC=$ec QR=$qr TP=$tp OM=$om W=$w IN=$inc"

    smb_spk_ele(flag, small_body, DateTime(start_time), DateTime(stop_time), elements, email, file_name; kwargs...)
end

function smb_spk_ele(flag::String, small_body::ObjectName,
        start_time::DateTime, stop_time::DateTime, elements::String,
        email::String="joe@your.domain.name", file_name::String="";
        ftp_verbose::Bool=false, timeout::Int=60)

    # TODO: handle spk_ID_override (see smb_spk_ele Expect script)

    # Convert start and stop time from `DateTime`s to `String`s
    small_body_str = string(small_body)
    start_time_str = Dates.format(start_time, HORIZONS_DATE_FORMAT)
    stop_time_str = Dates.format(stop_time, HORIZONS_DATE_FORMAT)

    if flag == "t"
        file_type = "yes"
        ftp_type = :ascii
        ftp_sufx = ".xsp"
    elseif flag == "b"
        file_type  = "no"
        ftp_type = :binary
        ftp_sufx = ".bsp"
    elseif flag == "1"
        file_type = "1"
        ftp_type = :binary
        ftp_sufx = ".bsp"
    elseif flag == "2"
        file_type = "21"
        ftp_type = :binary
        ftp_sufx = ".bsp"
    else
        ArgumentError("Unknown file type: $flag")
    end

    local_file = file_name

    # Connect to Horizons
    proc = ExpectProc(`telnet $HORIZONS_MACHINE 6775`, timeout)

    # Wait for main Horizons prompt, set up, proceed
    idx = expect!(proc, ["unknown host", "Horizons> "])
    if idx == 1
        warn("This system cannot find $HORIZONS_MACHINE")
        close(proc)
    elseif idx == 2
        println(proc, "PAGE") # turn off paging
    end
    idx = expect!(proc, ["Horizons> "], timeout=15)
    if idx == 1
        println(proc, "##2")
    end
    idx = expect!(proc, ["Horizons> "], timeout=15)
    if idx == 1
        println(proc, ";") # magic option to compute orbit from elements
    end

    # Wait for element input prompt and send elements
    idx = expect!(proc, [r".*: $"])
    if idx == 1
        println(proc, elements*"\r")
    end

    # Process any errors from element input and specify frame
    idx = expect!(proc, [r"INPUT ERROR.*", r"Error.*", r".*Ecliptic frame of input.*: $"])
    if idx == 1
        println(proc, "q")
        throw(ArgumentError("Horizons encountered an input error and halted --"))
    elseif idx == 2
        println(proc, "q")
        throw(ArgumentError("Horizons encountered an input error and halted --"))
    elseif idx == 3
        println(proc, "J2000")
    end

    # Wait for input prompt and send name of object
    idx = expect!(proc, [r".*Optional name of object.*: $"])
    if idx == 1
        println(proc, small_body)
    end

    # Request SPK
    idx = expect!(proc, [r".*Select.*<cr>: $"])
    if idx == 1
        println(proc, "S")
    end

    # Pick out SPK ID sent by Horizons
    if file_name==""
        idx = expect!(proc, [r" Assigned SPK object ID: (.*)\r\r\n \r\r\n Enter your"])
        # @show proc.match
        proc_match = match(r" Assigned SPK object ID: (\s\d+).*\r\r\n \r\r\n Enter your", proc.match)
        spkid = strip(proc_match[1])
        # @show spkid
        local_file = spkid*ftp_sufx
        # @show local_file
    end

    # Process prompt for e-mail address
    idx = expect!(proc, [r".*address.*: $"])
    if idx == 1
        println(proc, email)
    end

    # Process e-mail confirmation
    idx = expect!(proc, [r".*yes.*: $"])
    if idx == 1
        println(proc, "yes")
    end

    # Process file type
    idx = expect!(proc, [r".*SPK file format.*: $", r".*YES.*: $"])
    if idx == 1
        println(proc, file_type)
    elseif idx == 2
        println(proc, file_type)
    end

    # Set start date
    idx = expect!(proc, [r".*START.*: "s])
    if idx == 1
        println(proc, start_time_str)
    end

    # Handle start date error or STOP date
    idx = expect!(proc, [r".*try.*: "s, r".*STOP.*: "s])
    if idx == 1
        println(proc, "X")
        throw(ArgumentError("START time $start_time_str outside set SPK limits."))
    elseif idx == 2
        println(proc, stop_time_str)
    end

    # Handle stop date error
    # timeout is set to Inf to allow for file production
    idx = expect!(proc, [r".*large.*", r".*try.*"s, r".*time-span too small.*", r".*YES.*"s], timeout=Inf)
    if idx == 1
        println(proc, "X")
        throw(ArgumentError("Error in STOP date: $stop_time_str\nStop date must not be more than 200 years after start."))
    elseif idx == 2
        println(proc, "X")
        throw(ArgumentError("STOP time $stop_time_str outside set SPK limits."))
    elseif idx == 3
        println(proc, "X")
        throw(ArgumentError("Error in requested length: $start_time_str to $stop_time_str\nTime span of file must be >= 32 days."))
    elseif idx == 4
        # Binary SPK file created.
        # Add more objects to file  [ YES, NO, ? ] :
        println(proc, "NO")
    end

    # Pick out FTP file name
    idx = expect!(proc, [r"File name   : (.*)\r\r\n   File type"], timeout=15)
    proc_match = match(r"File name   : (.*)\r\r\n   File type", proc.match)
    ftp_name = strip(proc_match[1])
    # @show ftp_name

    # Close telnet connection
    close(proc)

    # Retrieve file by anonymous FTP and save to file
    ftp_init()
    # workaround `@` in email address
    ftp_email = replace(email, "@" => "_at_")
    ftp = FTP(hostname=HORIZONS_MACHINE, username="anonymous", password=ftp_email, verbose=ftp_verbose)
    cd(ftp, HORIZONS_FTP_DIR)
    if file_name == ""
        io = download(ftp, ftp_name, local_file)
        close(ftp)
        ftp_cleanup()
        return ftp_name, local_file
    else
        io = download(ftp, ftp_name, file_name)
        close(ftp)
        ftp_cleanup()
        return ftp_name, file_name
    end
end
