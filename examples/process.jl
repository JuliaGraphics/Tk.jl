f = "radio.png"

function process_file(f)
    a = readall(`base64 $f`) | chomp
    "<!-- $f -->\n<img src='data:image/png;base64,$a'></img>"
end

process_file(f)
