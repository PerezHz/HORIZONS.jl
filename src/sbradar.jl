# The HORIZONS.jl package is licensed under the MIT "Expat" License:
# Copyright (c) 2017: Jorge Pérez.

# JPL's Small-Body Radar Astrometry API
const SBRADAR_API_URL = "https://ssd-api.jpl.nasa.gov/sb_radar.api"

@doc raw"""
    sbradar(params::Pair{String, String}...) -> Dict{String, Any}

Search in JPL's Small-Body Radar Astrometry DataBase. For a list of query parameters
see the **Query Parameters** section in [1].

!!! references
    [1] https://ssd-api.jpl.nasa.gov/doc/sb_radar.html.

# Examples
```julia-repl
# Search Apophis' radar astrometry

julia> sbradar("spk" => "20099942")
Dict{String, Any} with 4 entries:
  "fields"    => Any["des", …
  "signature" => Dict{String, Any}("source"=>"NASA/JPL Small-Body Radar Astrometry API", …
  "data"      => Any[Any["99942", …
  "count"     => "50"

# Add observer information

julia> sbradar("spk" => "20099942", "observer" => "true")
Dict{String, Any} with 4 entries:
  "fields"    => Any["des", …
  "signature" => Dict{String, Any}("source"=>"NASA/JPL Small-Body Radar Astrometry API", …
  "data"      => Any[Any["99942", …
  "count"     => "50"
```
"""
function sbradar(params::Pair{String, String}...)
    # HTTP response code and text
    code, text = jplapi(SBRADAR_API_URL, params...)
    iszero(code) && return Dict{String, Any}()
    # Parse JSON
    dict = jsonparse(text)

    return dict
end