## Create basic widgets here

## Most types are simple, some have other properties
type Tk_Label       <: TTk_Widget w::TkWidget end
type Tk_Button      <: TTk_Widget w::TkWidget end
type Tk_Checkbutton <: TTk_Widget w::TkWidget end
##type Tk_Radio <: TTk_Widget w::TkWidget end
##type Tk_Combobox <: TTk_Widget w::TkWidget end
type Tk_Scale       <: TTk_Widget w::TkWidget end
#type Tk_Spinbox <: TTk_Widget w::TkWidget end
type Tk_Entry       <: TTk_Widget w::TkWidget end
type Tk_Sizegrip    <: TTk_Widget w::TkWidget end
type Tk_Separator   <: TTk_Widget w::TkWidget end
type Tk_Progressbar <: TTk_Widget w::TkWidget end
type Tk_Menu        <: TTk_Widget w::TkWidget end
type Tk_Menubutton  <: TTk_Widget w::TkWidget end
type Tk_Image       <: TTk_Widget w::String end
type Tk_Scrollbar   <: TTk_Widget w::TkWidget end
type Tk_Text        <: Tk_Widget  w::TkWidget end
##type Tk_Treeview    <: Tk_Widget  w::TkWidget end
type Tk_Canvas      <: Tk_Widget  w::TkWidget end

for (k, k1, v) in ((:Label, :Tk_Label, "ttk::label"),
                   (:Button, :Tk_Button, "ttk::button"),
                   (:Checkbutton, :Tk_Checkbutton, "ttk::checkbutton"),
                   (:Radiobutton, :Tk_Radiobutton, "ttk::radiobutton"),
                   (:Combobox, :Tk_Combobox, "ttk::combobox"),
                   (:Slider, :Tk_Scale, "ttk::scale"), # Scale conflicts with Gadfly.Scale
                   (:Spinbox, :Tk_Spinbox, "ttk::spinbox"),
                   (:Entry, :Tk_Entry, "ttk::entry"),
                   (:Sizegrip, :Tk_Sizegrip, "ttk::sizegrip"),
                   (:Separator, :Tk_Separator, "ttk::separator"),
                   (:Progressbar, :Tk_Progressbar, "ttk::progressbar"),
                   (:Menu, :Tk_Menu, "menu"),
                   (:Menubutton, :Tk_Menubutton, "ttk::menubutton"),
                   (:Scrollbar, :Tk_Scrollbar, "ttk::scrollbar"),
                   (:Text, :Tk_Text, "text"),
                   (:Treeview, :Tk_Treeview, "ttk::treeview"),
                   (:TkCanvas, :Tk_Canvas, "canvas"),
                   ##
                   (:Frame, :Tk_Frame, "ttk::frame"),
                   (:Labelframe, :Tk_Labelframe, "ttk::labelframe"),
                   (:Notebook, :Tk_Notebook, "ttk::notebook"),
                   (:Panedwindow, :Tk_Panedwindow, "ttk::panedwindow")
                   )
    @eval begin
        function $k(parent::Widget, args::Dict)
            w = make_widget(parent, $v, args)
            $k1(w)
        end
        $k(parent::Widget) = $k(parent, Dict())
    end
end


## Now customize

## Label constructors
Label(parent::Widget, text::String, image::Tk_Image) = Label(parent, {:text => text, :image=>image, :compound => "left"})
Label(parent::Widget, text::String) = Label(parent, {:text => text})
Label(parent::Widget,  image::Tk_Image) = Label(parent, {:image=>image, :compound => "image"})
## cf. Button for get_value, set_value

## Button constructors
Button(parent::Widget, text::String, command::Function, image::Tk_Image) =
    Button(parent, {:text => text, :command=>command, :image=>image, :compound=>"left"})
Button(parent::Widget, text::String, image::Tk_Image) =
    Button(parent, {:text => text, :image=>image, :compound=>"left"})
Button(parent::Widget, text::String, command::Function) = Button(parent, {:text=>text, :command=>command})
Button(parent::Widget, text::String) = Button(parent, {:text=>text})
Button(parent::Widget, command::Function, image::Tk_Image) =
    Button(parent, {:command=>command, :image=>image, :compound=>"image"})
Button(parent::Widget, image::Tk_Image) =
    Button(parent, {:image=>image, :compound=>"image"})
    
get_value(widget::Union(Tk_Button, Tk_Label)) = tk_cget(widget, "text")
function set_value(widget::Union(Tk_Button, Tk_Label), value::String) 
    variable = tk_cget(widget, "variable")
    (variable == "") ? tk_configure(widget, {:text => value}) : tclvar(variable, value)
end

## checkbox
function Checkbutton(parent::Widget, label::String)
    cb = Checkbutton(parent)
    set_items(cb, label)
    tk_configure(cb, {:variable => tclvar()})
    set_value(cb, false)
    cb
end

function get_value(widget::Tk_Checkbutton)
    ## var = tk_cget(widget, "variable")
    ## tclvar(var) == "1"
    tk_instate(widget, "selected")
end
function set_value(widget::Tk_Checkbutton, value::Bool)
    var = tk_cget(widget, "variable")
    tclvar(var, value ? 1 : 0)
end
get_items(widget::Tk_Checkbutton) = tk_cget(widget, "text")
set_items(widget::Tk_Checkbutton, value::String) = tk_configure(widget, {:text => value})

## RadioButton
type Tk_Radiobutton <: TTk_Widget
    w::TkWidget
end
MaybeTkRadioButton = Union(Nothing, Tk_Radiobutton)

function Radiobutton(parent::Widget, group::MaybeTkRadioButton, label::String)
    
    rb = Radiobutton(parent)

    var = isa(group, Tk_Radiobutton) ? tk_cget(group, "variable") : tclvar()
    tk_configure(rb, {:variable => var, :text=>label, :value=>label})
    rb
end
Radiobutton(parent::Widget, label::String) = Radiobutton(parent, nothing, label)

get_value(widget::Tk_Radiobutton) = tk_instate(widget, "selected")
set_value(widget::Tk_Radiobutton, value::Bool) = tk_state(value ? "selected" : "!selected")
get_items(widget::Tk_Radiobutton) = tk_cget(widget, "text")
set_items(widget::Tk_Radiobutton, value::String) = tk_configure(widget, {:text => value})


## Radio Button Group
type Tk_Radio <: TTk_Widget
    w::TkWidget
    buttons::Vector
    Tk_Radio(w::TkWidget) = new(w, [])
end

function Radio(parent::Widget, labels::Vector, horizontal::Bool)
    rbs = Array(Tk_Radiobutton, length(labels))
    frame = Frame(parent)
    rbs[1] = Radiobutton(frame, labels[1])
    if length(labels) > 1
        for j in 2:length(labels)
            rbs[j] = Radiobutton(frame, rbs[1], labels[j])
        end
    end
    path = tk_cget(rbs[1], "variable")
    value = labels[1]
    tcl("set", path, value)
    
    
    rb = Tk_Radio(frame.w)
    rb.buttons = rbs
    map(u -> pack(u, {:side => horizontal ? "left" : "top",
                      :anchor => horizontal ? "n" : "w"}), rbs)

    set_value(rb, labels[1])
    rb
end
Radio(parent::Widget, labels::Vector) = Radio(parent, labels, false) ## vertical default

function get_value(widget::Tk_Radio)
    items = get_items(widget)
    sel = map(get_value, widget.buttons)
    items[sel][1]
end
function set_value(widget::Tk_Radio, value::String)
    var = tk_cget(widget.buttons[1], "variable")
    tclvar(var, value)
end
function set_value(widget::Tk_Radio, value::Integer)
    items = get_items(widget)
    set_value(widget, items[value])
end
get_items(widget::Tk_Radio) = map(get_items, widget.buttons)
function tk_bind(widget::Tk_Radio, event::String, callback::Function)
    ## put onto each, but W now refers to button -- not group of buttons
    map(u -> tk_bind(u, event, callback), widget.buttons)
end
## return ith button
getindex(widget::Tk_Radio, i::Integer) = widget.buttons[i]

## Combobox
type Tk_Combobox <: TTk_Widget
    w::TkWidget
    values::Dict
    Tk_Combobox(w::TkWidget) = new(w, Dict())
end

## Constructor for vectors
## One can use a Dict to configure too, but this must be done with
## cb = Combobox(parent)
## set_items(cb, d) ## thekeys are displayed, the values are returned
function Combobox(parent::Widget, values::Vector)
    cb = Combobox(parent)
    set_items(cb, values)
    set_editable(cb, false)
    cb
end

function get_value(widget::Tk_Combobox)
    value =tcl(widget, "get")
    if value == "" return(nothing) end
    if has(widget.values, Base.symbol(value))
        return(widget.values[Base.symbol(value)])
    else
        return(value)
    end
end
set_value(widget::Tk_Combobox, index::Integer) = set_value(widget, [k for (k,v) in widget.values][index])
function set_value(widget::Tk_Combobox, value::MaybeString)
    if value == nothing
        tcl(widget, "set", "{}")
    elseif has(widget.values, value)
        tcl(widget, "set", value)
    else
        tcl(widget, "set", value)       #  not in list
    end
end


get_items(widget::Tk_Combobox) =  widget.values

function set_items(widget::Tk_Combobox, items::Dict)
    vals = Array(String, 0)
    for (k,v) in items
        push!(vals, string(k))
    end
    tk_configure(widget, {:values => vals})
    widget.values = items
end
function set_items{T <: String}(widget::Tk_Combobox, items::Vector{T})
    d = Dict()
    for k in items
        d[k] = k
    end
    set_items(widget, d)
end

get_editable(widget::Tk_Combobox) = tk_cget(widget, "state") == "normal"
set_editable(widget::Tk_Combobox, value::Bool) = tk_configure(widget, {:state => value ? "normal" : "readonly"})

## Slider
## Restricted to integer ranges stepping by 1!

function Slider{T <: Integer}(parent::Widget, range::Range1{T}, args::Dict)
    w = Slider(parent, args)
    var = tclvar()
    tclvar(var, min(range))
    tk_configure(w, {:from=>min(range), :to => max(range), :variable=>var})
    w
end
Slider{T <: Integer}(parent::Widget, range::Range1{T}) = Slider(parent, range, Dict())


get_value(widget::Tk_Scale) = int(float(tk_cget(widget, "value")))
function set_value(widget::Tk_Scale, value::Integer)
    variable = tk_cget(widget, "variable")
    (variable == "") ? tk_cget(widget, {:value => value}) : tclvar(variable, value)
end


## tk_bind needs extra args for command
function tk_bind(widget::Tk_Scale, event::String, callback::Function)
    if event == "command"
        wrapper = (path, xs...) -> callback(path)
        tk_bind(widget.w, event, wrapper)
    else
        tk_bind(widget, event, callback)
    end
end

## Spinbox
type Tk_Spinbox <: TTk_Widget
    w::TkWidget
    range::Range1{Int}
    Tk_Spinbox(w::TkWidget) = new(w, 1:1)
end

function Spinbox{T <: Integer}(parent, range::Range1{T})
    w = Spinbox(parent)
    set_items(w, range)
    set_value(w, min(range))
    w
end

get_value(widget::Tk_Spinbox) = int(tcl(widget, "get"))
set_value(widget::Tk_Spinbox, value::Integer) = tcl(widget, "set", value)

get_items(widget::Tk_Spinbox) = widget.range
function set_items{T <: Integer}(widget::Tk_Spinbox, range::Range1{T})
    tk_configure(widget, {:from=>min(range), :to => max(range), :increment => step(range)})
    widget.range = range
end


## Separator
function Separator(widget::Widget, horizontal::Bool)
    w = Separator(widget)
    tk_configure(w, {:orient => (horizontal ? "horizontal" : "vertical")})
end

## Progressbar
function Progressbar(widget::Widget, mode::String)
    w = Progressbar(widget)
    tk_configure(w, {:mode => mode})    #  one of "determinate", "indeterminate"
    w
end

get_value(widget::Tk_Progressbar) = tk_cget(widget, "value")
set_value(widget::Tk_Progressbar, value::Integer) = tk_configure(widget, {:value => min(100, max(0, value))})

## Image
MaybeImage = Union(Nothing, Tk_Image)
to_tcl(x::Tk_Image) = x.w

function Image(fname::String)
    if isfile(fname)
        w = tcl(I"image create photo", {:file => fname})
        Tk_Image(w)
    else
        error("Image needs filename of .gif file: $fname")
    end
end

## Entry

function Entry(parent::Widget, text::String)
    w = Entry(parent)
    set_value(w, text)
    w
end

### methods
get_value(widget::Tk_Entry) = tcl(widget, "get")
function set_value(widget::Tk_Entry, val::String)
    tcl(widget, I"delete @0 end")
    tcl(widget, I"insert @0", val == "" ? "{}" : val)
end

get_editable(widget::Tk_Entry) = tk_cget(widget, "state") == "normal"
set_editable(widget::Tk_Entry, value::Bool) = tk_configure(widget, {:state => value ? "normal" : "readonly"})

## visibility is for passwords
get_visible(widget::Tk_Entry) = tk_cget(widget, "show") != "*"
set_visible(widget::Tk_Entry, value::Bool) = tk_configure(widget, {:show => value ? "" : "*"})



## Text
get_value(widget::Tk_Text) = tcl(widget, I"get 0.0 end")

function set_value(widget::Tk_Text, value::String)
    path = get_path(widget)
    tcl(widget, I"delete 0.0 end")
    tcl(widget, I"insert end", value)
    tcl(widget, I"see 0.0")
end

get_editable(widget::Tk_Text) = tk_cget(widget, "state") != "disabled"
set_editable(widget::Tk_Text, value::Bool) = tk_configure(widget, {:state => value ? "normal" : "disabled"})




## Tree
type Tk_Treeview <: TTk_Widget
    w::Widget
    names::MaybeVector
    Tk_Treeview(w::Widget) = new(w, nothing)
end
type TreeNode node::String end
to_tcl(x::TreeNode) = x.node
MaybeTreeNode = Union(TreeNode, Nothing)

## Special Tree cases

## listbox like interface
function Treeview(widget::Widget, items::Vector, title::String)
    w = Treeview(widget)
    tk_configure(w, {:show => "tree headings", :selectmode => "browse"})
    tcl(w, I"heading #0", {:text => title})
    tcl(w, I"column  #0", {:anchor => I"w"})

    for i in items
        tcl(w, I"insert {} end", {:text => i})
    end

    color = "gray"
    tcl_eval("ttk::style map Treeview.Row -background [list selected $color]")
    
    w
end
Treeview(widget::Widget, items::Vector) = Treeview(widget, items, "")


## t = Treeview(w, ["one" "two" "half"; "three" "four" "half"], [100, 50, 23])
function Treeview(widget::Widget, items::Array{ASCIIString,2}, widths::MaybeVector)

    sz = size(items)

    w = Treeview(widget)
    tk_configure(w, {:show => "tree headings", :selectmode => "browse", :columns=>[1:(sz[2]-1)]})
    ## widths ...
    if isa(widths, Vector)
        tcl(w, I"column #0", {:width => widths[1]})
        for k in 2:length(widths)
            tcl(w, I"column", k - 1, {:width => widths[k]})
        end
    end
    for i in 1:sz[1]
        val = "[list"
        for j in 2:sz[2]
          tmp = items[i,j]
          val = val * " {$tmp}"
        end
    val = val * "]"
    item = items[i,1]
    tcl(w, I"insert {} end", {:text => items[i,1], :values => val})
    end

    color = "gray"
    tcl_eval("ttk::style map Treeview.Row -background [list selected $color]")
    
    w
end
Treeview(widget::Widget, items::Array{ASCIIString,2}) = Treeview(widget, items, nothing)


## Return array of selected values by key or nothing
## A selected key is a string or array if path is needed
function get_value(widget::Tk_Treeview)
    sels = selected_nodes(widget)
    sels == nothing ? nothing : [tree_get_keys(widget, sel) for sel in sels]
end


## Some conveniences for working with trees
## w = Toplevel()
## f = Frame(w)
## tr = Treeview(f)
## scrollbars_add(f, tr)
## pack(f, {:expand=>true, :fill=>"both"})
## set_size(w, 300, 300)

## ### Okay, lets make a tree

## d = ["data1", "data2"]
## id_1   = Tk.node_insert(tr, nothing, "node 1", d)
## id_1_1 = Tk.node_insert(tr, id_1,  "node 1_1", d)
## id_1_2 = Tk.node_insert(tr, id_1,  "node 1_2", d)
## id_2   = Tk.node_insert(tr, nothing, "node 2", d)

## Tk.tree_headers(tr, ["col 1", "col2"], [50, 75])


## used by get_value to return path of keys for a node
function tree_get_keys(widget::Tk_Treeview, node::TreeNode)
    if tcl(widget, "exists", node) == "0" error("Node is not in tree") end
    
    x = String[]
    while node.node != ""
        push!(x, tcl(widget, "item", node, "-text"))
        node = TreeNode(tcl(widget, "parent", node))
    end
    length(x) > 1 ? reverse(x) : x[1]   #  return Vector or single value
end

## return vector of TreeNodes that are currently selected or nothing (Maybe{Vector{TreeNodes}}
function selected_nodes(widget::Tk_Treeview)
    sel = tcl(widget, "selection")
    length(sel) == 0 ? nothing : map(TreeNode, split(sel, " "))
end



## insert into node, return new node
function node_insert(widget::Tk_Treeview, node::MaybeTreeNode, at::MaybeStringInteger,
                     text::MaybeString, image::MaybeImage, values::MaybeVector, opened::MaybeBool)

    parent = isa(node, Nothing) ? "{}" : node.node
    at = isa(at, Nothing) ? "end" : at
    
    args = Dict()
    args["text"] = isa(text, Nothing) ? "" : text
    args["image"] = image.i
    args["values"] = values
    args["open"] = opened

    id = tcl(widget, "insert", parent, at,  args)
    TreeNode(id)
end

## widget, node, text, image, values
node_insert(widget::Tk_Treeview, node::MaybeTreeNode, text::MaybeString, image::MaybeImage, values::MaybeVector) =
    node_insert(widget, node, nothing, text, image, values, true)
## widget, node, text, values
node_insert(widget::Tk_Treeview, node::MaybeTreeNode, text::MaybeString,  values::MaybeVector) =
    node_insert(widget, node, nothing, text, nothing, values, true)
## widget, node, text
node_insert(widget::Tk_Treeview, node::MaybeTreeNode, text::MaybeString) =
    insert_tree(widget, node, nothing, text, nothing, nothing, true)

## move node to parent and at, a string index, eg. "0" or "end".
function node_move(widget::Tk_Treeview, node::TreeNode, parent::MaybeTreeNode, at::MaybeStringInteger)
    to = isa(parent, Nothing) ? "{}" : parent.node
    ind = isa(at, Nothing) ? "end" : at
    tcl(widget, "move", node.node, to, ind)
end
## move to end
node_move(widget::Tk_Treeview, node::TreeNode, parent::MaybeTreeNode) = node_move(widget, node, parent, nothing)

## remove a node
node_delete(widget::Tk_Treeview, node::TreeNode) = tcl(widget, "delete", node.node)

## Set or retrieve node open status
node_open(widget::Tk_Treeview, node::TreeNode, opened::Bool) = tcl(widget, "item", node, {:open => opened})
function node_open(widget::Tk_Treeview, node::TreeNode)
  tcl(widget, "item", node, "-open") == "true" && tcl(widget, "children", node) != ""
end


## set column names, and widths. This works on values, not text part
function tree_headers{T <: String, S<: Integer}(widget::Tk_Treeview, names::Vector{T}, widths::Vector{S})
    tree_headers(widget, names)
    tree_column_widths(widget, widths)
end

function tree_headers{T <: String}(widget::Tk_Treeview, names::Vector{T})
    tcl(widget, "configure", {:column => names})
    widget.names = names
    map(u -> tcl(widget, "heading", u, {:text => u}), names)
end

## Set Column widths. Must have set headers first
function tree_column_widths{T <: Integer}(widget::Tk_Treeview, widths::Vector{T})
    if widget.names == nothing
        error("Must set header names, then widths")
    end
    heads = widget.names
    if length(widths) == length(heads) + 1
        tcl(widget,  I"heading column #0", {:text => widths[1]})
        map(i -> tcl(widget, " column", heads[i], {:width=>widths[i + 1]}), 1:length(heads))
    elseif length(widths) == length(heads)
        map(i -> tcl(widget, "column", heads[i], {:width=>widths[i]}), 1:length(widths))
    else
        error("Widths must match number of column names or one more")
    end
end

## set name and width of key column
## a ttk::treeview has a special column for the one which can expand
tree_key_header(widget::Tk_Treeview, name::String) = tcl(widget, I"header @0", {:text => name})
tree_key_width(widget::Tk_Treeview, width::Integer) = tcl(widget, I"column @0", {:width => width})




## TkCanvas is plain canvas object, reserve name Canvas for Cairo enhanced one
function TkCanvas(widget::Tk_Widget, width::Integer, height::Integer)
    TkCanvas(widget, {:width => width, :height => height})
end




## The main purpose of Tk is to provide an interactive device for graphics. This is the Tk.Canvas
## widget.



## Bring Canvas object into Tk_Widget level.
type Tk_CairoCanvas <: Tk_Widget
    w::Union(Nothing, Canvas)
    device::Union(Nothing, Cairo.CairoRenderer)
    function Tk_CairoCanvas(widget::Widget)
        self = new(Tk.Canvas(widget.w), nothing)
        function callback(path)
            if self.device == nothing
                c = self.w
                Tk.init_canvas(c)
                w = tk_winfo(c, "width")  | int
                h = tk_winfo(c, "height")  | int

                r = Cairo.CairoRenderer(Tk.cairo_surface(c))
                r.upperright = (w, h)
                r.on_open = () -> (cr = Tk.cairo_context(c); Cairo.set_source_rgb(cr, 1, 1, 1); Cairo.paint(cr))
                r.on_close = () -> (Tk.reveal(c); Tk.tcl_doevent())
                self.device = r
            end
        end
        tk_bind(self.w, "<Map>", callback)
        tk_bind(self.w, "<Configure>", (path) -> begin
            if !isa(self.device, Nothing)
                w, h = map(u -> tk_winfo(self.w, u) | int, ("width", "height"))
                self.device.upperright = (w, h)
            end
        end)
        self
    end
end

CairoCanvas(w::Widget) = Tk_CairoCanvas(widget)

## This would be used with the following, but it only works directly if the
## canvas is packed in a window. It doesn't show in a themed widget (Frame, Panedwindow)
## and loosk funny when sharing the stage with a button.

## using Winston ## also Image library...


## function render(cnv::Tk_CairoCanvas, p::Winston.PlotContainer)
##     if !isa(cnv.device, Nothing)
##         Winston.page_compose(p, cnv.device, false)
##         cnv.device.on_close()
##     else
##         println("Device not initialized yet. Did you manage its layout?")
##     end
## end


## name = "test"; w,h = 500, 500
## win = Toplevel(name, w, h)
## tcl("pack", "propagate", win, false)

## ## Pack into toplevel window -- works
## #canvas = Tk_CairoCanvas(win)


## f = Frame(win); pack(f, {:side=>"left"})
## canvas = Tk_CairoCanvas(win)
## pack(canvas, {:side=>"left", :expand=>true, :fill => "both"})

## ## pack in frame
## b = Button(f, "click me", (path) -> begin
##     x = [-pi:1:pi]
##     y = sin(x)

##     p = FramedPlot()
##     add(p, Curve(x, y))
##     render(canvas, p)
## end)
## pack(b)





## ## Pack into Frame -- Fails!
## #f = Frame(win); pack(f, {:expand=>true, :fill => "both"})
## #set_size(win, w, h)
## #canvas = Tk_CairoCanvas(f)
## #pack(canvas, {:expand=>true, :fill => "both"})

## ## Fails

## ## pg = Panedwindow(win)
## ## pack(pg, {:expand=>true, :fill => "both"})

## ## b = Button(pg, "click me")
## ## page_add(b)

## ## canvas = Tk_CairoCanvas(pg)
## ## page_add(canvas)




## x = [-pi:1:pi]
## y = sin(x)

## p = FramedPlot()
## add(p, Curve(x, y))


## must pause until map call is doen
#render(canvas, p)

## This is a Tk issue:
##

## do_frame = false

## using Tk
## w, h = (500, 500)
## win = Window("name", w, h)
## tcl_eval(" pack propagate $(win.path) 0")

## if !do_frame
##     c = Tk.Canvas(win)
## else
##     f = Tk.TkWidget(win, "ttk:frame")
##     cmd = "ttk::frame $(f.path)"
##     tcl_eval(cmd)
##     tcl_eval("pack $(f.path) -expand 1 -fill both")
    
##     c = Tk.Canvas(f)
## end



## pack(c)

## Tk.init_canvas(c)
## r = Cairo.CairoRenderer(Tk.cairo_surface(c))
## r.upperright = (w, h)
## r.on_open = () -> (cr = Tk.cairo_context(c); Cairo.set_source_rgb(cr, 1, 1, 1); Cairo.paint(cr))
## r.on_close = () -> (Tk.reveal(c); Tk.tcl_doevent())


## using Winston
## x = [-pi:1:pi]
## y = sin(x)

## p = FramedPlot()
## add(p, Curve(x, y))

## Winston.page_compose(p, r, false)
## r.on_close()
