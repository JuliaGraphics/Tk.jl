## dialogs

## can add arguments if desired. Don't like names or lack of arguments
GetOpenFile() = tcl("tk_getOpenFile")
GetSaveFile() = tcl("tk_getSaveFile")
ChooseDirectory() = tcl("tk_chooseDirectory")

## Message box
function Messagebox(parent::MaybeWidget; title::String="", message::String="", detail::String="")
    args = Dict()
    if !isa(parent, Nothing) args["parent"] = get_path(parent) end
    if length(title) > 0 args["title"] = title  end
    if length(message) > 0 args["message"] = message end
    if length(detail) > 0 args["detail"] = detail end
    args["type"] = "okcancel"

    tcl("tk_messageBox", args)
end
Messagebox(;kwargs...) = Messagebox(nothing; kwargs...)
Messagebox(parent::Widget, message::String) = Messagebox(parent, message=message)
Messagebox(message::String) = Message(nothing, message=message)
