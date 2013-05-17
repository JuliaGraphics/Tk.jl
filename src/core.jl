show(io::IO, widget::TkWidget) = print(io, typeof(widget))
show(io::IO, widget::Tk_Widget) = print(io, "Tk widget of type $(typeof(widget))")


tcl_eval("set auto_path")
tcl_add_path(path::String) = tcl_eval("lappend auto_path $path")
tcl_require(pkg::String) = tcl_eval("package require $pkg")


## helper to get path
## assumes Tk_Widgets have w property storing TkWidget
get_path(path::String) = path
get_path(widget::Tk_Widget) = get_path(widget.w)
get_path(widget::TkWidget) = get_path(widget.path)
get_path(widget::Canvas) = get_path(widget.c) # Tk.Canvas object

## Coversion of julia objects into tcl strings for inclusion via tcl() call
to_tcl(x) = string(x)
to_tcl(x::Nothing) = ""
has_space = r" "
to_tcl(x::String) = ismatch(has_space, x) ? "{$x}" : x
type I x::MaybeString end               #  avoid wrapping in {} and ismatch call.
macro I_str(s) I(s) end
to_tcl(x::I) = x.x == nothing ? "" : x.x
to_tcl{T <: Number}(x::Vector{T}) = "\"" * string(join(x, " ")) * "\""
function to_tcl{T <: String}(x::Vector{T})
    tmp = join(["{$i}" for i in x], " ")
    "[list $tmp ]"
end
to_tcl(x::Widget) = get_path(x)
function to_tcl(x::Dict)
    out = filter((k,v) -> v != nothing, x)
    join([" -$(string(k)) $(to_tcl(v))" for (k, v) in out], "")
end
function to_tcl(x::Function)
    ccb = tcl_callback(x)
    args = get_args(x)
    perc_args = join(map(u -> "%$(string(u))", args[2:end]), " ")
    cmd = "{$ccb $perc_args}"
end

## Function to simplify call to tcl_eval, ala R's tcl() function
## converts argumets through to_tcl
function tcl(xs...)
    cmd = join([" $(to_tcl(x))" for x in xs], "")
    ## println(cmd)
    tcl_eval(cmd)
end


## tclvar for textvariables
## Work with a text variable. Stores values as strings. Must coerce!
## getter -- THIS FAILS IN A CALLBACK!!!
#function tclvar(nm::String)
#    cmd = "return \$::" * nm
#    tcl(cmd)
#end

## setter
function tclvar(nm::String, value)
    tcl("set", nm, value)
end

## create new variable with random name
function tclvar()
    var = "tcl" * join(int(10*rand(20)), "")
    tclvar(var, "null")
    var
end

## main configuration interface
function tk_configure(widget::Widget, args::Dict)
    tcl(widget, "configure", args)
end

## Get values
## cget
function tk_cget(widget::Widget, prop::String, coerce::MaybeFunction)
    out = tcl(widget, "cget", "-$prop")
    isa(coerce, Function) ? coerce(out) : out
end
tk_cget(widget::Widget, prop::String) = tk_cget(widget, prop, nothing)

## Identify widget at x,y
tk_identify(widget::Widget, x::Integer, y::Integer) = tcl(widget, "identify", "%x", "%y")

## tk_state(w, "!disabled")
tk_state(widget::Widget, state::String) = tcl(widget, "state", state)
tk_instate(widget::Widget, state::String) = tcl(widget, "instate", state) == "1" # return Bool

## tkwinfo
function tk_winfo(widget::Widget, prop::String, coerce::MaybeFunction)
    out = tcl("winfo", prop, widget)
    isa(coerce, Function) ? coerce(out) : out
end
tk_winfo(widget::Widget, prop::String) = tk_winfo(widget, prop, nothing)

## wm. 
tk_wm(window::Widget, prop::String, args...) = tcl("wm", prop, window, args...)
tk_wm(window::Widget, prop::String) = tk_wm(window, prop, nothing)    

## Take a function, get its args as array of symbols. There must be better way...
## Helper functions for bind callback
function get_args(li::LambdaStaticData)
    e = li.ast
    if !isa(e, Expr)
        e = Base.uncompressed_ast(li)
    end
    argnames = e.args[1]
    ## return array of symbols -- not args
    if isa(argnames[1], Expr)
        argnames = map(u -> u.args[1], argnames)
    end

    argnames
end

function get_args(m::Method)
    li = m.func.code
    get_args(li)
end

function get_args(f::Function)
    try
        get_args(f.env.defs.func)
    catch e
        get_args(f.code)
    end
end


## bind
## Function callbacks have first argument path that is ignored
## others match percent substitution
## e.g. (path, W, x, y) -> x will have  W, x and y available through %W %x %y bindings
function tk_bind(widget::Widget, event::String, callback::Function)
    if event == "command"
        tk_configure(widget, {:command => callback})
    else
        path = get_path(widget)
        ## Need to grab percent subs from signature of function
        ccb = Tk.tcl_callback(callback)
        args = get_args(callback)
        if length(args) == 0
            error("Callback should have first argument of \"path\".")
        end
        ## ala: "bind $path <ButtonPress-1> {$bp1cb %x %y}"
        cmd = "bind $path $event {$ccb " * join(map(u -> "%$(string(u))", args[2:end]), " ") * "}"
        tcl_eval(cmd)
    end
end
tk_bind(widget::Canvas, event::String, callback::Function) = tk_bind(widget.c, event, callback)

## for use with do style
tk_bind(callback::Function, widget::Union(Widget, Canvas), event::String) = tk_bind(widget, event, callback)

## Binding to mouse wheel
function tk_bindwheel(widget::Widget, modifier::String, callback::Function, tkargs::String = "")
    path = get_path(widget)
    if !isempty(modifier) && !endswith(modifier,"-")
        modifier = string(modifier, "-")
    end
    if !isempty(tkargs) && !beginswith(tkargs," ")
        tkargs = string(" ", tkargs)
    end
    ccb = Tk.tcl_callback(callback)
    if OS_NAME == :Linux
        Tk.tcl_eval("bind $(path) <$(modifier)Button-4> {$ccb -120$tkargs}")
        Tk.tcl_eval("bind $(path) <$(modifier)Button-5> {$ccb 120$tkargs}")
    else
        Tk.tcl_eval("bind $(path) <$(modifier)MouseWheel> {$ccb %D$tkargs}")
    end
end

## add most typical callback    
function callback_add(widget::Tk_Widget, callback::Function)
  events ={:Tk_Window => "<Destroy>",
           :Tk_Frame => nothing,
           :Tk_Labelframe => nothing,
           :Tk_Notebook => "<<NotebookTabChanged>>",
           :Tk_Panedwindow => nothing,
           ##
           :Tk_Label => nothing,
           :Tk_Button => "command",
           :Tk_Checkbutton => "command",
           :Tk_Radio => "command",
           :Tk_Combobox => "<<ComboboxSelected>>",
           :Tk_Scale => "command",
           :Tk_Spinbox => "command",
           :Tk_Entry => "<FocusOut>",
           :Tk_Text => "<FocusOut>",
           :Tk_Treeview => "<<TreeviewSelect>>"
           }
    key = (widget | typeof | string | Base.symbol)
    if has(events, key)
        event = events[key]
        if event == nothing
            return()
        else
            tk_bind(widget, event, callback)
        end
    end
end        
    

## Need this pattern to make a widget
## Parent is not a string, but TkWidget or Tk_Widget instance
function make_widget(parent::Widget, str::String, args::Dict)
    if isa(parent, Tk_Widget)
        return(make_widget(parent.w, str, args))
    end

    w = TkWidget(parent, str)
    tcl(str, w, args)
    w
end
make_widget(parent::Widget, str::String) = make_widget(parent, str, Dict())


## tcl after ... (Maybe there is a better julia construct...)
## create an object that will repeatedly call a
## function after a delay of ms milliseconds. This is started with
## obj.start() and stopped, if desired, with obj.stop(). To restart is
## possible, but first set obj.run=true.
type TclAfter
    cb::Function
    run::Bool
    start::Union(Nothing, Function)
    stop::Union(Nothing, Function)
    ms::Int
    
    function TclAfter(ms, cb::Function)
        obj = new(cb, true, nothing, nothing, ms)
        function fun(path)
            cb()
            if obj.run
                Tk.tcl("after", obj.ms, fun)
            end
        end
        obj.start = () -> Tk.tcl("after", obj.ms, fun)
        obj.stop = () -> obj.run = false
        obj
    end
end
tcl_after(ms::Integer, cb::Function) = TclAfter(ms, cb)
