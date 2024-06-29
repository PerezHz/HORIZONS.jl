# This file is part of the HORIZONS.jl package, licensed under the MIT "Expat" License

# Breaking change warning added in v0.4.0; to be deleted in next minor version (v0.5.0)
@warn("""\n
    # Breaking change
    Starting from v0.4.0 HORIZONS.jl connects to JPL via a HTTP API.
    Previous versions used the telnet command line utility as an external dependency.
""")
