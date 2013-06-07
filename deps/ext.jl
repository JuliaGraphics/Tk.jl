let 
    printerror() = error("Failed to find required library "*libname*". Try re-running the package script using Pkg.runbuildscript(\"pkg\")")

    if OS_NAME == :Linux || OS_NAME == :Darwin
        tcl8.6 = find_library("Tk", "libtcl8.6", "libtcl8.6")
        tk8.6  = find_library("Tk", "libtk8.6", "libtk8.6")
    elseif OS_NAME == :Windows
        tcl8.6 = find_library("Tk", "libtcl", "tcl86g")
        tk8.6  = find_library("Tk", "libtk", "tk86g")
    end

    if !(tcl8.6 && tk8.6)
        if OS_NAME == :Linux
            tcl8.5 = find_library("Tk", "libtcl8.5", "libtcl8.5")
            tk8.5  = find_library("Tk", "libtk8.5", "libtk8.5")
            
            if !(tcl8.5 && tk8.5)
                printerror()
            end
        else
            printerror()
        end
    end

    tk_wrapper = find_library("Tk", "libtk_wrapper","libtk_wrapper")
    if !tk_wrapper; printerror(); end

end
