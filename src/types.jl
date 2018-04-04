## Abstract types
abstract type Tk_Widget end
abstract type TTk_Widget <: Tk_Widget end ## for ttk::widgets
abstract type TTk_Container <: Tk_Widget end ## for containers (frame, labelframe, ???)

const Widget = Union{TkWidget, Tk_Widget, Canvas, AbstractString}

## Maybe -- can this be parameterized?
## https://groups.google.com/forum/?fromgroups=#!topic/julia-dev/IbbWwplrqlc (takeaway -- this style is frowned upon)
const MaybeFunction = Union{Function, Nothing}
const MaybeString = Union{AbstractString, Nothing}
const MaybeStringInteger = Union{AbstractString, Integer, Nothing} # for at in tree insert
const MaybeVector = Union{Vector, Nothing}
const MaybeWidget = Union{Widget, Nothing}
const MaybeBool = Union{Bool, Nothing}
