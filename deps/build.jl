depsdir = joinpath(julia_pkgdir(),"Tk","deps")
prefix = joinpath(depsdir,"usr")
require("BinDeps")
cd(depsdir) do
    ENV["PKG_CONFIG_PATH"]=joinpath(prefix,"lib","pkgconfig")
    ENV["PATH"]=joinpath(prefix,"lib")*":"*ENV["PATH"]
    println("unix/libtcl8.6.$shlib_ext")
    autotools_install("http://prdownloads.sourceforge.net/tcl/tcl8.6.0-src.tar.gz","tcl-8.6.0.tar.gz",String["--enable-64bit","--enable-threads","--enable-symbols"],"tcl8.6.0/unix","libtcl8.6.$shlib_ext")
    autotools_install("http://prdownloads.sourceforge.net/tcl/tk8.6.0-src.tar.gz","tk-8.6.0.tar.gz",String["--enable-symbols","--enable-64bit","--enable-threads","--enable-aqua=yes","--with-tcl="*joinpath(prefix,"lib")],"tk8.6.0/unix","libtk8.6.$shlib_ext")
    cd("builds/tk8.6.0/unix") do
        run(`make install-private-headers`)
    end
    cd("builds/tcl8.6.0/unix") do
        run(`make install-private-headers`)
    end
    CC = "clang"
    CFLAGS = ["-shared","-fPIC"]
    INCPATH = ["-I$prefix/include","-I/Users/keno/Documents/src/julia/src","-I/Users/keno/Documents/src/julia/deps/libuv/include","-I/Users/keno/Documents/src/julia/src/support","-I/usr/local/include"]
    LIBDIRS = ["-L$prefix/lib"]
    LDFLAGS = ["-Wl,-U,_jl_pgcstack","-Wl,-U,_jl_cstr_to_string","-Wl,-U,_jl_enter_handler","-Wl,-U,_jl_defer_signal","-Wl,-U,_jl_current_task","-Wl,-U,_jl_ascii_string_type","-Wl,-U,_jl_utf8_string_type","-Wl,-U,_jl_signal_pending"]
    LIBS = ["-ltcl8.6","-ltk8.6","-framework","Carbon","-framework","ApplicationServices","-framework","Foundation","-framework","AppKit"]
    OUTPUT = "-o$prefix/lib/libtk_wrapper.$shlib_ext"
    @make_rule isfile(joinpath(prefix,"lib","libtk_wrapper.$shlib_ext")) run(`$CC -g -x objective-c -v -mmacosx-version-min=10.6 $CFLAGS $INCPATH $LIBDIRS $LDFLAGS src/tk_wrapper.c $LIBS $OUTPUT`)
end
