## Additional methods to give simplified interface to the Tk widgets created in this package

XXX() = error("No default method.")

## Main value
get_value(widget::Widget) = XXX()
set_value(widget::Widget, value) = XXX()

## items to select from
get_items(widget::Widget) = XXX()
set_items(widget::Widget, items) = XXX()

## size
width(widget::Widget) = winfo(widget, "width") | int
set_width(widget::Widget, value::Integer) = widget[:width] = value


height(widget::Widget) = winfo(widget, "height") | int
set_height(widget::Widget, value::Integer) = widget[:height] = value

get_size(widget::Widget) = [get_width(widget), get_height(widget)]
function set_size(widget::Widget, width::Integer, height::Integer)
    set_width(widget, width)
    set_height(widget, height)
end
set_size(widget::Widget, value::Array{Integer}) = set_size(widget, value[1], value[2])

## sensitive to user input
get_enabled(widget::Widget) = XXX()
get_enabled(widget::TTk_Widget) = instate(widget, "!disabled")

set_enabled(widget::Widget, value::Bool) = XXX()
set_enabled(widget::TTk_Widget, value::Bool) = widget[:state] = value ? "!disabled" : "disabled"
    

## can be edited
get_editable(widget::Widget) = XXX()
get_editable(widget::TTk_Widget) = instate(widget, "!readonly")

set_editable(widget::Widget, value::Bool) = XXX()
set_editable(widget::TTk_Widget, value::Bool) = widget[:state] = value ? "!readonly" : "readonly"

## hide/show widget
get_visible(widget::Widget) = XXX()
set_visible(widget::Widget, value::Bool) = XXX()

## set focus
focus(widget::Widget) = tcl("focus", widget)
raise(widget::Widget) = tcl("raise", widget)

## does widget exist?
exists(widget::Widget) = winfo(widget, "exists") == "1"
