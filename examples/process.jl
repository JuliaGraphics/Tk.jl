f = "radio.png"

function process_file(f)
    a = readchomp(`base64 $f`)
    "<!-- $f -->\n<img src='data:image/png;base64,$a'></img>"
end

process_file(f)
