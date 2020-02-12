f = "logo.gif"
using Base64

function process_file(f)
    a = readchomp(`cat $f`)
    "<!-- $f -->\n<img src='data:image/gif;base64,$(base64encode(a))'></img>"
end

process_file(f)
