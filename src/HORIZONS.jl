# The HORIZONS.jl package is licensed under the MIT "Expat" License:
# Copyright (c) 2017: Jorge Pérez.


module HORIZONS

using HTTP, JSON, Base64, Dates
using HTTP: Messages.Response

export horizons, smb_spk, smb_spk_ele, vec_tbl, obs_tbl, sbdb, sbradar, scout, ooe_tbl

@doc raw"""
    horizons()

Connect to JPL HORIZONS `telnet` interface

`telnet horizons.jpl.nasa.gov 6775`

!!! warning
    To run this function, the `telnet` command line utility should be locally installed and enabled.
"""
horizons() = run(ignorestatus(`telnet horizons.jpl.nasa.gov 6775`))

include("common.jl")
include("horizonsapi.jl")
include("sbdb.jl")
include("sbradar.jl")
include("obstbl.jl")
include("scout.jl")
include("ooetbl.jl")

end # module
