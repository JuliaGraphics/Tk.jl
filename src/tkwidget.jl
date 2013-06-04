if OS_NAME == :Linux
    const libtcl = "libtcl8.5"
    const libtk = "libtk8.5"
elseif OS_NAME == :Darwin
    const libtcl = "libtcl8.6"
    const libtk = "libtk8.6"
else
    const libtcl = "libtcl"
    const libtk = "libtk"
end

#const libX = "libX11"

const TCL_OK       = int32(0)
const TCL_ERROR    = int32(1)
const TCL_RETURN   = int32(2)
const TCL_BREAK    = int32(3)
const TCL_CONTINUE = int32(4)

const TCL_VOLATILE = convert(Ptr{Void}, 1)
const TCL_STATIC   = convert(Ptr{Void}, 0)
const TCL_DYNAMIC  = convert(Ptr{Void}, 3)

tcl_doevent() = tcl_doevent(0)
function tcl_doevent(fd)
    while (ccall((:Tcl_DoOneEvent,libtcl), Int32, (Int32,), (1<<1))!=0)
    end
end

global timeout = nothing

# fetch first word from struct
tk_display(w) = pointer_to_array(convert(Ptr{Ptr{Void}},w), (1,), false)[1]

function init()
    ccall((:Tcl_FindExecutable,libtcl), Void, (Ptr{Uint8},),
          joinpath(JULIA_HOME, "julia"))
    ccall((:g_type_init,"libgobject-2.0"),Void,())
    tcl_interp = ccall((:Tcl_CreateInterp,libtcl), Ptr{Void}, ())
    ccall((:Tcl_Init,libtcl), Int32, (Ptr{Void},), tcl_interp)
    if ccall((:Tk_Init,libtk), Int32, (Ptr{Void},), tcl_interp) == TCL_ERROR
        throw(TclError(string("error initializing Tk: ", tcl_result())))
    end
    # TODO: for now cheat and use X-specific hack for events
    #mainwin = mainwindow(tcl_interp)
    #if mainwin == C_NULL
    #    error("cannot initialize Tk: window system not available")
    #end
    #disp = tk_display(mainwin)
    #fd = ccall((:XConnectionNumber,libX), Int32, (Ptr{Void},), disp)
    #add_fd_handler(fd, tcl_doevent)
    global timeout
    timeout = Base.TimeoutAsyncWork(tcl_doevent)
    Base.start_timer(timeout,int64(50),int64(50))
    tcl_interp
end

mainwindow(interp) =
    ccall((:Tk_MainWindow,libtk), Ptr{Void}, (Ptr{Void},), interp)
mainwindow() = mainwindow(tcl_interp)

type TclError <: Exception
    msg::String
end

function tcl_result()
    bytestring(ccall((:Tcl_GetStringResult,libtcl),
                     Ptr{Uint8}, (Ptr{Void},), tcl_interp))
end

function tcl_evalfile(name)
    if ccall((:Tcl_EvalFile,libtcl), Int32, (Ptr{Void}, Ptr{Uint8}),
             tcl_interp, name) != 0
        throw(TclError(tcl_result()))
    end
    nothing
end

function tcl_eval(cmd)
    code = ccall((:Tcl_Eval,libtcl), Int32, (Ptr{Void}, Ptr{Uint8}),
                 tcl_interp, cmd)
    result = tcl_result()
    if code != 0
        throw(TclError(result))
    else
        result
    end
end

type TkWidget
    path::ByteString
    kind::ByteString
    parent::Union(TkWidget,Nothing)

    ID::Int = 0
    function TkWidget(parent::TkWidget, kind)
        path = "$(parent.path).jl_$(replace(kind, "::", "_"))$(ID)"; ID += 1
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

Window(title) = Window(title, 200, 200)

place(widget::TkWidget, x::Int, y::Int) = tcl_eval("place $(widget.path) -x $x -y $y")

function nametowindow(name)
    ccall((:Tk_NameToWindow,libtk), Ptr{Void},
          (Ptr{Void}, Ptr{Uint8}, Ptr{Void}),
          tcl_interp, name, mainwindow(tcl_interp))
end

const _callbacks = ObjectIdDict()

const empty_str = ""

function jl_tcl_callback(f, interp, argc::Int32, argv::Ptr{Ptr{Uint8}})
    args = { bytestring(unsafe_load(argv,i)) for i=1:argc }
    local result
    try
        result = f(args...)
    catch e
        println("error during Tk callback: ", e)
        return TCL_ERROR
    end
    if isa(result,ByteString)
        ccall((:Tcl_SetResult,libtcl), Void, (Ptr{Void}, Ptr{Uint8}, Int32),
              interp, result, TCL_VOLATILE)
    else
        ccall((:Tcl_SetResult,libtcl), Void, (Ptr{Void}, Ptr{Uint8}, Int32),
              interp, empty_str, TCL_STATIC)
    end
    return TCL_OK
end

jl_tcl_callback_ptr = cfunction(jl_tcl_callback,
                                Int32, (Function, Ptr{Void}, Int32, Ptr{Ptr{Uint8}}))

function tcl_callback(f)
    cname = string("jl_cb", repr(uint32(object_id(f))))
    # TODO: use Tcl_CreateObjCommand instead
    ccall((:Tcl_CreateCommand,libtcl), Ptr{Void},
          (Ptr{Void}, Ptr{Uint8}, Ptr{Void}, Any, Ptr{Void}),
          tcl_interp, cname, jl_tcl_callback_ptr, f, C_NULL)
    # TODO: use a delete proc (last arg) to remove this
    _callbacks[f] = true
    cname
end

width(w::TkWidget) = int(tcl_eval("winfo width $(w.path)"))
height(w::TkWidget) = int(tcl_eval("winfo height $(w.path)"))

# NOTE: This has to be ported to each window environment.
# But, this should be the only such function needed.
function cairo_surface_for(w::TkWidget)
    win = nametowindow(w.path)
    if OS_NAME == :Linux
        disp = ccall((:jl_tkwin_display,:libtk_wrapper), Ptr{Void}, (Ptr{Void},),
                     win)
        d = ccall((:jl_tkwin_id,:libtk_wrapper), Int32, (Ptr{Void},), win)
        vis = ccall((:jl_tkwin_visual,:libtk_wrapper), Ptr{Void}, (Ptr{Void},),
                    win)
        if disp==C_NULL || d==0 || vis==C_NULL
            error("invalid window")
        end
        return CairoXlibSurface(disp, d, vis, width(w), height(w))
    elseif OS_NAME == :Darwin
        context = ccall((:getView,:libtk_wrapper), Ptr{Void},
                        (Ptr{Void},Int32), win, height(w))
        return CairoQuartzSurface(context, width(w), height(w))
    elseif OS_NAME == :Windows
	disp = ccall((:jl_tkwin_display,:libtk_wrapper), Ptr{Void}, (Ptr{Void},),
                     win)
        hdc = ccall((:jl_tkwin_hdc,:libtk_wrapper), Ptr{Void}, (Ptr{Void},Ptr{Void}),
                    win,disp)
	return CairoWin32Surface(hdc, width(w), height(w))
    else
        error("Unsupported Operating System")
    end
end

const default_mouse_cb = (w, x, y)->nothing

type MouseHandler
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
type Canvas
    c::TkWidget
    front::CairoSurface  # surface for window
    back::CairoSurface   # backing store
    frontcc::CairoContext
    backcc::CairoContext
    mouse::MouseHandler
    redraw
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
        this.redraw = nothing
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
    if isdefined(c,:front)
        Cairo.destroy(c.frontcc)
        Cairo.destroy(c.backcc)
        Cairo.destroy(c.front)
        Cairo.destroy(c.back)
    end
    c.front = cairo_surface_for(c.c)
    w = width(c.c)
    h = height(c.c)
    c.frontcc = CairoContext(c.front)
    if Base.is_unix(OS_NAME)
        c.back = surface_create_similar(c.front, w, h)
    else
        c.back = CairoRGBSurface(w, h)
    end
    c.backcc = CairoContext(c.back)
    # Check c.initialized to prevent infinite recursion if initialized from
    # c.redraw. This also avoids a double-redraw on the first call.
    if !is(c.redraw, nothing) && c.initialized
        c.redraw(c)
    end
end


function add_canvas_callbacks(c::Canvas)
    bind(c, "<Map>", path -> init_canvas(c))
    bind(c, "<Expose>", path -> reveal(c))
    bind(c, "<Configure>", path -> configure(c))
    bind(c, "<ButtonPress-1>", (path,x,y)->(c.mouse.button1press(c,int(x),int(y))))
    bind(c, "<ButtonRelease-1>", (path,x,y)->(c.mouse.button1release(c,int(x),int(y))))
    bind(c, "<ButtonPress-2>",   (path,x,y)->(c.mouse.button2press(c,int(x),int(y))))
    bind(c, "<ButtonRelease-2>", (path,x,y)->(c.mouse.button2release(c,int(x),int(y))))
    bind(c, "<ButtonPress-3>",   (path,x,y)->(c.mouse.button3press(c,int(x),int(y))))
    bind(c, "<ButtonRelease-3>", (path,x,y)->(c.mouse.button3release(c,int(x),int(y))))
    bind(c, "<Motion>",          (path,x,y)->(c.mouse.motion(c,int(x),int(y))))       
    bind(c, "<Button1-Motion>",  (path,x,y)->(c.mouse.button1motion(c,int(x),int(y))))
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

function pack(c::Canvas, args...)
    pack(c.c, args...)
end

function grid(c::Canvas, args...)
    grid(c.c, args...)
end

function place(c::Canvas, x::Int, y::Int)
    place(c.c, x, y)
end

function reveal(c::Canvas)
    back = cairo_surface(c)
    set_source_surface(c.frontcc, back, 0, 0)
    paint(c.frontcc)
    tcl_doevent()
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

tcl_interp = init()
tcl_eval("wm withdraw .")
