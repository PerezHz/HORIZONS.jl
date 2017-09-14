module HORIZONS

using Expect, FTPClient

export horizons, vectbl

"""
`horizons()`

Connect to JPL HORIZONS telnet interface

`telnet horizons.jpl.nasa.gov 6775`

"""
function horizons()
run(ignorestatus(`telnet horizons.jpl.nasa.gov 6775`))
end

include("vec_tbl.jl")

end # module
