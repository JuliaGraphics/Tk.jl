let addSearchDirs = [Pkg.dir("Tk","deps","usr","lib")], tcl, tk
    tcl = find_library(["tcl86g", "libtcl8.6"], addSearchDirs)
    if tcl != ""
        tk = find_library(["tk86g", "libtk8.6"], addSearchDirs)
    else
        tcl = find_library(["tcl85g", "libtcl8.5"], addSearchDirs)
        if tcl != ""
            tk = find_library(["tk85g", "libtk8.5"], addSearchDirs)
        end
    end
    if tcl == "" || tk == ""
        error("Tcl/Tk libraries not found")
    end
    global const libtcl = tcl
    global const libtk = tk
end
