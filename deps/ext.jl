let 
    function find_library(libname,filename)
        try 
            dl = dlopen(joinpath(Pkg.dir(),"Tk","deps","usr","lib",filename))
            ccall(:add_library_mapping,Int32,(Ptr{Uint8},Ptr{Uint8}),libname,dl)
        catch
            try 
                dl = dlopen(libname)
                dlclose(dl)
            catch
                error("Failed to find required library "*libname*". Try re-running the package script using Pkg.runbuildscript(\"pkg\")")
            end
        end
    end
    find_library(OS_NAME == :Linux ? "libtcl8.5" : "libtcl",
                 OS_NAME == :Windows ? "tcl86g" : "libtcl8.6")
    find_library(OS_NAME == :Linux ? "libtk8.5" : "libtk",
                 OS_NAME == :Windows ? "tk86g" : "libtk8.6")
    find_library("libtk_wrapper","libtk_wrapper")
end
