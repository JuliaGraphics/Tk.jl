# Julia interface to the Tk windowing toolkit.

[![][docs-dev-img]][docs-dev-url] 

[contrib-url]: https://juliadocs.github.io/Documenter.jl/dev/contributing/
[discourse-tag-url]: https://discourse.julialang.org/tags/documenter
[gitter-url]: https://gitter.im/juliadocs/users

[docs-dev-img]: https://img.shields.io/badge/docs-dev-blue.svg
[docs-dev-url]: https://juliagraphics.github.io/Tk.jl/dev

[docs-stable-img]: https://img.shields.io/badge/docs-stable-blue.svg
[docs-stable-url]: https://juliagraphics.github.io/Tk.jl

[issues-url]: https://github.com/JuliaGraphics/Tk.jl/issues

# A simple example

```julia
using Tk

w = Toplevel("Example")                                 ## A titled top level window
f = Frame(w, padding = [3,3,2,2], relief="groove")      ## A Frame with some options set
pack(f, expand = true, fill = "both")                   ## using pack to manage the layout of f

b = Button(f, "Click for a message")                    ## Button constructor has convenience interface
grid(b, 1, 1)                                           ## use grid to pack in b. 1,1 specifies location

## A callback to open a message
callback(path) = Messagebox(w, title="A message", message="Hello World") 
bind(b, "command", callback)                            ## bind callback to 'command' option
bind(b, "<Return>", callback)                           ## press return key when button has focus
```
