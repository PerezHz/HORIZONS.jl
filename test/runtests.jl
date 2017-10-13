# This file is part of the HORIZONS.jl package
# The HORIZONS.jl package is licensed under the MIT "Expat" License
# Copyright (c) 2017: Jorge Perez.

using HORIZONS, Expect

if VERSION < v"0.7.0-DEV.2004"
    using Base.Test
else
    using Test
end

@testset "Test connection to HORIZONS machine using Expect.jl" begin
    port = 6775
    if is_windows()
        horizons_telnet_cmd_win = `cmd /c telnet $(HORIZONS.HORIZONS_MACHINE) $port`
        @show horizons_telnet_cmd_win
        proc = ExpectProc(horizons_telnet_cmd_win, 15)
    else
        horizons_telnet_cmd = `telnet $(HORIZONS.HORIZONS_MACHINE) $port`
        @show horizons_telnet_cmd
        proc = ExpectProc(horizons_telnet_cmd, 15)
    end
    # Get main prompt and proceed, turning off paging, specifying I/O model,
    # and sending object look-up from command-line 
    idx = expect!(proc, ["unknown host", "Horizons> "])
    if idx == 1
        throw("This system cannot find $HORIZONS_MACHINE")
    end
    @test idx == 2
end

@testset "Test for erroneous arguments" begin
    @test_throws ArgumentError vec_tbl_csv("@#", Date(2000), Date(2010), Dates.Year(1))
    @test_throws ArgumentError vec_tbl_csv(99942, Date(2000), Date(2010), Dates.Year(1); CENTER="nomatch")
    @test_throws ArgumentError vec_tbl_csv(499, Date(2009), Date(2010), Dates.Year(1); VEC_TABLE = 1, CENTER="mars")
end

@testset "Vector table generation: vec_tbl" begin
    dt0 = Dates.DateTime(2029,4,13)
    dtmax = Dates.Date(2029,4,14)
    δt = Dates.Hour(1)
    apophisraw = vec_tbl("Apophis", dt0, dtmax, δt; CSV_FORMAT=true);
    @test isa(apophisraw, String)
    @test contains(apophisraw, "\$\$SOE")
    @test contains(apophisraw, "\$\$EOE")
    @test ismatch(r"\$\$SOE", apophisraw)
    @test ismatch(r"\$\$EOE", apophisraw)
    mSOE = match(r"\$\$SOE", apophisraw)
    mEOE = match(r"\$\$EOE", apophisraw)
    @test mSOE.offsets == Int64[]
    @test mEOE.offsets == Int64[]

    # get everything within SOE and EOE
    apophisste = apophisraw[mSOE.offset+7:mEOE.offset-3]
    # turn into 2-dim array
    apophisarr = readdlm(IOBuffer(apophisste), ',')[:,1:end-1]

    @test typeof(apophisarr) == Array{Any,2}
    @test size(apophisarr) == (25, 11)

    # get table labels
    apophishdr = convert(Array{String,2}, strip.(    readdlm(  IOBuffer( match(r"JDTDB.*,\r\n", apophisraw).match ), ','  )[:,1:end-1]    ));
    @test typeof(apophishdr) == Array{String,2}
    @test size(apophishdr) == (1,11)
    # vcat into common 2-dim array
    apophistable = vcat(apophishdr, apophisarr)

    @test typeof(apophistable) == Array{Any,2}
    @test size(apophistable) == (26, 11)
end

@testset "Vector table generation and save to file" begin
    dt0 = Dates.Date(1836)
    dtmax = Dates.Date(1994)
    δt = Dates.Year(5)
    # 900033 corresponds to last Halley's apparition
    file_name = vec_tbl("900033", "Halley.txt", dt0, dtmax, δt; CSV_FORMAT=true);
    @test isfile(file_name)
    @test isfile("Halley.txt")
    @test file_name == "Halley.txt"
    file_name = vec_tbl("900033", "", dt0, dtmax, δt; CSV_FORMAT=true);
    @test isfile(file_name)
end

@testset "Vector table generation with CSV format: vec_tbl_csv" begin
    dt0 = Dates.Date(1950,1,1)
    dtmax = Dates.DateTime(1959, 12, 31, 11, 59, 59, 999)
    δt = Dates.Year(1)
    # 399 corresponds to Earth
    earth_tbl, earth_csv_str = vec_tbl_csv("399", dt0, dtmax, δt; VEC_TABLE = 2)
    @test typeof(earth_tbl) == Array{Any,2}
    @test size(earth_tbl) == (11, 8)
    dtmax = Dates.DateTime(1960, 1, 1, 0, 0, 0, 1)
    earth_tbl, earth_csv_str = vec_tbl_csv("399", dt0, dtmax, δt; VEC_TABLE = 2)
    @test typeof(earth_tbl) == Array{Any,2}
    @test size(earth_tbl) == (12, 8)
    earth_tbl2, earth_csv_str2 = vec_tbl_csv("399", dt0, dtmax, δt; VEC_TABLE = "2")
    @test typeof(earth_tbl2) == Array{Any,2}
    @test size(earth_tbl2) == (12, 8)
    @test earth_tbl == earth_tbl2
    @test earth_csv_str == earth_csv_str2
    # generate table with uncertainties for asteroid 1950 DA
    dt0 = Dates.Date(2000)
    dtmax = Dates.Date(2015)
    δt = Dates.Year(1)
    _1950da_tbl, _1950da_csv_str = vec_tbl_csv("1950 DA", dt0, dtmax, δt; VEC_TABLE = "2xa");
    @test typeof(_1950da_tbl) == Array{Any,2}
    @test size(_1950da_tbl) == (17, 20)
    labels_2xa = ["JDTDB" "Calendar_Date_TDB" "X" "Y" "Z" "VX" "VY" "VZ" "X_s" "Y_s" "Z_s" "VX_s" "VY_s" "VZ_s" "A_s" "C_s" "N_s" "VA_s" "VC_s" "VN_s"]
    for i in eachindex(labels_2xa)
        _1950da_tbl[1, i] = labels_2xa[i]
    end
    #NOTE: the second object returned by vec_tbl_csv may be used to produce a DataFrame!
    # e.g.:
    # using DataFrames
    # mydataframe = readtable(IOBuffer(ea_csv_str))
end
