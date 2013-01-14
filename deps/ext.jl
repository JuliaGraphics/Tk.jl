ENV["LD_LIBRARY_PATH"]="/Users/keno/.julia/Tk/deps/usr/lib"
ccall(:add_library_mapping,Int32,(Ptr{Uint8},Ptr{Uint8}),"libtcl8.6",dlopen(joinpath(julia_pkgdir(),"Tk","deps","usr","lib","libtcl8.6")))
ccall(:add_library_mapping,Int32,(Ptr{Uint8},Ptr{Uint8}),"libtk8.6",dlopen(joinpath(julia_pkgdir(),"Tk","deps","usr","lib","libtk8.6")))
ccall(:add_library_mapping,Int32,(Ptr{Uint8},Ptr{Uint8}),"libtk_wrapper",dlopen(joinpath(julia_pkgdir(),"Tk","deps","usr","lib","libtk_wrapper")))

#THIS IS FOR TESTING ONLY
 ccall(:add_library_mapping,Int32,(Ptr{Uint8},Ptr{Uint8}),"libX11",dlopen("/usr/X11/lib/libX11.dylib"))
