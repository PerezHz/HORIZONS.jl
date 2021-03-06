# HORIZONS.jl

[![Build status](https://github.com/PerezHz/HORIZONS.jl/workflows/CI/badge.svg)](https://github.com/PerezHz/HORIZONS.jl/actions)

[![codecov](https://codecov.io/gh/PerezHz/HORIZONS.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/PerezHz/HORIZONS.jl) [![Coverage Status](https://coveralls.io/repos/github/PerezHz/HORIZONS.jl/badge.svg?branch=master)](https://coveralls.io/github/PerezHz/HORIZONS.jl?branch=master)

An interface to NASA-JPL [HORIZONS](https://ssd.jpl.nasa.gov/?horizons) system in
[Julia](http://julialang.org).

## Author

- [Jorge A. Pérez-Hernández](https://www.linkedin.com/in/perezhz),
Instituto de Ciencias Físicas, Universidad Nacional Autónoma de México (UNAM)

Comments, suggestions, and improvements are welcome and appreciated.

## Installation

`HORIZONS.jl` is a registered Julia package and may be installed
from the Julia REPL doing `import Pkg; Pkg.add("HORIZONS")`. Current stable
release is `v0.3.0`, which is compatible with Julia 1.0, 1.3 and 1.4.

## External dependencies

Connection to the HORIZONS machine is done via the `telnet` command line
utility, which should be locally installed and enabled. File downloading is done via `ftp`.

## Usage examples

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

`HORIZONS.jl` also has Julia functions which for some of the scripts authored by
Jon D. Giorgini for automated generation of small-body binary SPK files and tables.
These scripts were originally written in `expect`, and can be found at the
JPL's Solar System Dynamics group ftp server `ftp://ssd.jpl.nasa.gov/pub/ssd/SCRIPTS/`.
Below, we describe the functions `smb_spk`, `smb_spk_ele` and `vec_tbl`.

### `smb_spk`

The `smb_spk` function automates generation and downloading of Solar System
small-bodies binary SPK files from HORIZONS:
```julia
using HORIZONS, Dates

# generate a binary SPK file for asteroid 99942 Apophis covering from 2021 to 2029
ftp_name, local_file = smb_spk("b", "DES= 2099942;", DateTime(2021,Jan,1), DateTime(2029,Apr,13))

isfile(local_file) # check that the binary SPK file `local_file` exists
```
Binary SPK files (i.e., extension `.bsp`) can be read using e.g.
[`SPICE.jl`](https://github.com/JuliaAstro/SPICE.jl):
```julia
# import Pkg; Pkg.add("SPICE") # uncomment this line to add `SPICE.jl` to current environment
using SPICE, Dates
furnsh(local_file)
et = 86400*(datetime2julian(DateTime(2024,3,1)) - 2.451545e6)
pv = spkgeo(2099942, et, "J2000", 0)
```

### `smb_spk_ele`

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

# generate a binary SPK file for asteroid 1990 MU at `epoch`
ftp_name, local_file = smb_spk_ele("b", "1990 MU", start_time, stop_time, epoch, ec, qr, tp, om, w, inc)

isfile(local_file) # check that the binary SPK was downloaded
```

### `vec_tbl`

`HORIZONS.jl` function `vec_tbl` allows the user to generate vector tables for
designated objects and save the output into a file:

```julia
# date variables for start and stop times
t_start = DateTime(2029,4,13)
t_stop = Date(2029,4,14)

# step size (allowed types: Period, Int, String)
δt = Hour(1) # 1 hour step size

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

julia> IDs = string.([99942, 90000033])
2-element Array{String,1}:
 "99942"
 "90000033"

julia> local_files = string.(IDs,".txt")
2-element Array{String,1}:
 "99942.txt"
 "90000033.txt"

julia> vec_tbl.(IDs, local_files, t_start, t_stop, δt) #save output to local files 99942.txt and 90000033.txt in current folder
2-element Array{Void,1}:
 nothing
 nothing

julia>
```

Additionally, the `vec_tbl_csv` function returns HORIZONS output both as an
`Array{Any,2}` and a CSV-formatted `String`, which
can in turn be used to construct a `DataFrame` (requires
[DataFrames.jl](https://github.com/JuliaData/DataFrames.jl) to be installed):

```julia
using HORIZONS, DataFrames

dt0 = Date(2000)
dtmax = Date(2015)
δt = Year(1)

#tbl is an Array{Any,2}; str is a String with CSV format
tbl, str = vec_tbl_csv("1950 DA", dt0, dtmax, δt;
    VEC_TABLE = "2", REF_PLANE="F", CENTER="coord", COORD_TYPE="C", SITE_COORD="1,45,45");

mydataframe = readtable(IOBuffer(str))
```

Then, `mydataframe` is a 16×8 `DataFrame`:

```
# mydataframe:
# 16×8 DataFrames.DataFrame
│ Row │ JDTDB     │ Calendar_Date_TDB                │ X          │ Y          │ Z          │ VX      │ VY       │ VZ       │
├─────┼───────────┼──────────────────────────────────┼────────────┼────────────┼────────────┼─────────┼──────────┼──────────┤
│ 1   │ 2.45154e6 │ "A.D. 2000-Jan-01 00:00:00.0000" │ 3.49475e8  │ 2.10629e7  │ 5.71688e7  │ 25.2192 │ 15.1321  │ 9.42222  │
│ 2   │ 2.45191e6 │ "A.D. 2001-Jan-01 00:00:00.0000" │ -6.98285e7 │ 2.58022e7  │ 5.45238e7  │ 14.9524 │ -12.6021 │ -10.6881 │
│ 3   │ 2.45228e6 │ "A.D. 2002-Jan-01 00:00:00.0000" │ 3.61348e8  │ -5.69666e7 │ 1.54172e6  │ 31.3711 │ 17.5209  │ 11.1536  │
│ 4   │ 2.45264e6 │ "A.D. 2003-Jan-01 00:00:00.0000" │ 4.38864e7  │ 1.05596e8  │ 1.13413e8  │ 12.2543 │ -1.86915 │ -2.97705 │
│ 5   │ 2.45301e6 │ "A.D. 2004-Jan-01 00:00:00.0000" │ 3.22054e8  │ -1.46042e8 │ -6.27119e7 │ 39.9381 │ 18.0432  │ 11.7154  │
│ 6   │ 2.45337e6 │ "A.D. 2005-Jan-01 00:00:00.0000" │ 1.58117e8  │ 1.26817e8  │ 1.30187e8  │ 14.1172 │ 5.18222  │ 2.03615  │
│ 7   │ 2.45374e6 │ "A.D. 2006-Jan-01 00:00:00.0000" │ 2.16183e8  │ -2.27991e8 │ -1.22995e8 │ 52.494  │ 15.0644  │ 9.69931  │
│ 8   │ 2.4541e6  │ "A.D. 2007-Jan-01 00:00:00.0000" │ 2.52251e8  │ 1.08971e8  │ 1.18844e8  │ 17.5583 │ 9.77493  │ 5.43963  │
│ 9   │ 2.45447e6 │ "A.D. 2008-Jan-01 00:00:00.0000" │ 7.88944e6  │ -2.43067e8 │ -1.36722e8 │ 65.0567 │ -6.41305 │ -5.42335 │
│ 10  │ 2.45483e6 │ "A.D. 2009-Jan-01 00:00:00.0000" │ 3.21987e8  │ 6.3783e7   │ 8.74408e7  │ 21.7692 │ 13.586   │ 8.1631   │
│ 11  │ 2.4552e6  │ "A.D. 2010-Jan-01 00:00:00.0000" │ -1.15663e8 │ -7.63649e7 │ -1.92427e7 │ 27.1975 │ -22.6347 │ -17.6561 │
│ 12  │ 2.45556e6 │ "A.D. 2011-Jan-01 00:00:00.0000" │ 3.57936e8  │ -3.91115e6 │ 3.95854e7  │ 27.1418 │ 16.0684  │ 10.0908  │
│ 13  │ 2.45593e6 │ "A.D. 2012-Jan-01 00:00:00.0000" │ -3.42864e7 │ 6.17015e7  │ 8.08374e7  │ 13.0119 │ -8.54587 │ -7.70992 │
│ 14  │ 2.45629e6 │ "A.D. 2013-Jan-01 00:00:00.0000" │ 3.55506e8  │ -8.52031e7 │ -1.86717e7 │ 33.8279 │ 18.0591  │ 11.5473  │
│ 15  │ 2.45666e6 │ "A.D. 2014-Jan-01 00:00:00.0000" │ 8.32588e7  │ 1.17897e8  │ 1.22693e8  │ 12.6344 │ 0.803698 │ -1.08723 │
│ 16  │ 2.45702e6 │ "A.D. 2015-Jan-01 00:00:00.0000" │ 2.96116e8  │ -1.75053e8 │ -8.37231e7 │ 43.4907 │ 17.7757  │ 11.5517  │
```

## License

`HORIZONS.jl` is licensed under the [MIT "Expat" license](./LICENSE.md).

## Acknowledgments

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
[Expect.jl](https://gitlab.com/wavexx/Expect.jl) package.

## References

* [HORIZONS documentation (HTML)](https://ssd.jpl.nasa.gov/?horizons_doc)
* Giorgini, J.D., Yeomans, D.K., Chamberlin, A.B., Chodas, P.W.,
    Jacobson, R.A., Keesey, M.S., Lieske, J.H., Ostro, S.J.,
    Standish, E.M., Wimberly, R.N., "JPL's On-Line Solar System Data
    Service", Bulletin of the American Astronomical Society, Vol 28,
    No. 3, p. 1158, 1996.
