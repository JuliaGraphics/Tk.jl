## Types
type Tk_Toplevel    <: TTk_Container w::TkWidget; children::Vector{Tk_Widget} end
type Tk_Frame       <: TTk_Container w::TkWidget; children::Vector{Tk_Widget} end
type Tk_Labelframe  <: TTk_Container w::TkWidget; children::Vector{Tk_Widget} end
type Tk_Notebook    <: TTk_Container w::TkWidget; children::Vector{Tk_Widget} end
type Tk_Panedwindow <: TTk_Container w::TkWidget; children::Vector{Tk_Widget} end

isequal(a::TTk_Container, b::TTk_Container) = isequal(a.w, b.w) && typeof(a) == typeof(b)

## Toplevel window
function Toplevel(;title::String="Toplevel Window", width::Integer=200, height::Integer=200, visible::Bool=true)
    w = Window(title, width, height, visible)
    Tk_Toplevel(w, Tk_Widget[])
end
Toplevel(title::String, width::Integer, height::Integer, visible::Bool) = Toplevel(title=title, width=width, height=height, visible=visible)
Toplevel(title::String, width::Integer, height::Integer) = Toplevel(title=title, width=width, height=height)
Toplevel(title::String, visible::Bool) = Toplevel(title=title,  visible=visible)
Toplevel(title::String) = Toplevel(title=title)


## Sizing of toplevel windows should refer to the geometry
width(widget::Tk_Toplevel) = int(winfo(widget, "width"))
height(widget::Tk_Toplevel) = int(winfo(widget, "height"))
get_size(widget::Tk_Toplevel) = [width(widget), height(widget)]
set_size(widget::Tk_Toplevel,  width::Integer, height::Integer) = wm(widget, "geometry", "$(string(width))x$(string(height))")
set_size{T <: Integer}(widget::Tk_Toplevel, widthheight::Vector{T}) = set_size(widget, widthheight[1], widthheight[2])




Canvas(parent::TTk_Container, args...) = Canvas(parent.w, args...)

get_value(widget::Tk_Toplevel) = wm(widget, "title")
set_value(widget::Tk_Toplevel, value::String) = wm(widget, "title", value)

function set_visible(widget::Tk_Toplevel, value::Bool)
    value = value ? "normal" : "withdrawn"
    wm(widget, "state", value)
end
get_visible(widget::Tk_Toplevel) = wm(widget, "state") == "normal"


function get_visible(w::TkWidget)
    if w.kind == "toplevel"
        return wm(w, "state") == "normal"
    else
        return get_visible(w.parent)
    end
end

## Set upper left corner of Toplevel to...
function set_position(widget::Tk_Toplevel, x::Integer, y::Integer)
    p_or_m(x) = x < 0 ? "$x" : "+$x"
    wm(widget, "geometry", I(p_or_m(x) * p_or_m(y)))
end
set_position{T <: Integer}(widget::Tk_Toplevel, pos::Vector{T}) = set_position(w, pos[1], pos[2])
set_position(widget::Tk_Toplevel, pos::Tk_Widget) = set_position(widget, Integer[parse_int(winfo(pos, i)) for i in ["x", "y"]] + [10,10])

update(widget::Tk_Toplevel) = wm(widget, "geometry")
destroy(widget::Tk_Toplevel) = tcl("destroy", widget)

## Frame
## nothing to add...

## Labelframe
Labelframe(parent::Widget, text::String) = Labelframe(parent, text=text)
get_value(widget::Tk_Labelframe) = cget(widget, "text")
set_value(widget::Tk_Labelframe, text::String) = configure(widget, {:text=> text})


## Notebook
function page_add(child::Widget, label::String)
    parent = winfo(child, "parent")
    tcl(parent, "add", child, text = label)
end


function page_insert(child::Widget, index::Integer, label::String)
    parent = winfo(child, "parent")
    tcl(parent, "insert", index, child, text = label)
end

get_value(widget::Tk_Notebook) = 1 + int(tcl(widget, I"index current"))
set_value(widget::Tk_Notebook, index::Integer) = tcl(widget, "select", index - 1)
no_tabs(widget::Tk_Notebook) = length(split(tcl(widget, "tabs")))


## Panedwindow
## orient in "horizontal" or "vertical"
Panedwindow(widget::Widget, orient::String) = Panedwindow(widget, orient = orient)

function page_add(child::Widget, weight::Integer)
    parent = winfo(child, "parent")
    tcl(parent, "add", child, weight = weight)
end

## value is sash position as percentage of first pane
function get_value(widget::Tk_Panedwindow)
    sz = (cget(widget, "orient") == "horizontal") ? width(widget) : height(widget)
    pos = int(tcl(widget, "sashpos", 0))
    floor(pos/sz*100)
end
## can set with Integer -- pixels, or real (proportion in [0,1])
set_value(widget::Tk_Panedwindow, value::Integer) = tcl(widget, "sashpos", 0, value)
function set_value(widget::Tk_Panedwindow, value::Real)
    if value <= 1 && value >= 0
        sz = (cget(widget, "orient") == "horizontal") ? width(widget) : height(widget)
        set_value(widget, int(value * sz/100))
    end        
end


page_add(child::Widget) = page_add(child, 1)
        
        
## Container methods

## pack(widget, {:expand => true, :anchor => "w"})
pack(widget::Widget;  kwargs...) = tcl("pack", widget; kwargs...)

pack_configure(widget::Widget, kwargs...) = tcl(I"pack configure", widget; kwargs...)
pack_stop_propagate(widget::Widget) = tcl(I"pack propagate", widget, false)

## remove a page from display
forget(widget::Widget) = tcl(widget, "forget")
forget(parent::Widget, child::Widget) = tcl(widget, "forget", child)

## grid ...
IntOrRange = Union(Integer, Range1)
function grid(child::Widget, row::IntOrRange, column::IntOrRange; kwargs...)
    path = get_path(child)
    if isa(row, Range1) rowspan = 1 + max(row) - min(row)  else rowspan = 1 end
    if isa(column, Range1) columnspan = 1 + max(column) - min(column) else columnspan = 1 end

    row = min(row) - 1
    column = min(column) - 1
    
    grid_configure(child,  row=row, column=column, rowspan=rowspan, columnspan=columnspan; kwargs...)
end


grid_configure(child::Widget, args...; kwargs...) = tcl("grid", "configure", child, args...,; kwargs...)
grid_rowconfigure(parent::Widget, row::Integer; kwargs...) = tcl(I"grid rowconfigure", parent, row-1; kwargs... )
grid_columnconfigure(parent::Widget, column::Integer; kwargs...) = tcl(I"grid columnconfigure", parent, column-1; kwargs...)
grid_stop_propagate(parent::Widget) = tcl(I"grid propagate", parent, false)
grid_forget(child::Widget) = tcl(I"grid forget", child)

## Helper to layout two column with label using grid
##
## w = Toplevel()
## f = Frame(w); pack(f)
## sc = Slider(f, 1:10)
## e  = Entry(f, "")
## b = Button(f, "click me", W -> println(map(get_value, (sc, e))))
## formlayout(sc, "Slider")
## formlayout(e, "Entry")
## formlayout(Separator(f), nothing)
## formlayout(b, nothing)
##
function formlayout(child::Tk_Widget, label::MaybeString)
    master = winfo(child, "parent")
    sz = int(split(tcl_eval("grid size $master"))) ## columns, rows
    nrows = sz[2]

    if isa(label, String)
        l = Label(child.w.parent, label)
        grid(l, nrows + 1, 1)
        grid_configure(l, sticky = "e")
    end
    grid(child, nrows + 1, 2)
    grid_configure(child, sticky = "we", padx=5, pady=2)
    grid_columnconfigure(master, 1, weight = 1)
end

  
## Wrap child in frame, return frame to pack (or grid) into parent of child
##
## w = Toplevel()
## f = Frame(w); pack(f) ## f shouldn't have any layout management of its children
## t = Text(f)
## scrollbars_add(f,t)
##
function scrollbars_add(parent::Tk_Frame, child::Tk_Widget)

    grid_stop_propagate(parent)
    xscr = Scrollbar(parent, child, "horizontal")
    yscr = Scrollbar(parent, child, "vertical")
    
    grid(child, 1, 1)
    grid(yscr, 1, 2)
    grid(xscr, 2, 1)
    grid_configure(child, sticky = "news")
    grid_configure(yscr, sticky = "ns")
    grid_configure(xscr, sticky = "ew")
    grid_rowconfigure(parent, 1, weight = 1)
    grid_columnconfigure(parent, 1, weight = 1)
    
end

# Navigating hierarchies

# parent returns a TkWidget, because we don't know how to wrap it otherwise (?)
parent(w::TkWidget) = w.parent
parent(w::Tk_Widget) = parent(w.w)
parent(c::Canvas) = parent(c.c)

# For toplevel it's obvious how to wrap it...
function toplevel(w::Union(TkWidget, Tk_Widget, Canvas))
    p = parent(w)
    pold = p
    while !is(p, nothing)
        pold = p
        p = parent(p)
    end
    Tk_Toplevel(pold, Tk_Widget[])
end

toplevel(w::Tk_Toplevel) = w

## children (may need means to filter out children that are not in layout?)
children(w::TTk_Container) = w.children
