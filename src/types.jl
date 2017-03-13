## Abstract types
@compat abstract type Tk_Widget end
@compat abstract type TTk_Widget <: Tk_Widget end ## for ttk::widgets
@compat abstract type TTk_Container <: Tk_Widget end ## for containers (frame, labelframe, ???)

const Widget = Union{TkWidget, Tk_Widget, Canvas, AbstractString}

## Maybe -- can this be parameterized?
## https://groups.google.com/forum/?fromgroups=#!topic/julia-dev/IbbWwplrqlc (takeaway -- this style is frowned upon)
const MaybeFunction = Union{Function, Void}
const MaybeString = Union{AbstractString, Void}
const MaybeStringInteger = Union{AbstractString, Integer, Void} # for at in tree insert
const MaybeVector = Union{Vector, Void}
const MaybeWidget = Union{Widget, Void}
const MaybeBool = Union{Bool, Void}
