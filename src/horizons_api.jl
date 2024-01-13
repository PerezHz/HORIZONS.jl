struct API end

const HORIZONS_API_URL = "https://ssd.jpl.nasa.gov/api/horizons.api"

const HORIZONS_URL_ENCODING = Dict(
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

const HORIZONS_API_DATEFORMAT = "yyyy-mm-dd HH:MM:SS.sss"

const HORIZONS_NAME_REGEX = Regex(string(
    raw"Target body name: ",
    raw"(?<id>[\d\s]*)?",
    raw"(?<name>[\w\s]*)",
    raw"\((?<des>[\d\s\w]*)\)",
    raw"\s*\{"
))

# Return 's'
horizonstr(s::String) = string("'", s, "'")
horizonstr(s::T) where {T <: Real} = string("'", string(s), "'")
horizonstr(s::StepSize) = string("'", string(s), "'")
horizonstr(s::StartStopTime) = string("'", Dates.format(DateTime(s), HORIZONS_API_DATEFORMAT), "'")
horizonstr(s::Bool) = string("'", yesornostring(s), "'")

# Assemble url for HTTP.get from HORIZONS API
function horizons_url(url::String, params::Pair{String, String}...)
    # HTTP URL
    s = Vector{String}(undef, length(params)+2)
    s[1] = url
    s[2] = "?"
    # Add parameters to url
    for i in eachindex(params)
        s[i+2] = string(
            params[i].first, 
            "=", 
            replace(params[i].second, HORIZONS_URL_ENCODING...),
            i == length(params) ? "" : "&"
        )
    end

    return join(s)
end

# Plain request to HORIZONS API
function horizons_api(params::Pair{String, String}...)
    # HTTP URL
    url = horizons_url(HORIZONS_API_URL, params...)
    # HTTP response
    resp = HTTP.get(url)

    return resp
end

# Handle HTTP response code
function responsecode(code::Integer)
    if code == 200
        # OK normal successful result
        return 200
    elseif code == 400
        @warn("
        Bad Request (400): the request contained invalid keywords and/or content
        or used a request-method other than GET or POST (details returned in the
        JSON or text payload).
        ")
    elseif code == 405
        @warn("
        Method Not Allowed (405): the request used an incorrect method (see the 
        HTTP Request section).
        ")
    elseif code == 500
        @warn("
        Internal Server Error (500): the database is not available at the time 
        of the request.
        ")
    elseif code == 503
        @warn("
        Service Unavailable (503): the server is currently unable to handle the
        request due to a temporary overloading or maintenance of the server, 
        which will likely be alleviated after some delay.
        ")
    else
        @warn("""
        Unknown Response Code.
        """)
    end

    return 0
end

@doc raw"""
    smb_spk(COMMAND::ObjectName, START_TIME::StartStopTime, STOP_TIME::StartStopTime, ::Val{API})

Generate binary SPK file of Solar System small body `COMMAND` between `START_TIME` and
`STOP_TIME`.

!!! reference
    For more information see https://ssd-api.jpl.nasa.gov/doc/horizons.html.
"""
function smb_spk(COMMAND::ObjectName, START_TIME::StartStopTime, STOP_TIME::StartStopTime, ::Val{API})
    # Convert HTTP parameters to String
    command_str = horizonstr(COMMAND)
    start_time_str = horizonstr(START_TIME)
    stop_time_str = horizonstr(STOP_TIME)
    # HTTP response
    resp = horizons_api(
        "COMMAND" => command_str,    
        "EPHEM_TYPE" => "SPK", 
        "START_TIME" => start_time_str,
        "STOP_TIME" => stop_time_str,
        "OBJ_DATA" => "NO"
    )
    # Handle response code
    code = responsecode(resp.status)
    iszero(code) && return ""
    # Convert response body to String
    text = String(resp.body)
    # Parse JSON
    dict = JSON.parse(text)
    # Object ID
    id = dict["spk_file_id"]
    # Filename
    filename = id * ".bsp"
    # Decode
    dec = base64decode(dict["spk"])
    # Save .bsp file
    open(filename, "w") do file
        write(file, dec)
    end

    return filename
end

# Find name in vector table response
function vect_tbl_fname(text::String)
    m = match(HORIZONS_NAME_REGEX, text)
    if isnothing(m)
        return "unknown"
    elseif !isempty(m[1])
        return replace(strip(m[1]), " " => "")
    elseif !isempty(m[3])
        return replace(strip(m[3]), " " => "")
    else
        return replace(strip(m[2]), " " => "")
    end
end

@doc raw"""
    vec_tbl(COMMAND::ObjectName, START_TIME::StartStopTime, STOP_TIME::StartStopTime,
            STEP_SIZE::StepSize, ::Val{API}; kwargs...)

Save to a `.txt` file the vector table of body `COMMAND` from `START_TIME` to `STOP_TIME`
with step `STEP_SIZE`.

!!! reference
    For more information see https://ssd-api.jpl.nasa.gov/doc/horizons.html.
"""
function vec_tbl(COMMAND::ObjectName, START_TIME::StartStopTime, STOP_TIME::StartStopTime,
                 STEP_SIZE::StepSize, ::Val{API}; CENTER::String = "@ssb", REF_PLANE::String = "FRAME",
                 COORD_TYPE::String = "G", SITE_COORD::String = "0,0,0", REF_SYSTEM::String = "J2000",  
                 VEC_CORR::String = "NONE", VEC_DELTA_T::Bool = false, OUT_UNITS::String = "KM-S",
                 CSV_FORMAT::Bool = false, VEC_LABELS::Bool = false, VEC_TABLE::VecTable = 3)

    # Convert http parameters to String
    command_str = horizonstr(COMMAND)
    start_time_str = horizonstr(START_TIME)
    stop_time_str = horizonstr(STOP_TIME)
    step_size_str = horizonstr(STEP_SIZE)
    center_str = horizonstr(CENTER)
    ref_plane_str = horizonstr(REF_PLANE)
    coord_type_str = horizonstr(COORD_TYPE)
    site_coord_str = horizonstr(SITE_COORD)
    ref_system_str = horizonstr(REF_SYSTEM)
    vec_corr_str = horizonstr(VEC_CORR)
    vec_delta_t_str = horizonstr(VEC_DELTA_T)
    out_units_str = horizonstr(OUT_UNITS)
    csv_format_str = horizonstr(CSV_FORMAT)
    vec_labels_str = horizonstr(VEC_LABELS)
    vec_table_str = horizonstr(VEC_TABLE)
    # HTTP response
    resp = horizons_api(
        "COMMAND" => command_str,    
        "EPHEM_TYPE" => "VECTORS", 
        "START_TIME" => start_time_str,
        "STOP_TIME" => stop_time_str,
        "STEP_SIZE" => step_size_str,
        "CENTER" => center_str,
        "REF_PLANE" => ref_plane_str,
        "COORD_TYPE" => coord_type_str,
        "SITE_COORD" => site_coord_str,
        "REF_SYSTEM" => ref_system_str,
        "VEC_CORR" => vec_corr_str,
        "VEC_DELTA_T" => vec_delta_t_str,
        "OUT_UNITS" => out_units_str,
        "CSV_FORMAT" => csv_format_str,
        "VEC_LABELS" => vec_labels_str,
        "VEC_TABLE" => vec_table_str
    )
    # Handle response code
    code = responsecode(resp.status)
    iszero(code) && return ""
    # Convert response body to String
    text = String(resp.body)
    # Filename
    filename = vect_tbl_fname(text) * ".txt"
    # Parse JSON
    dict = JSON.parse(text)
    # Save .txt file
    open(filename, "w") do file
        write(file, dict["result"])
    end
    
    return filename
end

@doc raw"""
    smb_spk_ele(COMMAND::ObjectName, START_TIME::StartStopTime, STOP_TIME::StartStopTime, 
                EPOCH::T, EC::T, QR::T, TP::T, OM::T, W::T, INC::T, ::Val{API}) where {T <: Real}

Generate binary SPK file of Solar System small body `COMMAND` between `START_TIME` and
`STOP_TIME` with heliocentric ecliptic osculating elements:
- `EC`: Eccentricity
- `QR` [au]: Perihelion distance
- `TP`: Perihelion Julian Day number
- `OM` [deg]: Longitude of ascending node wrt ecliptic
- `W` [deg]: Argument of perihelion wrt ecliptic
- `IN` [deg]: Inclination wrt ecliptic

!!! reference
    For more information see https://ssd-api.jpl.nasa.gov/doc/horizons.html.
"""
function smb_spk_ele(COMMAND::ObjectName, START_TIME::StartStopTime, STOP_TIME::StartStopTime, 
                     EPOCH::T, EC::T, QR::T, TP::T, OM::T, W::T, INC::T, ::Val{API}) where {T <: Real}

    # Convert http parameters to String
    command_str = horizonstr(COMMAND)
    start_time_str = horizonstr(START_TIME)
    stop_time_str = horizonstr(STOP_TIME)
    epoch_str = horizonstr(EPOCH)
    ec_str = horizonstr(EC)
    qr_str = horizonstr(QR)
    tp_str = horizonstr(TP)
    om_str = horizonstr(OM)
    w_str = horizonstr(W)
    inc_str = horizonstr(INC)
    # HTTP response
    resp = horizons_api(
        "COMMAND" => command_str,    
        "EPHEM_TYPE" => "SPK", 
        "START_TIME" => start_time_str,
        "STOP_TIME" => stop_time_str,
        "OBJ_DATA" => "NO",
        "EPOCH" => epoch_str,
        "EC" => ec_str,
        "QR" => qr_str,
        "TP" => tp_str,
        "OM" => om_str,
        "W" => w_str,
        "IN" => inc_str
    )
    # Handle response code
    code = responsecode(resp.status)
    iszero(code) && return ""
    # Convert response body to String
    text = String(resp.body)
    # Parse JSON
    dict = JSON.parse(text)
    # Object ID
    id = dict["spk_file_id"]
    # Filename
    filename = id * ".bsp"
    # Decode
    dec = base64decode(dict["spk"])
    # Save .bsp file
    open(filename, "w") do file
        write(file, dec)
    end

    return filename
end

#=  
The examples in README.md can be reproduced with the new API as follows:

using HORIZONS, Dates

# smb_spk

# Generate a binary SPK file for asteroid 99942 Apophis covering from 2021 to 2029
local_file = smb_spk("DES= 2099942;", DateTime(2021,Jan,1), DateTime(2029,Apr,13), Val(HORIZONS.API))

isfile(local_file) # Check that the binary SPK file `local_file` exists

# smb_spk_ele

epoch = 2449526.5 # Osculating elements epoch, in Barycentric Dynamical Time (TDB)
ec = 0.6570220840219289 # Orbital eccentricity
qr = 0.5559654280797371 # Perihelion distance
tp = 2449448.890787227 # Julian date of perihelion passage
om = 78.10766874391773 # Longitude of ascending node
w = 77.40198125423228 # Argument of perihelion
inc = 24.4225258251465 # Inclination

start_time = DateTime(2021,Jan,1)
stop_time = DateTime(2022,Jan,1)

# Generate a binary SPK file for asteroid 1990 MU at `epoch`
local_file = smb_spk_ele("1990 MU", start_time, stop_time, epoch, ec, qr, tp, om, w, inc, Val(HORIZONS.API))

isfile(local_file) # Check that the binary SPK was downloaded

# vec_tbl

# Date variables for start and stop times
t_start = DateTime(2029,4,13)
t_stop = Date(2029,4,14)

# Step size (allowed types: Period, Int, String)
δt = Hour(1) # 1 hour step size

# Generate tables and save output to 99942.txt in current directory:
vec_tbl("Apophis;", t_start, t_stop, δt, Val(HORIZONS.API); CENTER = "@ssb", REF_PLANE = "FRAME",
        OUT_UNITS = "AU-D", CSV_FORMAT = true, VEC_TABLE = 2)
=#