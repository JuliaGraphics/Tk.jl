## simple workspace browser for julia
using Tk

## Some functions to work with a module
function get_names(m::Module)
    sort!(map(string, names(m)))
end

unique_id(v::Symbol, m::Module) = isdefined(m,v) ? unique_id(Base.eval(m,v)) : ""
unique_id(x) = string(objectid(x))

## short_summary
## can customize description here
short_summary(x) = summary(x)
short_summary(x::AbstractString) = "A string"

## update ids, returning false if the same, true if not
__ids__ = Vector{AbstractString}()
function update_ids(m::Module)
    global __ids__
    nms = get_names(m)
    nms = filter(u -> u != "__ids__", nms)
    a_ids = map(u -> unique_id(Symbol(u), m), nms)
    if __ids__ == a_ids
        false
    else
        __ids__ = a_ids
        true
    end
end


negate(x::Bool, val::Bool) = val ? !x : x
const MaybeRegex = Union{Nothing, Regex}
const MaybeType = Union{Nothing, DataType}

## get array of names and summaries
## m module
## pat regular expression to filter by
## dtype: DataType or Union to filter out by.
## dtypefilter: If true not these types, if false only these types
function get_names_summaries(m::Module, pat::MaybeRegex, dtype::MaybeType, dtypefilter::Bool)
    nms = get_names(m)

    if pat != nothing
        nms = filter(s -> occursin(pat, s), nms)
    end
    ## filter out this type
    if dtype != nothing
        nms = filter(u -> isdefined(m, Symbol(u)) && negate(isa(Base.eval(m,Symbol(u)), dtype), dtypefilter), nms)
    end
    summaries = map(u -> isdefined(m, Symbol(u)) ? short_summary(Base.eval(m,Symbol(u))) : "undefined", nms)

    if length(nms) == length(summaries)
        return [nms summaries]
    else
        return nothing                  #  didn't match
    end
end
get_names_summaries(m::Module, pat::Regex) = get_names_summaries(m, pat, nothing, true)
get_names_summaries(m::Module, dtype::MaybeType) = get_names_summaries(m, nothing, dtype, true)
get_names_summaries(m::Module) = get_names_summaries(m::Module, nothing, nothing, true)

## Simple layout for our tree view.

w = Toplevel("Workspace", 600, 600)
f = Frame(w)
pack_stop_propagate(w)
pack(f, expand=true, fill="both")
tv = Treeview(f, get_names_summaries(Main, nothing, (Module), true))
tree_key_header(tv, "Object")
tree_headers(tv,  ["Summary"])
scrollbars_add(f, tv)

## add a callback. Here we get the obj clicked on.
callback_add(tv, (path) -> begin
    val = get_value(tv)[1]
    obj = Base.eval(Main, Symbol(val))
    println(short_summary(obj))
end)

## Update values after 1000ms. Call aft.stop() to stop
function cb()
    exists(tv) ? nothing : aft.stop()
    if update_ids(Main)
        set_items(tv, get_names_summaries(Main, nothing, (Module), true))
    end
end
aft = tcl_after(1000, cb)
aft.start()
