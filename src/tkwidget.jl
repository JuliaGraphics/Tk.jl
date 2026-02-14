const TCL_OK       = convert(Int32, 0)
const TCL_ERROR    = convert(Int32, 1)
const TCL_RETURN   = convert(Int32, 2)
const TCL_BREAK    = convert(Int32, 3)
const TCL_CONTINUE = convert(Int32, 4)

const TCL_VOLATILE = convert(Ptr{Cvoid}, 1)
const TCL_STATIC   = convert(Ptr{Cvoid}, 0)
const TCL_DYNAMIC  = convert(Ptr{Cvoid}, 3)

# Thread-safety: Tcl/Tk requires all interpreter calls from the OS thread
# that created it.  We dispatch all Tcl calls through the timer task, which
# runs on the creating thread (interactive threadpool, thread 1).
const _tcl_call_queue = Channel{Any}(256)
const _tcl_timer_task = Ref{Any}(nothing)   # set to current_task() in timer cb
const _tcl_initialized = Ref{Bool}(false)   # set to true after Timer is created

"""
    _tcl_do(f) -> result

Execute `f()` on the Tcl thread.  If the caller is already on the timer task
(or during `init()` before the timer starts), `f` is called directly.
Otherwise, `f` is queued for the timer callback and the caller blocks until
the result is available.
"""
function _tcl_do(f::Function)
    # During init (before timer exists): call directly, we're on the creating thread
    if !_tcl_initialized[]
        return f()
    end
    # Already on the timer task (e.g., within a Tcl callback): call directly
    if current_task() === _tcl_timer_task[]
        return f()
    end
    # Dispatch to the timer thread and wait for result
    result_ch = Channel{Any}(1)
    put!(_tcl_call_queue, (f, result_ch))
    response = take!(result_ch)
    if response isa Exception
        throw(response)
    end
    return response
end

function _process_tcl_queue()
    while isready(_tcl_call_queue)
        (f, result_ch) = take!(_tcl_call_queue)
        try
            result = f()
            put!(result_ch, result)
        catch e
            put!(result_ch, e)
        end
    end
end

tcl_doevent() = _tcl_do(_tcl_process_events)
function _tcl_process_events()
    while (ccall((:Tcl_DoOneEvent,libtcl), Int32, (Int32,), (1<<1))!=0)
    end
end
function tcl_doevent(timer,status=0)
    _tcl_timer_task[] = current_task()
    # https://www.tcl.tk/man/tcl8.6/TclLib/DoOneEvent.htm
    # DONT_WAIT* = 1 shl 1
    _process_tcl_queue()
    _tcl_process_events()
end

global timeout = nothing

# fetch first word from struct
tk_display(w) = unsafe_load(convert(Ptr{Ptr{Cvoid}},w))

const TCL_GLOBAL_ONLY = Int32(1)

function _find_tcl_scripts(artifact_dir, filename)
    # Check common locations for Tcl/Tk library scripts
    for subdir in ("lib/tcl9.0", "lib/tk9.0", "share/tcl9.0", "share/tk9.0")
        candidate = joinpath(artifact_dir, subdir)
        if isfile(joinpath(candidate, filename))
            return candidate
        end
    end
    # Fall back to searching the artifact
    for (root, dirs, files) in walkdir(artifact_dir)
        if filename in files
            return root
        end
    end
    # Return default guess if not found; Tcl_Init will produce a clear error
    return joinpath(artifact_dir, "lib", "tcl9.0")
end

function init()
    # Point Tcl and Tk to their library scripts in the JLL artifacts.
    # Set env vars BEFORE any Tcl calls so that Tcl_FindExecutable and
    # Tcl_CreateInterp can find encoding files and init scripts.
    tcl_lib = _find_tcl_scripts(dirname(dirname(Tcl_jll.libtcl_path)), "init.tcl")
    tk_lib  = _find_tcl_scripts(dirname(dirname(Tk_jll.libtk_path)),  "tk.tcl")
    ENV["TCL_LIBRARY"] = tcl_lib
    ENV["TK_LIBRARY"]  = tk_lib

    ccall((:Tcl_FindExecutable,libtcl), Cvoid, (Ptr{UInt8},),
          Tcl_jll.libtcl_path)
    tclinterp = ccall((:Tcl_CreateInterp,libtcl), Ptr{Cvoid}, ())

    ccall((:Tcl_SetVar2,libtcl), Ptr{UInt8},
          (Ptr{Cvoid}, Ptr{UInt8}, Ptr{Cvoid}, Ptr{UInt8}, Int32),
          tclinterp, "tcl_library", C_NULL, tcl_lib, TCL_GLOBAL_ONLY)
    ccall((:Tcl_SetVar2,libtcl), Ptr{UInt8},
          (Ptr{Cvoid}, Ptr{UInt8}, Ptr{Cvoid}, Ptr{UInt8}, Int32),
          tclinterp, "tk_library", C_NULL, tk_lib, TCL_GLOBAL_ONLY)

    if ccall((:Tcl_Init,libtcl), Int32, (Ptr{Cvoid},), tclinterp) == TCL_ERROR
        throw(TclError(string("error initializing Tcl: ", tcl_result(tclinterp))))
    end
    if ccall((:Tk_Init,libtk), Int32, (Ptr{Cvoid},), tclinterp) == TCL_ERROR
        throw(TclError(string("error initializing Tk: ", tcl_result(tclinterp))))
    end
    global timeout
    if ccall(:jl_generating_output, Cint, ()) != 1
        timeout = Timer(tcl_doevent, 0.1, interval=0.01)
        _tcl_initialized[] = true
    end
    tclinterp
end

mainwindow(interp) = _tcl_do() do
    ccall((:Tk_MainWindow,libtk), Ptr{Cvoid}, (Ptr{Cvoid},), interp)
end
mainwindow() = mainwindow(tcl_interp[])

mutable struct TclError <: Exception
    msg::AbstractString
end

tcl_result() = tcl_result(tcl_interp[])
function tcl_result(tclinterp)
    objPtr = ccall((:Tcl_GetObjResult,libtcl), Ptr{Cvoid}, (Ptr{Cvoid},), tclinterp)
    unsafe_string(ccall((:Tcl_GetString,libtcl), Ptr{UInt8}, (Ptr{Cvoid},), objPtr))
end

function tcl_evalfile(name)
    _tcl_do() do
        if ccall((:Tcl_EvalFile,libtcl), Int32, (Ptr{Cvoid}, Ptr{UInt8}),
                 tcl_interp[], name) != 0
            throw(TclError(tcl_result()))
        end
        nothing
    end
end

tcl_eval(cmd) = tcl_eval(cmd,tcl_interp[])
function tcl_eval(cmd,tclinterp)
    _tcl_do() do
        code = ccall((:Tcl_EvalEx,libtcl), Int32, (Ptr{Cvoid}, Ptr{UInt8}, Int, Int32),
                     tclinterp, cmd, -1, 0)
        result = tcl_result(tclinterp)
        if code != 0
            throw(TclError(result))
        else
            result
        end
    end
end

mutable struct TkWidget
    path::String
    kind::String
    parent::Union{TkWidget,Nothing}

    let ID::Int = 0
    function TkWidget(parent::TkWidget, kind)
        underscoredKind = replace(kind, "::" => "_")
        path = "$(parent.path).jl_$(underscoredKind)$(ID)"; ID += 1
        new(path, kind, parent)
    end
    global Window
    function Window(title, w, h, visible = true)
        wpath = ".jl_win$ID"; ID += 1
        tcl_eval("toplevel $wpath -width $w -height $h -background \"\"")
        if !visible
            tcl_eval("wm withdraw $wpath")
        end
        tcl_eval("wm title $wpath \"$title\"")
        tcl_doevent()
        new(wpath, "toplevel", nothing)
    end
    end
end

Window(title) = Window(title, 200, 200)

place(widget::TkWidget, x::Int, y::Int) = tcl_eval("place $(widget.path) -x $x -y $y")

function nametowindow(name)
    _tcl_do() do
        ccall((:Tk_NameToWindow,libtk), Ptr{Cvoid},
              (Ptr{Cvoid}, Ptr{UInt8}, Ptr{Cvoid}),
              tcl_interp[], name, ccall((:Tk_MainWindow,libtk), Ptr{Cvoid}, (Ptr{Cvoid},), tcl_interp[]))
    end
end

const _callbacks = Dict{String, Any}()

const empty_str = ""

function jl_tcl_callback(fptr, interp, argc::Int32, argv::Ptr{Ptr{UInt8}})::Int32
    cname = unsafe_pointer_to_objref(fptr)
    f=_callbacks[cname]
    args = [unsafe_string(unsafe_load(argv,i)) for i=1:argc]
    local result
    try
        result = f(args...)
    catch e
        println("error during Tk callback: ")
        Base.display_error(e,catch_backtrace())
        return TCL_ERROR
    end
    if isa(result,String)
        obj = ccall((:Tcl_NewStringObj,libtcl), Ptr{Cvoid}, (Ptr{UInt8}, Int),
                    result, -1)
        ccall((:Tcl_SetObjResult,libtcl), Cvoid, (Ptr{Cvoid}, Ptr{Cvoid}),
              interp, obj)
    else
        obj = ccall((:Tcl_NewStringObj,libtcl), Ptr{Cvoid}, (Ptr{UInt8}, Int),
                    empty_str, 0)
        ccall((:Tcl_SetObjResult,libtcl), Cvoid, (Ptr{Cvoid}, Ptr{Cvoid}),
              interp, obj)
    end
    return TCL_OK
end

function tcl_callback(f)
    cname = string("jl_cb", repr(objectid(f)))
    _tcl_do() do
        # TODO: use Tcl_CreateObjCommand instead
        ccall((:Tcl_CreateCommand,libtcl), Ptr{Cvoid},
              (Ptr{Cvoid}, Ptr{UInt8}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}),
              tcl_interp[], cname, jl_tcl_callback_ptr, pointer_from_objref(cname), C_NULL)
        # TODO: use a delete proc (last arg) to remove this
        _callbacks[cname] = f
    end
    cname
end

width(w::TkWidget) = parse(Int, tcl_eval("winfo width $(w.path)"))
height(w::TkWidget) = parse(Int, tcl_eval("winfo height $(w.path)"))

const default_mouse_cb = (w, x, y)->nothing

mutable struct MouseHandler
    button1press
    button1release
    button2press
    button2release
    button3press
    button3release
    motion
    button1motion

    MouseHandler() = new(default_mouse_cb, default_mouse_cb, default_mouse_cb,
                         default_mouse_cb, default_mouse_cb, default_mouse_cb,
                         default_mouse_cb, default_mouse_cb)
end

# TkCanvas is the plain Tk canvas widget. This one is double-buffered
# and built on Cairo.
mutable struct Canvas
    c::TkWidget
    back::CairoSurface   # backing store
    backcc::CairoContext
    mouse::MouseHandler
    draw
    resize
    initialized::Bool

    Canvas(parent) = Canvas(parent, -1, -1)
    function Canvas(parent, w, h)
        c = TkWidget(parent, "ttk::frame")
        # frame supports empty background, allowing us to control drawing
        if w < 0
            w = width(parent)
        end
        if h < 0
            h = height(parent)
        end
        this = new(c)
        tcl_eval("frame $(c.path) -width $w -height $h -background \"\"")
        this.draw = x->nothing
        this.resize = x->nothing
        this.mouse = MouseHandler()
        this.initialized = false
        add_canvas_callbacks(this)
        this
    end
end

width(c::Canvas) = width(c.c)
height(c::Canvas) = height(c.c)

function configure(c::Canvas)
    # this is called e.g. on window resize
    if isdefined(c,:back)
        Cairo.destroy(c.backcc)
        Cairo.destroy(c.back)
    end
    w = width(c.c)
    h = height(c.c)
    @static if Sys.isapple()
        # Use an image surface on macOS; reveal() displays it via Tk photo
        c.back = CairoImageSurface(w, h, Cairo.FORMAT_ARGB32)
    else
        render_to_cairo(c.c, false) do surf
            c.back = surface_create_similar(surf, w, h)
        end
    end
    c.backcc = CairoContext(c.back)
    # Check c.initialized to prevent infinite recursion if initialized from
    # c.resize. This also avoids a double-redraw on the first call.
    if c.initialized
        c.resize(c)
        draw(c)
    end
end

function draw(c::Canvas)
    c.draw(c)
    reveal(c)
end

const _reveal_active = Set{String}()

function reveal(c::Canvas)
    @static if Sys.isapple()
        # On macOS with Tk 9, layer-backed views prevent direct CGContext
        # rendering. Display the back buffer as a Tk photo image instead.
        c.c.path in _reveal_active && return
        push!(_reveal_active, c.c.path)
        try
            back = cairo_surface(c)
            io = IOBuffer()
            write_to_png(back, io)
            png_b64 = base64encode(take!(io))
            imgname = "jl_photo_" * replace(c.c.path[2:end], r"[.:]" => "_")
            tcl_eval("image create photo $imgname -data {$png_b64}")
            lblpath = c.c.path * ".jl_img"
            if tcl_eval("winfo exists $lblpath") == "0"
                tcl_eval("label $lblpath -image $imgname -bd 0 -highlightthickness 0")
                tcl_eval("place $lblpath -x 0 -y 0 -relwidth 1 -relheight 1")
                # Forward mouse/keyboard events from label through the Canvas frame
                tcl_eval("bindtags $lblpath [list $lblpath $(c.c.path) [winfo class $lblpath] . all]")
            else
                tcl_eval("$lblpath configure -image $imgname")
            end
        finally
            delete!(_reveal_active, c.c.path)
        end
        return
    end
    render_to_cairo(c.c) do front
        frontcc = CairoContext(front)
        back = cairo_surface(c)
        set_source_surface(frontcc, back, 0, 0)
        paint(frontcc)
        destroy(frontcc)
    end
    tcl_doevent()
end

@static if Sys.isapple()
    if Sys.WORD_SIZE == 32
        const CGFloat = Float32
    else
        const CGFloat = Float64
    end
    function objc_msgSend(id, uid, ::Type{T}=Ptr{Cvoid}) where T
        convert(T, ccall(:objc_msgSend, Ptr{Cvoid}, (Ptr{Cvoid}, Ptr{Cvoid}),
                         id, ccall(:sel_getUid, Ptr{Cvoid}, (Ptr{UInt8},), uid)))
    end
end

# NOTE: This has to be ported to each window environment.
# But, this should be the only such function needed.
function render_to_cairo(f::Function, w::TkWidget, clipped::Bool=true)
    _tcl_do() do
        _render_to_cairo_impl(f, w, clipped)
    end
end
function _render_to_cairo_impl(f::Function, w::TkWidget, clipped::Bool)
    win = ccall((:Tk_NameToWindow,libtk), Ptr{Cvoid},
          (Ptr{Cvoid}, Ptr{UInt8}, Ptr{Cvoid}),
          tcl_interp[], w.path, ccall((:Tk_MainWindow,libtk), Ptr{Cvoid}, (Ptr{Cvoid},), tcl_interp[]))
    win == C_NULL && error("invalid window")
    @static if Sys.islinux()
        disp = jl_tkwin_display(win)
        d = jl_tkwin_id(win)
        vis = jl_tkwin_visual(win)
        if disp==C_NULL || d==0 || vis==C_NULL
            error("invalid window")
        end
        surf = CairoXlibSurface(disp, d, vis, width(w), height(w))
        f(surf)
        destroy(surf)
        return
    end
    @static if Sys.isapple()
        drawable = jl_tkwin_id(win)
        view = ccall((:TkMacOSXGetRootControl,libtk), Ptr{Cvoid}, (Int,), drawable)
        if view == C_NULL
            error("Invalid macOS window")
        end
        # Lock focus on the view to get a valid drawing context
        focusView = objc_msgSend(ccall(:objc_getClass, Ptr{Cvoid}, (Ptr{UInt8},), "NSView"), "focusView")
        focusLocked = false
        if view != focusView
            focusLocked = objc_msgSend(view, "lockFocusIfCanDraw", Int32) != 0
            if !focusLocked
                error("Cannot draw to macOS window")
            end
        elseif 0 == objc_msgSend(view, "canDraw", Int32)
            error("Cannot draw to macOS window")
        end
        # Get CGContext from the current NSGraphicsContext (modern API)
        nsGC = objc_msgSend(
            ccall(:objc_getClass, Ptr{Cvoid}, (Ptr{UInt8},), "NSGraphicsContext"),
            "currentContext")
        context = objc_msgSend(nsGC, "CGContext")
        if !focusLocked
            ccall(:CGContextSaveGState, Cvoid, (Ptr{Cvoid},), context)
        end
        try
            wi, hi = width(w), height(w)
            if clipped
                # Flip Y axis: CG uses bottom-left origin, Tk uses top-left
                ccall(:CGContextTranslateCTM, Cvoid, (Ptr{Cvoid}, CGFloat, CGFloat), context, 0, height(toplevel(w)))
                ccall(:CGContextScaleCTM, Cvoid, (Ptr{Cvoid}, CGFloat, CGFloat), context, 1, -1)
                # Apply widget offset within toplevel
                macDraw = unsafe_load(convert(Ptr{TkWindowPrivate}, drawable))
                ccall(:CGContextTranslateCTM, Cvoid, (Ptr{Cvoid}, CGFloat, CGFloat), context, macDraw.xOff, macDraw.yOff)
            end
            surf = CairoQuartzSurface(context, wi, hi)
            try
                f(surf)
            finally
                destroy(surf)
            end
        finally
            ccall(:CGContextSynchronize, Cvoid, (Ptr{Cvoid},), context)
            if focusLocked
                objc_msgSend(view, "unlockFocus")
            else
                ccall(:CGContextRestoreGState, Cvoid, (Ptr{Cvoid},), context)
            end
        end
        return
    end
    @static if Sys.iswindows()
        state = Vector{UInt8}(undef, sizeof(Int)*2) # 8.4, 8.5, 8.6
        drawable = jl_tkwin_id(win)
        hdc = ccall((:TkWinGetDrawableDC,libtk), Ptr{Cvoid}, (Ptr{Cvoid}, Int, Ptr{UInt8}),
            jl_tkwin_display(win), drawable, state)
        surf = CairoWin32Surface(hdc, width(w), height(w))
        f(surf)
        destroy(surf)
        ccall((:TkWinReleaseDrawableDC,libtk), Cvoid, (Int, Ptr{Cvoid}, Ptr{UInt8}),
            drawable, hdc, state)
        return
    end
    error("Unsupported Operating System")
end

function add_canvas_callbacks(c::Canvas)
    # See Table 15-3 of http://oreilly.com/catalog/mastperltk/chapter/ch15.html
    # A widget has been mapped onto the display and is visible
    bind(c, "<Map>", path -> init_canvas(c))
    # All or part of a widget has been uncovered and may need to be redrawn
    bind(c, "<Expose>", path -> reveal(c))
    # A widget has changed size or position and may need to adjust its layout
    bind(c, "<Configure>", path -> configure(c))
    # A mouse button was pressed
    bind(c, "<ButtonPress-1>", (path,x,y)->(c.mouse.button1press(c, parse(Int, x), parse(Int, y))))
    bind(c, "<ButtonRelease-1>", (path,x,y)->(c.mouse.button1release(c, parse(Int, x), parse(Int, y))))
    bind(c, "<ButtonPress-2>",   (path,x,y)->(c.mouse.button2press(c, parse(Int, x), parse(Int, y))))
    bind(c, "<ButtonRelease-2>", (path,x,y)->(c.mouse.button2release(c, parse(Int, x), parse(Int, y))))
    bind(c, "<ButtonPress-3>",   (path,x,y)->(c.mouse.button3press(c, parse(Int, x), parse(Int, y))))
    bind(c, "<ButtonRelease-3>", (path,x,y)->(c.mouse.button3release(c, parse(Int, x), parse(Int, y))))
    # The cursor is in motion over a widget
    bind(c, "<Motion>",          (path,x,y)->(c.mouse.motion(c, parse(Int, x), parse(Int, y))))
    bind(c, "<Button1-Motion>",  (path,x,y)->(c.mouse.button1motion(c, parse(Int, x), parse(Int, y))))
end

# some canvas init steps require the widget to fully exist
# this is called once per Canvas, before doing anything else with it
function init_canvas(c::Canvas)
    c.initialized = true
    configure(c)
    c
end

get_visible(c::Canvas) = get_visible(c.c.parent)

initialized(c::Canvas) = c.initialized

function pack(c::Canvas; kwargs...)
    pack(c.c; kwargs...)
end

function grid(c::Canvas, args...; kwargs...)
    grid(c.c, args...; kwargs...)
end

function place(c::Canvas, x::Int, y::Int)
    place(c.c, x, y)
end


function update()
    tcl_eval("update")
end

function wait_initialized(c::Canvas)
    n = 0
    while !initialized(c)
        tcl_doevent()
        n += 1
        if n > 10000
            error("getgc: Canvas is not drawable")
        end
    end
end

function getgc(c::Canvas)
    wait_initialized(c)
    c.backcc
end

function cairo_surface(c::Canvas)
    wait_initialized(c)
    c.back
end
@static if Sys.isapple()
    struct TkWindowPrivate
        winPtr::Ptr{Cvoid}
        view::Ptr{Cvoid}
        context::Ptr{Cvoid}
        xOff::Cint
        yOff::Cint
        sizeX::CGFloat
        sizeY::CGFloat
        visRgn::Ptr{Cvoid}
        aboveVisRgn::Ptr{Cvoid}
        drawRgn::Ptr{Cvoid}
        referenceCount::Ptr{Cvoid}
        toplevel::Ptr{Cvoid}
        flags::Cint
    end
end

global tcl_interp = Ref{Ptr{Cvoid}}()
global tk_version = Ref{VersionNumber}()

jl_tkwin_display(tkwin::Ptr{Cvoid}) = unsafe_load(convert(Ptr{Ptr{Cvoid}},tkwin), 1) # 8.4, 8.5, 8.6
jl_tkwin_visual(tkwin::Ptr{Cvoid}) = unsafe_load(convert(Ptr{Ptr{Cvoid}},tkwin), 4) # 8.4, 8.5, 8.6
jl_tkwin_id(tkwin::Ptr{Cvoid}) = unsafe_load(convert(Ptr{Int},tkwin), 6) # 8.4, 8.5, 8.6
