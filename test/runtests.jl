# This file is part of the HORIZONS.jl package
# The HORIZONS.jl package is licensed under the MIT "Expat" License
# Copyright (c) 2017: Jorge Pérez.

using Test, Dates
using HORIZONS

@testset "Generation and file download of small-bodies binary SPK files: smb_spk" begin
    # Generate a binary SPK file for asteroid 99942 Apophis covering from 2021 to 2029

    local_file = smb_spk("DES = 20099942;", DateTime(2021, Jan, 1), DateTime(2029, Apr, 13))
    @test isfile(local_file)
    rm(local_file)

    local_file = smb_spk("Apophis;", "2021-1-1", "2029-4-13")
    @test isfile(local_file)
    rm(local_file)
end

@testset "Generation and file download of small-bodies binary SPK files: smb_spk_ele" begin
    # Generate a binary SPK file for asteroid 99942 Apophis from its osculating elements
    epoch = 2454733.5
    ec = 0.1911952942528226
    qr = 0.7460724385331012
    tp = 2454894.912507658200
    om = 204.4460284242489
    w = 126.401880836064
    inc = 3.331369228495799
    local_file = smb_spk_ele("99942", DateTime(2021, Jan, 1), DateTime(2022, Jan, 1),
                             epoch, ec, qr, tp, om, w, inc)
    @test isfile(local_file)
    rm(local_file)

    # Generate a binary SPK file for asteroid 1990 MU from its osculating elements
    epoch = 2449526.5
    ec = 0.6570220840219289
    qr = 0.5559654280797371
    tp = 2449448.890787227
    om = 78.10766874391773
    w = 77.40198125423228
    inc = 24.4225258251465
    local_file = smb_spk_ele("1990 MU", DateTime(2021, Jan, 1), DateTime(2022, Jan, 1),
                             epoch, ec, qr, tp, om, w, inc)
    @test isfile(local_file)
    rm(local_file)
end

@testset "Vector table generation: vec_tbl" begin
    # Generate tables and save output to Apophis.txt
    t_start = DateTime(2029, 4, 13)
    t_stop = Date(2029, 4, 14)
    δt = Hour(1)
    local_file = vec_tbl("Apophis;", t_start, t_stop, δt; FILENAME = "Apophis.txt", CENTER = "@ssb",
                         REF_PLANE = "FRAME", OUT_UNITS = "AU-D", CSV_FORMAT = true, VEC_TABLE = 2)

    @test isfile(local_file)

    apophisvt = vec_tbl("Apophis;", t_start, t_stop, δt; CENTER = "@ssb", REF_PLANE = "FRAME",
                        OUT_UNITS = "AU-D", CSV_FORMAT = true, VEC_TABLE = 2)

    x = readlines(local_file)
    y = split(apophisvt, "\n")[1:end-1]

    @test length(x) == length(y)
    lx = length(x)
    inds = setdiff(1:lx,[2, 35]) # Avoid lines 2 and 35, since they have time of retrieval
    @test x[inds] == y[inds]

    rm(local_file)
end

@testset "Observer table generation: obs_tbl" begin
    # Generate tables and save output to Voyager1.txt
    t_start = DateTime(2024, 4, 13)
    t_stop = Date(2024, 4, 14)
    δt = Hour(1)
    local_file = obs_tbl("Voyager 1", t_start, t_stop, δt; CSV_FORMAT = true,
                         FILENAME = "Voyager1.txt", CENTER = "GBT")

    @test isfile(local_file)

    voyager1 = obs_tbl("Voyager 1", t_start, t_stop, δt; CSV_FORMAT = true,
                       CENTER = "GBT")

    x = readlines(local_file)
    y = split(chomp(voyager1), "\n")

    @test length(x) == length(y)
    # Find lines that differ
    diffinds = findall(x .!= y)
    # The only lines that should differ start with "Ephemeris / API_USER" and
    # contain time of retrieval.
    @test all(startswith("Ephemeris / API_USER"), y[diffinds])

    rm(local_file)
end

@testset "Osculating Orbital Elements table generation: ooe_tbl" begin
    # Generate tables and save output to JWST.txt
    t_start = DateTime(2024, 3, 13)
    t_stop = Date(2024, 3, 14)
    δt = Hour(1)
    local_file = ooe_tbl("JWST", t_start, t_stop, δt; CSV_FORMAT = true,
                         FILENAME = "jwst.csv", CENTER = "SSB")

    @test isfile(local_file)

    jwst = ooe_tbl("JWST", t_start, t_stop, δt; CSV_FORMAT = true, CENTER = "SSB")

    x = readlines(local_file)
    y = split(chomp(jwst), "\n")

    @test length(x) == length(y)
    # Find lines that differ
    diffinds = findall(x .!= y)
    # The only lines that should differ start with "Ephemeris / API_USER" and
    # contain time of retrieval.
    @test all(startswith("Ephemeris / API_USER"), y[diffinds])

    rm(local_file)
end

@testset "Small-Body DataBase API" begin
    # Search 433 Eros in three different ways
    eros_1 = sbdb("sstr" => "Eros")
    eros_2 = sbdb("spk" => "2000433")
    eros_3 = sbdb("des" => "433")

    @test eros_1 == eros_2 == eros_3
    @test isa(eros_1, Dict{String, Any})
    @test isa(eros_1["orbit"], Dict{String, Any})
    @test isa(eros_1["signature"], Dict{String, Any})
    @test isa(eros_1["object"], Dict{String, Any})

    # Search Apophis's close approach data
    apophis = sbdb("sstr" => "Apophis", "ca-data" => "true")
    @test isa(apophis, Dict{String, Any})
    @test isa(apophis["orbit"], Dict{String, Any})
    @test isa(apophis["signature"], Dict{String, Any})
    @test isa(apophis["object"], Dict{String, Any})
    @test isa(apophis["ca_data"], Vector{Any})
end

@testset "Small-Body Radar Astrometry API" begin
    # Search Apophis' radar astrometry
    apophis_1 = sbradar("spk" => "20099942")

    @test isa(apophis_1, Dict{String, Any})
    @test isa(apophis_1["fields"], Vector{Any})
    @test isa(apophis_1["signature"], Dict{String, Any})
    @test isa(apophis_1["data"], Vector{Any})
    @test isa(apophis_1["count"], String)
    @test length(apophis_1["data"]) == parse(Int, apophis_1["count"])
    @test apophis_1["fields"] == ["des", "epoch", "value", "sigma", "units",
                                  "freq", "rcvr", "xmit", "bp"]
    @test all(first.(apophis_1["data"]) .== "99942")
    @test apophis_1["signature"]["source"] == "NASA/JPL Small-Body Radar Astrometry API"
    @test VersionNumber(apophis_1["signature"]["version"]) ≥ v"1"

    # Add observer information
    apophis_2 = sbradar("spk" => "20099942", "observer" => "true")
    @test isa(apophis_2, Dict{String, Any})
    @test isa(apophis_2["fields"], Vector{Any})
    @test isa(apophis_2["signature"], Dict{String, Any})
    @test isa(apophis_2["data"], Vector{Any})
    @test isa(apophis_2["count"], String)
    @test length(apophis_2["data"]) == parse(Int, apophis_2["count"])
    @test apophis_2["fields"] == ["des", "epoch", "value", "sigma", "units",
                                  "freq", "rcvr", "xmit", "bp", "observer"]
    @test all(first.(apophis_2["data"]) .== "99942")
    @test apophis_2["signature"]["source"] == "NASA/JPL Small-Body Radar Astrometry API"
    @test VersionNumber(apophis_2["signature"]["version"]) ≥ v"1"

    @test apophis_1["signature"] == apophis_2["signature"]
    @test all(map((x, y) -> x == y[1:end-1], apophis_1["data"], apophis_2["data"]))
    @test apophis_1["count"] == apophis_2["count"]
end

@testset "CNEOS Scout API" begin
    # Get a list of all CNEOS objects
    cneos = scout()

    @test isa(cneos, Dict{String, Any})
    @test isa(cneos["signature"], Dict{String, Any})
    @test isa(cneos["data"], Vector{Any})
    @test isa(cneos["count"], String)
    @test length(cneos["data"]) == parse(Int, cneos["count"])

    fields = Set([
        "neo1kmScore", "geocentricScore", "nObs", "rating", "rate",
        "objectName", "elong", "phaScore", "ieoScore", "ra", "H",
        "arc", "tisserandScore", "lastRun", "unc", "moid", "neoScore",
        "uncP1", "rmsN", "dec", "vInf", "tEphem", "Vmag", "caDist"
    ])
    @test all(map(x -> keys(x) == fields, cneos["data"]))

    # Get orbital elements plots of an object listed in CNEOS
    tdes = cneos["data"][1]["objectName"]
    neocp = scout("tdes" => tdes, "plot" => "el")

    @test isa(neocp, Dict{String, Any})

    fields = Set([
        "neo1kmScore", "geocentricScore", "nObs", "rating", "signature",
        "rate", "H_hist_fig", "qr_e_fig", "objectName", "elong", "phaScore",
        "ieoScore", "ra", "qr_in_fig", "H", "arc", "tisserandScore", "lastRun",
        "unc", "moid", "neoScore", "uncP1", "rmsN", "dec", "vInf", "tEphem",
        "qr_H_fig", "Vmag", "caDist"
    ])
    @test keys(neocp) == fields
end
