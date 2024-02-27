# The HORIZONS.jl package is licensed under the MIT "Expat" License:
# Copyright (c) 2017: Jorge Pérez.

# JPL's Small-Body DataBase API
const SCOUT_API_URL = "https://ssd-api.jpl.nasa.gov/scout.api"

@doc raw"""
    scout(COMMAND::Pair{String, String}, params::Pair{String, String}...)

Search in JPL's CNEOS Scout system. For a list of query parameters
see the **Query Parameters** section in [1].

!!! references
    [1] https://ssd-api.jpl.nasa.gov/doc/scout.html.

# Examples
```julia-repl
# Get a list of all CNEOS objects

julia> scout()
Dict{String, Any} with 3 entries:
  "signature" => Dict{String, Any}("source"=>"NASA/JPL Scout API", "version"=>"1.3")
  "data"      => Any[Dict{String, Any}("neo1kmScore"=>0, …
  "count"     => "22"

# Get orbital elements plots of JYRh1Iu
# Warning: JYRh1Iu may no longer be listed in CNEOS

julia> scout("tdes" => "JYRh1Iu", "plot" => "el")
Dict{String, Any} with 29 entries:
  "neo1kmScore"     => 0
  "geocentricScore" => 0
  "nObs"            => 4
  "rating"          => 0
  "signature"       => Dict{String, Any}("source"=>"NASA/JPL Scout API", "version"=>"1.3")
  "rate"            => "0.7"
  "H_hist_fig"      => "iVBORw0KGgoAAAA …
  …
```
"""
function scout(params::Pair{String, String}...)
    # HTTP response code and text
    code, text = jplapi(SCOUT_API_URL, params...)
    iszero(code) && return Dict{String, Any}()
    # Parse JSON
    dict = jsonparse(text)

    return dict
end