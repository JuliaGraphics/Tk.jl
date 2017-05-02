using Tk
using Graphics

function sketch_window()
    w = Window("drawing", 400, 300)
    canvas = Canvas(w)
    pack(canvas, expand=true)
    ctx = getgc(canvas)

    set_source_rgb(ctx, 1, 1, 1)
    paint(ctx)
    reveal(canvas)

    set_source_rgb(ctx, 0, 0, 0.85)
    pressed = false
    points = []

    canvas.mouse.button1press = function (c, x, y)
        pressed = true
        push!(points, (x, y))
        move_to(ctx, x, y)
    end

    canvas.mouse.button1release = function (c, x, y)
        pressed = false
        empty!(points)
    end

    canvas.mouse.button1motion = function (c, x, y)
        if pressed
            push!(points, (x, y))
            for (a,b) in points
                line_to(ctx, a, b)
            end
            stroke(ctx)
            reveal(canvas)
            Tk.update()
        end
    end
end

sketch_window()
