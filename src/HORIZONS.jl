module HORIZONS

using Expect, FTPClient

export horizons, vec_tbl

const HORIZONS_MACHINE = "ssd.jpl.nasa.gov"
const HORIZONS_FTP_DIR = "pub/ssd"
const HORIZONS_DATE_FORMAT = "yyyy-u-dd HH:MM:SS.sss"
const DateOrDateTime = Union{Dates.DateTime, Dates.Date}

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
