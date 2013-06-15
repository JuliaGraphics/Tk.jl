using BinDeps

depsdir = joinpath(Pkg.dir(),"Tk","deps")
prefix=joinpath(depsdir,"usr")
uprefix = replace(replace(prefix,"\\","/"),"C:/","/c/")

function build()
    s = @build_steps begin
        c=Choices(Choice[Choice(:skip,"Skip Installation - Binaries must be installed manually",nothing)])
    end

    ## Homebrew
    @osx_only push!(c,Choice(:brew,"Install depdendency using brew",@build_steps begin
        HomebrewInstall("https://raw.github.com/Homebrew/homebrew-dupes/master/tcl-tk.rb",ASCIIString[])
    end))

    ## Prebuilt Binaries
    @windows_only begin
        local_file = joinpath(joinpath(depsdir,"downloads"),"Tk.tar.gz")
                   push!(c,Choice(:binary,"Download prebuilt binary",@build_steps begin
                       ChangeDirectory(depsdir)
                       FileDownloader("http://julialang.googlecode.com/files/Tk.tar.gz",local_file)
                       FileUnpacker(local_file,joinpath(depsdir,"usr"))
         end))
    end

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
            autotools_install(depsdir,"http://prdownloads.sourceforge.net/tcl/tcl8.6.0-src.tar.gz","tcl-8.6.0.tar.gz",String[is64bit ? "--enable-64bit" : "--disable-64bit","--enable-threads","--enable-symbols","TCL_BIN_DIR=\"$uprefix/bin\""],"tcl8.6.0",tcldir,"libtcl8.6."*BinDeps.shlib_ext,"libtcl8.6."*BinDeps.shlib_ext)
            begin
                ChangeDirectory(joinpath("builds",tcldir))
                `make install-private-headers`
            end
            autotools_install(depsdir,"http://prdownloads.sourceforge.net/tcl/tk8.6.0-src.tar.gz","tk-8.6.0.tar.gz",String["--enable-symbols",is64bit ? "--enable-64bit" : "--disable-64bit","--enable-threads","--enable-aqua=yes","--with-tcl="*joinpath(uprefix,"lib")],"tk8.6.0",tkdir,"libtk8.6."*BinDeps.shlib_ext,"libtk8.6."*BinDeps.shlib_ext)
            begin
                ChangeDirectory(joinpath("builds",tkdir))
                `make install-private-headers`
            end
        end

        push!(c,Choice(:source,"Install depdendency from source",steps))
    end

    run(s)
end

function build_wrapper()
    include_paths = ["$prefix/include", "/usr/local/include"]
    lib_paths = ["$prefix/lib"]
    @osx_only begin
        insert!(include_paths, 1, "/usr/local/opt/tcl-tk/include")
        insert!(lib_paths, 1, "/usr/local/opt/tcl-tk/lib")
    end
    cc = CCompile("src/tk_wrapper.c","$prefix/lib/libtk_wrapper."*BinDeps.shlib_ext,
                  ["-shared","-g","-fPIC","-I$prefix/include",
                   ["-I$path" for path in include_paths]...,
                   ["-L$path" for path in lib_paths]...],
                  OS_NAME == :Linux ? ["-ltcl8.5","-ltk8.5"] : OS_NAME == :Darwin ? ["-ltcl8.6","-ltk8.6"] : ["-ltcl","-ltk"])
    if(OS_NAME == :Darwin)
#        push!(cc.options, "-I/opt/X11/include")
        unshift!(cc.options,"-xobjective-c")
        append!(cc.libs,["-framework","AppKit","-framework","Foundation","-framework","ApplicationServices"])
    elseif(OS_NAME == :Windows)
        push!(cc.libs,"-lGdi32")
    elseif(OS_NAME == :Linux)
        for idir in ("/usr/include/tcl8.5", "/usr/include/tcl")
            if isdir(idir)
                push!(cc.options, "-I$idir")
                break
            end
        end
    end
    s = @build_steps begin
        CreateDirectory(joinpath(prefix,"lib"))
        cc
    end

    run(s)
end

# Build Tcl and Tk
builddeps = false

find_library("Tk", "libtcl", ["tcl86g", "libtcl8.6", "/usr/local/opt/tcl-tk/lib/libtcl8.6", "/usr/local/opt/tcl-tk/lib/libtcl8.5", "libtcl8.5"]) || (builddeps = true)
find_library("Tk", "libtk", ["tk86g", "libtk8.6", "/usr/local/opt/tcl-tk/lib/libtk8.6", "/usr/local/opt/tcl-tk/lib/libtk8.5", "libtk8.5"]) || (builddeps = true)
if builddeps; build(); end

# Build Tk_wrapper
find_library("Tk", "libtk_wrapper","libtk_wrapper") || build_wrapper()
