## dialogs

## can add arguments if desired. Don't like names or lack of arguments
GetOpenFile(;kwargs...) = tcl("tk_getOpenFile";kwargs...)
GetSaveFile(;kwargs...) = tcl("tk_getSaveFile";kwargs...)
ChooseDirectory(;kwargs...) = tcl("tk_chooseDirectory";kwargs...)

## Message box
function Messagebox(parent::MaybeWidget; title::AbstractString="", message::AbstractString="", detail::AbstractString="")
    args = Dict()
    if !isa(parent, Nothing) args["parent"] = get_path(parent) end
    if length(title) > 0 args["title"] = title  end
    if length(message) > 0 args["message"] = message end
    if length(detail) > 0 args["detail"] = detail end
    args["type"] = "okcancel"

    tcl("tk_messageBox", args)
end
Messagebox(;kwargs...) = Messagebox(nothing; kwargs...)
Messagebox(parent::Widget, message::AbstractString) = Messagebox(parent, message=message)
Messagebox(message::AbstractString) = Message(nothing, message=message)
