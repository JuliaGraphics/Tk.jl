using Documenter, Literate
using Tk

Literate.markdown("../examples/manipulate.jl", "src/examples"; documenter=true)
Literate.markdown("../examples/process.jl", "src/examples"; documenter=true)
Literate.markdown("../examples/sketch.jl", "src/examples"; documenter=true)
Literate.markdown("../examples/test.jl", "src/examples"; documenter=true)

makedocs(modules = [Tk],
        sitename = "Tk.jl",
        pages = Any[
            "Home" => "index.md",
            "More" => Any[
                "Manipulate" => "examples/manipulate.md",
                "Process" => "examples/process.md",
                "Sketch" => "examples/sketch.md",
                "Test" => "examples/test.md"
            ],
       "API Reference" => "api.md"
   ])
