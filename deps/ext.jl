using BinDeps

find_library("Tk", "libtcl", ["tcl86g", "libtcl8.6", "libtcl8.5", "/usr/local/opt/tcl-tk/lib/libtcl8.6", "/usr/local/opt/tcl-tk/lib/libtcl8.5"]) || error("libtcl not found")
find_library("Tk", "libtk", ["tk86g", "libtk8.6", "libtk8.5", "/usr/local/opt/tcl-tk/lib/libtk8.6", "/usr/local/opt/tcl-tk/lib/libtk8.5"]) || error("libtk not found")
find_library("Tk", "libtk_wrapper",["libtk_wrapper"]) || error("libtk_wrapper not found")
