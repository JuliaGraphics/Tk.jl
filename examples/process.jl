# # File Processing Example
# This example demonstrates encoding a file as a base64 data URI.

using Tk
using Base64

function process_file(f)
    data = read(f)
    "<!-- $(basename(f)) -->\n<img src='data:image/gif;base64,$(base64encode(data))'></img>"
end

f = joinpath(pkgdir(Tk), "examples", "logo.gif")
process_file(f)
