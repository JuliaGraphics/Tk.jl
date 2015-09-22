## Abstract types
abstract Tk_Widget
abstract TTk_Widget <: Tk_Widget ## for ttk::widgets
abstract TTk_Container <: Tk_Widget ## for containers (frame, labelframe, ???)

Widget = (@compat Union{TkWidget, Tk_Widget, Canvas, AbstractString})

## Maybe -- can this be parameterized?
## https://groups.google.com/forum/?fromgroups=#!topic/julia-dev/IbbWwplrqlc (takeaway -- this style is frowned upon)
MaybeFunction = (@compat Union{Function, (@compat Void)})
MaybeString = (@compat Union{AbstractString, (@compat Void)})
MaybeStringInteger = (@compat Union{AbstractString, Integer, (@compat Void)}) # for at in tree insert
MaybeVector = (@compat Union{Vector, (@compat Void)})
MaybeWidget = (@compat Union{Widget, (@compat Void)})
MaybeBool = (@compat Union{Bool, (@compat Void)})
