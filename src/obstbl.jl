@doc raw"""
    obs_tbl(COMMAND::ObjectName, START_TIME::StartStopTime, STOP_TIME::StartStopTime,
            STEP_SIZE::StepSize; FILENAME::String = "", kwargs...) -> String

Generate an observer table for object `COMMAND` from `START_TIME` to `STOP_TIME`
with step `STEP_SIZE`. If `FILENAME` is empty, return the output as a `String`;
otherwise, save the table to the corresponding file. For more information see
[1], in particular the **Common Parameters** and **SPK File Parameters**
sections; for a list of keyword arguments see the **Ephemeris-Specific
Parameters** section.

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

    # Convert http parameters to String
    command_str = jplstr(COMMAND)
    start_time_str = jplstr(Dates.format(DateTime(START_TIME), JPL_DATE_FORMAT))
    stop_time_str = jplstr(Dates.format(DateTime(STOP_TIME), JPL_DATE_FORMAT))
    step_size_str = jplstr(STEP_SIZE)
    center_str = jplstr(CENTER)
    coord_type_str = jplstr(COORD_TYPE)
    site_coord_str = jplstr(SITE_COORD)
    quantities_str = jplstr(QUANTITIES)
    ref_system_str = jplstr(REF_SYSTEM)
    cal_format_str = jplstr(CAL_FORMAT)
    cal_type_str = jplstr(CAL_TYPE)
    ang_format_str = jplstr(ANG_FORMAT)
    apparent_str = jplstr(APPARENT)
    time_digits_str = jplstr(TIME_DIGITS)
    time_zone_str = jplstr(TIME_ZONE)
    range_units_str = jplstr(RANGE_UNITS)
    suppress_range_rate_str = jplstr(SUPPRESS_RANGE_RATE)
    elev_cut_str = jplstr(ELEV_CUT)
    skip_daylt_str = jplstr(SKIP_DAYLT)
    solar_elong_str = jplstr(join(SOLAR_ELONG, ','))
    airmass_str = jplstr(AIRMASS)
    lha_cutoff_str = jplstr(LHA_CUTOFF)
    ang_rate_cutoff_str = jplstr(ANG_RATE_CUTOFF)
    extra_prec_str = jplstr(EXTRA_PREC)
    r_t_s_only_str = jplstr(R_T_S_ONLY)
    csv_format_str = jplstr(CSV_FORMAT)
    make_ephem_str = jplstr(MAKE_EPHEM)
    obj_data_str = jplstr(OBJ_DATA)
    # HTTP response code and text
    code, text = jplapi(
        HORIZONS_API_URL,
        "COMMAND" => command_str,
        "EPHEM_TYPE" => "OBSERVER",
        "START_TIME" => start_time_str,
        "STOP_TIME" => stop_time_str,
        "STEP_SIZE" => step_size_str,
        "CENTER" => center_str,
        "COORD_TYPE" => coord_type_str,
        "SITE_COORD" => site_coord_str,
        "QUANTITIES" => quantities_str,
        "REF_SYSTEM" => ref_system_str,
        "CAL_FORMAT" => cal_format_str,
        "CAL_TYPE" => cal_type_str,
        "ANG_FORMAT" => ang_format_str,
        "APPARENT" => apparent_str,
        "TIME_DIGITS" => time_digits_str,
        "TIME_ZONE" => time_zone_str,
        "RANGE_UNITS" => range_units_str,
        "SUPPRESS_RANGE_RATE" => suppress_range_rate_str,
        "ELEV_CUT" => elev_cut_str,
        "SKIP_DAYLT" => skip_daylt_str,
        "SOLAR_ELONG" => solar_elong_str,
        "AIRMASS" => airmass_str,
        "LHA_CUTOFF" => lha_cutoff_str,
        "ANG_RATE_CUTOFF" => ang_rate_cutoff_str,
        "EXTRA_PREC" => extra_prec_str,
        "R_T_S_ONLY" => r_t_s_only_str,
        "CSV_FORMAT" => csv_format_str,
        "MAKE_EPHEM" => make_ephem_str,
        "OBJ_DATA" => obj_data_str
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