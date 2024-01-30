# The HORIZONS.jl package is licensed under the MIT "Expat" License:
# Copyright (c) 2017: Jorge Pérez.

# JPL's Horizons API
const HORIZONS_API_URL = "https://ssd.jpl.nasa.gov/api/horizons.api"

# Vector table object name regex
const HORIZONS_NAME_REGEX = Regex(string(
    raw"Target body name: ",
    raw"(?<id>[\d\s]*)?",
    raw"(?<name>[\w\s]*)",
    raw"\((?<des>[\d\s\w]*)\)",
    raw"\s*\{"
))

@doc raw"""
    smb_spk(COMMAND::ObjectName, START_TIME::StartStopTime, STOP_TIME::StartStopTime) -> String

Generate binary SPK file of Solar System Small Body `COMMAND` between `START_TIME` and
`STOP_TIME`. Return the local SPK file name. For more information see [1], in particular
the **Common Parameters** and **SPK File Parameters** sections.

!!! reference
    [1] https://ssd-api.jpl.nasa.gov/doc/horizons.html.

# Examples
```julia-repl
# Generate a binary SPK file for asteroid 99942 Apophis covering from 2021 to 2029

julia> local_file = smb_spk("DES = 20099942;", DateTime(2021,Jan,1), DateTime(2029,Apr,13))
"20099942.bsp"

# Check that the binary SPK file `local_file` exists

julia> isfile(local_file)
true
```
"""
function smb_spk(COMMAND::ObjectName, START_TIME::StartStopTime, STOP_TIME::StartStopTime)
    # Convert HTTP parameters to String
    command_str = jplstr(COMMAND)
    start_time_str = jplstr(Dates.format(DateTime(START_TIME), JPL_DATE_FORMAT))
    stop_time_str = jplstr(Dates.format(DateTime(STOP_TIME), JPL_DATE_FORMAT))
    # HTTP response code and text
    code, text = jplapi(
        HORIZONS_API_URL,
        "COMMAND" => command_str,
        "EPHEM_TYPE" => "SPK",
        "START_TIME" => start_time_str,
        "STOP_TIME" => stop_time_str,
        "OBJ_DATA" => "NO"
    )
    iszero(code) && return ""
    # Parse JSON
    dict = jsonparse(text)
    # Object ID
    if "spk_file_id" in keys(dict)
        id = dict["spk_file_id"]
    else
        println(dict["result"])
        return ""
    end
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

@doc raw"""
    smb_spk_ele(COMMAND::ObjectName, START_TIME::StartStopTime, STOP_TIME::StartStopTime,
                EPOCH::T, EC::T, QR::T, TP::T, OM::T, W::T, INC::T) where {T <: Real} -> String

Generate binary SPK file of Solar System Small Body `COMMAND` between `START_TIME` and
`STOP_TIME` with heliocentric ecliptic osculating elements:
- `EPOCH`: Julian Day number (JDTDB)
- `EC`: Eccentricity
- `QR` [au]: Perihelion distance
- `TP`: Perihelion Julian Day number
- `OM` [deg]: Longitude of ascending node wrt ecliptic
- `W` [deg]: Argument of perihelion wrt ecliptic
- `IN` [deg]: Inclination wrt ecliptic
Return the local SPK file name. For more information see [1], in particular
the **Common Parameters**, **User-specified Heliocentric Ecliptic Osculating Elements**
and **SPK File Parameters** sections.

!!! reference
    [1] https://ssd-api.jpl.nasa.gov/doc/horizons.html.

# Examples
```julia-repl
# Osculating elements

epoch = 2449526.5           # Epoch, in Barycentric Dynamical Time (TDB)
ec = 0.6570220840219289     # Orbital eccentricity
qr = 0.5559654280797371     # Perihelion distance
tp = 2449448.890787227      # Julian date of perihelion passage
om = 78.10766874391773      # Longitude of ascending node
w = 77.40198125423228       # Argument of perihelion
inc = 24.4225258251465      # Inclination

start_time = DateTime(2021,Jan,1)
stop_time = DateTime(2022,Jan,1)

# Generate a binary SPK file for asteroid 1990 MU at `epoch`

julia> local_file = smb_spk_ele("1990 MU", start_time, stop_time, epoch, ec, qr, tp, om, w, inc)
"20004953.bsp"

# Check that the binary SPK was downloaded

julia> isfile(local_file)
true
```
"""
function smb_spk_ele(COMMAND::ObjectName, START_TIME::StartStopTime, STOP_TIME::StartStopTime,
                     EPOCH::T, EC::T, QR::T, TP::T, OM::T, W::T, INC::T) where {T <: Real}

    # Convert http parameters to String
    command_str = jplstr(COMMAND)
    start_time_str = jplstr(Dates.format(DateTime(START_TIME), JPL_DATE_FORMAT))
    stop_time_str = jplstr(Dates.format(DateTime(STOP_TIME), JPL_DATE_FORMAT))
    epoch_str = jplstr(EPOCH)
    ec_str = jplstr(EC)
    qr_str = jplstr(QR)
    tp_str = jplstr(TP)
    om_str = jplstr(OM)
    w_str = jplstr(W)
    inc_str = jplstr(INC)
    # HTTP response code and text
    code, text = jplapi(
        HORIZONS_API_URL,
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
    iszero(code) && return ""
    # Parse JSON
    dict = JSON.parse(text)
    # Object ID
    if "spk_file_id" in keys(dict)
        id = dict["spk_file_id"]
    else
        println(dict["result"])
        return ""
    end
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

@doc raw"""
    vec_tbl(COMMAND::ObjectName, START_TIME::StartStopTime, STOP_TIME::StartStopTime,
            STEP_SIZE::StepSize; FILENAME::String = "", kwargs...) -> String

Generate vector table of Solar System Small Body `COMMAND` from `START_TIME`
to `STOP_TIME` with step `STEP_SIZE`. If `FILENAME` is empty, return the output as
a `String`; otherwise, save the table to the corresponding file. For more information
see [1], in particular the **Common Parameters** and **SPK File Parameters** sections;
for a list of keyword arguments see the **Ephemeris-Specific Parameters** section.

!!! reference
    [1] https://ssd-api.jpl.nasa.gov/doc/horizons.html.

# Examples
```julia-repl
# Date variables for start and stop times

t_start = DateTime(2029,4,13)
t_stop = Date(2029,4,14)

# Step size (allowed types: Period, Int, String)

δt = Hour(1) # 1 hour step size

# Generate tables and save output to Apophis.txt in current directory:

julia> local_file = vec_tbl("Apophis;", t_start, t_stop, δt; FILENAME = "Apophis.txt", CENTER = "@ssb",
                            REF_PLANE = "FRAME", OUT_UNITS = "AU-D", CSV_FORMAT = true, VEC_TABLE = 2)
"Apophis.txt"

julia> isfile(local_file)
true
```
"""
function vec_tbl(COMMAND::ObjectName, START_TIME::StartStopTime, STOP_TIME::StartStopTime,
                 STEP_SIZE::StepSize; FILENAME::String = "", CENTER::String = "@ssb",
                 REF_PLANE::String = "FRAME", COORD_TYPE::String = "G", SITE_COORD::String = "0,0,0",
                 REF_SYSTEM::String = "J2000", VEC_CORR::String = "NONE", VEC_DELTA_T::Bool = false,
                 OUT_UNITS::String = "KM-S", CSV_FORMAT::Bool = false, VEC_LABELS::Bool = false,
                 VEC_TABLE::VecTable = 3)

    # Convert http parameters to String
    command_str = jplstr(COMMAND)
    start_time_str = jplstr(Dates.format(DateTime(START_TIME), JPL_DATE_FORMAT))
    stop_time_str = jplstr(Dates.format(DateTime(STOP_TIME), JPL_DATE_FORMAT))
    step_size_str = jplstr(STEP_SIZE)
    center_str = jplstr(CENTER)
    ref_plane_str = jplstr(REF_PLANE)
    coord_type_str = jplstr(COORD_TYPE)
    site_coord_str = jplstr(SITE_COORD)
    ref_system_str = jplstr(REF_SYSTEM)
    vec_corr_str = jplstr(VEC_CORR)
    vec_delta_t_str = jplstr(VEC_DELTA_T)
    out_units_str = jplstr(OUT_UNITS)
    csv_format_str = jplstr(CSV_FORMAT)
    vec_labels_str = jplstr(VEC_LABELS)
    vec_table_str = jplstr(VEC_TABLE)
    # HTTP response code and text
    code, text = jplapi(
        HORIZONS_API_URL,
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
    iszero(code) && return ""
    # Parse JSON
    dict = jsonparse(text)
    # Return table as String
    if isempty(FILENAME)
        return dict["result"]
    # Save table to FILENAME
    else
        open(FILENAME, "w") do file
            write(file, dict["result"])
        end
        return FILENAME
    end
end