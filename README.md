# HORIZONS.jl

[![Build status](https://github.com/PerezHz/HORIZONS.jl/workflows/CI/badge.svg)](https://github.com/PerezHz/HORIZONS.jl/actions)

[![codecov](https://codecov.io/gh/PerezHz/HORIZONS.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/PerezHz/HORIZONS.jl) [![Coverage Status](https://coveralls.io/repos/github/PerezHz/HORIZONS.jl/badge.svg?branch=main)](https://coveralls.io/github/PerezHz/HORIZONS.jl?branch=main)

An interface to JPL [HORIZONS](https://ssd.jpl.nasa.gov/horizons) system and other Solar System Dynamics [APIs](https://ssd.jpl.nasa.gov/api.html) in
[Julia](http://julialang.org).

## Authors

- [Jorge A. Pérez Hernández](https://github.com/PerezHz),
Instituto de Ciencias Físicas, Universidad Nacional Autónoma de México (UNAM)
- [Luis Eduardo Ramírez Montoya](https://github.com/LuEdRaMo),
Facultad de Ciencias, Universidad Nacional Autónoma de México (UNAM)

Comments, suggestions, and improvements are welcome and appreciated.

## Installation

`HORIZONS.jl` is a registered Julia package and may be installed
from the Julia REPL doing
```
] add HORIZONS
```
Current stable
release is `v0.4.1`, which is compatible with Julia >= 1.6.

## Usage examples

### Horizons API

The `horizons()` function is a shortcut to the HORIZONS `telnet` interface
prompt from the Julia REPL:

```julia
julia> using HORIZONS

julia> horizons() # get Horizons prompt from the Julia REPL
JPL Horizons, version 4.70
Type '?' for brief help, '?!' for details,
'-' for previous prompt, 'x' to exit
System news updated June 08, 2020

Horizons>
```
To run this function, the `telnet` command line utility should be locally installed and
enabled.



`HORIZONS.jl` also has Julia functions for some of the scripts authored by
Jon D. Giorgini for automated generation of small-body binary SPK files and tables.
These scripts were originally written in `expect`, and can be found at the
JPL's Solar System Dynamics group ftp server `ftp://ssd.jpl.nasa.gov/pub/ssd/SCRIPTS/`.
Below, we describe these functions `smb_spk`, `smb_spk_ele`, and `vec_tbl`, as
well as the *observer table* function `obs_tbl` and the *osculating orbital
elements table* function `ooe_tbl`.

#### `smb_spk`

The `smb_spk` function automates generation and downloading of Solar System
small-bodies binary SPK files from HORIZONS:
```julia
using HORIZONS, Dates

# Generate a binary SPK file for asteroid 99942 Apophis covering from 2021 to 2029
local_file = smb_spk("DES = 20099942;", DateTime(2021,Jan,1), DateTime(2029,Apr,13))

isfile(local_file) # Check that the binary SPK file `local_file` exists
```
Binary SPK files (i.e., extension `.bsp`) can be read using e.g.
[`SPICE.jl`](https://github.com/JuliaAstro/SPICE.jl):
```julia
# ] add SPICE" # uncomment this line to add `SPICE.jl` to current environment
using SPICE, Dates
furnsh(local_file)
et = 86400*(datetime2julian(DateTime(2024,3,1)) - 2.451545e6)
pv = spkgeo(20099942, et, "J2000", 0)
```

#### `smb_spk_ele`

`HORIZONS.jl` function `smb_spk_ele` generates `.bsp` binary SPK files for
small-bodies from a set of osculating orbital elements at a given epoch:
```julia
using HORIZONS, Dates

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
local_file = smb_spk_ele("1990 MU", start_time, stop_time, epoch, ec, qr, tp, om, w, inc)

isfile(local_file) # Check that the binary SPK was downloaded
```

#### `vec_tbl`

`HORIZONS.jl` function `vec_tbl` allows the user to generate vector tables for
designated objects and save the output into a file:

```julia
# Date variables for start and stop times
t_start = DateTime(2029,4,13)
t_stop = Date(2029,4,14)

# Step size (allowed types: Period, Int, String)
δt = Hour(1) # 1 hour step size

# Generate tables and save output to Apophis.txt in current directory:
vec_tbl("Apophis", t_start, t_stop, δt; FILENAME = "Apophis.txt", CENTER = "@ssb", REF_PLANE = "FRAME", OUT_UNITS = "AU-D", CSV_FORMAT = true, VEC_TABLE = 2)
```

Note that `CENTER`, `REF_PLANE`, etc., are keyword arguments. If they are omitted
from the `vec_tbl` call, then they will take default values:

```julia
δt = 1 # Return only one step

# Generate tables with default values and save output to Apophis.txt in current directory:

vec_tbl("Apophis", t_start, t_stop, δt; FILENAME = "Apophis.txt")
```

More details about default values of keyword arguments are available in the
`vec_tbl` docstrings.

If the output file is not specified, then `vec_tbl` returns the output as a
`String`, which may be then used for further processing within Julia:

```julia
δt = "2 hours" # 2 hour step size

# Save into `apophisvt::String` the output from HORIZONS
apophisvt = vec_tbl("Apophis", t_start, t_stop, δt)

# Do stuff with `apophisvt` inside julia...
```

#### `obs_tbl`

`HORIZONS.jl` function `obs_tbl` allows the user to generate observer tables for
designated objects and save the output into a file:

```julia
# Date variables for start and stop times
t_start = DateTime(2020,7,16, 22)
t_stop = Date(2020,7,16, 24)

# Step size (allowed types: Period, Int, String)
δt = Minute(1) # 1 minute step size

# Generate observer table for Voyager 1 as seen from the Green Bank Telescope
# and save output to Voyager1.csv in current directory:
obs_tbl("Voyager 1", t_start, t_stop, δt; FILENAME = "Voyager1.csv", CENTER = "GBT", CSV_FORMAT = true)
```

If the output file is not specified, then `obs_tbl` returns the output as a
`String`, which may be then used for further processing within Julia.

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

#### `ooe_tbl`

`HORIZONS.jl` function `ooe_tbl` allows the user to generate osculating orbital
elements tables for designated objects and save the output into a file:

```julia
# Date variables for start and stop times
t_start = DateTime(2024,4,1)
t_start = DateTime(2024,4,2)

# Get data for a single interval (two points in time)
δt = 1

# Generate osculating orbital elements table for JWST relative to the solar
# system barycenter and save output to jwst.csv in current directory:
ooe_tbl("JWST", t_start, t_stop, δt; FILENAME = "jwst.csv", CENTER = "SSB", CSV_FORMAT = true)
```

More details about default values of keyword arguments are available in the
`ooe_tbl` docstrings.  NB: The HORIZONS default value for `CENTER` is
`Geocentric`, but for objects in a heliocentric orbit you probably want to use
`CENTER="SSB"` (i.e. solar system barycenter) instead.

If the output file is not specified, then `ooe_tbl` returns the output as a
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

### Small-Body DataBase API

`HORIZONS.jl` function `sbdb` fetchs data for a specific small-body in JPL's Small-Body
DataBase (SBDB) and returns the output as a `Dict{String, Any}`:

```julia
# Fetch data of asteroid 433 Eros
sbdb("sstr" => "Eros")

# Fetch data of asteroid 99942 Apophis, including close-approach information
sbdb("sstr" => "Apophis", "ca-data" => "true")
```

### Small-Body Radar Astrometry API

`HORIZONS.jl` function `sbradar` searches for radar astrometry of asteroids/commets and
returns the output as a `Dict{String, Any}`:

```julia
# Search Apophis' radar astrometry
sbradar("spk" => "20099942")

# Add observer information
sbradar("spk" => "20099942", "observer" => "true")
```

## License

`HORIZONS.jl` is licensed under the [MIT "Expat" license](./LICENSE.md).

## Disclaimer

This software package is not affiliated, associated, authorized, endorsed by, or in any way
officially connected with NASA, JPL, or any of its subsidiaries or its affiliates.

## Acknowledgments

JAPH is thankful to Dr. Jon Giorgini for his helpful comments and feedback towards
the first release of this Julia interface to the HORIZONS system, and to Yuri
D'Elia ([@wavexx](https://github.com/wavexx)) for all the help with the telnet interface via
[Expect.jl](https://gitlab.com/wavexx/Expect.jl). Special thanks to LERM ([@LuEdRaMo](https://github.com/LuEdRaMo))
for the implementation of the HTTP interface to HORIZONS and JPL APIs. `obs_tbl` and
`ooe_tbl` implementations are due to [@david-macmahon](https://github.com/david-macmahon).
The [HORIZONS](https://ssd.jpl.nasa.gov/?horizons) system itself is the work of several
people at JPL:

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

## References

* [JPL Solar System Dynamics APIs](https://ssd.jpl.nasa.gov/api.html)
* [HORIZONS documentation (HTML)](https://ssd.jpl.nasa.gov/?horizons_doc)
* Giorgini, J.D., Yeomans, D.K., Chamberlin, A.B., Chodas, P.W.,
    Jacobson, R.A., Keesey, M.S., Lieske, J.H., Ostro, S.J.,
    Standish, E.M., Wimberly, R.N., "JPL's On-Line Solar System Data
    Service", Bulletin of the American Astronomical Society, Vol 28,
    No. 3, p. 1158, 1996.
