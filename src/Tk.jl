# julia tk interface
# TODO:
# * callbacks (possibly via C wrapper)
# - portable event handling, probably using Tcl_CreateEventSource
# * types: may not make sense to have one for each widget, maybe one TkWidget
# * Cairo drawing surfaces
# - port cairo_surface_for to other platforms
# - expose constants from tcl.h like TCL_OK, TCL_ERROR, etc.
# - more widgets
# - state-interrogating functions
# - cleaning up unused callbacks


module Tk
using Base
using Cairo
using BinDeps

@BinDeps.load_dependencies [:tk => :libtk, :tcl=>:libtcl]

import Base: string, show, getindex, setindex!, isequal
import Base.Graphics: width, height, getgc
import Cairo: destroy

include("tkwidget.jl")                  # old Tk
include("types.jl")
include("core.jl")
include("methods.jl")
include("widgets.jl")
include("containers.jl")
include("dialogs.jl")
include("menu.jl")


export Window, TkCanvas, Canvas, pack, place, tcl_eval, TclError,
    cairo_surface_for, width, height, reveal, cairo_surface, getgc,
    tcl_doevent, MouseHandler, draw

export tcl, tclvar, configure, cget, identify, state, instate, winfo, wm, exists,
       tcl_after, bind, bindwheel, callback_add
export Tk_Widget, TTk_Widget, Tk_Container
export Toplevel, Frame, Labelframe, Notebook, Panedwindow
export Label, Button
export Checkbutton, Radio, Combobox
export Slider, Spinbox
export Entry, set_validation, Text
export Treeview, selected_nodes, node_insert, node_move, node_delete, node_open
export tree_headers, tree_column_widths, tree_key_header, tree_key_width
export Sizegrip, Separator, Progressbar, Image, Scrollbar
export Menu, menu_add, tk_popup
export GetOpenFile, GetSaveFile, ChooseDirectory, Messagebox
export pack, pack_configure, forget, pack_stop_propagate
export grid, grid_configure, grid_rowconfigure, grid_columnconfigure, grid_forget, grid_stop_propagate
export page_add, page_insert
export formlayout, scrollbars_add
export get_value, set_value,
       get_items, set_items,
       set_width,
       set_height,
       get_size, set_size,
       get_enabled, set_enabled,
       get_editable, set_editable,
       get_visible, set_visible,
       set_position,
       parent, toplevel, children,
       raise, focus, update, destroy


@deprecate  tk_bindwheel  bindwheel
@deprecate  tk_cget       cget
@deprecate  tk_configure  configure
@deprecate  tk_winfo      winfo
@deprecate  tk_wm         wm
@deprecate  tk_exists     exists
@deprecate  tk_bind       bind
@deprecate  tk_state      state
@deprecate  tk_instate    instate
@deprecate  get_width     width
@deprecate  get_height    height


end  # module
