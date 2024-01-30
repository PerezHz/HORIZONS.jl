# The HORIZONS.jl package is licensed under the MIT "Expat" License:
# Copyright (c) 2017: Jorge Pérez.

module HORIZONS

using HTTP, JSON, Base64, Dates
using HTTP: Messages.Response

export horizons, smb_spk, smb_spk_ele, vec_tbl, sbdb, sbradar

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

function __init__()

    # Breaking change warning added in v0.4.0; to be deleted in next minor version (v0.5.0)
    @warn("""\n
        # Breaking change
        Starting from v0.4.0 HORIZONS.jl connects to JPL via a HTTP API.
        Previous versions used the telnet command line utility as an external dependency.
    """)

end


end # module
