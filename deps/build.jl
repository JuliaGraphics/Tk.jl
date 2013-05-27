using BinDeps

function build()
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
end

function build_wrapper()
    cc = CCompile("src/tk_wrapper.c","$prefix/lib/libtk_wrapper."*BinDeps.shlib_ext,
                  ["-shared","-g","-fPIC","-I$prefix/include",
                   "-I/usr/local/include",
                   "-L$prefix/lib"],
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
    s |= @build_steps begin
        CreateDirectory(joinpath(prefix,"lib"))
        cc
    end

    run(s)
end

function find_library(pkg,libname,filename)
    dl = dlopen_e(joinpath(Pkg.dir(),pkg,"deps","usr","lib",filename))
    if dl == C_NULL
        dl = dlopen_e(libname)
        if dl == C_NULL; return false; end
    end

    if dl != C_NULL
        dlclose(dl)
        return true
    end
end

builddeps = false

if !find_library("Tk", OS_NAME == :Linux ? "libtcl8.5" : "libtcl", OS_NAME == :Windows ? "tcl86g" : "libtcl8.6"); builddeps = true; end
if !find_library("Tk", OS_NAME == :Linux ? "libtk8.5" : "libtk", OS_NAME == :Windows ? "tk86g" : "libtk8.6"); builddeps = true; end

if builddeps; build(); end

if !find_library("Tk", "libtk_wrapper","libtk_wrapper"); build_wrapper(); end
