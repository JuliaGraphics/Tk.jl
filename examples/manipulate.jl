# Manipulate Example
# Demonstrates interactive controls that dynamically update a Cairo drawing,
# mimicking RStudio's `manipulate` package (inspired by Mathematica).
# Controls: slider, picker, checkbox.

using Tk
import Cairo
using Cairo: set_source_rgb, set_source_rgba, rectangle, move_to, line_to,
             stroke, close_path, set_line_width, paint

const COLORS = Dict(
    "red"    => (1.0, 0.0, 0.0),
    "green"  => (0.0, 0.7, 0.0),
    "yellow" => (0.8, 0.8, 0.0),
    "orange" => (1.0, 0.5, 0.0),
)

function draw_plot(c, n, color_name, fill_between)
    cr = getgc(c)
    w = width(c)
    h = height(c)

    # White background
    set_source_rgb(cr, 1, 1, 1)
    rectangle(cr, 0, 0, w, h)
    Cairo.fill(cr)  # qualified to avoid conflict with Base.fill

    # Plot area with margins
    mx, my = 50, 30
    pw = w - 2mx
    ph = h - 2my

    # Axes
    set_source_rgb(cr, 0, 0, 0)
    set_line_width(cr, 1)
    move_to(cr, mx, my + ph / 2)
    line_to(cr, mx + pw, my + ph / 2)
    stroke(cr)
    move_to(cr, mx, my)
    line_to(cr, mx, my + ph)
    stroke(cr)

    # Compute curves
    npts = 300
    xs = range(0, n * pi, length=npts)
    cos_vals = cos.(xs)
    sin_vals = sin.(xs)
    to_px_x(x) = mx + (x - xs[1]) / (xs[end] - xs[1]) * pw
    to_px_y(y) = my + ph / 2 - y * (ph / 2 - 10)

    # Fill between curves
    if fill_between
        set_source_rgba(cr, 0.5, 0.5, 1.0, 0.15)
        move_to(cr, to_px_x(xs[1]), to_px_y(cos_vals[1]))
        for i in 2:npts
            line_to(cr, to_px_x(xs[i]), to_px_y(cos_vals[i]))
        end
        for i in npts:-1:1
            line_to(cr, to_px_x(xs[i]), to_px_y(sin_vals[i]))
        end
        close_path(cr)
        Cairo.fill(cr)  # qualified to avoid conflict with Base.fill
    end

    # Draw cosine
    r, g, b = get(COLORS, color_name, (1.0, 0.0, 0.0))
    set_source_rgb(cr, r, g, b)
    set_line_width(cr, 2)
    move_to(cr, to_px_x(xs[1]), to_px_y(cos_vals[1]))
    for i in 2:npts
        line_to(cr, to_px_x(xs[i]), to_px_y(cos_vals[i]))
    end
    stroke(cr)

    # Draw sine
    set_source_rgb(cr, 0, 0, 0.85)
    set_line_width(cr, 2)
    move_to(cr, to_px_x(xs[1]), to_px_y(sin_vals[1]))
    for i in 2:npts
        line_to(cr, to_px_x(xs[i]), to_px_y(sin_vals[i]))
    end
    stroke(cr)

    reveal(c)
end

function manipulate_demo()
    w = Toplevel("Manipulate", 700, 500)
    pack_stop_propagate(w)

    graph = Canvas(w)
    pack(graph, side="left", expand=true, fill="both")

    control_pane = Frame(w)
    pack(control_pane, side="right", fill="y", padx=10, pady=10)

    sl = Slider(control_pane, 1:10)
    set_value(sl, 2)
    formlayout(sl, "Periods")

    color_pick = Combobox(control_pane)
    set_items(color_pick, ["red", "green", "yellow", "orange"])
    set_value(color_pick, "red")
    set_editable(color_pick, false)
    formlayout(color_pick, "Cos color")

    fill_cb = Checkbutton(control_pane, "Fill between?")
    set_value(fill_cb, true)
    formlayout(fill_cb, nothing)

    function do_render(args...)
        n = get_value(sl)
        color = get_value(color_pick)
        do_fill = get_value(fill_cb)
        draw_plot(graph, n, color, do_fill)
    end

    callback_add(sl, do_render)
    callback_add(color_pick, do_render)
    callback_add(fill_cb, do_render)

    graph.draw = _ -> do_render()
    graph
end

manipulate_demo()
