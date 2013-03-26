## dialogs

## can add arguments if desired. Don't like names or lack of arguments
GetOpenFile() = tcl("tkGetOpenFile")
GetSaveFile() = tcl("tkGetSaveFile")
ChooseDirectory() = tcl("tk_chooseDirectory")

## Message box
function Messagebox(parent::MaybeWidget, title::MaybeString, message::MaybeString, detail::MaybeString)
    args = Dict()
    if !isa(parent, Nothing) args["parent"] = get_path(parent) end
    args["title"] = title 
    args["message"] = message
    args["detail"] = detail
    args["type"] = "okcancel"
    
    tcl("tk_messageBox", args)
end

Messagebox(parent::Widget, title::String, message::String) = Messagebox(parent, title, message, nothing)
Messagebox(parent::Widget, message::String) = Messagebox(parent, nothing, message, nothing)
Messagebox(title::String, message::String, detail::String) = Messagebox(nothing, title, message, detail)
Messagebox(title::String, message::String) = Messagebox(nothing, title, message, nothing)
