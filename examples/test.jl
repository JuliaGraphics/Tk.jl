# # Widget Test Example
# This example creates a window with various widgets and a change handler.

using Tk

w = Toplevel("Test window", false)
# pack in tk frame for themed widgets
f = Frame(w)
configure(f, Dict(:padding => [3,3,2,2], :relief=>"groove"))
pack(f, expand=true, fill="both")

# widgets
b  = Button(f, "one")
cb = Checkbutton(f, "checkbutton")
rg = Radio(f, ["one", "two", "three"])
sc = Slider(f, 1:10)
sl = Spinbox(f, 1:10)
e  = Entry(f, "starting text")
widgets = (b, cb, rg, sc, sl, e)

# packing
map(u -> formlayout(u, "label"), widgets)

# bind a callback to each widget
change_handler(path, xs...) = println(map(get_value, widgets))
map(u -> callback_add(u, change_handler), widgets)

set_visible(w, true)
