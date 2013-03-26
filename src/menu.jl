## remove tearoff menus
tcl_eval("option add *tearOff 0")


## make a menubar
## w = Toplevel()
## mb = Menu(w) ## adds to toplevel too when w is Toplevel
## file_menu = menu_add(mb, "File...") ## make top level entry
## menu_add(file_menu, "title", w -> println("hi")) ## pass function to make action item
## menu_add(file_menu, Separator(w)) ## a separator
## menu_add(file_menu, Checkbutton(w, "label")) ## A checkbutton
## menu_add(file_menu, Radio(w, ["one", "two"])) ## A checkbutton

## create menu, add to window
function Menu(widget::Tk_Toplevel)
    m = Menu(widget.w)                  #  dispatch down
    tk_configure(widget, {:menu => m})
    m
end

## add a submenu, return it
function menu_add(widget::Tk_Menu, label::String)
    m = Menu(widget)
    tcl(widget, "add", "cascade", {:menu => m, :label => label})
    m
end

## add menu item to menu
function menu_add(widget::Tk_Menu, label::String, command::Function, img::Tk_Image)
    tcl(widget, "add", "command", {:label => label, :command => command, :image => img, :compound => "left"})
end
function menu_add(widget::Tk_Menu, label::String, command::Function)
    ccb = Tk.tcl_callback(command)
    tcl(widget, "add", "command", {:label => label, :command => command})
end

function menu_add(widget::Tk_Menu, sep::Tk_Separator)
    tcl(widget, "add", "separator")
end

function menu_add(widget::Tk_Menu, cb::Tk_Checkbutton)
    ## no ! here, as state has changed by the time we get this
    tcl(widget, "add", "checkbutton", {:label => get_items(cb), :variable => tk_cget(cb, "variable")})
end


function menu_add(widget::Tk_Menu, rb::Tk_Radio)
    var = tk_cget(rb.buttons[1], "variable")
    items = get_items(rb)
    for i in 1:length(items)
        tcl(widget, "add", "radiobutton", {:label => items[i], :value => items[i],
                                         :variable => var})
    end
end

