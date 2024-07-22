using Documenter, Literate
using Tk

dir = @__DIR__
Literate.markdown(joinpath(dirname(dir), "examples", "manipulate.jl"), joinpath(dir, "src", "examples"); documenter=true)
Literate.markdown(joinpath(dirname(dir), "examples", "process.jl"), joinpath(dir, "src", "examples"); documenter=true)
Literate.markdown(joinpath(dirname(dir), "examples", "sketch.jl"), joinpath(dir, "src", "examples"); documenter=true)
Literate.markdown(joinpath(dirname(dir), "examples", "test.jl"), joinpath(dir, "src", "examples"); documenter=true)

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

deploydocs(repo = "github.com/JuliaGraphics/Tk.jl.git")
