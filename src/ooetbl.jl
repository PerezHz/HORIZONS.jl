@doc raw"""
    ooe_tbl(COMMAND::ObjectName, START_TIME::StartStopTime, STOP_TIME::StartStopTime,
            STEP_SIZE::StepSize; FILENAME::String = "", kwargs...) -> String

Generate an osculating orbital elements table for object `COMMAND` from
`START_TIME` to `STOP_TIME` with step `STEP_SIZE`. If `FILENAME` is empty,
return the output as a `String`; otherwise, save the table to the corresponding
file. For more information see [1], in particular the **Common Parameters** and
**SPK File Parameters** sections; for a list of keyword arguments see the
**Ephemeris-Specific Parameters** section.

!!! reference
    [1] https://ssd-api.jpl.nasa.gov/doc/horizons.html.

# Examples
```julia-repl
# Date variables for start and stop times

t_start = DateTime(2024,4,13)
t_stop = Date(2024,4,14)

# Step size (allowed types: Period, Int, String)

δt = Hour(1) # 1 hour step size

# Generate tables and save output to Voyager1.txt in current directory:

julia> local_file = ooe_tbl("JWST", t_start, t_stop, δt;
                            FILENAME = "JWST.txt", CENTER = "SSB", CSV_FORMAT = true)
"JWST.txt"

julia> isfile(local_file)
true
```

# Extended help

This table summarizes the available keyword argument names, types, default
values, and a brief description:

| Keyword::Type         | Default      | Description                     |
|:----------------------|:------------:|:--------------------------------|
| `FILENAME::String`    | ""           | Output filename                 |
| `CENTER::String`      | "Geocentric" | Reference body/barycenter       |
| `REF_PLANE::String`   | "ECLIPTIC"   | Ephemeris reference plane       |
| `COORD_TYPE::String`  | "GEODETIC"   | Type of user coordinates        |
| `SITE_COORD::String`  | "0,0,0"      | User coordinates for CENTER     |
| `REF_SYSTEM::String`  | "ICRF"       | Astrometric reference frame     |
| `OUT_UNITS::String`   | "KM-S"       | Output units (KM-S, KM-D, AU-D) |
| `CAL_TYPE::String`    | "MIXED"      | Type of calendar                |
| `TIME_DIGITS::String` | "MINUTES"    | Output time precision           |
| `CSV_FORMAT::Bool`    | false        | Output in CSV format            |
| `ELM_LABELS::Bool`    | true         | Include label for each element  |
| `TP_TYPE::String`     | "ABSOLUTE"   | Type of periapsis time (Tp) .   |
| `MAKE_EPHEM::Bool`    | true         | Generate ephemeris              |
| `OBJ_DATA::Bool`      | true         | Include object summary          |
"""
function ooe_tbl(COMMAND::ObjectName, START_TIME::StartStopTime, STOP_TIME::StartStopTime,
                 STEP_SIZE::StepSize; FILENAME::String = "",
                 CENTER::String = "Geocentric", REF_PLANE::String = "ECLIPTIC",
                 COORD_TYPE::String = "GEODETIC", SITE_COORD::String = "0,0,0",
                 REF_SYSTEM::String = "ICRF", OUT_UNITS::String="KM-S",
                 CAL_TYPE::String = "MIXED", TIME_DIGITS::String = "MINUTES",
                 CSV_FORMAT::Bool = false, ELM_LABELS::Bool = true,
                 TP_TYPE::String = "ABSOLUTE", MAKE_EPHEM::Bool = true,
                 OBJ_DATA::Bool = true)

    # HTTP response code and text
    code, text = jplapi(
        HORIZONS_API_URL,
        "COMMAND" => jplstr(COMMAND),
        "EPHEM_TYPE" => "ELEMENTS",
        "START_TIME" => jplstr(Dates.format(DateTime(START_TIME), JPL_DATE_FORMAT)),
        "STOP_TIME" => jplstr(Dates.format(DateTime(STOP_TIME), JPL_DATE_FORMAT)),
        "STEP_SIZE" => jplstr(STEP_SIZE),
        "CENTER" => jplstr(CENTER),
        "REF_PLANE" => jplstr(REF_PLANE),
        "COORD_TYPE" => jplstr(COORD_TYPE),
        "SITE_COORD" => jplstr(SITE_COORD),
        "REF_SYSTEM" => jplstr(REF_SYSTEM),
        "OUT_UNITS" => jplstr(OUT_UNITS),
        "CAL_TYPE" => jplstr(CAL_TYPE),
        "TIME_DIGITS" => jplstr(TIME_DIGITS),
        "CSV_FORMAT" => jplstr(CSV_FORMAT),
        "ELM_LABELS" => jplstr(ELM_LABELS),
        "TP_TYPE" => jplstr(TP_TYPE),
        "MAKE_EPHEM" => jplstr(MAKE_EPHEM),
        "OBJ_DATA" => jplstr(OBJ_DATA)
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