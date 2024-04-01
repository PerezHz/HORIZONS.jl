@doc raw"""
    obs_tbl(COMMAND::ObjectName, START_TIME::StartStopTime, STOP_TIME::StartStopTime,
            STEP_SIZE::StepSize; FILENAME::String = "", kwargs...) -> String

Generate an observer table for object `COMMAND` from `START_TIME` to `STOP_TIME`
with step `STEP_SIZE`. If `FILENAME` is empty, return the output as a `String`;
otherwise, save the table to the corresponding file. For more information see
[1], in particular the **Common Parameters** and **SPK File Parameters**
sections; for a list of keyword arguments see the **Ephemeris-Specific
Parameters** section (or the extended help).

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

julia> local_file = obs_tbl("Voyager 1", t_start, t_stop, δt;
                            FILENAME = "Voyager1.txt", CENTER = "GBT", CSV_FORMAT = true)
"Voyager1.txt"

julia> isfile(local_file)
true
```

# Extended help

This table summarizes the available keyword argument names, types, default
values, and a brief description:

| Keyword::Type                 | Default      | Description                  |
|:------------------------------|:------------:|:-----------------------------|
| `FILENAME::String`            | ""           | Output filename              |
| `CENTER::String`              | "Geocentric" | Observing site               |
| `COORD_TYPE::String`          | "GEODETIC"   | Type of user coordinates     |
| `SITE_COORD::String`          | "0,0,0"      | User coordinates for CENTER  |
| `QUANTITIES::String`          | "A"          | list of quantities to return |
| `REF_SYSTEM::String`          | "ICRF"       | Astrometric reference frame  |
| `CAL_FORMAT::String`          | "CAL"        | Type of date output          |
| `CAL_TYPE::String`            | "MIXED"      | Type of calendar             |
| `ANG_FORMAT::String`          | "HMS"        | RA/dec angle format          |
| `APPARENT::String`            | "AIRLESS"    | Toggle refractive correction |
| `TIME_DIGITS::String`         | "MINUTES"    | Output time precision        |
| `TIME_ZONE::String`           | "+00:00"     | Local time offset from UTC   |
| `RANGE_UNITS::String `        | "AU"         | Units for range quantities   |
| `SUPPRESS_RANGE_RATE::Bool`   | false        | Turns off delta-dot and rdot |
| `ELEV_CUT::Real`              | -90.0        | Elevation cutoff             |
| `SKIP_DAYLT::Bool`            | false        | Skip when CENTER in daylight |
| `SOLAR_ELONG::NTuple{2,Real}` | (0,180)      | Solar elongation bounds      |
| `AIRMASS::Real`               | 38.0         | Airmass cutoff, horizon=~38  |
| `LHA_CUTOFF::Real`            | 0.0          | Local hour angle cutoff      |
| `ANG_RATE_CUTOFF::Real`       | 0.0          | Angular rate cutoff          |
| `EXTRA_PREC::Bool`            | false        | Output extra precision       |
| `R_T_S_ONLY::Bool`            | false        | Only output rise/transit/set |
| `CSV_FORMAT::Bool`            | false        | Output in CSV format         |
| `MAKE_EPHEM::Bool`            | true         | Generate ephemeris           |
| `OBJ_DATA::Bool`              | true         | Include object summary       |
"""
function obs_tbl(COMMAND::ObjectName, START_TIME::StartStopTime, STOP_TIME::StartStopTime,
                 STEP_SIZE::StepSize; FILENAME::String = "", CENTER::String = "Geocentric",
                 COORD_TYPE::String = "GEODETIC", SITE_COORD::String = "0,0,0", QUANTITIES::String = "A",
                 REF_SYSTEM::String = "ICRF", CAL_FORMAT::String = "CAL", CAL_TYPE::String = "MIXED",
                 ANG_FORMAT::String = "HMS", APPARENT::String = "AIRLESS", TIME_DIGITS::String = "MINUTES",
                 TIME_ZONE::String = "+00:00", RANGE_UNITS::String = "AU", SUPPRESS_RANGE_RATE::Bool = false,
                 ELEV_CUT::Real = -90.0, SKIP_DAYLT::Bool = false, SOLAR_ELONG::NTuple{2,Real} = (0,180),
                 AIRMASS::Real = 38.0, LHA_CUTOFF::Real = 0.0, ANG_RATE_CUTOFF::Real = 0.0,
                 EXTRA_PREC::Bool = false, R_T_S_ONLY::Bool = false, CSV_FORMAT::Bool = false,
                 MAKE_EPHEM::Bool = true, OBJ_DATA::Bool = true)

    # HTTP response code and text
    code, text = jplapi(
        HORIZONS_API_URL,
        "COMMAND" => jplstr(COMMAND),
        "EPHEM_TYPE" => "OBSERVER",
        "START_TIME" => jplstr(Dates.format(DateTime(START_TIME), JPL_DATE_FORMAT)),
        "STOP_TIME" => jplstr(Dates.format(DateTime(STOP_TIME), JPL_DATE_FORMAT)),
        "STEP_SIZE" => jplstr(STEP_SIZE),
        "CENTER" => jplstr(CENTER),
        "COORD_TYPE" => jplstr(COORD_TYPE),
        "SITE_COORD" => jplstr(SITE_COORD),
        "QUANTITIES" => jplstr(QUANTITIES),
        "REF_SYSTEM" => jplstr(REF_SYSTEM),
        "CAL_FORMAT" => jplstr(CAL_FORMAT),
        "CAL_TYPE" => jplstr(CAL_TYPE),
        "ANG_FORMAT" => jplstr(ANG_FORMAT),
        "APPARENT" => jplstr(APPARENT),
        "TIME_DIGITS" => jplstr(TIME_DIGITS),
        "TIME_ZONE" => jplstr(TIME_ZONE),
        "RANGE_UNITS" => jplstr(RANGE_UNITS),
        "SUPPRESS_RANGE_RATE" => jplstr(SUPPRESS_RANGE_RATE),
        "ELEV_CUT" => jplstr(ELEV_CUT),
        "SKIP_DAYLT" => jplstr(SKIP_DAYLT),
        "SOLAR_ELONG" => jplstr(join(SOLAR_ELONG, ',')),
        "AIRMASS" => jplstr(AIRMASS),
        "LHA_CUTOFF" => jplstr(LHA_CUTOFF),
        "ANG_RATE_CUTOFF" => jplstr(ANG_RATE_CUTOFF),
        "EXTRA_PREC" => jplstr(EXTRA_PREC),
        "R_T_S_ONLY" => jplstr(R_T_S_ONLY),
        "CSV_FORMAT" => jplstr(CSV_FORMAT),
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