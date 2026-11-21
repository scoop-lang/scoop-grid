#import <AppKit/AppKit.h>
#include <stdbool.h>

bool scoop_grid_test_header_click(void *pointer, double x, double y,
                                  bool command, bool shift) {
  @autoreleasepool {
    @try {
      NSView *view = (__bridge NSView *)pointer;
      NSEventModifierFlags flags = (command ? NSEventModifierFlagCommand : 0) |
                                   (shift ? NSEventModifierFlagShift : 0);
      NSPoint point = [view convertPoint:NSMakePoint(x, y) toView:nil];
      NSEvent *move =
          [NSEvent mouseEventWithType:NSEventTypeMouseMoved
                             location:point
                        modifierFlags:flags
                            timestamp:NSProcessInfo.processInfo.systemUptime
                         windowNumber:view.window.windowNumber
                              context:nil
                          eventNumber:1
                           clickCount:0
                             pressure:0];
      [view mouseMoved:move];
      for (int pressed = 1; pressed >= 0; --pressed) {
        NSEvent *event =
            [NSEvent mouseEventWithType:pressed ? NSEventTypeLeftMouseDown
                                                : NSEventTypeLeftMouseUp
                               location:point
                          modifierFlags:flags
                              timestamp:NSProcessInfo.processInfo.systemUptime
                           windowNumber:view.window.windowNumber
                                context:nil
                            eventNumber:1
                             clickCount:1
                               pressure:pressed ? 1.0 : 0.0];
        if (pressed)
          [view mouseDown:event];
        else
          [view mouseUp:event];
      }
      return true;
    } @catch (NSException *exception) {
      (void)exception;
      return false;
    }
  }
}
