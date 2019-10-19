# This file is part of the HORIZONS.jl package
# The HORIZONS.jl package is licensed under the MIT "Expat" License
# Copyright (c) 2017: Jorge Pérez.

using Test, Dates, DelimitedFiles
using HORIZONS, Expect

@testset "Test connection to HORIZONS machine using Expect.jl" begin
    proc = ExpectProc(`telnet $HORIZONS_MACHINE 6775`, 15)
    @show proc.proc
    # Get main prompt and proceed, turning off paging, specifying I/O model,
    # and sending object look-up from command-line
    idx = expect!(proc, ["unknown host", "Horizons> "])
    if idx == 1
        throw("This system cannot find $HORIZONS_MACHINE")
    end
    @test idx == 2
end

@testset "Vector table generation: vec_tbl" begin
    dt0 = DateTime(2029,4,13)
    dtmax = Date(2029,4,14)
    δt = Hour(1)
    apophisraw = vec_tbl("Apophis", dt0, dtmax, δt; CSV_FORMAT=true);
    @test isa(apophisraw, String)
    @test occursin("\$\$SOE", apophisraw)
    @test occursin("\$\$EOE", apophisraw)
    @test occursin(r"\$\$SOE", apophisraw)
    @test occursin(r"\$\$EOE", apophisraw)
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

    dt0 = Date(2000); dtmax = Date(2015); δt = Year(1);

    #test case VEC_LABELS=true
    out_str = vec_tbl("1950 DA", dt0, dtmax, δt; VEC_LABELS=true)
    @test isa(out_str, String)
    @test occursin("\$\$SOE", out_str)
    @test occursin("\$\$EOE", out_str)
    @test occursin(r"\$\$SOE.*\$\$EOE"s, out_str)
    @test occursin(r"JDTDB\r\n.*X.*Y.*Z\r\n.*VX.*VY.*VZ\r\n.*LT.*RG.*RR", out_str)
    @test occursin(r"\*+\r\nJDTDB\r\n.*X.*Y.*Z\r\n.*VX.*VY.*VZ\r\n.*LT.*RG.*RR\r\n\*+", out_str)
    @test occursin(r"\*+\r\n\$\$SOE\r\n.*\r\n\$\$EOE\r\n\*+"s, out_str)
    @test occursin(r"\$\$SOE\r\n[0-9]+.[0-9]+ = A.D. [0-9]{4}-[A-Z][a-z]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}.[0-9]{4} TDB \r\n X = ", out_str)

    #test case VEC_LABELS=false
    out_str = vec_tbl("1950 DA", dt0, dtmax, δt; VEC_LABELS=false, CENTER="Paris", REF_PLANE="E")
    @test isa(out_str, String)
    @test occursin("\$\$SOE", out_str)
    @test occursin("\$\$EOE", out_str)
    @test occursin(r"\$\$SOE.*\$\$EOE"s, out_str)
    @test occursin(r"JDTDB\r\n.*X.*Y.*Z\r\n.*VX.*VY.*VZ\r\n.*LT.*RG.*RR", out_str)
    @test occursin(r"\*+\r\nJDTDB\r\n.*X.*Y.*Z\r\n.*VX.*VY.*VZ\r\n.*LT.*RG.*RR\r\n\*+", out_str)
    @test occursin(r"\*+\r\n\$\$SOE\r\n.*\r\n\$\$EOE\r\n\*+"s, out_str)
    @test occursin(r"\$\$SOE\r\n[0-9]+.[0-9]+ = A.D. [0-9]{4}-[A-Z][a-z]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}.[0-9]{4} TDB \r\n +[0-9]+.[0-9]+E[+,-][0-9]+ +[0-9]+.[0-9]+E[+,-][0-9]+", out_str)
end

@testset "Vector table generation with CSV format: vec_tbl_csv" begin
    dt0 = Date(1950,1,1)
    dtmax = DateTime(1959, 12, 31, 11, 59, 59, 999)
    δt = Year(1)
    # 399 corresponds to Earth
    earth_tbl, earth_csv_str = vec_tbl_csv("399", dt0, dtmax, δt; VEC_TABLE = 2)
    @test typeof(earth_tbl) == Array{Any,2}
    @test size(earth_tbl) == (11, 8)
    dtmax = DateTime(1960, 1, 1, 0, 0, 0, 1)
    earth_tbl, earth_csv_str = vec_tbl_csv("399", dt0, dtmax, δt; VEC_TABLE = 2)
    @test typeof(earth_tbl) == Array{Any,2}
    @test size(earth_tbl) == (12, 8)
    earth_tbl2, earth_csv_str2 = vec_tbl_csv("399", dt0, dtmax, δt; VEC_TABLE = "2")
    @test typeof(earth_tbl2) == Array{Any,2}
    @test size(earth_tbl2) == (12, 8)
    @test earth_tbl == earth_tbl2
    @test earth_csv_str == earth_csv_str2
    # generate table with uncertainties for asteroid 1950 DA
    dt0 = Date(2000)
    dtmax = Date(2015)
    δt = Year(1)
    _1950da_tbl, _1950da_csv_str = vec_tbl_csv("1950 DA", dt0, dtmax, δt;
        VEC_TABLE = "2xa", REF_PLANE="F", CENTER="coord", COORD_TYPE="C", SITE_COORD="1,45,45")
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

### CI is failing currently for these test in Linux due to ftp issues on travis
### For more details, see https://blog.travis-ci.com/2018-07-23-the-tale-of-ftp-at-travis-ci
@testset "Vector table generation and write output to file: vec_tbl" begin
    dt0 = Date(1836)
    dtmax = Date(1994)
    δt = Year(5)
    # 90000033 corresponds to last Halley's apparition
    file_name = vec_tbl("90000033", "Halley.txt", dt0, dtmax, δt; CSV_FORMAT=true, ftp_verbose=true);
    @test isfile(file_name)
    @test isfile("Halley.txt")
    @test file_name == "Halley.txt"
    file_name = vec_tbl("90000033", "", dt0, dtmax, δt; ftp_verbose=true, CSV_FORMAT=true);
    @test isfile(file_name)
end

### CI is failing currently for these test in Linux due to ftp issues on travis
### For more details, see https://blog.travis-ci.com/2018-07-23-the-tale-of-ftp-at-travis-ci
@testset "Generation and file download of small-bodies binary SPK files: smb_spk" begin
    smb_spk("b", "DES= 2099942;", DateTime(2021,Jan,1), DateTime(2029,Apr,13), "joe@your.domain.name")
    @test isfile("2099942.bsp")
    smb_spk("b", "DES= 2099942;", DateTime(2021,Jan,1), DateTime(2029,Apr,13), "joe@your.domain.name", "mybinaryspk.apophis")
    smb_spk("b", "DES= 2099942;", DateTime(2021,Jan,1), DateTime(2029,Apr,13), "joe@your.domain.name", "mybinaryspk.apophis", ftp_verbose=true)
    @test isfile("mybinaryspk.apophis")
    smb_spk("b", "DES= 2099942;", "2021-1-1", "2029-4-13T21:46:07.999", "joe@your.domain.name", "2099942_.bsp")
    smb_spk("b", "DES= 2099942;", "2021-1-1", "2029-4-13T21:46:07.999", "joe@your.domain.name", "2099942_.bsp", ftp_verbose=true)
    @test isfile("2099942_.bsp")
end

@testset "Test for erroneous arguments" begin
    @test_throws ArgumentError vec_tbl_csv("erroneous-input", Date(2000), Date(2010), Year(1))
    @test_throws ArgumentError vec_tbl_csv(99942, Date(2000), Date(2010), Year(1); CENTER="nomatch")
    @test_throws ArgumentError vec_tbl_csv(499, Date(2009), Date(2010), Year(1); VEC_TABLE = 1, CENTER="mars")
    dt0 = Date(2000); dtmax = Date(2015); δt = Year(1)
    @test_throws ArgumentError vec_tbl_csv("1950 DA", dt0, dtmax, δt; VEC_TABLE = "2xa", CENTER="coord", COORD_TYPE="w")
    @test_throws ArgumentError vec_tbl_csv("1950 DA", dt0, dtmax, δt; VEC_TABLE = "2xa", CENTER="coord", COORD_TYPE="%")
    @test_throws ArgumentError vec_tbl_csv("1950 DA", dt0, dtmax, δt; VEC_TABLE = "2xa", CENTER="coord", COORD_TYPE="")
    @test_throws ArgumentError vec_tbl_csv("1950 DA", dt0, dtmax, δt; VEC_TABLE = "2xa", CENTER="coord", COORD_TYPE="c", SITE_COORD="a,b,c")
    @test_throws ArgumentError vec_tbl_csv("1950 DA", dt0, dtmax, δt; VEC_TABLE = "2xa", CENTER="coord", COORD_TYPE="c", SITE_COORD="")
    @test_throws ArgumentError vec_tbl_csv("1950 DA", dt0, dtmax, δt; REF_PLANE="T", VEC_TABLE = "2xa", CENTER="coord", COORD_TYPE="c", SITE_COORD="10,1,1")
    @test_throws ArgumentError vec_tbl_csv("1950 DA", "1400-1-1", dtmax, δt)
    @test_throws ArgumentError vec_tbl_csv("1950 DA", "bad-start-time", dtmax, δt)
    @test_throws ArgumentError vec_tbl_csv("1950 DA", dt0, "3500-2-1", δt)
    @test_throws ArgumentError vec_tbl_csv("1950 DA", dt0, "bad-stop-time", δt)
    @test_throws ArgumentError vec_tbl_csv("1950 DA", dt0, dtmax, "1 w")
    @test_throws ArgumentError vec_tbl_csv("1950 DA", dt0, dtmax, "bad-step_size")
    @test_throws TypeError vec_tbl_csv("1950 DA", dt0, dtmax, δt; VEC_LABELS=0)
    @test_throws TypeError vec_tbl("1950 DA", dt0, dtmax, δt; VEC_LABELS=0)
end
