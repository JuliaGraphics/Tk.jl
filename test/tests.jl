## Tests
using Tk

## Toplevel
w = Toplevel("Toplevel", 400, 400)
set_position(w, 10, 10)
@assert get_value(w) == "Toplevel"
set_value(w, "Toplevel 2")
@assert get_value(w) == "Toplevel 2"
@assert get_size(w) == [400, 400]
p = toplevel(w)
@assert p == w
destroy(w)
@assert !exists(w)

## Frame
w = Toplevel("Frame", 400, 400)
pack_stop_propagate(w)
f = Frame(w)
pack(f, expand=true, fill="both")
@assert get_size(w) == [400, 400]
p = toplevel(f)
@assert p == w
destroy(w)

## Labelframe
w = Toplevel("Labelframe", 400, 400)
pack_stop_propagate(w)
f = Labelframe(w, "Label")
pack(f, expand=true, fill="both")
set_value(f, "new label")
@assert get_value(f) == "new label"
p = toplevel(f)
@assert p == w
destroy(w)

## notebook
w = Toplevel("Notebook")
nb = Notebook(w); pack(nb, expand=true, fill="both")
page_add(Button(nb, "one"), "tab one")
page_add(Button(nb, "two"), "tab two")
page_add(Button(nb, "three"), "tab three")
@assert Tk.no_tabs(nb) == 3
set_value(nb, 2)
@assert get_value(nb) == 2
destroy(w)

## Panedwindow
w = Toplevel("Panedwindow", 400, 400)
pack_stop_propagate(w)
pw = Panedwindow(w, "horizontal"); pack(pw, expand=true, fill="both")
page_add(Button(pw, "one"), 1)
page_add(Button(pw, "two"), 1)
page_add(Button(pw, "three"), 1)
set_value(pw, 100)
destroy(w)

## pack Anchor
w = Toplevel("Anchor argument", 500, 500)
pack_stop_propagate(w)
f = Frame(w, padding = [3,3,12,12]); pack(f, expand = true, fill = "both")
tr = Frame(f); mr = Frame(f); br = Frame(f)
map(u -> pack(u, expand =true, fill="both"), (tr, mr, br))
pack(Label(tr, "nw"), anchor = "nw", expand = true, side = "left")
pack(Label(tr, "n"),  anchor = "n",  expand = true, side = "left")
pack(Label(tr, "ne"), anchor = "ne", expand = true, side = "left")
##
pack(Label(mr, "w"),       anchor = "w",       expand =true, side ="left")
pack(Label(mr, "center"),  anchor = "center",  expand =true, side ="left")
pack(Label(mr, "e"),       anchor = "e",       expand =true, side ="left")
##
pack(Label(br, "sw"), anchor = "sw", expand = true,  side = "left")
pack(Label(br, "s"),  anchor = "s",  expand = true,  side = "left")
pack(Label(br, "se"), anchor = "se", expand = true,  side = "left")
destroy(w)

## example of last in first covered
## Create this GUI, then shrink window with the mouse
w = Toplevel("Last in, first covered", 400, 400)
f = Frame(w)

g1 = Frame(f)
g2 = Frame(f)
map(u -> pack(u, expand=true, fill="both"), (f, g1, g2))

b11 = Button(g1, "first")
b12 = Button(g1, "second")
b21 = Button(g2, "first")
b22 = Button(g2, "second")

map(u -> pack(u, side="left"),  (b11, b12))
map(u -> pack(u, side="right"), (b21, b22))
## Now shrink window
destroy(w)


## Grid
w = Toplevel("Grid", 400, 400)
pack_stop_propagate(w)
f = Frame(w); pack(f, expand=true, fill="both")
grid(Slider(f, 1:10, orient="vertical"), 1:3, 1)
grid(Slider(f, 1:10), 1  , 2:3, sticky="news")
grid(Button(f, "2,2"), 2  , 2)
grid(Button(f, "2,3"), 2  , 3)
destroy(w)

## Formlayout
w = Toplevel("Formlayout")
f = Frame(w); pack(f, expand=true, fill="both")
map(u -> formlayout(Entry(f, u), u), ["one", "two", "three"])
destroy(w)

## Widgets

## button, label
w = Toplevel("Widgets")
f = Frame(w); pack(f, expand=true, fill="both")
l = Label(f, "label")
b = Button(f, "button")
map(pack, (l, b))

set_value(l, "new label")
@assert get_value(l) == "new label"
set_value(b, "new label")
@assert get_value(b) == "new label"
ctr = 1
function cb(path)
    global ctr
    ctr = ctr + 1
end
bind(b, "command", cb)
tcl(b, "invoke")
@assert ctr == 2
img = Image(Pkg.dir("Tk", "examples", "weather-overcast.gif"))
map(u-> configure(u, image=img, compound="left"), (l,b))
destroy(w)

## checkbox
w = Toplevel("Checkbutton")
f = Frame(w)
pack(f, expand=true, fill="both")
check = Checkbutton(f, "check me"); pack(check)
set_value(check, true)
@assert get_value(check) == true
set_items(check, "new label")
@assert get_items(check) == "new label"
ctr = 1
bind(check, "command", cb)
tcl(check, "invoke")
@assert ctr == 2
destroy(w)

## radio
choices = ["choice one", "choice two", "choice three"]
w = Toplevel("Radio")
f = Frame(w)
pack(f, expand=true, fill="both")
r = Radio(f, choices); pack(r)
set_value(r, choices[1])
@assert get_value(r) == choices[1]
set_value(r, 2)                         #  by index
@assert get_value(r) == choices[2]
@assert get_items(r) == choices
destroy(w)

## combobox
w = Toplevel("Combobox")
f = Frame(w)
pack(f, expand=true, fill="both")
combo = Combobox(f, choices); pack(combo)
set_editable(combo, false)              # default
set_value(combo, choices[1])
@assert get_value(combo) == choices[1]
set_value(combo, 2)                         #  by index
@assert get_value(combo) == choices[2]
set_value(combo, nothing)
@assert get_value(combo) == nothing
set_items(combo, map(uppercase, choices))
set_value(combo, 2)
@assert get_value(combo) == uppercase(choices[2])
set_items(combo, {:one=>"ONE", :two=>"TWO"})
set_value(combo, "one")
@assert get_value(combo) == "one"
destroy(w)


## slider
w = Toplevel("Slider")
f = Frame(w)
pack(f, expand=true, fill="both")
sl = Slider(f, 1:10, orient="vertical"); pack(sl)
set_value(sl, 3)
@assert get_value(sl) == 3
bind(sl, "command", cb) ## can't test
destroy(w)

## spinbox
w = Toplevel("Spinbox")
f = Frame(w)
pack(f, expand=true, fill="both")
sp = Spinbox(f, 1:10); pack(sp)
set_value(sp, 3)
@assert get_value(sp) == 3
destroy(w)

## progressbar
w = Toplevel("Progress bar")
f = Frame(w)
pack(f, expand=true, fill="both")
pb = Progressbar(f, orient="horizontal"); pack(pb)
set_value(pb, 50)
@assert get_value(pb) == 50
configure(pb, mode = "indeterminate")
destroy(w)


## Entry
w = Toplevel("Entry")
f = Frame(w)
pack(f, expand=true, fill="both")
e = Entry(f, "initial"); pack(e)
set_value(e, "new text")
@assert get_value(e) == "new text"
set_visible(e, false)
set_visible(e, true)
## Validation
function validatecommand(path, s, S)
    println("old $s, new $S")
    s == "invalid" ? tcl("expr", "FALSE") : tcl("expr", "TRUE")     # *must* return logical in this way
end
function invalidcommand(path, W)
    println("called when invalid")
    tcl(W, "delete", "@0", "end")
    tcl(W, "insert", "@0", "new text")
end
configure(e, validate="key", validatecommand=validatecommand, invalidcommand=invalidcommand)
destroy(w)

## Text
w = Toplevel("Text")
pack_stop_propagate(w)
f = Frame(w); pack(f, expand=true, fill="both")
txt = Text(f)
scrollbars_add(f, txt)
set_value(txt, "new text\n")
@assert get_value(txt) == "new text\n"
destroy(w)

## tree. Listbox
w = Toplevel("Listbox")
pack_stop_propagate(w)
f = Frame(w); pack(f, expand=true, fill="both")
tr = Treeview(f, choices)
## XXX scrollbars_add(f, tr)
set_value(tr, 2)
@assert get_value(tr)[1] == choices[2]
set_items(tr, choices[1:2])
destroy(w)

## tree grid
w = Toplevel("Array")
pack_stop_propagate(w)
f = Frame(w); pack(f, expand=true, fill="both")
tr = Treeview(f, hcat(choices, choices))
tree_key_header(tr, "right"); tree_key_width(tr, 50)
tree_headers(tr, ["left"], [50])
scrollbars_add(f, tr)
set_value(tr, 2)
@assert get_value(tr)[1] == choices[2]
destroy(w)

## Canvas
w = Toplevel("Canvas")
pack_stop_propagate(w)
f = Frame(w); pack(f, expand=true, fill="both")
c = Canvas(f)
@assert parent(c) == f.w
@assert toplevel(c) == w
destroy(w)
