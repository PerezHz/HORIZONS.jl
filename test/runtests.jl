# This file is part of the HORIZONS.jl package
# The HORIZONS.jl package is licensed under the MIT "Expat" License
# Copyright (c) 2017: Jorge Perez.

using HORIZONS, Expect
using Base.Test

@testset "Test connection to HORIZONS machine using Expect.jl" begin
    port = 6775
    horizons_telnet_cmd = `telnet $(HORIZONS.HORIZONS_MACHINE) $port`
    @show horizons_telnet_cmd
    proc = ExpectProc(horizons_telnet_cmd, 15)
    # Get main prompt and proceed, turning off paging, specifying I/O model,
    # and sending object look-up from command-line 
    idx = expect!(proc, ["unknown host", "Horizons> "])
    if idx == 1
        throw("This system cannot find $HORIZONS_MACHINE")
    end
    @test idx == 2
end

@testset "Test output formatting" begin
    dt0 = Dates.DateTime(2029,4,13)
    dtmax = Dates.Date(2029,4,14)
    δt = Dates.Hour(1)
    apophisraw = vec_tbl("Apophis", dt0, dtmax, δt, CSV_FORMAT=true);
    @test isa(apophisraw, String)
    @test contains(apophisraw, "\$\$SOE")
    @test contains(apophisraw, "\$\$EOE")
    @test ismatch(r"\$\$SOE", apophisraw)
    @test ismatch(r"\$\$EOE", apophisraw)
    mSOE = match(r"\$\$SOE", apophisraw)
    mEOE = match(r"\$\$EOE", apophisraw)
    @test mSOE.offsets == Int64[]
    @test mEOE.offsets == Int64[]

    apophisste = apophisraw[mSOE.offset+7:mEOE.offset-3] #from SOE to EOE
    iob = IOBuffer(apophisste)
    apophisarr = readcsv(iob)[:,1:end-1]

    @test size(apophisarr) == (25, 11)

end
