#The following methods implement some functionality from JPL's Horizons telnet interface
#For more detailed info about JPL HORIZONS system, visit http://ssd.jpl.nasa.gov/?horizons

"""
    `horizons()`

Connect to JPL HORIZONS telnet interface

`telnet horizons.jpl.nasa.gov 6775`

"""
function horizons()
    run(ignorestatus(`telnet horizons.jpl.nasa.gov 6775`))
end

# The following code is based on the vec_tbl script, as was taken from:
# ftp://ssd.jpl.nasa.gov/pub/ssd/SCRIPTS/vec_tbl.inp
# Date retrieved: Jul 19, 2017
# Credit: Jon D. Giorgini, NASA-JPL
# Jon.D.Giorgini@jpl.nasa.gov

function vec_tbl(OBJECT_NAME::String; timeout::Int=15, param::Int=0)
    vec_tbl(OBJECT_NAME, OBJECT_NAME*".txt", timeout=timeout, param=param)
end

function vec_tbl(OBJECT_NAME::String, local_file::String; timeout::Int=15)

    ftp_name = ""
    EMAIL_ADDR = "your@domain.name"
    CENTER = "675"
    REF_PLANE = "ECLIP"
    START_TIME = "2016-Sep-8"
    STOP_TIME = "2016-Oct-9"
    STEP_SIZE = "1 d"

    # Initialize output table default over-rides to null
    COORD_TYPE  = ""
    SITE_COORD  = ""
    REF_SYSTEM  = ""
    VEC_CORR    = ""
    OUT_UNITS   = ""
    CSV_FORMAT  = ""
    VEC_LABELS  = ""
    VEC_DELTA_T = ""
    VEC_TABLE   = ""

    # Uncomment variable settings below to change VECTOR table defaults.
    # Brackets (in comment text) indicate default value. 
    #
    # See Horizons documentation for more explanation (or e-mail command-file 
    # example: ftp://ssd.jpl.nasa.gov/pub/ssd/horizons_batch_example.long )
    #
    # The first two, "COORD_TYPE" and "SITE_COORD" must be defined if CENTER 
    # is set to 'coord' (above), but are unused for other CENTER settings.
    COORD_TYPE = "G" # Type of SITE_COORD; [G]eodetic, Cylindrical
    SITE_COORD = "0,0,0" # Topocentric coordinates wrt CENTER [0,0,0]

    REF_SYSTEM = "J2000" # Reference system; [J]2000 or B1950
    VEC_CORR = "1" # Aberrations; [1], 2, 3 (1=NONE, 2=LT, 3=LT+S)
    VEC_DELTA_T = "NO" # Output time difference TDB - UT; [NO] or YES
    OUT_UNITS = "1" # Output units; 1, 2, 3 (1=KM-S, 2=AU-D, 3=KM-D)
    CSV_FORMAT = "NO" # Comma-separated-values; [NO] or YES
    VEC_LABELS = "NO" # Label vector components; [NO] or YES
    VEC_TABLE = "3" # Output format type; 1,2,[3],4,5,6

    exp_internal = 0 # Diagnostic output: 1= on, 0=off
    
    remove_nulls = 0 # Disable null removal from Horizons output
    horizons_machine = "ssd.jpl.nasa.gov"
    horizons_ftp_dir = "pub/ssd/"
    quiet = 0
    start_flag = 0
    
    DEFAULTS = ""
    DEFAULTS = "$DEFAULTS$REF_SYSTEM$VEC_CORR$VEC_DELTA_T"
    DEFAULTS = "$DEFAULTS$OUT_UNITS$CSV_FORMAT$VEC_LABELS$VEC_TABLE"

    # Connect to Horizons 
    proc = ExpectProc(`telnet $horizons_machine 6775`, timeout)

    # Get main prompt and proceed, turning off paging, specifying I/O model,
    # and sending object look-up from command-line 
    idx = expect!(proc, ["unknown host", "Horizons> "])
    if idx == 1
        throw("This system cannot find $horizons_machine")
    elseif idx == 2
        println(proc, "PAGE")
    end

    idx = expect!(proc, ["Horizons> "])
    if idx == 1
        println(proc, "\#\#2")
    end

    idx = expect!(proc, ["Horizons> "])
    if idx == 1
        println(proc, OBJECT_NAME)
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
            throw(println("Cancelled -- unique object not found: $OBJECT_NAME\nObject not matched to database OR multiple matches found."))
        end
    elseif idx == 2
        println(proc, "x")
        throw(println("No such object record found: $OBJECT_NAME"))
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
    idx = expect!(proc, [r".*Cannot find central body.*: $", r".*Select.*<cr>: $", r".*Coordinate center.*<cr>: $", r".*Confirm selected.* $", r".*Cylindrical.*: $", r".*Reference plane.*: $"])

    if idx == 1
        println(proc, "X")
        throw(println("Cannot find CENTER = '$CENTER'"))
    elseif idx == 2
        println(proc, "X")
        throw(println("Non-unique CENTER = '$CENTER' (multiple matches)"))
    elseif idx == 3
        println(proc, "X")
        throw(println("Non-unique CENTER = '$CENTER' (multiple matches)"))    
    elseif idx == 4
        println(proc, "Y")
        idx = expect!(proc, [r".*Reference plane.*: $"])
        if idx == 1
            println(proc, REF_PLANE)
        end
    elseif idx == 5
        println(proc, COORD_TYPE)
        idx = expect!(proc, [r".*Unknown.*: $", r".*Enter c or g.*: $", r".*Specify.*: $"])
        if idx == 1
            println(proc, "X")
            throw(println("Unrecognized user-input coordinate: COORD_TYPE = '$COORD_TYPE'"))
        elseif idx == 2
            throw(println("Undefined or bad coordinate type: COORD_TYPE = '$COORD_TYPE'"))
        elseif idx == 3
            println(proc, SITE_COORD)
            idx = expect!(proc, [r".*Cannot read.*: $", r".*Specify.*: $", r".*Reference plane.*: $"])
            if idx == 1
                println(proc, "X")
                throw(println("Unrecognized site coordinate-triplet: SITE_COORD='$SITE_COORD'"))
            elseif idx == 2
                throw(println("Undefined site coordinate triplet: SITE_COORD = '$SITE_COORD'"))
            elseif idx == 3
                println(proc, REF_PLANE)
            end
        end
    elseif idx == 6
        println(proc, REF_PLANE)
    end

    # Handle reference plane error or START date
    idx = expect!(proc, [r".*Enter.*abbreviation.*: $", r".*Starting .*: $"])
    if idx == 1
        println(proc, "X")
        throw(println("Error in specification: REF_PLANE = '$REF_PLANE'\nSee Horizons documentation for available options."))
    elseif idx == 2
        start_flag = 1
        println(proc, START_TIME)
    end

    # Handle start date error or STOP date
    idx = expect!(proc, [r".*Cannot interpret.*: $", r".*No ephemeris.*: $", r".*Ending.*: $"])
    if idx == 1
        println(proc, "X")
        throw(println("Error in date format: START_TIME = '$START_TIME'\nSee Horizons documentation for accepted formats."))
    elseif idx == 2
        println(proc, "X")
        throw(println("START_TIME = '$START_TIME' prior to available ephemeris"))
    elseif idx == 3
        println(proc, STOP_TIME)
    end

    # Handle stop date error or get step size
    idx = expect!(proc, [r".*Cannot interpret.*", r".*No ephemeris.*", r".*Output interval.*: $"])
    if idx == 1
        println(proc, "X")
        throw(println("Error in date format: STOP_TIME = '$STOP_TIME'\nSee Horizons documentation for accepted formats."))
    elseif idx == 2
        println(proc, "X")
        throw(println("STOP_TIME = '$STOP_TIME' date beyond available ephemeris."))
    elseif idx == 3
        println(proc, STEP_SIZE)
    end

    # Handle step-size error or proceed to defaults
    idx = expect!(proc, [r".*Unknown.*: $", r".*Cannot use.*: $", r".*Accept default.*: $"])
    if idx == 1
        println(proc, "X")
        throw(println("STEP_SIZE = '$STEP_SIZE' error."))
    elseif idx == 2
        println(proc, "X")
        throw(println("STEP_SIZE = '$STEP_SIZE' error."))
    elseif idx == 3
        if length(DEFAULTS) > 0
            @show "myN"
            println(proc, "N")
        else
            @show "myY"
            println(proc, "Y")
        end
    end

    # Change output table defaults if requested
    if length(DEFAULTS) > 0
        while true
            idx = expect!(proc, [r"(Cannot interpret.*\r)", r".*frame.*].*: $", r".*Corrections.*].*: $", r".*units.*].*: $", r".*CSV.*].*: $", r".*Label.*].*: $", r".*delta-T.*].*: $", r".*table type.*].*: $", r".*Select.*: $", r".*].*: $"])
            if idx == 1
                println(proc, "X")
                throw(println("Error in $proc.match, $proc.before. \nSee Horizons documentation for acceptable values."))
            elseif idx == 2
                println(proc, REF_SYSTEM)
            elseif idx == 3
                println(proc, VEC_CORR)
            elseif idx == 4
                println(proc, OUT_UNITS)
            elseif idx == 5
                println(proc, CSV_FORMAT)
            elseif idx == 6
                println(proc, VEC_LABELS)
            elseif idx == 7
                println(proc, VEC_DELTA_T)
            elseif idx == 8
                println(proc, VEC_TABLE)
            elseif idx == 9
                println("BREAKING!!!!")
                break # Done w/default override
            elseif idx == 10
                println(proc, "") # Skip unknown (new?) prompt
            end 
        end
    else
        println("SELECTED DEFAULTS")
        expect!(proc, r".*Select.*: $")
    end

    # Osculating element table output has been generated. Now sitting at 
    # post-output prompt. Initiate FTP file transfer.
    println(proc, "F")

    # Pick out ftp file name
    result = expect!(proc, r"File name   : (.*)\r\r\n   File type")
    proc_match = match(r"File name   : (.*)\r\r\n   File type", proc.match)
    ftp_name = strip(proc_match[1]) #quit possible trailing whitespaces

    @show ftp_name
    @show result
    @show proc_match

    println(proc.match)
    println(proc.before)

    # # Retrieve file by anonymous FTP
    # timeout = 30
    # ftpproc = ExpectProc(`ftp $horizons_machine`, timeout)
    # expect!(ftpproc, r"Name.*: $")
    # println(ftpproc, "anonymous")
    # expect!(ftpproc, "Password:")
    # println(ftpproc, EMAIL_ADDR)

    # # Next bit is HP-UNIX work-around

    # # IS THIS NECESSARY FROM THE ORIGINAL SCRIPT? Only travis will tell!
    # #  set oldpw $EMAIL_ADDR
    # #  if [regsub @ $oldpw '\134@' pw] {
    # #    set newpw $pw
    # #  } else {
    # #    set newpw $oldpw
    # #  }
    # #  send $newpw\r

    # # # If it is indeed necessary, then we'd have to do something along the lines of:
    # # oldpw = "$EMAIL_ADDR"
    # # pw = replace(oldpw, r"@", "\134@")

    # # Handle login fail
    # idx = expect!(ftpproc, ["Login failed.","ftp> "])
    # if idx == 1
    #     println(ftpproc, "quit")
    #     throw(println("FTP login failed -- must use full Internet e-mail address.\nExample:  'joe@your.domain.name'"))
    # elseif idx == 2
    #     println(ftpproc, "ascii")
    # end

    # # Change directory to pub/ssd
    # idx = expect!(ftpproc, ["ftp> "])
    # if idx == 1
    #     println(ftpproc, "cd pub/ssd")
    # end

    # # Send file
    # # # TODO: fix timeout Inf
    # ftpproc.timeout = 100
    # idx = expect!(ftpproc, ["ftp> "])
    # if idx == 1
    #     println(ftpproc, "get $ftp_name $local_file")
    # end
    # idx = expect!(ftpproc, [r".*No such.*", "ftp> "])
    # if idx == 1
    #     throw(println("Error -- cannot find $ftp_name on server."))
    # elseif idx == 2
    #     println(ftpproc, "quit")
    # end

    # Alternative to FTP downloading using FTPClient
    ftp_init()
    ftp = FTP(hostname="ssd.jpl.nasa.gov", username="anonymous", password=EMAIL_ADDR)
    # dir_list = readdir(ftp)
    cd(ftp, "pub/ssd")
    # pwd(ftp)
    file = download(ftp, ftp_name, local_file)
    close(ftp)
    ftp_cleanup()

    nothing

end



