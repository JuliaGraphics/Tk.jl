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
        function $k(parent::Widget; kwargs...)
            w = make_widget(parent, $v; kwargs...)
            widget = $k1 <: TTk_Container ? $k1(w, Tk_Widget[]) : $k1(w)
            if isa(parent, TTk_Container) push!(parent.children, widget) end
            widget
        end
    end
end


## Now customize

## Label constructors
Label(parent::Widget, text::String, image::Tk_Image) = Label(parent, text=tk_string_escape(text), image=image, compound="left")
Label(parent::Widget, text::String) = Label(parent, text=tk_string_escape(text))
Label(parent::Widget,  image::Tk_Image) = Label(parent, image=image, compound="image")
get_value(widget::Union(Tk_Button, Tk_Label)) = widget[:text]
function set_value(widget::Union(Tk_Label, Tk_Button), value::String)
    variable = cget(widget, "textvariable")
    (variable == "") ? widget[:text] =  tk_string_escape(value) : tclvar(variable, value)
end

## Button constructors
Button(parent::Widget, text::String, command::Function, image::Tk_Image) =
    Button(parent, text = tk_string_escape(text), command=command, image=image, compound="left")
Button(parent::Widget, text::String, image::Tk_Image) =
    Button(parent, text = tk_string_escape(text), image=image, compound="left")
Button(parent::Widget, text::String, command::Function) = Button(parent, text=tk_string_escape(text), command=command)
Button(parent::Widget, text::String) = Button(parent, text=tk_string_escape(text))
Button(parent::Widget, command::Function, image::Tk_Image) =
    Button(parent, command=command, image=image, compound="image")
Button(parent::Widget, image::Tk_Image) =
    Button(parent, image=image, compound="image")



## checkbox
function Checkbutton(parent::Widget, label::String)
    cb = Checkbutton(parent)
    set_items(cb, label)
    cb[:variable] = tclvar()
    set_value(cb, false)
    cb
end

function get_value(widget::Tk_Checkbutton)
    instate(widget, "selected")
end
function set_value(widget::Tk_Checkbutton, value::Bool)
    var = widget[:variable]
    tclvar(var, value ? 1 : 0)
end
get_items(widget::Tk_Checkbutton) = widget[:text]
set_items(widget::Tk_Checkbutton, value::String) = widget[:text] = tk_string_escape(value)

## RadioButton
type Tk_Radiobutton <: TTk_Widget
    w::TkWidget
end
MaybeTkRadioButton = Union(Nothing, Tk_Radiobutton)

function Radiobutton(parent::Widget, group::MaybeTkRadioButton, label::String)

    rb = Radiobutton(parent)

    var = isa(group, Tk_Radiobutton) ? group[:variable] : tclvar()
    configure(rb, variable = var, text=label, value=label)
    rb
end
Radiobutton(parent::Widget, label::String) = Radiobutton(parent, nothing, label)

get_value(widget::Tk_Radiobutton) = instate(widget, "selected")
set_value(widget::Tk_Radiobutton, value::Bool) = state(value ? "selected" : "!selected")
get_items(widget::Tk_Radiobutton) = widget[:text]
set_items(widget::Tk_Radiobutton, value::String) = configure(widget, text = value, value=value)


## Radio Button Group
type Tk_Radio <: TTk_Widget
    w::TkWidget
    buttons::Vector
    orient::Union(Nothing, String)
end

function Radio{T<:String}(parent::Widget, labels::Vector{T}, orient::String)
    n = size(labels)[1]
    rbs = Array(Tk_Radiobutton, n)
    frame = Frame(parent)

    rbs[1] = Radiobutton(frame, tk_string_escape(labels[1]))
    if n > 1
        for j in 2:n
            rbs[j] = Radiobutton(frame, rbs[1], tk_string_escape(labels[j]))
        end
    end

    rb = Tk_Radio(frame.w, rbs, orient)
    set_value(rb, labels[1])
    map(u -> pack(u, side = orient == "horizontal" ? "left" : "top",
                     anchor = orient == "horizontal" ? "n" : "w"), rbs)

    rb
end
Radio{T <: String}(parent::Widget, labels::Vector{T}) = Radio(parent, labels, "vertical") ## vertical default

function get_value(widget::Tk_Radio)
    items = get_items(widget)
    sel = map(get_value, widget.buttons)
    items[sel][1]
end
function set_value(widget::Tk_Radio, value::String)
    var = cget(widget.buttons[1], "variable")
    tclvar(var, value)
end
function set_value(widget::Tk_Radio, value::Integer)
    items = get_items(widget)
    set_value(widget, items[value])
end
get_items(widget::Tk_Radio) = map(get_items, widget.buttons)

function bind(widget::Tk_Radio, event::String, callback::Function)
    ## put onto each, but W now refers to button -- not group of buttons
    map(u -> bind(u, event, callback), widget.buttons)
end
## return ith button
## remove this until we split off a version for newer julia's.
##getindex(widget::Tk_Radio, i::Integer) = widget.buttons[i]

## Combobox
type Tk_Combobox <: TTk_Widget
    w::TkWidget
    values::Vector                      #  of tuples (key, label)
    Tk_Combobox(w::TkWidget) = new(w, [])
end

## Combobox.
## One can specify the values different ways
## * as a vector of strings
## * as a vector of (key,value) tuples. The value is displayed, keys are used by get_value, set_value
##   This has the advantage of keeping order.
## * as a dict of (key,value) pairs. This must be specified through set_items though
function Combobox(parent::Widget, values::Vector)
    cb = Combobox(parent)
    set_items(cb, values)
    set_editable(cb, false)
    cb
end

cb_pluck_labels(t) = String[v for (k,v) in t]
cb_pluck_keys(t) = String[k for (k,v) in t]
function get_value(widget::Tk_Combobox)
    label  = tcl(widget, "get")
    if get_editable(widget) return(label) end
    ## okay look up in vector or tuples
    labels = cb_pluck_labels(widget.values)
    keys = cb_pluck_keys(widget.values)
    out = keys[label .== labels]
    length(out) == 0 ? nothing : out[1]
end

set_value(widget::Tk_Combobox, index::Integer) = set_value(widget, cb_pluck_labels(widget.values)[index])
## value is a key
function set_value(widget::Tk_Combobox, value::MaybeString)
    if value == nothing tcl(widget, "set", "{}"); return end
    if get_editable(widget)
        tcl(widget, "set", value)
    else
        keys = cb_pluck_keys(widget.values)
        labels = cb_pluck_labels(widget.values)
        if any(value .== keys) tcl(widget, "set", labels[value .== keys][1]) end
    end
end


get_items(widget::Tk_Combobox) =  widget.values
function set_items{T}(widget::Tk_Combobox, items::Vector{(T,T)})
    vals = cb_pluck_labels(items)
    configure(widget, values = vals)
    widget.values = items
end
function set_items(widget::Tk_Combobox, items::Dict)
    widget.values = [(string(k),v) for (k,v) in items]
    configure(widget, values = cb_pluck_labels(widget.values))
end
function set_items{T <: String}(widget::Tk_Combobox, items::Vector{T})
    d = [(v,v) for v in items]
    set_items(widget, d)
end

get_editable(widget::Tk_Combobox) = widget[:state] == "normal"
set_editable(widget::Tk_Combobox, value::Bool) = widget[:state] = value ? "normal" : "readonly"


## Slider
## deprecate this interface as integer values are not guaranteed in return.
function Slider{T <: Integer}(parent::Widget, range::Range1{T}; orient="horizontal")
    w = Slider(parent, orient=orient)
    var = tclvar()
    tclvar(var, minimum(range))
    configure(w, from=minimum(range), to = maximum(range), variable=var)
    w
end

function Slider{T <: Real}(parent::Widget, lo::T, hi::T; orient = "horizontal")
    w = Slider(parent, orient = orient)
    var = tclvar()
    tclvar(var, lo)
    configure(w, from = lo, to = hi, variable = var)
    w
end

get_value(widget::Tk_Scale) = float(widget[:value])

function set_value(widget::Tk_Scale, value::Real)
    variable = widget[:variable]
    (variable == "") ? widget[:value] = value : tclvar(variable, value)
end

## bind needs extra args for command
function bind(widget::Tk_Scale, event::String, callback::Function)
    if event == "command"
        wrapper = (path, xs...) -> callback(path)
        bind(widget.w, event, wrapper)
    else
        bind(widget, event, callback)
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
    set_value(w, minimum(range))
    w
end

get_value(widget::Tk_Spinbox) = parse(Int, tcl(widget, "get"))
set_value(widget::Tk_Spinbox, value::Integer) = tcl(widget, "set", value)

get_items(widget::Tk_Spinbox) = widget.range
function set_items{T <: Integer}(widget::Tk_Spinbox, range::Range1{T})
    configure(widget, from=minimum(range), to = maximum(range), increment = step(range))
    widget.range = range
end


## Separator
function Separator(widget::Widget, horizontal::Bool)
    w = Separator(widget)
    configure(w, orient = (horizontal ? "horizontal" : "vertical"))
    w
end

## Progressbar
function Progressbar(widget::Widget, mode::String)
    w = Progressbar(widget)
    configure(w, mode = mode)    #  one of "determinate", "indeterminate"
    w
end

get_value(widget::Tk_Progressbar) = round(Int, float(widget[:value]))
set_value(widget::Tk_Progressbar, value::Integer) = widget[:value] = min(100, max(0, value))

## Image
MaybeImage = Union(Nothing, Tk_Image)
to_tcl(x::Tk_Image) = x.w

function Image(fname::String)
    if isfile(fname)
        w = tcl(I"image create photo", file = fname)
        Tk_Image(w)
    else
        error("Image needs filename of .gif file: $fname")
    end
end

# Create an image as a bitmap
function Image(source::BitArray{2}, mask::BitArray{2}, background::String, foreground::String)
    if size(source) != size(mask)
        error("Source and mask must have the same size")
    end
    ssource = x11encode(source)
    smask = x11encode(mask)
    w = tcl(I"image create bitmap", data = ssource, maskdata = smask, background = background, foreground = foreground)
    Tk_Image(w)
end

function x11header(s::IO, data::AbstractMatrix)
    println(s, "#define im_width ", size(data, 2))
    println(s, "#define im_height ", size(data, 1))
    println(s, "static char im_bits[] = {")
end

function x11encode(data::BitArray{2})
    # Not efficient, but easy
    s = IOBuffer()
    x11header(s, data)
    u8 = zeros(Uint8, iceil(size(data, 1)/8), size(data, 2))
    for i = 1:size(data,1)
        ii = iceil(i/8)
        n = i - 8*(ii-1) - 1
        for j = 1:size(data,2)
            u8[ii, j] |= uint8(data[i,j]) << n
        end
    end
    for i = 1:length(u8)-1
        print(s, u8[i], ",")
    end
    println(s, u8[end], "\n};")
    takebuf_string(s)
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
    tcl(widget, I"insert @0", tk_string_escape(val))
end

get_editable(widget::Tk_Entry) = widget[:state] == "normal"
set_editable(widget::Tk_Entry, value::Bool) = widget[:state] = value ? "normal" : "readonly"

## visibility is for passwords
get_visible(widget::Tk_Entry) = widget[:show] != "*"
set_visible(widget::Tk_Entry, value::Bool) = widget[:show] = value ? "{}" : "*"

## validate is one of none, key, focus, focusin, focusout or all
## validatecommand must return either tcl("expr", "FALSE") or tcl("expr", "TRUE") Use FALSE to call invalidate command
## percent substitution is matched in callbacks
function set_validation(widget::Tk_Entry, validate::String, validatecommand::Function, invalidcommand::MaybeFunction)
    tk_configure(widget, validate=validate, validatecommand=validatecommand, invalidcommand=invalidcommand)
end
set_validation(widget::Tk_Entry, validate::String, validatecommand::Function) = set_validation(widget, validate, validatecommand, nothing)



## Scrollbar. Pass in parent and child. We configure both
## used in scrollbars_add
function Scrollbar(parent::Widget, child::Widget, orient::String)
    which_view  = (orient == "horizontal") ? "xview" : "yview"
    scr = Scrollbar(parent, orient=orient, command=I("[list $(get_path(child)) $which_view]"))
    d = Dict()
    d[(orient == "horizontal") ? :xscrollcommand : :yscrollcommand] =  I("[list $(get_path(scr)) set]")
    configure(child, d)
    scr
end

## Text

## non-exported helpers
get_text(widget::Tk_Text, start_index, end_index) = tcl(widget, "get", start_index, end_index)
function set_text(widget::Tk_Text, value::String, index)
    tcl(widget, "insert", index, tk_string_escape(value))
end

get_value(widget::Tk_Text) = chomp(get_text(widget, "0.0", "end"))
function set_value(widget::Tk_Text, value::String)
    path = get_path(widget)
    tcl(widget, I"delete 0.0 end")
    set_text(widget, value, "end")
    tcl(widget, I"see 0.0")
end





get_editable(widget::Tk_Text) = widget[:state] != "disabled"
set_editable(widget::Tk_Text, value::Bool) = widget[:state] = value ? "normal" : "disabled"




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
function Treeview{T <: String}(widget::Widget, items::Vector{T}, title::String; selected_color::String="gray")
    w = Treeview(widget)
    configure(w, show="tree headings", selectmode="browse")
    tcl(w, I"heading #0", text = title)
    tcl(w, I"column  #0", anchor = I"w")

    set_items(w, items)

    tcl_eval("ttk::style map Treeview.Row -background [list selected $selected_color]")

    w
end
Treeview(widget::Widget, items::Vector) = Treeview(widget, items, "")

function treeview_delete_children(widget::Tk_Treeview)
    children = tcl(widget, I"children {}")
    if children != ""
        tcl(widget, "delete", children)
    end
end

function set_items{T <: String}(widget::Tk_Treeview, items::Vector{T})
    treeview_delete_children(widget)
    for i in items
        tcl(widget, I"insert {} end", text = i)
    end
end






## t = Treeview(w, ["one" "two" "half"; "three" "four" "half"], [100, 50, 23])
function Treeview{T <: String}(widget::Widget, items::Array{T,2}, widths::MaybeVector)

    sz = size(items)

    w = Treeview(widget)
    configure(w, show = "tree headings", selectmode = "browse", columns=collect(1:(sz[2]-1)))
    ## widths ...
    if isa(widths, Vector)
        tcl(w, I"column #0", width = widths[1])
        for k in 2:length(widths)
            tcl(w, I"column", k - 1, width=widths[k])
        end
    end

    set_items(w, items)
    color = "gray"
    tcl_eval("ttk::style map Treeview.Row -background [list selected $color]")

    w
end
Treeview{T <: String}(widget::Widget, items::Array{T,2}) = Treeview(widget, items, nothing)

function set_items{T <: String}(widget::Tk_Treeview, items::Array{T,2})
    treeview_delete_children(widget)
    sz = size(items)
    for i in 1:sz[1]
        vals = String[j for j in items[i,2:end]]
        tcl(widget, I"insert {} end", text = items[i,1], values = vals)
    end
end


## Return array of selected values by key or nothing
## A selected key is a string or array if path is needed
function get_value(widget::Tk_Treeview)
    sels = selected_nodes(widget)
    sels == nothing ? nothing : [tree_get_keys(widget, sel) for sel in sels]
end

## select row given by index. extend = true to add selection
function set_value(widget::Tk_Treeview, index::Integer, extend::Bool)
    children = split(tcl(widget, "children", "{}"))
    child = children[index]
    tcl(widget, "selection", extend ? "add" : "set", child)
end
set_value(widget::Tk_Treeview, index::Integer) = set_value(widget, index, false)

## Some conveniences for working with trees
## w = Toplevel()
## f = Frame(w)
## tr = Treeview(f)
## scrollbars_add(f, tr)
## pack(f, expand=true, fill="both")
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
    length(sel) == 0 ? nothing : map(TreeNode, split(sel))
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
node_open(widget::Tk_Treeview, node::TreeNode, opened::Bool) = tcl(widget, "item", node, open=opened)
function node_open(widget::Tk_Treeview, node::TreeNode)
  tcl(widget, "item", node, "-open") == "true" && tcl(widget, "children", node) != ""
end


## XXX This could be cleaned up a bit. It is annoying to treat the value and text differently when
## working on a grid XXX

## set column names, and widths. This works on values, not text part
function tree_headers{T <: String, S<: Integer}(widget::Tk_Treeview, names::Vector{T}, widths::Vector{S})
    tree_headers(widget, names)
    tree_column_widths(widget, widths)
end

function tree_headers{T <: String}(widget::Tk_Treeview, names::Vector{T})
    tcl(widget, "configure", column=names)
    widget.names = names
    map(u -> tcl(widget, "heading", u, text=u), names)
end

## Set Column widths. Must have set headers first
function tree_column_widths{T <: Integer}(widget::Tk_Treeview, widths::Vector{T})
    if widget.names == nothing
        error("Must set header names, then widths")
    end
    heads = widget.names
    if length(widths) == length(heads) + 1
        tcl(widget,  I"heading column #0", text=widths[1])
        map(i -> tcl(widget, " column", heads[i], width=widths[i + 1]), 1:length(heads))
    elseif length(widths) == length(heads)
        map(i -> tcl(widget, "column", heads[i], width=widths[i]), 1:length(widths))
    else
        error("Widths must match number of column names or one more")
    end
end

## set name and width of key column
## a ttk::treeview has a special column for the one which can expand
tree_key_header(widget::Tk_Treeview, name::String)  = tcl(widget, I"heading #0", text = name)
tree_key_width(widget::Tk_Treeview, width::Integer) = tcl(widget, I"column #0", width = width)


## Canvas


## TkCanvas is plain canvas object, reserve name Canvas for Cairo enhanced one
function TkCanvas(widget::Tk_Widget, width::Integer, height::Integer)
    TkCanvas(widget, width = width, height = height)
end


## Bring Canvas object into Tk_Widget level.
type Tk_CairoCanvas       <: TTk_Widget
    w::Canvas
end

function TkCairoCanvas(Widget::Tk_Widget; width::Int=-1, height::Int=-1)
    c = Canvas(Widget.w, width, height)
    Tk_CairoCanvas(c)
end

function Canvas(parent::TTk_Container, args...)
    c = Canvas(parent.w, args...)
    push!(parent.children, Tk_CairoCanvas(c))
    c
end

