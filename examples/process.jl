f = "radio.png"
using Base64

function process_file(f)
    a = readchomp(`cat $f`)
    "<!-- $f -->\n<img src='data:image/png;base64,$(base64encode(a))'></img>"
end

process_file(f)
