let addSearchDirs = [Pkg.dir("Tk","deps","usr","lib")]
global const libtcl = find_library(["tcl86g", "libtcl8.6", "tcl85g", "libtcl8.5"], addSearchDirs)
libtcl != "" || error("libtcl not found")
global const libtk = find_library(["tk86g", "libtk8.6", "tk85g", "libtk8.5"], addSearchDirs)
libtk != "" || error("libtk not found")
global const libtk_wrapper = find_library(["libtk_wrapper"],addSearchDirs)
libtk_wrapper != "" || error("libtk_wrapper not found")
end
