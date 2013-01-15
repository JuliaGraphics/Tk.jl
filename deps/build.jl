@windows_only require("BinDeps")
@windows_only begin
	depsdir = joinpath(julia_pkgdir(),"Tk","deps")
	prefix=joinpath(depsdir,"usr")
	uprefix = replace(replace(prefix,"\\","/"),"C:/","/c/")
	if(true)
		local_file = joinpath(joinpath(depsdir,"downloads"),"Tk.tar.gz")
		cd(depsdir) do
			run(@build_steps begin
				FileDownloader("http://julialang.googlecode.com/files/Tk.tar.gz",local_file)
				FileUnpacker(local_file,joinpath(depsdir,"usr"))
			end)
		end
	else
		cd(depsdir) do
			ENV["PKG_CONFIG_PATH"]=joinpath(prefix,"lib","pkgconfig")
			#ENV["PATH"]=joinpath(prefix,"lib")*";"*ENV["PATH"]
			println("unix/libtcl8.6.$shlib_ext")
			#autotools_install("http://prdownloads.sourceforge.net/tcl/tcl8.6.0-src.tar.gz","tcl-8.6.0.tar.gz",String["--disable-64bit","--enable-threads","--enable-symbols","TCL_BIN_DIR=\"$uprefix/bin\""],"tcl8.6.0","tcl8.6.0/win","libtcl8.6.$shlib_ext","libtcl8.6.$shlib_ext")
			#autotools_install("http://prdownloads.sourceforge.net/tcl/tk8.6.0-src.tar.gz","tk-8.6.0.tar.gz",String["--enable-symbols","--disable-64bit","--enable-threads","--enable-aqua=yes","--with-tcl="*joinpath(uprefix,"lib")],"tk8.6.0","tk8.6.0/win","libtk8.6.$shlib_ext","libtk8.6.$shlib_ext")
			#cd("builds/tk8.6.0/unix") do
			#    run(`make install-private-headers`)
			#end
			#cd("builds/tcl8.6.0/unix") do
			#    run(`make install-private-headers`)
			#end
			CC = "gcc"
			CFLAGS = ["-shared","-fPIC"]
			INCPATH = ["-I$prefix/include","-IC:/src/julia/src","-IC:/src/julia/deps/libuv/include","-IC:/src/julia/src/support","-I/usr/local/include"]
			LIBDIRS = ["-L$prefix/lib","-LC:/src/julia/usr/lib"]
			LDFLAGS = ["-Wl,-u,jl_pgcstack","-u","_jl_cstr_to_string","-u","_jl_enter_handler","-Wl,-u,_jl_defer_signal","-u","_jl_current_task","-u","_jl_ascii_string_type","-u","_jl_utf8_string_type","-u","_jl_signal_pending"]
			LIBS = ["-ltcl8.6","-ltk8.6","-lGdi32"]
			OUTPUT = "-o$prefix/lib/libtk_wrapper.$shlib_ext"
			@make_rule isfile(joinpath(prefix,"lib","libtk_wrapper.$shlib_ext")) run(`$CC -shared -g $INCPATH $LIBDIRS $LDFLAGS src/tk_wrapper.c $LIBS $OUTPUT`)
		end
	end
end