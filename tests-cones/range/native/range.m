#import <AppKit/AppKit.h>
#import <CoreGraphics/CoreGraphics.h>
#include <math.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>

static id findTable(id node) {
  if ([[node accessibilityRole] isEqual:NSAccessibilityTableRole])
    return node;
  for (id child in [node accessibilityChildren]) {
    id found = findTable(child);
    if (found)
      return found;
  }
  return nil;
}

double scoop_grid_range_coordinate(void *pointer, int64_t row, int64_t column,
                                   bool horizontal) {
  NSView *view = (__bridge NSView *)pointer;
  id grid = findTable(view.accessibilityChildren.firstObject);
  id cell = [grid accessibilityCellForColumn:column row:row];
  if (!cell)
    return NAN;
  NSRect frame = [cell accessibilityFrame];
  if (NSIsEmptyRect(frame))
    return NAN;
  NSPoint window = [view.window
      convertPointFromScreen:NSMakePoint(NSMidX(frame), NSMidY(frame))];
  NSPoint local = [view convertPoint:window fromView:nil];
  return horizontal ? local.x : local.y;
}

static NSMenuItem *findCopy(NSMenu *menu) {
  for (NSMenuItem *item in menu.itemArray) {
    if ([item.title isEqualToString:@"Range Copy"])
      return item;
    NSMenuItem *found = findCopy(item.submenu);
    if (found)
      return found;
  }
  return nil;
}

bool scoop_grid_range_menu_copy(void *pointer) {
  @try {
    NSView *view = (__bridge NSView *)pointer;
    NSMenuItem *item = findCopy(NSApp.mainMenu);
    [item.menu update];
    return view.window.keyWindow && item && item.enabled &&
           [NSApp sendAction:item.action to:item.target from:item];
  } @catch (NSException *error) {
    fprintf(stderr, "range menu copy failed: %s\n", error.reason.UTF8String);
    return false;
  }
}

bool scoop_grid_range_context_click(void *pointer, double x, double y) {
  @try {
    NSView *view = (__bridge NSView *)pointer;
    if (!view.window.keyWindow)
      return false;
    NSPoint point = [view convertPoint:NSMakePoint(x, y) toView:nil];
    CGFloat top = NSMaxY(NSScreen.screens.firstObject.frame);
    for (int released = 0; released < 2; ++released) {
      // NSEvent's mouse constructor always assigns button zero.
      CGEventRef native = CGEventCreateMouseEvent(
          NULL, released ? kCGEventRightMouseUp : kCGEventRightMouseDown,
          CGPointMake(point.x, top - point.y), kCGMouseButtonRight);
      if (!native)
        return false;
      CGEventSetFlags(native, 0);
      CGEventSetIntegerValueField(native, kCGMouseEventClickState, 1);
      NSEvent *event = [NSEvent eventWithCGEvent:native];
      CFRelease(native);
      if (!event || event.buttonNumber != 1)
        return false;
      NSPoint actual = [view convertPoint:event.locationInWindow fromView:nil];
      if (fabs(actual.x - x) > 0.01 || fabs(actual.y - y) > 0.01) {
        fprintf(stderr, "context coordinate mismatch: %.2f,%.2f -> %.2f,%.2f\n", x, y, actual.x, actual.y);
        return false;
      }
      if (released)
        [view rightMouseUp:event];
      else
        [view rightMouseDown:event];
    }
    return true;
  } @catch (NSException *error) {
    fprintf(stderr, "range context click failed: %s\n", error.reason.UTF8String);
    return false;
  }
}
