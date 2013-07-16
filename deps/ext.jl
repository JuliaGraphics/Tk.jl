let addSearchDirs = [Pkg.dir("Tk","deps","usr","lib"),
                     "/usr/local/opt/tcl-tk/lib/"], tcl, tk
    tcl = find_library(["libtcl8.6", "tcl86g", "tcl86"], addSearchDirs)
    if tcl != ""
        tk = find_library(["libtk8.6", "tk86g", "tk86"], addSearchDirs)
    else
        tcl = find_library(["libtcl8.5", "tcl85g", "tcl85"], addSearchDirs)
        if tcl != ""
            tk = find_library(["libtk8.5", "tk85g", "tk85"], addSearchDirs)
        end
    end
    if tcl == "" || tk == ""
        error("Tcl/Tk libraries not found")
    end
    global const libtcl = tcl
    global const libtk = tk
end
