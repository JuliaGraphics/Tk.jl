## The Tk Package

This package provides an interface to the Tcl/Tk libraries, useful for creating graphical user interfaces. The basic functionality is provided by the `tcl_eval` function, which is used to pass on Tcl commands. The `Canvas` widget is used to create a device for plotting of `julia`'s graphics. In particular, the `Winston` and `Images` package can render to such a device.

In addition, there are convenience methods for working with most of
the widgets provided by `Tk`. The `tcl` function is a wrapper for
`tcl_eval` which provides translations from `julia` objects into Tcl
constructs. This function is similar to the one found in `R`'s `tcltk`
package. Following that package, we provides several basic functions
to simplify the interface for working with Tk.



### Constructors

Constructors are provided  for the following widgets

* `Toplevel`: for toplevel windows
* `Frame`, `Labelframe`, `Notebook`, `Panedwindow`: for the basic containers
* `Label`, `Button`, `Menu`: basic elements
* `Checkbutton`, `Radio`, `Combobox`, `Slider`, `Spinbox`: selection widgets
* `Entry`, `Text`: text widgets
* `Treeview`: for trees, but also listboxes and grids
* `Sizegrip`, `Separator`, `Progressbar`, `Image` various widgets

The basic usage simply calls the `ttk::` counterpart, though one can
use a Dict to pass in configuration options. As well, some have a
convenience interfaces.

### Methods

In addition to providing  constructors, there are some convenience methods defined.

* The `tk_configure`, `tk_cget`, `tclvar`, `tk_identify`, `tk_state`,
  `tk_instate`, `tk_winfo`, `tk_wm`, `tk_bind` methods to simplify the
  corresponding Tcl commands.

* For widget layout, we have  `pack`, `pack_configure`, `forget`, `grid`,
  `grid_configure`, `grid_forget`, ... providing interfaces to the appropriate Tk commands, but also
   `formlayout` and `page_add` for working with simple forms and notebooks and pane windows..

* We add the methods `get_value` and `set_value` to get and set the
  primary value for a control

* We add the methods `get_items` and `set_items` to get and set the
  item(s) to select from for selection widgets.

* We add the methods `get_width`, `get_height`, `get_size`, `set_width`,
  `set_height`, `set_size` for adjusting sizes. (Resizing a window
  with the mouse does strange things on a Mac ...)

* The conveniences `get_enabled` and `set_enabled` to specify if a
  widget accepts user input


## Examples

A simple "Hello world" example, which shows off many of the styles is given by:

```
w = Toplevel("Example")                                    ## A titled top level window
f = Frame(w, {:padding => [3,3,2,2], :relief=>"groove"})   ## A Frame with some options set
pack(f, {:expand => true, :fill => "both"})                ## using pack to manage the layout of f
#
b = Button(f, "Click for a message")                       ## Button constructor has convenience interface
grid(b, 1, 1)                                              ## use grid to pack in b. 1,1 specifies location
#
callback(path) = Messagebox(w, "A message", "Hello World") ## A callback to open a message
tk_bind(b, "command", callback)                            ## bind callback to 'command' option	 
tk_bind(b, "<Return>", callback)                           ## press return key when button has focus
```

We see the use of an internal frame to hold the button. The frames
layout is managed using `pack`, the buttons with `grid`. Both these
have some conveniences. For grid, the location of the cell can be
specified by 1-based index as shown. The button callback is just a
`julia` function. Its first argument, `path`, is used internally. In
this case, we open a modal dialog with the `Messagebox` constructor
when the callback is called. The button object has this callback bound
to the button's `command` option. This responds to a mouse click, but
not a press of the `enter` key when the button has the focus. For
that, we also bind to the '<Return>' event.


For the R package `tctlk` there are numerous examples at
http://bioinf.wehi.edu.au/~wettenhall/RTclTkExamples/

We borrow a few of these to illustrate the `Tk` package for `julia`.

The `Tk` package provides some convenience constructors. We
follow Tk's convention of capitalizing the first letter, so
`ttk::checkbutton` is `Checkbutton`. As well, we have the function
`tcl` as a more convenient alternative to `Tk.tcl_eval` and some
helpers like `tk_configure` and `tk_cget`.  In addition, the package
provides a few non-standard methods for interacting with the widgets
in a generic manner: `get_value`, `set_value`, ...

`Tk` commands are combined strings followed by options. Something
like: `.button configure -text {button text}` is called as
`tk_configure(button, {:text => "button text})`. key-value options are
specified with a Dict, which converts to the underlying Tcl
object. Similarly, path names are also translated and functions are
converted to callbacks.


### Pack widgets into a themed widget for better appearance

`Toplevel` is the command to create a new top-level
window. (`Tk.Window` is similar, but we give `Toplevel` a unique type
allowing us to add methods, such as `set_value` to modify the title.)
Toplevel windows play a special role, as they start the widget
hierarchy needed when constructing child components.

A toplevel window is not a themed widget. Immediately packing in a
`Frame` instance is good practice, as otherwise the background of the
window may show through:

```
w = Toplevel()
f = Frame(w)
pack(f, {:expand=>true, :fill=>"both"})
```

#### Notes:

* Sometimes the frame is configured with padding so that the sizegrip
  shows, e.g. `frame(w,{:padding => [3,3,2,2]})`.

* The above will get the size from the frame -- which has no
  request. This means the window will disappear. You may want to force
  the size to come from the toplevel window. You can use `tcl("pack",
  "propagate", w, false)` (aliased to `pack_stop_propagate` to get
  this:)

```
w = Toplevel("title", 400, 300)	## title, width, height
pack_stop_propagate(w)
f = Frame(w)
pack(f, {:expand=>true, :fill=>"both"})
```

* resizing toplevel windows can leave visual artifacts, at least on a
  Mac. This is not optimal!

<img src="munged-window.png"></img>

### Message Box

The `Messagebox` constructor makes a modal message box.

```
Messagebox("title", "message")
```

An optional `parent` argument can be specified to locate the box near
the parent, as seen in the examples.

### Checkbuttons

<img src="checkbutton.png" > </img>

Check boxes are constructed with `Checkbutton`:

```
w = Toplevel()
cb = Checkbutton(w, "I like Julia")
pack(cb)

function callback(path)		   ## callbacks have at least one argument
  value = get_value(cb)
  msg = value ? "Glad to hear that" : "Sorry to hear that"
  Messagebox(w, "Thanks for the feedback", msg)
end	 

tk_bind(cb, "command", callback)   ## bind to command option
```

The `set_items` method can be used to change the label.


### Radio buttons

<img src="radio.png" > </img>

```
w = Toplevel()
f = Frame(w)
pack(f, {:expand=>true, :fill=>"both"})

l  = Label(f, "Which do you prefer?")
rb = Radio(f, ["apples", "oranges"])
b  = Button(f, "ok")
map(u -> pack(u, {:anchor => "w"}), (l, rb, b))     ## pack in left to right


function callback(path) 
  msg = (get_value(rb) == "apples") ? "Good choice!  An apple a day keeps the doctor away!" : 
                                      "Good choice!  Oranges are full of Vitamin C!"
  Messagebox(w, "Title:", msg)
end

tk_bind(b, "command", callback)
```

The individual buttons can be accessed via `[`, as in `rb[1]`. This
allows one to edit the labels, as in

```
set_items(rb[1], "Honeycrisp Apples")  
```

(The `set_items` method is used to set the items for a selection
widget, in this case the lone item is the name, or label of the
button.)

### Menus

Menu bars for toplevel windows are easily created with the `menu_add`
method. One can add actions items (pass a callback function), check
buttons, radio buttons, or separators.


```
w = Toplevel()
tcl("pack", "propagate", w, false) ## or pack_stop_propagate(w)

mb = Menu(w)			## makes menu, adds to top-level window
fmenu = menu_add(mb, "File")	
omenu = menu_add(mb, "Options")

menu_add(fmenu, "Open file...", (path) -> println("Open file dialog, ..."))
menu_add(fmenu, Separator(w))	## second argument is Tk_Separator instance
menu_add(fmenu, "Close window", (path) -> destroy(w))

cb = Checkbutton(w, "Something visible")
set_value(cb, true)		## initialize
menu_add(omenu, cb)		## second argument is Tk_Checkbutton instance

menu_add(omenu, Separator(w))	## put in a separator

rb = Radio(w, ["option 1", "option 2"])
set_value(rb, "option 1")	## initialize
menu_add(omenu, rb)		## second argument is Tk_Radio instance

b = Button(w, "print selected options")
pack(b, {:expand=>true, :fill=>"both"})

function callback(path)
  vals = map(get_value, (cb, rb))
  println(vals)
end	 

callback_add(b, callback)	## generic way to add callback for most common event
)
```


### Entry widget

<img src="entry.png"></img>

The entry widget can be used to collect data from the user.

```
w = Toplevel()
f = Frame(w); pack(f, {:expand=>true, :fill=>"both"})

e = Entry(f)
b = Button(f, "Ok")

formlayout(e, "First name:")
formlayout(b, nothing)
focus(e)			## put keyboard focus on widget

function callback(path) 
  val = get_value(e)
  msg = "You have a nice name $val"
  Messagebox(w, "Title", msg)
end

tk_bind(b, "command", callback)
tk_bind(b, "<Return>", callback)
tk_bind(e, "<Return>", callback)  ## bind to a certain key press event
```

### Listboxes

<img src="listbox.png"></img>

There is no `Listbox` constructor, rather we replicate this with
`Treeview` simply by passing a vector of strings. Here we use a
scrollbar too:

```
fruits = ["Apple", "Orange", "Banana", "Pear"]
w = Toplevel("Favorite fruit?")
tcl("pack", "propagate", w, false)
f = Frame(w)
pack(f, {:expand=>true, :fill=>"both"})

f1 = Frame(f)			## need internal frame for use with scrollbars
lb = Treeview(f1, fruits)
scrollbars_add(f1, lb)
pack(f1,  {:expand=>true, :fill=>"both"})

b = Button(f, "Ok")
pack(b)

function callback(path)
	 fruit_choice = get_value(lb)
	 msg = (fruit_choice == nothing) ? "What, no choice?" : "Good choice! $(fruit_choice[1])" * "s are delicious!"
	 Messagebox(w, "title", msg)
end
tk_bind(b, "command", callback)
```

The value returned by `get_value` is an array or `nothing`. Returning
`nothing` may not be the best choice, perhaps a 0-length array is
better?

One can configure the `selectmode`. E.g. `tk_configure(lb,
{:selectmode => "extended"})` with either `extended` (multiple
selection possible, `browse` (single selection), or `none` (no
selection).)

The `Treeview` widget can also display a matrix of strings in a grid
in addition to tree-like data.

An editable grid could be done, but requires some additional Tk
libraries.

### Combo boxes

Selection from a list of choices can be done with a combo box:

<img src="combo.png" > </img>

```
fruits = ["Apple", "Orange", "Banana", "Pear"]

w = Toplevel("Combo boxes", 300, 200)
tcl("pack", "propagate", w, false)
f = Frame(w); pack(f, {:expand=>true, :fill=>"both"})

grid(Label(f, "Again, What is your favorite fruit?"), 1, 1)
cb = Combobox(f, fruits)
grid(cb, 2,1, {:sticky=>"ew"})

b = Button(f, "Ok")
grid(b, 3, 1)

function callback(path)
  fruit_choice = get_value(cb)
  msg = (fruit_choice == nothing) ? "What, no choice?" : 
                                    "Good choice! $(fruit_choice)" * "s are delicious!"
  Messagebox(w, "title", msg)
end

tk_bind(b, "command", callback)
```


Here no choice also returns `nothing`. Use this value with `set_value`
to clear the selection, if desired.

Editable combo boxes need to be configured by hand. (So combo isn't
really what we have here :)

### Text windows

The basic multi-line text widget can be done through:

```
w = Toplevel()
tcl("pack", "propagate", w, false)
f = Frame(w)
txt = Text(f)
scrollbars_add(f, txt)
pack(f, {:expand=>true, :fill => "both"})
```

Only a `get_value` and `set_value` is provided. One can configure
other things (adding/inserting text, using tags, ...) directly with
`tcl` or `tcl_eval`.

### Events

One can bind a callback to an event in tcltk. There are few things to know:

* Callbacks have at least one argument (we use `path`). With
  `tk_bind`, other arguments are matched by name to correspond to
  tcltk's percent substitution. E.g. `f(path, x, y)` would get values
  for x and y through `%x %y`.

* We show how to bind to a widget event, but this can be more
  general. E.g., toplevel events are for all children of the window a
  style can match all object of that style.

* many widgets have a standard `command` argument in addition to
  window manager events they respond to. This can be passed to
  `tk_bind` as the event.

* The `tk_bind` method does most of the work. The `callback_add`
  method binds to the most common event, mostly the `command`
  one. This can be used to bind the same callback to multiple widgets
  at once.



### Sliders

The `Slider` widget presents a slider for selection from a range of
values. The convenience constructor allows one to specify the range of
values through a Range object:

```
w = Toplevel()
sc = Slider(w, 1:100)
pack(sc)
tk_bind(sc, "command", path -> println("The value is $(get_value(sc))"))
```


### Sharing a variable between widgets

<img src="scale-label.png"></img>

Some widgets have a `textvariable` option. These can be shared to have
automatic synchronization. For example, the scale widget does not have
any indication as to the value, we remedy this with a label.

```
w = Toplevel("Slider and label", 300, 200)
pack_stop_propagate(w)
f = Frame(w); pack(f, {:expand => true, :fill => "both"})

sc = Slider(f, 1:20)
l = Label(f)
tk_configure(l, {:textvariable => tk_cget(sc, "variable") })

pack(sc, {:side=>"left", :expand=>true, :fill=>"x", :anchor=>"w"})
pack(l,  {:side=>"left", :anchor=>"w"})
```

This combination above is not ideal, as the length of the label is not
fixed. It would be better to format the value and use `set_value` in a
callback.

### Spinbox

<img src="scale-spinbox.png"></img>

The scale widget easily lets one pick a value, but it can be hard to
select a precise one. The spinbox makes this easier. Here we link the
two using a callback:

```
w = Toplevel("Slider/Spinbox")
f = Frame(w); pack(f, {:expand => true, :fill => "both"})

sc = Slider(f, 1:100)
sp = Spinbox(f, 1:100)
map(pack, (sc, sp))

tk_bind(sc, "command", path -> set_value(sp, get_value(sc)))
tk_bind(sp, "command", path -> set_value(sc, get_value(sp)))
```
### Images

<img src="image.png"></img>

The `Image` widget can be used to show `gif` files.

```
fname = Pkg.dir("Tk", "examples", "logo.gif")
img = Image(fname)

w = Toplevel("Image")
l = Label(w, img)
pack(l)
```

This example adds an image to a button.

```
fname = Pkg.dir("Tk", "examples", "weather-overcast.gif") ## https://code.google.com/p/ultimate-gnome/
img = Image(fname)

w = Toplevel("Icon in button")
b = Button(w, "weather", img)   ## or: b = Button(w, {:text=>"weather", :image=>img, :compound=>"left"})
pack(b)
```

### Graphics

The obvious desire to embed a graph into a GUI turns out to be not so
simple. Why?

* `Gadfly` makes SVG graphics. This is great for showing in a web
  browser, but not so great with Tk, as there is not SVG viewer. The
  example below can be easily modified.

* `Winston` can render to a `Canvas` object. This should be great, *but* for
  some reason trying to show the canvas object in anything but a
  toplevel window fails. When this issue is fixed, that should work out
  really well.

* In the meantime, we can do the following:

  - write a Winston graphic to a `png` file.

  - convert this to `gif` format via imagemagick's `convert` function,
    which is also used by the `Images` package

  - use that `gif` file through an `Image` object.

The only issue is the asynchronous nature of the `convert` command
requires us to wait until the command is finished to update the
label. The `spawn` command below with all its arguments does this.

```
using Tk
using Winston
using Images ## not used, but installs imagemagick?

type WinstonLabel <: Tk.Tk_Widget
    w
    p
    fname
    WinstonLabel(w) = new(Tk.Label(w), nothing, nothing)
    WinstonLabel(w, args::Dict) = new(Tk.Label(w, args), nothing, nothing)
end

function render(parent::WinstonLabel, p)
    parent.p = p
    if isa(parent.fname, Nothing)
        parent.fname = nm = tempname()
	##	tk_bind(parent, "<Destroy>", map(rm, ("$nm.png", "$nm.gif"))) ## clean up
    end
    nm = parent.fname
    file(p, "$nm.png")
    ## would use imwrite(imread("$nm.png"), "$nm.gif") but need to wait until done to update label
    cmd = `convert $nm.png $nm.gif`     # imagemagick convert from Images
    spawn(false, cmd, (STDIN, STDOUT, STDERR), false, (self) -> begin ## spawn -- not run!
                img = Tk.Image("$nm.gif")
                Tk.tk_configure(parent.w, {:image=>img, :compound => "image"})
            end)
end
    

## The interface
w = Toplevel("demo", 800, 600)
tcl("pack", "propagate", w, false)
pg = Frame(w); pack(pg, {:expand=>true, :fill=>"both"})

f = Labelframe(pg, "Controls"); pack(f, {:side=> "left", :anchor=>"nw"})
img_area = WinstonLabel(pg)
pack(img_area, {:expand => true, :fill=>"both"})

sl = Slider(f, 1:20);
formlayout(sl, "n")

function plot_val(val) 
    x = linspace(0, 1.0, 200)
    y = x.^val
    p = FramedPlot()
    add(p, Curve(x, y))	 

    render(img_area, p)
end
	 
tk_bind(sl, "command", (path) -> plot_val(get_value(sl)))
plot_val(1)			## initial graph
```

If you try this you may find that it isn't great: sometimes the graphic is done; at times a black box
flashes across the screen as the slider is moved.

<img src="manipulate.png"></img>


In the examples directory you can find an implementation of RStudio's
`manipulate` function, which extends this example.  This functions makes it very straightforward to define
basic interactive GUIs for plotting with `Winston`.

To try it, run

```
require(Pkg.dir("Tk", "examples", "manipulate.jl"))
```

The above graphic was produced with:

```
ex = quote
    x = linspace( 0, n * pi, 100 )
    c = cos(x)
    s = sin(x)
    p = FramedPlot()
    setattr(p, "title", title)
    if
        fillbetween add(p, FillBetween(x, c, x, s) )
    end
    add(p, Curve(x, c, "color", color) )
    add(p, Curve(x, s, "color", "blue") )
    file(p, "example1.png")
    p				## return a winston object
end
obj = manipulate(ex,
                 slider("n", "[0, n*pi]", 1:10)
                 ,entry("title", "Title", "title")
                 ,checkbox("fillbetween", "Fill between?", true)
                 ,picker("color", "Cos color", ["red", "green", "yellow"])
                 ,button("update")
                 )
```           


### Frames

The basic widget to hold child widgets is the Frame. As seen in the
previous examples, it is simply constructed with `Frame`. The
`padding` option can be used to give some breathing room.

Laying out child components is done with a layout manager, one of
`pack`, `grid`, or `place` in Tk.

#### pack

For `pack` there are several configuration options that are used to
indicate how packing of child components is to be done. The examples
make use of

* `side`: to indicate the side of the cavity that the child should be
  packed against. Typically "top" to top to bottom packing or "left"
  for left to right packing.

* `anchor`: One of the compass points indicating what part of the
  cavity the child should be attached to.

* `expand`: should the child expand when packed

* `fill`: how should an expanding child fill its space. We use
  `{:expand=>true, :fill=>"both"}` to indicate the child should take
  all the available space it can. Use `"x"` to stetch horizontally,
  and `"y"` to stretch vertically.

Unlike other toolkits (Gtk, Qt), one can pack both horizontally and
vertically within a frame. So to pack horizontally, one must add the
`side` option each time. It can be convenient to do this using a map
by first creating the widgets, then managing them:

```
w = Toplevel("packing example")
f = Frame(w); pack(f, {:expand=>true, :fill=>"both"})
ok_b = Button(f, "Ok")
cancel_b = Button(f, "Cancel")
help_b = Button(f, "Help")
map(u -> pack(u, {:side => "left"}), (ok_b, cancel_b, help_b))
```

#### grid

For `grid`  the arguments are the  row and column. We  use integers or
ranges.  When a  range,  then the  widget  can span  multiple rows  or
columns. Within  a cell, the `sticky` argument  replaces the `expand`,
`fill`,  and `anchor` arguments.  This is  a string  with one  or more
directions  to attach.  A  value of  `news`  is like  `{:expand=>true,
:fill=>"both"}`, as all four sides are attached to.


<img src="grid.png"></img>

```
w = Toplevel("Grid")
f = Frame(w, {:padding => 10}); pack(f, {:expand=>true, :fill=>"both"})

s1 = Slider(f, 1:10)
s2 = Slider(f, 1:10, {:orient=>"vertical"})
b3 = Button(f, "ew sticky")
b4 = Button(f, "ns sticky")

grid(s1, 1, 1:2, {:sticky=>"news"})
grid(s2, 2:3, 2, {:sticky=>"news"})
grid(b3, 2, 1)
grid(b4, 3, 1,   {:sticky=>"ns"}) ## breaks theme
```

We provide the `formlayout` method for conveniently laying out widgets
in a form-like manner, with a label on the left. (Pass `nothing` to
suppress this.)

One thing to keep in mind: *a container in Tk can only employ one
layout style for its immediate children* That is, you can't manage
children both with `pack` and `grid`, though you can nest frames and
mix and match layout managers.


### Notebooks

A notebook container holds various pages and draws tabs to allow the
user to switch between them. The `page_add` method makes this easy:

```
w = Toplevel()
tcl("pack", "propagate", w, false)
nb = Notebook(w)
pack(nb, {:expand=>true, :fill=>"both"})

page1 = Frame(nb)
page_add(page1, "Tab 1")
pack(Button(page1, "page 1"))

page2 = Frame(nb)
page_add(page2, "Tab 2")
pack(Label(page2, "Some label"))

set_value(nb, 2)		## position on page 2
```


### Panedwindows

A paned window allows a user to allocate space between child
components using their mouse. This is done by dragging a "sash". As
with `Notebook` containers, children are added through `page_add`.

```
w = Toplevel("Panedwindow", 800, 300)
tcl("pack", "propagate", w, false)
f = Frame(w); pack(f, {:expand=>true, :fill=>"both"})

pg = Panedwindow(f, "horizontal") ## orientation. Use "vertical" for up down.
grid(pg, 1, 1, {:sticky => "news"})

page_add(Button(pg, "button"))
page_add(Label(pg, "label"))

f = Frame(pg)
formlayout(Entry(f), "Name:")
formlayout(Entry(f), "Rank:")
formlayout(Entry(f), "Serial Number:")
page_add(f)

tcl(pg, "sashpos", 0, 50)  ## move first sash
```
