## Tests
using Tk
using Test

@testset "Toplevel" begin
    w = Toplevel("Toplevel", 400, 400)
    set_position(w, 10, 10)
    @test get_value(w) == "Toplevel"
    set_value(w, "Toplevel 2")
    @test get_value(w) == "Toplevel 2"
    @test get_size(w) == [400, 400]
    p = toplevel(w)
    @test p == w
    destroy(w)
    @test !exists(w)
end

@testset "Frame" begin
    w = Toplevel("Frame", 400, 400)
    pack_stop_propagate(w)
    f = Frame(w)
    pack(f, expand=true, fill="both")
    @test get_size(w) == [400, 400]
    p = toplevel(f)
    @test p == w
    destroy(w)
end

@testset "Labelframe" begin
    w = Toplevel("Labelframe", 400, 400)
    pack_stop_propagate(w)
    f = Labelframe(w, "Label")
    pack(f, expand=true, fill="both")
    set_value(f, "new label")
    @test get_value(f) == "new label"
    p = toplevel(f)
    @test p == w
    destroy(w)
end

@testset "Notebook" begin
    w = Toplevel("Notebook")
    nb = Notebook(w); pack(nb, expand=true, fill="both")
    page_add(Button(nb, "one"), "tab one")
    page_add(Button(nb, "two"), "tab two")
    page_add(Button(nb, "three"), "tab three")
    @test Tk.no_tabs(nb) == 3
    set_value(nb, 2)
    @test get_value(nb) == 2
    destroy(w)
end

@testset "Panedwindow" begin
    w = Toplevel("Panedwindow", 400, 400)
    pack_stop_propagate(w)
    pw = Panedwindow(w, "horizontal"); pack(pw, expand=true, fill="both")
    page_add(Button(pw, "one"), 1)
    page_add(Button(pw, "two"), 1)
    page_add(Button(pw, "three"), 1)
    set_value(pw, 100)
    destroy(w)
end

@testset "pack Anchor" begin
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
end

## example of last in first covered
## Create this GUI, then shrink window with the mouse
@testset "Last in, first covered" begin
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
end


@testset "Grid" begin
    w = Toplevel("Grid", 400, 400)
    pack_stop_propagate(w)
    f = Frame(w); pack(f, expand=true, fill="both")
    grid(Slider(f, 1:10, orient="vertical"), 1:3, 1)
    grid(Slider(f, 1:10), 1  , 2:3, sticky="news")
    grid(Button(f, "2,2"), 2  , 2)
    grid(Button(f, "2,3"), 2  , 3)
    destroy(w)
end

@testset "Formlayout" begin
    w = Toplevel("Formlayout")
    f = Frame(w); pack(f, expand=true, fill="both")
    map(u -> formlayout(Entry(f, u), u), ["one", "two", "three"])
    destroy(w)
end

@testset "Widgets" begin
    global ctr = 1
    function cb(path)
        global ctr
        ctr += 1
    end
    global choices = ["choice one", "choice two", "choice three"]

    @testset "button, label" begin
        w = Toplevel("Widgets")
        f = Frame(w); pack(f, expand=true, fill="both")
        l = Label(f, "label")
        b = Button(f, "button")
        map(pack, (l, b))

        set_value(l, "new label")
        @test get_value(l) == "new label"
        set_value(b, "new label")
        @test get_value(b) == "new label"

        bind(b, "command", cb)
        tcl(b, "invoke")
        @test ctr == 2
        img = Image(joinpath(dirname(@__FILE__), "..", "examples", "weather-overcast.gif"))
        map(u-> configure(u, image=img, compound="left"), (l,b))
        destroy(w)
    end

    @testset "checkbox" begin
        w = Toplevel("Checkbutton")
        f = Frame(w)
        pack(f, expand=true, fill="both")
        check = Checkbutton(f, "check me"); pack(check)
        set_value(check, true)
        @test get_value(check) == true
        set_items(check, "new label")
        @test get_items(check) == "new label"
        ctr = 1
        bind(check, "command", cb)
        tcl(check, "invoke")
        @test ctr == 2
        destroy(w)
    end

    @testset "radio" begin
        w = Toplevel("Radio")
        f = Frame(w)
        pack(f, expand=true, fill="both")
        r = Radio(f, choices); pack(r)
        set_value(r, choices[1])
        @test get_value(r) == choices[1]
        set_value(r, 2)                         #  by index
        @test get_value(r) == choices[2]
        @test get_items(r) == choices
        destroy(w)
    end

    @testset "combobox" begin
        w = Toplevel("Combobox")
        f = Frame(w)
        pack(f, expand=true, fill="both")
        combo = Combobox(f, choices); pack(combo)
        set_editable(combo, false)              # default
        set_value(combo, choices[1])
        @test get_value(combo) == choices[1]
        set_value(combo, 2)                         #  by index
        @test get_value(combo) == choices[2]
        set_value(combo, nothing)
        @test get_value(combo) == nothing
        set_items(combo, map(uppercase, choices))
        set_value(combo, 2)
        @test get_value(combo) == uppercase(choices[2])
        set_items(combo, Dict(:one=>"ONE", :two=>"TWO"))
        set_value(combo, "one")
        @test get_value(combo) == "one"
        destroy(w)
    end

    @testset "slider" begin
        w = Toplevel("Slider")
        f = Frame(w)
        pack(f, expand=true, fill="both")
        sl = Slider(f, 1:10, orient="vertical"); pack(sl)
        set_value(sl, 3)
        @test get_value(sl) == 3
        bind(sl, "command", cb) ## can't test
        destroy(w)
    end

    @testset "spinbox" begin
        w = Toplevel("Spinbox")
        f = Frame(w)
        pack(f, expand=true, fill="both")
        sp = Spinbox(f, 1:10); pack(sp)
        set_value(sp, 3)
        @test get_value(sp) == 3
        destroy(w)
    end

    @testset "progressbar" begin
        w = Toplevel("Progress bar")
        f = Frame(w)
        pack(f, expand=true, fill="both")
        pb = Progressbar(f, orient="horizontal"); pack(pb)
        set_value(pb, 50)
        @test get_value(pb) == 50
        configure(pb, mode = "indeterminate")
        destroy(w)
    end
end

@testset "Entry" begin
    w = Toplevel("Entry")
    f = Frame(w)
    pack(f, expand=true, fill="both")
    e = Entry(f, "initial"); pack(e)
    set_value(e, "new text")
    @test get_value(e) == "new text"
    set_value(e, "[1,2,3]")
    @test get_value(e) == "[1,2,3]"
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
end

@testset "Text" begin
    w = Toplevel("Text")
    pack_stop_propagate(w)
    f = Frame(w); pack(f, expand=true, fill="both")
    txt = Tk.Text(f)
    scrollbars_add(f, txt)
    set_value(txt, "new text\n")
    @test get_value(txt) == "new text\n"
    set_value(txt, "[1,2,3]")
    @test get_value(txt) == "[1,2,3]"
    destroy(w)
end

@testset "tree. Listbox" begin
    w = Toplevel("Listbox")
    pack_stop_propagate(w)
    f = Frame(w); pack(f, expand=true, fill="both")
    tr = Treeview(f, choices)
    ## XXX scrollbars_add(f, tr)
    set_value(tr, 2)
    @test get_value(tr)[1] == choices[2]
    set_items(tr, choices[1:2])
    destroy(w)
end

@testset "tree grid" begin
    w = Toplevel("Array")
    pack_stop_propagate(w)
    f = Frame(w); pack(f, expand=true, fill="both")
    tr = Treeview(f, hcat(choices, choices))
    tree_key_header(tr, "right"); tree_key_width(tr, 50)
    tree_headers(tr, ["left"], [50])
    scrollbars_add(f, tr)
    set_value(tr, 2)
    @test get_value(tr)[1] == choices[2]
    destroy(w)
end

@testset "Canvas" begin
    w = Toplevel("Canvas")
    pack_stop_propagate(w)
    f = Frame(w); pack(f, expand=true, fill="both")
    c = Canvas(f)
    @test parent(c) == f.w
    @test toplevel(c) == w
    destroy(w)
end

## Examples
# Wrap each test in its own module to avoid namespace leaks between files
const exampledir = joinpath(splitdir(splitdir(@__FILE__)[1])[1], "examples")
dcur = pwd()
cd(exampledir)

# TODO: Uncomment when Winston supports 0.6
#module example_manipulate
#    if Pkg.installed("Winston")!=nothing
#        include("../examples/manipulate.jl")
#    end
#end


module example_process
    using Test
    @static if Sys.isunix()
    @testset "Examples_Process" begin
    @test_nowarn include(joinpath("..","examples","process.jl"))
    end
    end
end
module example_sketch
    using Test
    @testset "Examples_Sketch" begin
    @test_nowarn include(joinpath("..","examples","sketch.jl"))
    end
end
module example_test
    using Test
    @testset "Examples_Test" begin
    @test_nowarn include(joinpath("..","examples","test.jl"))
    @test_nowarn destroy(w)
    end
end
module example_workspace
    using Test
    @testset "Examples_Workspace" begin
    @test_nowarn include(joinpath("..","examples","workspace.jl"))
    @test_nowarn aft.stop()
    sleep(1.5)
    @test_nowarn destroy(w)
    end
end

cd(dcur)
