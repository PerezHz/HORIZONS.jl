# The HORIZONS.jl package is licensed under the MIT "Expat" License:
# Copyright (c) 2017: Jorge Pérez.

# JPL's Small-Body DataBase API
const SBDB_API_URL = "https://ssd-api.jpl.nasa.gov/sbdb.api"

@doc raw"""
    sbdb(COMMAND::Pair{String, String}, [params::Pair{String, String}...]) -> Dict{String, Any}

Search in JPL's Small-Body DataBase. `COMMAND` must be one of the following query parameters:
`sstr`, `spk`, or `des`; `params` are any other (optional) parameters. For instance, see the 
**Query Parameters** section in [1].

!!! references
    [1] https://ssd-api.jpl.nasa.gov/doc/sbdb.html.

# Examples
```julia-repl
# Search 433 Eros in three different ways 

julia> sbdb("sstr" => "Eros")
Dict{String, Any} with 3 entries:
  "orbit"     => Dict{String, Any}("t_jup"=>"4.582", …
  "signature" => Dict{String, Any}("source"=>"NASA/JPL Small-Body Database (SBDB) API", …
  "object"    => Dict{String, Any}("shortname"=>"433 Eros", …

julia> sbdb("spk" => "2000433")
Dict{String, Any} with 3 entries:
  "orbit"     => Dict{String, Any}("t_jup"=>"4.582", …
  "signature" => Dict{String, Any}("source"=>"NASA/JPL Small-Body Database (SBDB) API", …
  "object"    => Dict{String, Any}("shortname"=>"433 Eros", …

julia> sbdb("des" => "433")
  Dict{String, Any} with 3 entries:
    "orbit"     => Dict{String, Any}("t_jup"=>"4.582", …
    "signature" => Dict{String, Any}("source"=>"NASA/JPL Small-Body Database (SBDB) API", …
    "object"    => Dict{String, Any}("shortname"=>"433 Eros", …

# Search Apophis's close approach data

julia> dict = sbdb("sstr" => "Apophis", "ca-data" => "true")
Dict{String, Any} with 4 entries:
    "orbit"     => Dict{String, Any}("t_jup"=>"6.464", …
    "ca_data"   => Any[Dict{String, Any}("cd"=>"1905-Dec-26 05:03", …
    "signature" => Dict{String, Any}("source"=>"NASA/JPL Small-Body Database (SBDB) API", …
    "object"    => Dict{String, Any}("shortname"=>"99942 Apophis", …
```
"""
function sbdb(COMMAND::Pair{String, String}, params::Pair{String, String}...)
    # HTTP response code and text
    code, text = jplapi(SBDB_API_URL, COMMAND, params...)
    iszero(code) && return Dict{String, Any}()
    # Parse JSON
    dict = jsonparse(text)
    
    return dict
end