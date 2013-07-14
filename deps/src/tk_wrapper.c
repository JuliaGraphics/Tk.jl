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

#import <Cocoa/Cocoa.h>
#include "ApplicationServices/ApplicationServices.h"

typedef struct TkRegion_ *TkRegion;
#define MAC_OSX_TK
#include "tkMacOSX.h"

CGContextRef getView(Tk_Window *winPtr, int height)
{
    int focusLocked;
    int dontDraw = 0;

    NSView *view = TkMacOSXGetRootControl(Tk_WindowId(winPtr));

    if (view) {
        if (view != [NSView focusView]) {
            focusLocked = [view lockFocusIfCanDraw];
            dontDraw = !focusLocked;
        }
        else {
            dontDraw = ![view canDraw];
        }
        if (dontDraw) {
            return NULL;
        }
    }
    CGContextRef context = [[[view window] graphicsContext] graphicsPort];
    return context;
}

#endif
