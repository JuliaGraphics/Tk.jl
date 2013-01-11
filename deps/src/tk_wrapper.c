#include <stdlib.h>
#include <string.h>
#include <tcl.h>
#include <tk.h>
#include "julia.h"

int jl_tcl_callback(ClientData clientData, Tcl_Interp *interp,
                    int argc, char *argv[])
{
    jl_function_t *f = (jl_function_t*)clientData;
    jl_value_t **jlargs = alloca(argc * sizeof(void*));
    memset(jlargs, 0, argc * sizeof(void*));
    JL_GC_PUSHARGS(jlargs, argc);
    int i;
    for(i=0; i < argc; i++) {
        jlargs[i] = jl_cstr_to_string(argv[i]);
    }
    jl_value_t *result = NULL;
    JL_TRY {
        result = jl_apply(f, jlargs, argc);
    }
    JL_CATCH {
        //jl_show(jl_stdout_obj(), jl_exception_in_transit);
        JL_GC_POP();
        return TCL_ERROR;
    }
    if (jl_is_byte_string(result))
        Tcl_SetResult(interp, jl_string_data(result), TCL_VOLATILE);
    else
        Tcl_SetResult(interp, "", TCL_STATIC);
    JL_GC_POP();
    return TCL_OK;
}

void *jl_tkwin_display(Tk_Window tkwin)
{
    return Tk_Display(tkwin);
}

void *jl_tkwin_visual(Tk_Window tkwin)
{
    return Tk_Visual(tkwin);
}

int jl_tkwin_id(Tk_Window tkwin)
{
    return Tk_WindowId(tkwin);
}



#define MAC_OSX_TK
#import <Cocoa/Cocoa.h>
#include "ApplicationServices/ApplicationServices.h"
#include "TkMacOSXInt.h"

/* This thing is the cause of a lot of pain and suffering. In order to make this work correctly,
 * you need to make sure that the latest cached drawing context is that in which you want cairo to draw.
 */

NSView *drawableView(MacDrawable *macWin)
{
    NSView *view;
    if (!macWin) {
    view = NULL;
    } else if (!macWin->toplevel) {
    view = macWin->view;
    } else if (!(macWin->toplevel->flags & TK_EMBEDDED)) {
    view = macWin->toplevel->view;
    } else {
    TkWindow *contWinPtr = TkpGetOtherWindow(macWin->toplevel->winPtr);
    if (contWinPtr) {
        view = drawableView(contWinPtr->privatePtr);
    }
    }
    return view;
}

CGContextRef
getView(
    TkWindow *winPtr,
    int height)
{
    CGContextRef context;
    NSView *view;
    HIShapeRef clipRgn;
    CGRect portBounds;
    int focusLocked;
    CGRect clipBounds;
    int dontDraw = 0, isWin = 0;
    MacDrawable *macWin =  (MacDrawable *) winPtr->window;
    view = drawableView(macWin);

    if (view) {
        if (view != [NSView focusView]) {
        focusLocked = [view lockFocusIfCanDraw];
        dontDraw = !focusLocked;
        } else {
        dontDraw = ![view canDraw];
        }
        if (dontDraw) {
        goto end;
        }
        [[view window] disableFlushWindow];
        view = view;
        context = [[NSGraphicsContext currentContext] graphicsPort];
        portBounds = NSRectToCGRect([view bounds]);
        if (clipRgn) {
        clipBounds = CGContextGetClipBoundingBox(context);
        }
    }
    CGContextTranslateCTM (context, 0.0, height);
    CGContextScaleCTM (context, 1.0, -1.0);
    return context;
    end:
    return NULL;
}
