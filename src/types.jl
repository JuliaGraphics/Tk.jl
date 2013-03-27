## Abstract types
abstract Tk_Widget
abstract TTk_Widget <: Tk_Widget ## for ttk::widgets
abstract TTk_Container <: Tk_Widget ## for containers (frame, labelframe, ???)



Widget = Union(TkWidget, Tk_Widget, Canvas, String)

## Maybe -- can this be parameterized?
## https://groups.google.com/forum/?fromgroups=#!topic/julia-dev/IbbWwplrqlc (takeaway -- this style if frowned on)
MaybeFunction = Union(Function, Nothing)
MaybeString = Union(String, Nothing)
MaybeStringInteger = Union(String, Integer, Nothing) # for at in tree insert
MaybeVector = Union(Vector, Nothing)
MaybeWidget = Union(Widget, Nothing)
MaybeBool = Union(Bool, Nothing)
