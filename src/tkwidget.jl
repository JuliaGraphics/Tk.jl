const TCL_OK       = int32(0)
const TCL_ERROR    = int32(1)
const TCL_RETURN   = int32(2)
const TCL_BREAK    = int32(3)
const TCL_CONTINUE = int32(4)

const TCL_VOLATILE = convert(Ptr{Void}, 1)
const TCL_STATIC   = convert(Ptr{Void}, 0)
const TCL_DYNAMIC  = convert(Ptr{Void}, 3)

tcl_doevent() = tcl_doevent(nothing,0)
function tcl_doevent(timer,status)
    # https://www.tcl.tk/man/tcl8.6/TclLib/DoOneEvent.htm
    # DONT_WAIT* = 1 shl 1
    # WINDOW_EVENTS* = 1 shl 2
    # FILE_EVENTS* = 1 shl 3
    # TIMER_EVENTS* = 1 shl 4
    # IDLE_EVENTS* = 1 shl 5
    # ALL_EVENTS* = not DONT_WAIT
    while (ccall((:Tcl_DoOneEvent,libtcl), Int32, (Int32,), (1<<1))!=0)
    end
end

global timeout = nothing

# fetch first word from struct
tk_display(w) = pointer_to_array(convert(Ptr{Ptr{Void}},w), (1,), false)[1]

function init()
    ccall((:Tcl_FindExecutable,libtcl), Void, (Ptr{Uint8},),
          joinpath(JULIA_HOME, "julia"))
    ccall((:g_type_init,Cairo._jl_libgobject),Void,())
    tcl_interp = ccall((:Tcl_CreateInterp,libtcl), Ptr{Void}, ())
    ccall((:Tcl_Init,libtcl), Int32, (Ptr{Void},), tcl_interp)
    if ccall((:Tk_Init,libtk), Int32, (Ptr{Void},), tcl_interp) == TCL_ERROR
        throw(TclError(string("error initializing Tk: ", tcl_result(tcl_interp))))
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
    Base.start_timer(timeout,0.05,0.05)
    tcl_interp
end

mainwindow(interp) =
    ccall((:Tk_MainWindow,libtk), Ptr{Void}, (Ptr{Void},), interp)
mainwindow() = mainwindow(tcl_interp)

type TclError <: Exception
    msg::String
end

tcl_result() = tcl_result(tcl_interp)
function tcl_result(tcl_interp)
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
        underscoredKind = replace(kind, "::", "_")
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
    c.back = CairoRGBSurface(w, h)
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

function reveal(c::Canvas)
    render_to_cairo(c.c) do front
        frontcc = CairoContext(front)
        back = cairo_surface(c)
        set_source_surface(frontcc, back, 0, 0)
        paint(frontcc)
        destroy(frontcc)
    end
    tcl_doevent()
end

if WORD_SIZE == 32
    typealias CGFloat Float32
else
    typealias CGFloat Float64
end
jl_tkwin_display(tkwin::Ptr{Void}) = unsafe_load(pointer(Ptr{Void},tkwin), 1) # 8.4, 8.5, 8.6
jl_tkwin_visual(tkwin::Ptr{Void}) = unsafe_load(pointer(Ptr{Void},tkwin), 4) # 8.4, 8.5, 8.6
jl_tkwin_id(tkwin::Ptr{Void}) = unsafe_load(pointer(Int,tkwin), 6) # 8.4, 8.5, 8.6
objc_msgSend{T}(id, uid, ::Type{T}=Ptr{Void}) = ccall(:objc_msgSend, T, (Ptr{Void}, Ptr{Void}),
    id, ccall(:sel_getUid, Ptr{Void}, (Ptr{Uint8},), uid))

# NOTE: This has to be ported to each window environment.
# But, this should be the only such function needed.
function render_to_cairo(f::Function, w::TkWidget)
    win = nametowindow(w.path)
    if OS_NAME == :Linux
        disp = jl_tkwin_display(win)
        d = jl_tkwin_id(win)
        vis = jl_tkwin_visual(win)
        if disp==C_NULL || d==0 || vis==C_NULL
            error("invalid window")
        end
        surf = CairoXlibSurface(disp, d, vis, width(w), height(w))
        f(surf)
        destroy(surf)
    elseif OS_NAME == :Darwin
        view = ccall((:TkMacOSXGetRootControl,libtk), Ptr{Void}, (Int,), jl_tkwin_id(win)) # NSView*
        if view == C_NULL
            error("Invalid OS X window at getView")
        end
        focusView = objc_msgSend(ccall(:objc_getClass, Ptr{Void}, (Ptr{Uint8},), "NSView"), "focusView");
        if view != focusView
            focusLocked = bool(objc_msgSend(view, "lockFocusIfCanDraw", Int32))
            dontDraw = !focusLocked
        else
            dontDraw = !bool(objc_msgSend(view, "canDraw", Int32))
        end
        if dontDraw
            error("Cannot draw to OS X Window")
        end
        context = objc_msgSend(objc_msgSend(objc_msgSend(view, "window"), "graphicsContext"), "graphicsPort")
        ccall(:CGContextSaveGState, Void, (Ptr{Void},), context)
        ccall(:CGContextTranslateCTM, Void, (Ptr{Void}, CGFloat, CGFloat), context, 0, height(w))
        ccall(:CGContextScaleCTM, Void, (Ptr{Void}, CGFloat, CGFloat), context, 1, -1)
        surf = CairoQuartzSurface(context, width(w), height(w))
        f(surf)
        destroy(surf)
        ccall(:CGContextRestoreGState, Void, (Ptr{Void},), context)
    elseif OS_NAME == :Windows
        state = Array(Uint8, WORD_SIZE/8*2) # 8.4, 8.5, 8.6
        drawable = jl_tkwin_id(win)
        hdc = ccall((:TkWinGetDrawableDC,libtk), Ptr{Void}, (Ptr{Void}, Int, Ptr{Uint8}),
            jl_tkwin_display(win), drawable, state)
        surf = CairoWin32Surface(hdc, width(w), height(w))
        f(surf)
        destroy(surf)
        ccall((:TkWinReleaseDrawableDC,libtk), Void, (Int, Int, Ptr{Uint8}),
            drawable, hdc, state)
    else
        error("Unsupported Operating System")
    end
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
    bind(c, "<ButtonPress-1>", (path,x,y)->(c.mouse.button1press(c,int(x),int(y))))
    bind(c, "<ButtonRelease-1>", (path,x,y)->(c.mouse.button1release(c,int(x),int(y))))
    bind(c, "<ButtonPress-2>",   (path,x,y)->(c.mouse.button2press(c,int(x),int(y))))
    bind(c, "<ButtonRelease-2>", (path,x,y)->(c.mouse.button2release(c,int(x),int(y))))
    bind(c, "<ButtonPress-3>",   (path,x,y)->(c.mouse.button3press(c,int(x),int(y))))
    bind(c, "<ButtonRelease-3>", (path,x,y)->(c.mouse.button3release(c,int(x),int(y))))
    # The cursor is in motion over a widget
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
