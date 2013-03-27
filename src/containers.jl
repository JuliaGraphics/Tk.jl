## Types
type Tk_Toplevel    <: TTk_Container w::TkWidget end
type Tk_Frame       <: TTk_Container w::TkWidget end
type Tk_Labelframe  <: TTk_Container w::TkWidget end
type Tk_Notebook    <: TTk_Container w::TkWidget end
type Tk_Panedwindow <: TTk_Container w::TkWidget end

show(io::IO, widget::TkWidget) = println(typeof(widget))

## Toplevel window
function Toplevel(title::String, width::Integer, height::Integer, visible::Bool)
    w = Window(title, width, height)
    w = Tk_Toplevel(w)
    set_visible(w, visible)
    w
end
Toplevel(title::String, width::Integer, height::Integer) = Toplevel(title, width, height, true)
Toplevel(title::String, visible::Bool) = Toplevel(title, 200, 200, visible)
Toplevel(title::String) = Toplevel(title, 200, 200)
Toplevel() = Toplevel("Default window")


get_value(widget::Tk_Toplevel) = tk_wm(widget, "title")
set_value(widget::Tk_Toplevel, value::String) = tk_wm(widget, "title", value)

function set_visible(widget::Tk_Toplevel, value::Bool)
    value = value ? "normal" : "withdrawn"
    tk_wm(widget, "state", value)
end

set_size(widget::Tk_Toplevel, width::Integer, height::Integer) = tcl(I"wm minsize", widget, width, height)
update(widget::Tk_Toplevel) = tk_wm(widget, "geometry")
destroy(widget::Tk_Toplevel) = tcl("destroy", widget)

## Frame
## nothing to add...

## Labelframe
Labelframe(parent::Widget, text::String) = Labelframe(parent, {:text=>text})
set_value(widget::Tk_Labelframe, text::String) = tk_configure(f, {:text=> text})


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
function set_value(widget::Tk_Panedwindow, value::Integer)
    sz = (tk_cget(widget, "orient") == "horizontal") ? get_width(widget) : get_height(widget)
    pos = int(value * sz/100)
    tcl(widget, "sashpos", 0, pos)
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
    sz = int(split(tcl_eval("grid size $master"), " ")) ## columns, rows
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
## f = Frame(w); pack(f) ## f shouldn't have any layout management 
## t = Text(f)
## scrollbars_add(f,t)
##
function scrollbars_add(parent::Tk_Frame, child::Tk_Widget)

    ## we use tcl commands for the scrollbar, not Scrollbar. Can't get the callbacks to work properly
    fpath = parent.w.path
    wpath = child.w.path
    xscr = "$fpath.xscr"
    yscr = "$fpath.yscr"
    
    tcl_eval("ttk::scrollbar $xscr -orient horizontal -command \"$wpath xview\"")
    tcl_eval("ttk::scrollbar $yscr -orient vertical -command \"$wpath yview\"")

    tk_configure(child, {:xscrollcommand => "$xscr set",
                          :yscrollcommand => "$yscr set"})
    
    grid(child, 1, 1)
    grid(yscr, 1, 2)
    grid(xscr, 2, 1)
    grid_configure(child, {:sticky => "news"})
    grid_configure(yscr, {:sticky => "ns"})
    grid_configure(xscr, {:sticky => "ew"})
    grid_rowconfigure(parent, 1, {:weight => 1})
    grid_columnconfigure(parent, 1, {:weight => 1})

    tcl(I"grid propagate", parent, false) ## size request comes from parent, not from child.
end

