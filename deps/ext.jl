using BinDeps

find_library("Tk", "libtcl8.6", ["tcl86g", "libtcl8.6", "/usr/local/opt/tcl-tk/lib/libtcl8.6", OS_NAME == :Linux ? "libtcl8.5" : ""]) || error("libtcl not found")

find_library("Tk", "libtk8.6", ["tk86g", "libtk8.6", "/usr/local/opt/tcl-tk/lib/libtk8.6", OS_NAME == :Linux ? "libtk8.5": ""]) || error("libtk not found")

find_library("Tk", "libtk_wrapper",["libtk_wrapper"]) || error("libtk_wrapper not found")
