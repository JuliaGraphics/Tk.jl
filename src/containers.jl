## Types
type Tk_Toplevel    <: TTk_Container w::TkWidget end
type Tk_Frame       <: TTk_Container w::TkWidget end
type Tk_Labelframe  <: TTk_Container w::TkWidget end
type Tk_Notebook    <: TTk_Container w::TkWidget end
type Tk_Panedwindow <: TTk_Container w::TkWidget end



## Toplevel window
function Toplevel(title::String, width::Integer, height::Integer, visible::Bool)
    w = Window(title, width, height, visible)
    Tk_Toplevel(w)
end
Toplevel(title::String, width::Integer, height::Integer) = Toplevel(title, width, height, true)
Toplevel(title::String, visible::Bool) = Toplevel(title, 200, 200, visible)
Toplevel(title::String) = Toplevel(title, 200, 200)
Toplevel() = Toplevel("Toplevel window")

Canvas(parent::TTk_Container, args...) = Canvas(parent.w, args...)

get_value(widget::Tk_Toplevel) = tk_wm(widget, "title")
set_value(widget::Tk_Toplevel, value::String) = tk_wm(widget, "title", value)

function set_visible(widget::Tk_Toplevel, value::Bool)
    value = value ? "normal" : "withdrawn"
    tk_wm(widget, "state", value)
end

set_size(widget::Tk_Toplevel, width::Integer, height::Integer) = tcl(I"wm minsize", widget, width, height)

## Set upper left corner of Toplevel to...
function set_position(widget::Tk_Toplevel, x::Integer, y::Integer)
    p_or_m(x) = x < 0 ? "$x" : "+$x"
    tk_wm(widget, "geometry", I(p_or_m(x) * p_or_m(y)))
end
set_position{T <: Integer}(widget::Tk_Toplevel, pos::Vector{T}) = set_position(w, pos[1], pos[2])
set_position(widget::Tk_Toplevel, pos::Tk_Widget) = set_position(widget, Integer[parse_int(tk_winfo(pos, i)) for i in ["x", "y"]] + [10,10])

update(widget::Tk_Toplevel) = tk_wm(widget, "geometry")
destroy(widget::Tk_Toplevel) = tcl("destroy", widget)

## Frame
## nothing to add...

## Labelframe
Labelframe(parent::Widget, text::String) = Labelframe(parent, {:text=>text})
get_value(widget::Tk_Labelframe) = tk_cget(widget, "text")
set_value(widget::Tk_Labelframe, text::String) = tk_configure(widget, {:text=> text})


## Notebook
function page_add(child::Widget, label::String)
    parent = tk_winfo(child, "parent")
    tcl(parent, "add", child, {:text => label})
end


function page_insert(child::Widget, index::Integer, label::String)
    parent = tk_winfo(child, "parent")
    tcl(parent, "insert", index, child, {:text => label})
end

get_value(widget::Tk_Notebook) = 1 + int(tcl(widget, I"index current"))
set_value(widget::Tk_Notebook, index::Integer) = tcl(widget, "select", index - 1)
no_tabs(widget::Tk_Notebook) = length(split(tcl(widget, "tabs")))


## Panedwindow
## orient in "horizontal" or "vertical"
Panedwindow(widget::Widget, orient::String) = Panedwindow(widget, {:orient => orient})

function page_add(child::Widget, weight::Integer)
    parent = tk_winfo(child, "parent")
    tcl(parent, "add", child, {:weight => weight})
end

## value is sash position as percentage of first pane
function get_value(widget::Tk_Panedwindow)
    sz = (tk_cget(widget, "orient") == "horizontal") ? get_width(widget) : get_height(widget)
    pos = tcl(widget, "sashpos", 0) | int
    floor(pos/sz*100)
end
## can set with Integer -- pixels, or real (proportion in [0,1])
set_value(widget::Tk_Panedwindow, value::Integer) = tcl(widget, "sashpos", 0, value)
function set_value(widget::Tk_Panedwindow, value::Real)
    if value <= 1 && value >= 0
        sz = (tk_cget(widget, "orient") == "horizontal") ? get_width(widget) : get_height(widget)
        set_value(widget, int(value * sz/100))
    end        
end


page_add(child::Widget) = page_add(child, 1)
        
        
## Container methods

## pack(widget, {:expand => true, :anchor => "w"})
pack(widget::Widget, args::Dict) = tcl("pack", widget, args)
pack(widget::Widget) = pack(widget, Dict())

pack_configure(widget::Widget, args::Dict) = tcl(I"pack configure", widget, args)
pack_stop_propagate(widget::Widget) = tcl(I"pack propagate", widget, false)

## remove a page from display
forget(widget::Widget) = tcl(widget, "forget")
forget(parent::Widget, child::Widget) = tcl(widget, "forget", child)

## grid ...
IntOrRange = Union(Integer, Range1)
function grid(child::Widget, row::IntOrRange, column::IntOrRange, args::Dict)
    path = get_path(child)
    args[:row] = min(row) - 1
    args[:column] = min(column) - 1
    if isa(row, Range1) args[:rowspan] = 1 + max(row) - min(row) end
    if isa(column, Range1) args[:columnspan] = 1 + max(column) - min(column) end
    grid_configure(child, args)
end
grid(child::Widget, row::IntOrRange, column::IntOrRange) = grid(child, row, column, Dict())

grid_configure(child::Widget, args::Dict) = tcl("grid", "configure", child, args)
grid_rowconfigure(parent::Widget, row::Integer, args::Dict) = tcl(I"grid rowconfigure", parent, row-1, args)
grid_columnconfigure(parent::Widget, column::Integer, args::Dict) = tcl(I"grid columnconfigure", parent, column-1, args)
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
    master = tk_winfo(child, "parent")
    sz = int(split(tcl_eval("grid size $master"))) ## columns, rows
    nrows = sz[2]

    if isa(label, String)
        l = Label(child.w.parent, label)
        grid(l, nrows + 1, 1)
        grid_configure(l, {:sticky => "e"})
    end
    grid(child, nrows + 1, 2)
    grid_configure(child, {:sticky => "we", :padx=>5, :pady=>2})
    grid_columnconfigure(master, 1, {:weight => 1})
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
    grid_configure(child, {:sticky => "news"})
    grid_configure(yscr, {:sticky => "ns"})
    grid_configure(xscr, {:sticky => "ew"})
    grid_rowconfigure(parent, 1, {:weight => 1})
    grid_columnconfigure(parent, 1, {:weight => 1})
    
end

