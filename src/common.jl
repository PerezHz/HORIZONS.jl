# The HORIZONS.jl package is licensed under the MIT "Expat" License:
# Copyright (c) 2017: Jorge Pérez.

# For a list of accepted date formats see: 
# https://ssd.jpl.nasa.gov/horizons/manual.html#time
const JPL_DATE_FORMAT = "yyyy-mm-dd HH:MM:SS.sss"

# Input types
const ObjectName = Union{Int, String}
const StartStopTime = Union{DateTime, Date, String}
const StepSize = Union{Period, Int, String}
const VecTable = Union{Int, String}

# See the URL Encoding section in https://ssd-api.jpl.nasa.gov/doc/horizons.html
const JPL_URL_ENCODING = Dict(
    '\n' => "%0A",  # line feed (new-line)
    ' '	=> "%20",   # space
    '#'	=> "%23",   # hash tag
    '$'	=> "%24",   # dollar sign
    '&'	=> "%26",   # ampersand
    '+'	=> "%2B",   # plus sign
    ','	=> "%2C",   # comma
    '/'	=> "%2F",   # slash
    ':'	=> "%3A",   # colon
    ';'	=> "%3B",   # semicolon
    '='	=> "%3D",   # equals sign
    '?'	=> "%3F",   # question mark
    '@'	=> "%40",   # at symbol
    '['	=> "%5B",   # left square bracket
    ']'	=> "%5D"    # right square bracket
)

# Auxiliary function which translates a ::Bool to a "YES" or "NO" string
yesornostring(yesorno::Bool) = yesorno ? "YES" : "NO"

# Return 's'
jplstr(s::String) = string("'", s, "'")
jplstr(s::Union{T, Period}) where {T <: Real} = jplstr(string(s))
jplstr(s::Union{Date, DateTime}) = jplstr(Dates.format(DateTime(s), JPL_DATE_FORMAT))
jplstr(s::Bool) = jplstr(yesornostring(s))

if VERSION < v"1.7"
    function jplurlencoding(s::String)
        res = s
        for pair in JPL_URL_ENCODING
            res = replace(res, pair)
        end
        return res
    end
else
    jplurlencoding(s::String) = replace(s, JPL_URL_ENCODING...)
end

# Assemble URL for HTTP.get from a JPL API
function jplurl(url::String, params::Pair{String, String}...)
    # HTTP URL
    s = Vector{String}(undef, length(params)+2)
    s[1] = url
    s[2] = "?"
    # Add parameters to url
    for i in eachindex(params)
        s[i+2] = string(
            params[i].first,
            "=",
            jplurlencoding(params[i].second),
            i == length(params) ? "" : "&"
        )
    end

    return join(s)
end

# Handle response code and convert response body to String
# See the section HTTP Response Codes in 
# https://ssd-api.jpl.nasa.gov/doc/horizons.html
function responsecode(resp::Response)
    # Response code
    code = resp.status
    # Convert response body to String
    text = String(resp.body)
    # OK (200): normal successful result
    if code == 200 
        return 200, text
    end
    # Parse JSON
    dict = JSON.parse(text)
    # Error message
    if "message" in keys(dict)
        message = dict["message"]
    else
        message = "no error message returned by API"
    end
    # Unsuccessful codes
    if code == 400
        @warn("Bad Request (400): " * message)
    elseif code == 405
        @warn("Method Not Allowed (405): " * message)
    elseif code == 500
        @warn("Internal Server Error (500): " * message)
    elseif code == 503
        @warn("Service Unavailable (503): " * message)
    else
        @warn("Unknown Response Code: " * message)
    end

    return 0, text
end

# GET request to a JPL API
function jplapi(url::String, params::Pair{String, String}...)
    # HTTP URL
    url = jplurl(url, params...)
    # HTTP response
    resp = HTTP.get(url; status_exception = false) 
    # Response code and text
    code, text = responsecode(resp)

    return code, text
end

# JSON.parse sometimes requires 2 calls to return a Dict{String, Any}
function jsonparse(text::String)
    dict = JSON.parse(text)
    if isa(dict, Dict{String, Any})
        return dict
    else
        _dict_ = JSON.parse(dict)
        if isa(_dict_, Dict{String, Any})
            return _dict_
        else
            return Dict{String, Any}()
        end
    end
end