## Additional methods to give simplified interface to the Tk widgets created in this package

XXX() = error("No default method.")

## Main value
get_value(widget::Widget) = XXX()
set_value(widget::Widget, value) = XXX()

## items to select from
get_items(widget::Widget) = XXX()
set_items(widget::Widget, items) = XXX()

## size of widgets have three possible values:
## geometry -- actual size when drawn (winfo info)
## reqwidth -- may not be satisfied by window sizing algorithm. 
## that reported by -width property
## width, height, get_size refer to that drawn:
width(widget::Widget) = winfo(widget, "width") | float | int
height(widget::Widget) = winfo(widget, "height") | float | int
get_size(widget::Widget) = [width(widget), height(widget)]

## setting is different. 
## Toplevel windows are set by geometry and wm
## Other widgets *may* have a -width, -height property for setting a requested width and height that gets set
## may or may not be in pixels
## as getting and setting would be different, we skip the setting part
## a user can set the requested size with w[:width] = width, or w[:height] = height.
## (Or for sliders, w[:length] = width_or_height
## Changing the requested width will usually cause the geometry to recompute
## to force this, one has wm(toplevel, "geometry", "{}")
set_size(widget::Widget, args...) = XXX()


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
