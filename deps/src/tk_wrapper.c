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

int jl_tkwin_id(Tk_Window tkwin)
{
    return Tk_WindowId(tkwin);
}

#ifdef __WIN32__

HWND globalHWND;

#include "TkWinInt.h"

void *jl_tkwin_hdc(Tk_Window tkwin, Display *display)
{
    HDC dc;
    TkWinDCState state;
    PAINTSTRUCT PS;
    RECT rect, rect2;
    HWND win = ((TkWinDrawable *)Tk_WindowId(tkwin))->window.handle;
    GetClientRect(win,&rect);
    InvalidateRect(win,&rect,FALSE);
    HRGN rgn = CreateRectRgn(rect.left,rect.top,rect.right,rect.bottom);
    dc = GetDC(win);
    int ok = SelectClipRgn(dc,rgn);
    GetClipBox(dc,&rect2);
    SetBkMode(dc,1);
    TextOut(dc,10,10,"Hello World",11);
    return dc;
    //return TkWinGetHDC(Tk_WindowId(tkwin));
}

void *jl_tkwin_hdc_release(HDC hdc) 
{
    ReleaseDC(globalHWND,hdc);
}

#endif

#ifdef __APPLE__

#define MAC_OSX_TK
#import <Cocoa/Cocoa.h>
#include "ApplicationServices/ApplicationServices.h"
#include "tkMacOSXInt.h"

NSView *drawableView(MacDrawable *macWin)
{
    NSView *view;
    if (!macWin) {
        view = NULL;
    }
    else if (!macWin->toplevel) {
        view = macWin->view;
    }
    else if (!(macWin->toplevel->flags & TK_EMBEDDED)) {
        view = macWin->toplevel->view;
    }
    else {
        TkWindow *contWinPtr = TkpGetOtherWindow(macWin->toplevel->winPtr);
        if (contWinPtr) {
            view = drawableView(contWinPtr->privatePtr);
        }
    }
    return view;
}

CGContextRef getView(TkWindow *winPtr, int height)
{
    CGContextRef context;
    NSView *view;
    int focusLocked;
    int dontDraw = 0;
    MacDrawable *macWin = (MacDrawable *) winPtr->window;
    view = drawableView(macWin);

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
    context = [[[view window] graphicsContext] graphicsPort];
    return context;
}

#endif
