require("BinDeps")
s = @build_steps begin
	c=Choices(Choice[Choice(:skip,"Skip Installation - Binaries must be installed manually",nothing)])
end

## Homebrew
@osx_only push!(c,Choice(:brew,"Install depdendency using brew",@build_steps begin
		HomebrewInstall("tk",ASCIIString["--enable-aqua"])
		end))

## Prebuilt Binaries
depsdir = joinpath(Pkg.dir(),"Tk","deps")
@windows_only begin	
	local_file = joinpath(joinpath(depsdir,"downloads"),"Tk.tar.gz")
	push!(c,Choice(:binary,"Download prebuilt binary",@build_steps begin
				ChangeDirectory(depsdir)
				FileDownloader("http://julialang.googlecode.com/files/Tk.tar.gz",local_file)
				FileUnpacker(local_file,joinpath(depsdir,"usr"))
			end))
end

prefix=joinpath(depsdir,"usr")
uprefix = replace(replace(prefix,"\\","/"),"C:/","/c/")

## Install from source
let 
	steps = @build_steps begin ChangeDirectory(depsdir) end

	ENV["PKG_CONFIG_LIBDIR"]=ENV["PKG_CONFIG_PATH"]=joinpath(depsdir,"usr","lib","pkgconfig")
	@unix_only ENV["PATH"]=joinpath(prefix,"bin")*":"*ENV["PATH"]
	@windows_only ENV["PATH"]=joinpath(prefix,"bin")*";"*ENV["PATH"]
	## Windows Specific dependencies

	is64bit = WORD_SIZE == 64
	tcldir = OS_NAME==:Windows?"tcl8.6.0/win":OS_NAME==:Darwin?"tcl8.6.0/macosx":"tcl8.6.0/unix"
	tkdir = OS_NAME==:Windows?"tk8.6.0/win":OS_NAME==:Darwin?"tk8.6.0/macosx":"tk8.6.0/unix"

	steps |= @build_steps begin
		ChangeDirectory(depsdir)
		autotools_install("http://prdownloads.sourceforge.net/tcl/tcl8.6.0-src.tar.gz","tcl-8.6.0.tar.gz",String[is64bit ? "--enable-64bit" : "--disable-64bit","--enable-threads","--enable-symbols","TCL_BIN_DIR=\"$uprefix/bin\""],"tcl8.6.0",tcldir,"libtcl8.6.$shlib_ext","libtcl8.6.$shlib_ext")
		begin
			ChangeDirectory(joinpath("builds",tcldir))
			`make install-private-headers`
		end
		autotools_install("http://prdownloads.sourceforge.net/tcl/tk8.6.0-src.tar.gz","tk-8.6.0.tar.gz",String["--enable-symbols",is64bit ? "--enable-64bit" : "--disable-64bit","--enable-threads","--enable-aqua=yes","--with-tcl="*joinpath(uprefix,"lib")],"tk8.6.0",tkdir,"libtk8.6.$shlib_ext","libtk8.6.$shlib_ext")
		begin
			ChangeDirectory(joinpath("builds",tkdir))
			`make install-private-headers`
		end
	end

	push!(c,Choice(:source,"Install depdendency from source",steps))
end

cc = CCompile("src/tk_wrapper.c","$prefix/lib/libtk_wrapper.$shlib_ext",
		["-shared","-g","-fPIC","-I$prefix/include",
		 "-IC:/src/julia/src","-IC:/src/julia/deps/libuv/include","-IC:/src/julia/src/support","-I/usr/local/include",
		 "-L$prefix/lib"],["-ltcl8.6","-ltk8.6"])
if(OS_NAME == :Darwin)
	unshift!(cc.options,"-xobjective-c")
	append!(cc.libs,["-framework","AppKit","-framework","Foundation","-framework","ApplicationServices"])
elseif(OS_NAME == :Windows)
	push!(cc.libs,"-lGdi32")
end
s |= cc	

run(s)
