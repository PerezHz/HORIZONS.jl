# This file is part of the HORIZONS.jl package
# The HORIZONS.jl package is licensed under the MIT "Expat" License
# Copyright (c) 2017: Jorge Pérez.

#The following methods implement some functionality from JPL's Horizons telnet interface
#For more detailed info about JPL HORIZONS system, visit http://ssd.jpl.nasa.gov/?horizons

# The following code is based on the vec_tbl script, as was retrieved from:
# ftp://ssd.jpl.nasa.gov/pub/ssd/SCRIPTS/vec_tbl
# Date retrieved: Jul 19, 2017
# Credit: Jon D. Giorgini, NASA-JPL
# Jon.D.Giorgini@jpl.nasa.gov

"""
    vec_tbl(OBJECT_NAME, START_TIME, STOP_TIME, STEP_SIZE; kwargs...)

    vec_tbl(OBJECT_NAME, local_file, START_TIME, STOP_TIME, STEP_SIZE; kwargs...)

Automate the Horizons session required to produce a VECTOR table for an
object already listed in the Horizons database: a planet, natural satellite,
asteroid, comet, spacecraft, or dynamical point. If the file name `local_file`
is specified, then output is saved to that file in current folder. Otherwise,
then output is returned as a Julia string.

Generally, this script is suited for situations where the same output
format (as defined by the input file) is desired for a list of objects
specified one at a time on the script's command-line.

The current keyword arguments are:

    + `timeout=15`
    + `EMAIL_ADDR = "joe@your.domain.name"`
    + `CENTER = "@ssb"`
    + `REF_PLANE = "FRAME"`
    + `COORD_TYPE = "G"`
    + `SITE_COORD = "0,0,0"`
    + `REF_SYSTEM = "J2000"`
    + `VEC_CORR = 1`
    + `VEC_DELTA_T = false`
    + `OUT_UNITS = 1`
    + `CSV_FORMAT = false`
    + `VEC_LABELS = false`
    + `VEC_TABLE= 3`

More detailed information may be found at the HORIZONS system documentation:

https://ssd.jpl.nasa.gov/?horizons_doc

The original script vec_tbl, written by Jon D. Giorgini, may be found at src/SCRIPTS

"""
function vec_tbl(OBJECT_NAME::ObjectName, START_TIME::StartStopTime,
        STOP_TIME::StartStopTime, STEP_SIZE::StepSize; kwargs...)

    output_str, ftp_name = get_vec_tbl(OBJECT_NAME, DateTime(START_TIME), DateTime(STOP_TIME), STEP_SIZE; kwargs...)

    return output_str

    #TODO: turn output_str into a data table; possibly even a struct which saves object info + ephemeris
end

function vec_tbl(OBJECT_NAME::ObjectName, local_file::String,
        START_TIME::StartStopTime, STOP_TIME::StartStopTime,
        STEP_SIZE::StepSize; EMAIL_ADDR::String="joe@your.domain.name",
        ftp_verbose::Bool=false, kwargs...)

    output_str, ftp_name = get_vec_tbl(OBJECT_NAME, DateTime(START_TIME), DateTime(STOP_TIME), STEP_SIZE; kwargs...)

    # Retrieve file by anonymous FTP and save to file `local_file`
    ftp_init()
    # workaround `@` in email address
    ftp_email = replace(EMAIL_ADDR, "@" => "_at_")
    ftp = FTP(hostname=HORIZONS_MACHINE, username="anonymous", password=ftp_email, verbose=ftp_verbose)
    cd(ftp, HORIZONS_FTP_DIR)
    if local_file == ""
        io = download(ftp, ftp_name, ftp_name)
        close(ftp)
        ftp_cleanup()
        return ftp_name
    else
        io = download(ftp, ftp_name, local_file)
        close(ftp)
        return local_file
    end
end

function get_vec_tbl(OBJECT_NAME::ObjectName, START_TIME::DateTime,
        STOP_TIME::DateTime, STEP_SIZE::StepSize; timeout::Int=15,
        EMAIL_ADDR::String="joe@your.domain.name", CENTER::String="@ssb",
        REF_PLANE::String="FRAME", COORD_TYPE::String="G",
        SITE_COORD::String="0,0,0", REF_SYSTEM::String="J2000",
        VEC_CORR::Int=1, VEC_DELTA_T::Bool=false, OUT_UNITS::Int=1,
        CSV_FORMAT::Bool=false, VEC_LABELS::Bool=false, VEC_TABLE::VecTable=3)

    # Convert start and stop time from `DateTime`s to `String`s
    OBJECT_NAME_str = string(OBJECT_NAME)
    START_TIME_str = Dates.format(START_TIME, HORIZONS_DATE_FORMAT)
    STOP_TIME_str = Dates.format(STOP_TIME, HORIZONS_DATE_FORMAT)
    STEP_SIZE_str = string(STEP_SIZE)

    start_flag = 0

    # Connect to Horizons
    proc = ExpectProc(`telnet $HORIZONS_MACHINE 6775`, timeout)

    # Get main prompt and proceed, turning off paging, specifying I/O model,
    # and sending object look-up from command-line
    idx = expect!(proc, ["unknown host", "Horizons> "])
    if idx == 1
        warn("This system cannot find $HORIZONS_MACHINE")
        close(proc)
    elseif idx == 2
        println(proc, "PAGE")
    end

    idx = expect!(proc, ["Horizons> "])
    if idx == 1
        println(proc, "##2")
    end

    idx = expect!(proc, ["Horizons> "])
    if idx == 1
        println(proc, OBJECT_NAME_str)
    end

    # Handle object look-up confirmation
    idx = expect!(proc, [r".*Continue.*: $", r".*such object record.*", r".*Select.*<cr>: $"])
    if idx == 1
        println(proc, "yes")
        idx = expect!(proc, [r".*PK.*: $", r".*lay.*: $"])
        if idx ==1
            println(proc, "E")
        elseif idx == 2
            println(proc, "x")
            throw(ArgumentError("Cancelled -- unique object not found: $OBJECT_NAME\nObject not matched to database OR multiple matches found."))
        end
    elseif idx == 2
        # currently unable to reproduce this case on HORIZONS v4.10
        # println(proc, "x")
        # throw(ArgumentError("No such object record found: $OBJECT_NAME"))
    elseif idx == 3
        println(proc, "E")
    end

    # Request VECTOR table
    idx = expect!(proc, [r".*Observe, Elements.*: $"])
    if idx == 1
        println(proc, "V")
    end

    # Provide coordinate center
    idx = expect!(proc, [r".*Coordinate .*: $"])
    if idx == 1
        println(proc, CENTER)
    end

    # Handle coordinate center error or confirmation
    idx = expect!(proc, [r".*No site matches.*: $"s, r".*Select.*<cr>: $", r".*Coordinate center.*: $"s, r".*Confirm selected.* $", r".*Cylindrical.*: $", r".*Reference plane.*: $"])

    if idx == 1
        println(proc, "X")
        throw(ArgumentError("Cannot find CENTER = $CENTER"))
    elseif idx == 2
        # currently unable to reproduce this case on HORIZONS v4.10
        # println(proc, "X")
        # throw(ArgumentError("Non-unique CENTER = $CENTER (multiple matches); idx == $idx"))
    elseif idx == 3
        println(proc, "X")
        throw(ArgumentError("Non-unique CENTER = $CENTER (multiple matches); idx == $idx"))
    elseif idx == 4
        println(proc, "Y")
        idx = expect!(proc, [r".*Reference plane.*: $"])
        if idx == 1
            println(proc, REF_PLANE)
        end
    elseif idx == 5
        println(proc, COORD_TYPE)
        idx = expect!(proc, [r".*Unknown.*: $"s, r".*Enter c or g.*: $"s, r".*Specify.*: $"])
        if idx == 1
            println(proc, "X")
            throw(ArgumentError("Unrecognized user-input coordinate: COORD_TYPE = $COORD_TYPE"))
        elseif idx == 2
            println(proc, "X")
            throw(ArgumentError("Undefined or bad coordinate type: COORD_TYPE = $COORD_TYPE"))
        elseif idx == 3
            println(proc, SITE_COORD)
            idx = expect!(proc, [r".*Cannot read.*: $"s, r".*Specify.*: $"s, r".*Reference plane.*: $"])
            if idx == 1
                println(proc, "X")
                throw(ArgumentError("Cannot read coordinate triplet: SITE_COORD=$SITE_COORD"))
            elseif idx == 2
                println(proc, "X")
                throw(ArgumentError("Undefined site coordinate triplet: SITE_COORD = $SITE_COORD"))
            elseif idx == 3
                println(proc, REF_PLANE)
            end
        end
    elseif idx == 6
        println(proc, REF_PLANE)
    end

    # Handle reference plane error or START date
    idx = expect!(proc, [r".*Enter.*abbreviation.*: $"s, r".*Starting .*: $"])
    if idx == 1
        println(proc, "X")
        throw(ArgumentError("Enter \"ecliptic\", \"frame\" or \"body equator\" or abbreviation: REF_PLANE = $REF_PLANE\nSee Horizons documentation for available options."))
    elseif idx == 2
        start_flag = 1
        println(proc, START_TIME_str)
    end

    # Handle start date error or STOP date
    idx = expect!(proc, [r".*Cannot interpret.*: $", r".*No ephemeris.*: $"s, r".*Ending.*: $"])
    if idx == 1
        # this case is handled more "julianly" by argument typing and Base.Dates
        # println(proc, "X")
        # throw(ArgumentError("Error in date format: START_TIME = $START_TIME_str\nSee Horizons documentation for accepted formats."))
    elseif idx == 2
        println(proc, "X")
        throw(ArgumentError("START_TIME = $START_TIME_str prior to available ephemeris"))
    elseif idx == 3
        println(proc, STOP_TIME_str)
    end

    # Handle stop date error or get step size
    idx = expect!(proc, [r".*Cannot interpret.*", r".*No ephemeris.*"s, r".*Output interval.*: $"])
    if idx == 1
        # this case is handled more "julianly" by argument typing and Base.Dates
        # println(proc, "X")
        # throw(ArgumentError("Error in date format: STOP_TIME = $STOP_TIME_str\nSee Horizons documentation for accepted formats."))
    elseif idx == 2
        println(proc, "X")
        throw(ArgumentError("STOP_TIME = $STOP_TIME_str date beyond available ephemeris."))
    elseif idx == 3
        println(proc, STEP_SIZE_str)
    end

    # Handle step-size error or proceed to defaults
    idx = expect!(proc, [r".*Unknown.*: $"s, r".*Cannot use.*: $"s, r".*Accept default.*: $"s])
    if idx == 1
        println(proc, "X")
        throw(ArgumentError("STEP_SIZE = $STEP_SIZE_str error."))
    elseif idx == 2
        println(proc, "X")
        throw(ArgumentError("STEP_SIZE = $STEP_SIZE_str error."))
    elseif idx == 3
        println(proc, "N") # never accept table defaults
    end

    # Change output table defaults
    while true
        idx = expect!(proc, [r"(Cannot interpret.*\r)", r".*frame.*].*: $", r".*Corrections.*].*: $", r".*units.*].*: $", r".*CSV.*].*: $", r".*Label.*].*: $", r".*delta-T.*].*: $", r".*table type.*].*: $", r".*Select.*: $", r".*].*: $"])
        if idx == 1
            # this case is handled automatically by never accepting table defaults
            # println(proc, "X")
            # throw(ArgumentError("Error in $proc.match, $proc.before. \nSee Horizons documentation for acceptable values."))
        elseif idx == 2
            println(proc, REF_SYSTEM)
        elseif idx == 3
            println(proc, "$VEC_CORR")
        elseif idx == 4
            println(proc, "$OUT_UNITS")
        elseif idx == 5
            println(proc, yesornostring(CSV_FORMAT))
        elseif idx == 6
            println(proc, yesornostring(VEC_LABELS))
        elseif idx == 7
            println(proc, yesornostring(VEC_DELTA_T))
        elseif idx == 8
            println(proc, "$VEC_TABLE")
        elseif idx == 9
            break # Done w/default override
        # elseif idx == 10
        #     # currently unable to reproduce this case on HORIZONS v4.10
        #     # println(proc, "") # Skip unknown (new?) prompt
        end
    end
    # expect!(proc, r".*Select.*: $")

    # println(proc.before)
    # @show typeof(proc.before)
    output_str = proc.before

    # Osculating element table output has been generated. Now sitting at
    # post-output prompt. Initiate FTP file transfer.
    println(proc, "F")

    # Pick out ftp file name
    result = expect!(proc, r"File name   : (.*)\r\r\n   File type")
    proc_match = match(r"File name   : (.*)\r\r\n   File type", proc.match)
    # name of file at FTP server
    ftp_name = strip(proc_match[1]) #quit possible trailing whitespaces

    # Close telnet connection
    # println(proc, "exit")
    close(proc)

    return output_str, ftp_name
end

function vec_tbl_csv(OBJECT_NAME::ObjectName, START_TIME::StartStopTime,
        STOP_TIME::StartStopTime, STEP_SIZE::StepSize; timeout::Int=15,
        EMAIL_ADDR::String="joe@your.domain.name", CENTER::String="@ssb",
        REF_PLANE::String="FRAME", COORD_TYPE::String="G",
        SITE_COORD::String="0,0,0", REF_SYSTEM::String="J2000",
        VEC_CORR::Int=1, VEC_DELTA_T::Bool=false, OUT_UNITS::Int=1,
        VEC_TABLE::VecTable=3)

    output_str, ftp_name = get_vec_tbl(OBJECT_NAME, DateTime(START_TIME),
        DateTime(STOP_TIME), STEP_SIZE; timeout=timeout,
        EMAIL_ADDR=EMAIL_ADDR, CENTER=CENTER, REF_PLANE=REF_PLANE,
        COORD_TYPE=COORD_TYPE, SITE_COORD=SITE_COORD, REF_SYSTEM=REF_SYSTEM,
        VEC_CORR=VEC_CORR, VEC_DELTA_T=VEC_DELTA_T, OUT_UNITS=OUT_UNITS,
        CSV_FORMAT=true, VEC_LABELS=false, VEC_TABLE=VEC_TABLE)

    # get $$SOE, $$EOE offsets
    mSOE = match(r"\$\$SOE", output_str)
    mEOE = match(r"\$\$EOE", output_str)

    # get everything within SOE and EOE
    ste = output_str[mSOE.offset+7:mEOE.offset-1]
    ste = replace(ste, ",\r\n" => "\r\n") #get rid of comma at end of line

    # get and process table labels
    hdr_raw = match(r"JDTDB.*,\r\n", output_str).match
    hdr_raw = replace(hdr_raw, "Calendar Date (TDB)" => "Calendar_Date_TDB") #format calendar date string
    hdr_raw = replace(hdr_raw, ",\r\n" => "\r\n") #get rid of comma at end of line

    #string in CSV format with BOTH headers and data
    csv_str = hdr_raw*ste

    #convert data string into array
    arr = readdlm(IOBuffer(ste), ',')
    arr[:,2] = strip.( arr[:,2] ) #get rid of whitespaces

    # convert labels string into array
    hdr = convert(Array{String,2}, strip.(  readdlm( IOBuffer( hdr_raw ), ',' )  ));
    # vcat into common 2-dim array
    tbl = vcat(hdr, arr)

    #return labels and data as 2-dim array (table) and CSV-formatted string
    return tbl, csv_str
end
