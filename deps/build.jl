using BinDeps

@BinDeps.setup

tcl = library_dependency("tcl",aliases=["libtcl8.6","libtcl","libtcl8.6.so.0"])
tk = library_dependency("tk",aliases=["libtk8.6","libtk","libtk8.6.so.0"])

provides(Binaries,URI("http://julialang.googlecode.com/files/Tk.tar.gz"),[tcl,tk],os = :Windows)

provides(AptGet,"tcl8.6",tcl)
provides(AptGet,"tk8.6",tk)

provides(Sources,URI("http://prdownloads.sourceforge.net/tcl/tcl8.6.0-src.tar.gz"),tcl,unpacked_dir = "tcl8.6.0")
provides(Sources,URI("http://prdownloads.sourceforge.net/tcl/tk8.6.0-src.tar.gz"),tk,unpacked_dir = "tk8.6.0")

provides(BuildProcess,Autotools(configure_subdir = "unix"),tcl, os = :Unix)
provides(BuildProcess,Autotools(configure_subdir = "unix"),tk, os = :Unix)

@BinDeps.install