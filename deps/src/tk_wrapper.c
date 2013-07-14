#include <stdlib.h>
#include <string.h>
#include <tcl.h>
#include <tk.h>

void *jl_tkwin_display(Tk_Window tkwin)
{
    return Tk_Display(tkwin);
}

void *jl_tkwin_visual(Tk_Window tkwin)
{
    return Tk_Visual(tkwin);
}

int jl_tkwin_id(Tk_Window tkwin) // XXX: THIS IS NOT AN int ON MAC
{
    return Tk_WindowId(tkwin);
}

#ifdef __WIN32__

HWND globalHWND;
#include "TkWinInt.h"

void *jl_tkwin_hdc(Tk_Window tkwin, Display *display)
{
    HWND win = ((TkWinDrawable *)Tk_WindowId(tkwin))->window.handle;
    HDC dc = GetDC(win);
    return dc;
}

void *jl_tkwin_hdc_release(HDC hdc) 
{
    ReleaseDC(globalHWND,hdc);
}

#endif

#ifdef __APPLE__

#include "ApplicationServices/ApplicationServices.h"
#include "objc/objc-runtime.h"
typedef struct objc_object NSView;

typedef struct TkRegion_ *TkRegion;
#define MAC_OSX_TK
#include "tkMacOSX.h"

CGContextRef getView(Tk_Window *winPtr, int height)
{
    int focusLocked;
    int dontDraw = 0;

    NSView *view = TkMacOSXGetRootControl(Tk_WindowId(winPtr));

    if (!view) {
        return NULL;
    }
    NSView *focusView = (NSView*)objc_msgSend((id)objc_getClass("NSView"), sel_getUid("focusView"));
    if (view != focusView) {
        focusLocked = (int)(long)objc_msgSend(view, sel_getUid("lockFocusIfCanDraw"));
        dontDraw = !focusLocked;
    }
    else {
        dontDraw = !(int)(long)objc_msgSend(view, sel_getUid("canDraw"));
    }
    if (dontDraw) {
        return NULL;
    }
    CGContextRef context = (CGContextRef)objc_msgSend((id)objc_msgSend((id)objc_msgSend(view, sel_getUid("window")),sel_getUid("graphicsContext")),sel_getUid("graphicsPort"));
    return context;
}

#endif
