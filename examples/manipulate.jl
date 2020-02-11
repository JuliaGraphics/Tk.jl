# This is an example mimicking RStudio's `manipulate` package (inspired by Mathematica's no doubt)
# The manipulate function makes it easy to create "interactive" GUIs. In this case, we can
# dynamically control parameters of a `Winston` graph.
# To add a control is easy. There are just a few: slider, picker, checkbox, button, and entry

using Winston
using Tk
using Compat; import Compat.String


function render(c, p)
    ctx = getgc(c)
    Base.Graphics.set_source_rgb(ctx, 1, 1, 1)
    Base.Graphics.paint(ctx)
    Winston.page_compose(p, Tk.cairo_surface(c))
    reveal(c)
    Tk.update()
end

# do a manipulate type thing

# context to store dynamic values

module ManipulateContext
using Winston
end


abstract type ManipulateWidget end
get_label(widget::ManipulateWidget) = widget.label

mutable struct SliderWidget <: ManipulateWidget
    nm
    label
    initial
    rng
end
function make_widget(parent, widget::SliderWidget)
    sl = Slider(parent, widget.rng)
    set_value(sl, widget.initial)
    sl
end

slider(nm::AbstractString, label::AbstractString, rng::UnitRange, initial::Integer) = SliderWidget(nm, label, initial, rng)
slider(nm::AbstractString, label::AbstractString, rng::UnitRange) = slider(nm, label, rng, minimum(rng))
slider(nm::AbstractString,  rng::UnitRange) = slider(nm, nm, rng, minimum(rng))

mutable struct PickerWidget <: ManipulateWidget
    nm
    label
    initial
    vals
end

function make_widget(parent, widget::PickerWidget)
    cb = Combobox(parent)
    set_items(cb, widget.vals)
    set_value(cb, widget.initial)
    set_editable(cb, false)
    cb
end


picker(nm::AbstractString, label::AbstractString, vals::Vector{T}, initial) where {T <: AbstractString} = PickerWidget(nm, label, initial, vals)
picker(nm::AbstractString, label::AbstractString, vals::Vector{T}) where {T <: AbstractString} = picker(nm, label, vals, vals[1])
picker(nm::AbstractString, vals::Vector{T}) where {T <: AbstractString} = picker(nm, nm, vals)
picker(nm::AbstractString, label::AbstractString, vals::Dict, initial) = PickerWidget(nm, label, vals, initial)
picker(nm::AbstractString, label::AbstractString, vals::Dict) = PickerWidget(nm, label, vals, [string(k) for (k,v) in vals][1])
picker(nm::AbstractString, vals::Dict) = picker(nm, nm, vals)

mutable struct CheckboxWidget <: ManipulateWidget
    nm
    label
    initial
end
function make_widget(parent, widget::CheckboxWidget)
    w = Checkbutton(parent, widget.label)
    set_value(w, widget.initial)
    w
end
get_label(widget::CheckboxWidget) = nothing

checkbox(nm::AbstractString, label::AbstractString, initial::Bool) = CheckboxWidget(nm, label, initial)
checkbox(nm::AbstractString, label::AbstractString) = checkbox(nm, label, false)


mutable struct ButtonWidget <: ManipulateWidget
    label
    nm
end
make_widget(parent, widget::ButtonWidget) = Button(parent, widget.label)
get_label(widget::ButtonWidget) = nothing
button(label::AbstractString) = ButtonWidget(label, nothing)


# Add text widget to gather one-line of text
mutable struct EntryWidget <: ManipulateWidget
    nm
    label
    initial
end
make_widget(parent, widget::EntryWidget) = Entry(parent, widget.initial)
entry(nm::AbstractString, label::AbstractString, initial::AbstractString) = EntryWidget(nm, label, initial)
entry(nm::AbstractString, initial::AbstractString) = EntryWidget(nm, nm, initial)
entry(nm::AbstractString) = EntryWidget(nm, nm, "{}")


# Expression returns a plot object. Use names as values
function manipulate(ex::(Union{Symbol,Expr}), controls...)
    widgets = Array(Tk.Widget, 0)

    w = Toplevel("Manipulate", 800, 500)
    pack_stop_propagate(w)
    graph = Canvas(w, 500, 500); pack(graph, side="left")
    control_pane= Frame(w); pack(control_pane, side="left", expand=true, fill="both")


    ## create, layout widgets
    for i in controls
        widget = make_widget(control_pane, i)
        push!(widgets, widget)
        formlayout(widget, get_label(i))
    end

    get_values() = [get_value(i) for i in  widgets]
    get_nms() = map(u -> u.nm, controls)
    function get_vals()
        d = Dict()                      # return Dict of values
        vals = get_values(); keys = get_nms()
        for i in 1:length(vals)
            if !isa(keys[i], Nothing)
                d[keys[i]] = vals[i]
            end
        end
        d
    end

    function dict_to_module(d::Dict) ## stuff values into Manipulate Context
        for (k,v) in d
            eval(ManipulateContext, :($(Symbol(k)) = $v))
        end
    end

    function make_graphic(x...)
        d = get_vals()
        dict_to_module(d)
        p = eval(ManipulateContext, ex)
        render(graph, p)
    end
    map(u -> callback_add(u, make_graphic), widgets)
    widgets
end




# we need to make an expression. 
# here we need to
# * use semicolon (perhaps)
# * return p, the FramedPlot object to draw

ex = quote
    x = linspace( 0, n * pi, 100 )
    c = cos(x)
    s = sin(x)
    p = FramedPlot()
    setattr(p, "title", title)
    if fillbetween
        add(p, FillBetween(x, c, x, s) )
    end
    add(p, Curve(x, c, "color", color) )
    add(p, Curve(x, s, "color", "blue") )
    file(p, "example1.png")
    p
end

obj = manipulate(ex,
                 slider("n", "[0, n*pi]", 1:10)
                 ,entry("title", "Title", "title")
                 ,checkbox("fillbetween", "Fill between?", true)
                 ,picker("color", "Cos color", ["red", "green", "yellow"])
                 ,button("update")
                 )
