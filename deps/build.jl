using BinDeps

depsdir = joinpath(Pkg.dir(),"Tk","deps")
prefix=joinpath(depsdir,"usr")
uprefix = replace(replace(prefix,"\\","/"),"C:/","/c/")

function build()
    s = @build_steps begin
        c=Choices(Choice[Choice(:skip,"Skip Installation - Binaries must be installed manually",nothing)])
    end


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

# Build Tcl and Tk
alllibs = try
    evalfile("ext.jl")
    true
catch
    false
end

if !alllibs; build(); end
