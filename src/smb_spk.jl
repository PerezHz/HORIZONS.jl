# This file is part of the HORIZONS.jl package
# The HORIZONS.jl package is licensed under the MIT "Expat" License
# Copyright (c) 2017: Jorge Pérez.

#The following methods implement some functionality from JPL's Horizons telnet interface
#For more detailed info about JPL HORIZONS system, visit http://ssd.jpl.nasa.gov/?horizons

# The following code is based on the smb_spk script, as was retrieved from:
# ftp://ssd.jpl.nasa.gov/pub/ssd/SCRIPTS/smb_spk
# Date retrieved: Jul 19, 2017
# Credit: Jon D. Giorgini, NASA-JPL
# Jon.D.Giorgini@jpl.nasa.gov

function smb_spk(flag::String, small_body::ObjectName, start_time::StartStopTime,
        stop_time::StartStopTime, email::String="joe@your.domain.name",
        file_name::String=""; ftp_verbose::Bool=false, timeout::Int=60)

    smb_spk(flag, small_body, DateTime(start_time), DateTime(stop_time), email, file_name; timeout=timeout, ftp_verbose=ftp_verbose)
end

function smb_spk(flag::String, small_body::ObjectName,
        start_time::DateTime, stop_time::DateTime,
        email::String="joe@your.domain.name", file_name::String="";
        ftp_verbose::Bool=false, timeout::Int=60)

    # TODO: handle spk_ID_override (see smb_spk Expect script)

    # Convert start and stop time from `DateTime`s to `String`s
    small_body_str = string(small_body)
    start_time_str = Dates.format(start_time, HORIZONS_DATE_FORMAT)
    stop_time_str = Dates.format(stop_time, HORIZONS_DATE_FORMAT)

    if flag == "t"
        file_type = "yes"
        ftp_type = :ascii
        ftp_sufx = ".xsp"
    elseif flag == "b"
        file_type  = "no"
        ftp_type = :binary
        ftp_sufx = ".bsp"
    elseif flag == "1"
        file_type = "1"
        ftp_type = :binary
        ftp_sufx = ".bsp"
    elseif flag == "2"
        file_type = "21"
        ftp_type = :binary
        ftp_sufx = ".bsp"
    else
        ArgumentError("Unknown file type: $flag")
    end

    local_file = file_name

    # Connect to Horizons
    proc = ExpectProc(`telnet $HORIZONS_MACHINE 6775`, timeout)

    # Wait for main Horizons prompt, set up, proceed
    idx = expect!(proc, ["unknown host", "Horizons> "])
    if idx == 1
        warn("This system cannot find $HORIZONS_MACHINE")
        close(proc)
    elseif idx == 2
        println(proc, "PAGE")
    end

    idx = expect!(proc, ["Horizons> "], timeout=15)
    if idx == 1
        println(proc, "##2")
    end
    idx = expect!(proc, ["Horizons> "], timeout=15)
    if idx == 1
        println(proc, small_body_str)
    end

    # Handle prompt search/select
    idx = expect!(proc, [r".*Continue.*: $", r".*such object record.*", r".*Select.*<cr>: $"])
    if idx == 1
        println(proc, "yes")
        idx = expect!(proc, [r".*PK.*: $", r".*lay.*: $"])
        if idx ==1
            # TODO: handle spk_ID_override (see smb_spk Expect script)
            println(proc, "S")
        elseif idx == 2
            println(proc, "x")
            throw(ArgumentError("Cancelled -- unique object not found: $small_body_str\nObject not matched to database OR multiple matches found."))
        end
    elseif idx == 2
        # currently unable to reproduce this case on HORIZONS v4.10
        println(proc, "x")
        throw(ArgumentError("No such object record found: $small_body_str"))
    elseif idx == 3
        println(proc, "S")
    end

    # Pick out SPK ID sent by Horizons
    if file_name == ""
        idx = expect!(proc, [r" Assigned SPK object ID:  (.*)\r\r\n \r\r\n Enter your"])
        proc_match = match(r" Assigned SPK object ID:  (.*)\r\r\n \r\r\n Enter your", proc.match)
        # @show proc_match
        spkid = proc_match[1]
        local_file = spkid*ftp_sufx
    end

    # Process prompt for e-mail address
    idx = expect!(proc, [r".*address.*: $"])
    if idx == 1
        println(proc, email)
    end

    # Process e-mail confirmation
    idx = expect!(proc, [r".*yes.*: $"])
    if idx == 1
        println(proc, "yes")
    end

    # Process file type
    idx = expect!(proc, [r".*SPK file format.*: $", r".*YES.*: $"])
    if idx == 1
        println(proc, file_type)
    elseif idx == 2
        println(proc, file_type)
    end

    # Set start date
    idx = expect!(proc, [r".*START.*: "s])
    if idx == 1
        println(proc, start_time_str)
    end

    # Handle start date error or STOP date
    idx = expect!(proc, [r".*try.*: "s, r".*STOP.*: "s])
    if idx == 1
        println(proc, "X")
        throw(ArgumentError("START time $start_time_str outside set SPK limits."))
    elseif idx == 2
        println(proc, stop_time_str)
    end

    # Handle stop date error
    # timeout is set to Inf to allow for file production
    idx = expect!(proc, [r".*large.*", r".*try.*"s, r".*time-span too small.*", r".*YES.*"s], timeout=Inf)
    if idx == 1
        println(proc, "X")
        throw(ArgumentError("Error in STOP date: $stop_time_str\nStop date must not be more than 200 years after start."))
    elseif idx == 2
        println(proc, "X")
        throw(ArgumentError("STOP time $stop_time_str outside set SPK limits."))
    elseif idx == 3
        println(proc, "X")
        throw(ArgumentError("Error in requested length: $start_time_str to $stop_time_str\nTime span of file must be >= 32 days."))
    elseif idx == 4
        # Binary SPK file created.
        # Add more objects to file  [ YES, NO, ? ] :
        println(proc, "NO")
    end

    # Pick out FTP file name
    idx = expect!(proc, [r"File name   : (.*)\r\r\n   File type"], timeout=15)
    proc_match = match(r"File name   : (.*)\r\r\n   File type", proc.match)
    ftp_name = strip(proc_match[1])

    # Close telnet connection
    close(proc)

    # Retrieve file by anonymous FTP and save to file
    ftp_init()
    # workaround `@` in email address
    ftp_email = replace(email, "@" => "_at_")
    ftp = FTP(hostname=HORIZONS_MACHINE, username="anonymous", password=ftp_email, verbose=ftp_verbose)
    cd(ftp, HORIZONS_FTP_DIR)
    if file_name == ""
        io = download(ftp, ftp_name, local_file)
        close(ftp)
        ftp_cleanup()
        return ftp_name, local_file
    else
        io = download(ftp, ftp_name, file_name)
        close(ftp)
        ftp_cleanup()
        return ftp_name, file_name
    end
end
