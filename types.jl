## Abstract types
abstract Tk_Widget
abstract TTk_Widget <: Tk_Widget ## for ttk::widgets
abstract TTk_Container <: Tk_Widget ## for containers (frame, labelframe, ???)

Widget = Union{TkWidget, Tk_Widget, Canvas, AbstractString}

## Maybe -- can this be parameterized?
## https://groups.google.com/forum/?fromgroups=#!topic/julia-dev/IbbWwplrqlc (takeaway -- this style is frowned upon)
MaybeFunction = Union{Function, Void}
MaybeString = Union{AbstractString, Void}
MaybeStringInteger = Union{AbstractString, Integer, Void} # for at in tree insert
MaybeVector = Union{Vector, Void}
MaybeWidget = Union{Widget, Void}
MaybeBool = Union{Bool, Void}
