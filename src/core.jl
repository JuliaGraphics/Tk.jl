show(io::IO, widget::TkWidget) = print(io, typeof(widget))
show(io::IO, widget::Tk_Widget) = print(io, "Tk widget of type $(typeof(widget))")


tcl_eval("set auto_path")
tcl_add_path(path::AbstractString) = tcl_eval("lappend auto_path $path")
tcl_require(pkg::AbstractString) = tcl_eval("package require $pkg")


## helper to get path
## assumes Tk_Widgets have w property storing TkWidget
get_path(path::AbstractString) = path
get_path(widget::Tk_Widget) = get_path(widget.w)
get_path(widget::TkWidget) = get_path(widget.path)
get_path(widget::Canvas) = get_path(widget.c) # Tk.Canvas object

## Coversion of julia objects into tcl strings for inclusion via tcl() call
to_tcl(x) = string(x)
to_tcl(x::Void) = ""
has_space = r" "
to_tcl(x::AbstractString) = ismatch(has_space, x) ? "{$x}" : x
type I x::MaybeString end               #  avoid wrapping in {} and ismatch call.
macro I_str(s) I(s) end
to_tcl(x::I) = x.x == nothing ? "" : x.x
to_tcl{T <: Number}(x::Vector{T}) = "\"" * string(join(x, " ")) * "\""
function to_tcl{T <: AbstractString}(x::Vector{T})
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
function tcl(xs...; kwargs...)
    cmd = join([" $(to_tcl(x)) " for x in xs], "")
    cmd = cmd * join([" -$(string(k)) $(to_tcl(v)) " for (k, v) in kwargs], " ")
    ## println(cmd)
    tcl_eval(cmd)
end

## escape a string
## http://stackoverflow.com/questions/5302120/general-string-quoting-for-tcl
## still need to escape \ (but not {})
function tk_string_escape(x::AbstractString)
    tcl_eval("set stringescapevariable [subst -nocommands -novariables {$x}]")
    "\$stringescapevariable"
end
## tclvar for textvariables
## Work with a text variable. Stores values as strings. Must coerce!
## getter -- THIS FAILS IN A CALLBACK!!!
#function tclvar(nm::AbstractString)
#    cmd = "return \$::" * nm
#    tcl(cmd)
#end

## setter
function tclvar(nm::AbstractString, value)
    tcl("set", nm, value)
end

## create new variable with random name
function tclvar()
    var = "tcl_" * randstring(10)
    tclvar(var, "null")
    var
end

## main configuration interface
function configure(widget::Widget, args...; kwargs...)
    tcl(widget, "configure", args...; kwargs...)
end

setindex!(widget::Widget, value, prop::Symbol) = configure(widget, @compat Dict(prop=>value))

## Get values
## cget
function cget(widget::Widget, prop::AbstractString, coerce::MaybeFunction)
    out = tcl(widget, "cget", "-$prop")
    isa(coerce, Function) ? coerce(out) : out
end
cget(widget::Widget, prop::AbstractString) = cget(widget, prop, nothing)
## convenience
getindex(widget::Widget, prop::Symbol) = cget(widget, string(prop))

## Identify widget at x,y
identify(widget::Widget, x::Integer, y::Integer) = tcl(widget, "identify", "%x", "%y")

## state(w, "!disabled")
state(widget::Widget, state::AbstractString) = tcl(widget, "state", state)
instate(widget::Widget, state::AbstractString) = tcl(widget, "instate", state) == "1" # return Bool

## tkwinfo
function winfo(widget::Widget, prop::AbstractString, coerce::MaybeFunction)
    out = tcl("winfo", prop, widget)
    isa(coerce, Function) ? coerce(out) : out
end
winfo(widget::Widget, prop::AbstractString) = winfo(widget, prop, nothing)

## wm.
wm(window::Widget, prop::AbstractString, args...; kwargs...) = tcl("wm", prop, window, args...; kwargs...)


if VERSION >= v"0.6.0-pre.alpha.244"
    _slots(m::Method) = (Base.uncompressed_ast(m).slotnames, m.nargs)
elseif VERSION >= v"0.6.0-dev.624"
    _slots(m::Method) = (m.source.slotnames, m.nargs)
else
    _slots(m::Method) = (m.lambda_template.slotnames, n.lambda_template.nargs)
end

## Take a function, get its args as array of symbols. There must be better way...
## Helper functions for bind callback
function get_args(f::Function)
    slots, n = _slots(first(methods(f)))
    argnames = slots[1:n]
    return _arg_offset == 0 ? argnames : argnames[_arg_offset:end]
end

_arg_offset = 0
_arg_offset = length(get_args(x->x))

## bind
## Function callbacks have first argument path that is ignored
## others match percent substitution
## e.g. (path, W, x, y) -> x will have  W, x and y available through %W %x %y bindings
function bind(widget::Widget, event::AbstractString, callback::Function)
    if event == "command"
        configure(widget, command = callback)
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
bind(widget::Canvas, event::AbstractString, callback::Function) = bind(widget.c, event, callback)

## for use with do style
bind(callback::Function, widget::Union{Widget, Canvas}, event::AbstractString) = bind(widget, event, callback)

## Binding to mouse wheel
function bindwheel(widget::Widget, modifier::AbstractString, callback::Function, tkargs::AbstractString = "")
    path = get_path(widget)
    if !isempty(modifier) && !endswith(modifier,"-")
        modifier = string(modifier, "-")
    end
    if !isempty(tkargs) && !startswith(tkargs," ")
        tkargs = string(" ", tkargs)
    end
    ccb = tcl_callback(callback)
    if is_linux()
        tcl_eval("bind $(path) <$(modifier)Button-4> {$ccb -120$tkargs}")
        tcl_eval("bind $(path) <$(modifier)Button-5> {$ccb 120$tkargs}")
    else
        tcl_eval("bind $(path) <$(modifier)MouseWheel> {$ccb %D$tkargs}")
    end
end

## add most typical callback
function callback_add(widget::Tk_Widget, callback::Function)
    events = @compat Dict(
        :Tk_Window => "<Destroy>",
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
    )
    key = Base.Symbol(split(string(typeof(widget)), '.')[end])
    if haskey(events, key)
        event = events[key]
        if event == nothing
            return()
        else
            bind(widget, event, callback)
        end
    end
end


## Need this pattern to make a widget
## Parent is not a string, but TkWidget or Tk_Widget instance
function make_widget(parent::Widget, str::AbstractString; kwargs...)
    path = isa(parent, Tk_Widget) ? parent.w : parent
    w = TkWidget(path, str)
    tcl(str, w; kwargs...)
    w
end


## tcl after ...
## Better likely to use julia's
## timer = Base.Timer(next_frame)
## Base.start_timer(timer,int64(50),int64(50))
## create an object that will repeatedly call a
## function after a delay of ms milliseconds. This is started with
## obj.start() and stopped, if desired, with obj.stop(). To restart is
## possible, but first set obj.run=true.
type TclAfter
    cb::Function
    run::Bool
    start::Union{Void, Function}
    stop::Union{Void, Function}
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
