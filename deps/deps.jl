# Fish the binary dependency via GMT lib (except on Windows where we know it in advance)
const gmtlib = Ref{String}()
try
	gmtlib[] = haskey(ENV,"GMT_LIBRARY") ?
		ENV["GMT_LIBRARY"] : string(chop(read(`gmt --show-library`, String)))
catch
    error("This package can only be installed in systems that have GMT")
end
@static Sys.iswindows() ?
	(Sys.WORD_SIZE == 64 ? (const libnetcdf = "netcdf4_w64") : (const libnetcdf = "netcdf4_w32")) : 
	(
		Sys.isapple() ? (const libnetcdf = Symbol(split(readlines(pipeline(`otool -L $gmtlib`, `grep libnetcdf`))[1])[1])) :
		(
		    Sys.isunix() ? (const libnetcdf = Symbol(split(readlines(pipeline(`ldd $gmtlib`, `grep libnetcdf`))[1])[3])) :
			error("Don't know how to install this package in this OS.")
		)
	)