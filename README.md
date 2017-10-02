# HORIZONS.jl

[![Build Status](https://travis-ci.org/PerezHz/HORIZONS.jl.svg?branch=master)](https://travis-ci.org/PerezHz/HORIZONS.jl)

[![codecov](https://codecov.io/gh/PerezHz/HORIZONS.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/PerezHz/HORIZONS.jl) [![Coverage Status](https://coveralls.io/repos/github/PerezHz/HORIZONS.jl/badge.svg)](https://coveralls.io/github/PerezHz/HORIZONS.jl)

An interface to NASA-JPL's [HORIZONS](https://ssd.jpl.nasa.gov/?horizons) system in
[Julia](http://julialang.org).

## Author

- [Jorge A. Pérez](https://www.linkedin.com/in/perezhz),
Instituto de Ciencias Físicas, Universidad Nacional Autónoma de México (UNAM)

Comments, suggestions, and improvements are welcome and appreciated.

## Installation

Currently, `HORIZONS.jl` is an unregistered Julia package. It may be installed
from the Julia REPL via [`Pkg.clone`](https://docs.julialang.org/en/release-0.4/manual/packages/#installing-unregistered-packages).

## Usage examples

The `horizons()` function is a shortcut to HORIZONS `telnet` interface:

```julia
julia> using HORIZONS

julia> horizons()
Trying 128.149.23.134...
Connected to ssd.jpl.nasa.gov.
Escape character is '^]'.

  ======================================================================
  |                     Jet Propulsion Laboratory                      |
  |                                                                    |
  |                  * * *    W A R N I N G   * * *                    |
  |                                                                    |
  |                          Property of the                           |
  |                      UNITED STATES GOVERNMENT                      |
  |                                                                    |
  |    This computer is funded by the United States Government and     |
  | operated by the California Institute of Technology in support of   |
  | ongoing U.S. Government programs and activities.  If you are not   |
  | authorized to access this system, disconnect now.  Users of this   |
  | system have no expectation of privacy. By continuing, you consent  |
  |     to your keystrokes and data content being monitored.           |
  ======================================================================

     ___    _____     ___
    /_ /|  /____/ \  /_ /|       Horizons On-line Ephemeris System v4.08
    | | | |  __ \ /| | | |       Solar System Dynamics Group
 ___| | | | |__) |/  | | |__     Jet Propulsion Laboratory
/___| | | |  ___/    | |/__ /|   Pasadena, CA, USA
|_____|/  |_|/       |_____|/

Establishing connection, stand-by ...

JPL Horizons, version 4.08
Type `?' for brief intro, `?!' for more details
System news updated September 12, 2017

Horizons>
```

`HORIZONS.jl` function `vec_tbl` allows the user to generate vector tables for 
designated objects and save the output into a file:

```julia
# date variables for start and stop times
t_start = Dates.DateTime(2029,4,13)
t_stop = Dates.Date(2029,4,14)

# step size (allowed types: Dates.Period, Int,String)
δt = Dates.Hour(1) # 1 hour step size

# generate tables and save output to Apophis.txt in current directory:
vec_tbl("Apophis", "Apophis.txt", t_start, t_stop, δt; CENTER="@ssb", REF_PLANE="FRAME", OUT_UNITS=2, CSV_FORMAT=true, VEC_TABLE=2)
```

Note that `CENTER`, `REF_PLANE`, etc., are keyword arguments. If they are omitted
from the `vec_tbl` call, then they will take default values:

```julia
δt = 1 #return only one step

# generate tables with default values and save output to Apophis.txt in current directory:

vec_tbl("Apophis", "Apophis.txt", t_start, t_stop, δt)
```

More details about default values of keyword arguments are available in the 
`vec_tbl` docstrings.

If the output file is not specified, then `vec_tbl` returns the output as a
string, which may be then used for further processing within Julia:

```julia
δt = "2 hours" # 2 hour step size

# save into `apophisvt::String` the output from HORIZONS
apophisvt = vec_tbl("Apophis", t_start, t_stop, δt)

# do stuff with `apophisvt` inside julia...
```

Julia's broadcasting allows the user to get many vector tables at once:

```julia
julia> using HORIZONS

julia> IDs = string.([99942, 900033])
2-element Array{String,1}:
 "99942" 
 "900033"

julia> local_files = string.(IDs,".txt")
2-element Array{String,1}:
 "99942.txt" 
 "900033.txt"

julia> vec_tbl.(IDs, local_files, t_start, t_stop, δt) #save output to local files 99942.txt and 900033.txt in current folder
2-element Array{Void,1}:
 nothing
 nothing

julia>
```

## License

`HORIZONS.jl` is licensed under the [MIT "Expat" license](./LICENSE.md).

## Acknowledgments

`HORIZONS.jl` is based on the scripts authored by Jon D. Giorgini for automated
generation of tables, which may be
found at the JPL's Solar System Dynamics group ftp server
`ftp://ssd.jpl.nasa.gov/pub/ssd/SCRIPTS/`.

The [HORIZONS](https://ssd.jpl.nasa.gov/?horizons) system itself is the work of several people at JPL:

* Design/implementation :
  - Jon Giorgini
  - Don Yeomans
* Cognizant Eng.:
  - Jon Giorgini
* Major body ephemerides:
  - William Folkner (Planetary ephemerides)
  - Bob Jacobson    (Satellites)
  - Marina Brozovic (Satellites)
* Contributors:
  - Alan Chamberlin (web interface, database)
  - Paul Chodas     (some subroutines)
  - The NAIF group  (SPICELIB) (esp. Chuck Acton, Bill Taber, Nat Bachman)

Translation from the original `expect` scripts to Julia was done using the
[Expect.jl](https://github.com/wavexx/Expect.jl) package.

## References

* [HORIZONS documentation (HTML)](https://ssd.jpl.nasa.gov/?horizons_doc)
* Giorgini, J.D., Yeomans, D.K., Chamberlin, A.B., Chodas, P.W.,
    Jacobson, R.A., Keesey, M.S., Lieske, J.H., Ostro, S.J.,
    Standish, E.M., Wimberly, R.N., "JPL's On-Line Solar System Data
    Service", Bulletin of the American Astronomical Society, Vol 28,
    No. 3, p. 1158, 1996.
