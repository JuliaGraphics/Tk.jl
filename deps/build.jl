using BinDeps
using Libdl

@BinDeps.setup

tcl = library_dependency("tcl",aliases=["libtcl8.6","tcl86g","tcl86t","libtcl","libtcl8.6.so.0","libtcl8.5","libtcl8.5.so.0","tcl85"])
tk = library_dependency("tk",aliases=["libtk8.6","libtk","libtk8.6.so.0","libtk8.5","libtk8.5.so.0","tk85","tk86","tk86t"], depends=[tcl], validate = function(p,h)
    Sys.isapple() && (return Libdl.dlsym_e(h,:TkMacOSXGetRootControl) != C_NULL)
    return true
end)

if Sys.iswindows()
    using WinRPM
    provides(WinRPM.RPM,"tk",tk,os = :Windows)
    provides(WinRPM.RPM,"tcl",tcl,os = :Windows)
end

provides(AptGet,"tcl8.5",tcl)
provides(AptGet,"tk8.5",tk)

provides(Sources,URI("http://prdownloads.sourceforge.net/tcl/tcl8.6.0-src.tar.gz"),tcl,unpacked_dir = "tcl8.6.0")
provides(Sources,URI("http://prdownloads.sourceforge.net/tcl/tk8.6.0-src.tar.gz"),tk,unpacked_dir = "tk8.6.0")

is64bit = Sys.WORD_SIZE == 64

provides(BuildProcess,Autotools(configure_subdir = "unix", configure_options = [is64bit ? "--enable-64bit" : "--disable-64bit"]),tcl, os = :Unix)
provides(BuildProcess,Autotools(configure_subdir = "unix", configure_options = [is64bit ? "--enable-64bit" : "--disable-64bit"]),tk, os = :Unix)

if Sys.WORD_SIZE == 64
        # Unfortunately the mingw-built tc segfaults since some function signatures
        # are different between VC and mingw. This is fixed on tcl trunk. For now,
        # just use VC to build tcl (Note requlres Visual Studio Express in the PATH)
        provides(BuildProcess,(@build_steps begin
                GetSources(tcl)
                FileRule("tclConfig.sh",@build_steps begin
                        ChangeDirectory(joinpath(srcdir(tcl),"tcl8.6.0/win"))
                        `nmake -f Makefile.vc`
                        `nmake -f Makefile.vc install INSTALLDIR=$(usrdir(tcl))`
                        `xcopy $(libdir(tcl))\\tclConfig.sh $(srcdir(tcl))\\tcl8.6.0\\win`
                end)
        end),tcl)
        provides(BuildProcess,(@build_steps begin
                GetSources(tk)
                begin
                        ChangeDirectory(joinpath(srcdir(tk),"tk8.6.0/win"))
                        `nmake -f Makefile.vc TCLDIR=$(srcdir(tcl))\\tcl8.6.0`
                        `nmake -f Makefile.vc install INSTALLDIR=$(usrdir(tk))`
                end
        end),tk)
else
        provides(BuildProcess,Autotools(libtarget = "tcl86.dll", configure_subdir = "win", configure_options = [is64bit ? "--enable-64bit" : "--disable-64bit","--enable-threads"]),tcl, os = :Windows)
        provides(BuildProcess,Autotools(libtarget = "tk86.dll", configure_subdir = "win", configure_options = [is64bit ? "--enable-64bit" : "--disable-64bit"]),tk, os = :Windows)
end

@BinDeps.install Dict(:tk => :libtk, :tcl=>:libtcl)
