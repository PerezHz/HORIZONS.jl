# The HORIZONS.jl package is licensed under the MIT "Expat" License:
# Copyright (c) 2017: Jorge Pérez.

module HORIZONS

using Expect, FTPClient

VERSION ≥ v"0.7.0-DEV.2004" && using DelimitedFiles

export horizons, vec_tbl, vec_tbl_csv, HORIZONS_MACHINE

const HORIZONS_MACHINE = "ssd.jpl.nasa.gov"
const HORIZONS_FTP_DIR = "pub/ssd"
const HORIZONS_DATE_FORMAT = "yyyy-u-dd HH:MM:SS.sss"
const ObjectName = Union{Int, String}
const StartStopTime = Union{Dates.DateTime, Dates.Date, String}
const StepSize = Union{Dates.Period, Int, String}
const VecTable = Union{Int, String}

"""
`horizons()`

Connect to JPL HORIZONS telnet interface

`telnet horizons.jpl.nasa.gov 6775`

"""
function horizons()
run(ignorestatus(`telnet horizons.jpl.nasa.gov 6775`))
end

#auxiliary function which translates a ::Bool to a "YES" or "NO" string
function yesornostring(yesorno::Bool)
    yesorno ? "YES" : "NO"
end

include("vec_tbl.jl")

end # module
