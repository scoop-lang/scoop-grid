#import <AppKit/AppKit.h>
#include <math.h>
#include <stdbool.h>
#include <stdint.h>

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

static id table(void *pointer) {
  NSView *view = (__bridge NSView *)pointer;
  return findTable(view.accessibilityChildren.firstObject);
}

static id rowAt(id grid, int64_t index) {
  NSArray *rows =
      [grid accessibilityArrayAttributeValues:NSAccessibilityRowsAttribute
                                        index:(NSUInteger)index
                                     maxCount:1];
  return rows.count == 1 ? rows.firstObject : nil;
}

void *scoop_grid_selection_row(void *view, int64_t index) {
  return (__bridge_retained void *)rowAt(table(view), index);
}

bool scoop_grid_selection_check(void *view, int64_t index, bool selected,
                                int64_t count) {
  id grid = table(view);
  id row = rowAt(grid, index);
  NSArray *selection = [grid accessibilitySelectedRows];
  return grid && row && [row isAccessibilitySelected] == selected &&
         selection.count == (NSUInteger)count &&
         [selection containsObject:row] == selected;
}

static id findCheckbox(id node) {
  if ([[node accessibilityRole] isEqual:NSAccessibilityTableRole])
    return nil;
  if ([[node accessibilityRole] isEqual:NSAccessibilityCheckBoxRole])
    return node;
  for (id child in [node accessibilityChildren]) {
    id found = findCheckbox(child);
    if (found)
      return found;
  }
  return nil;
}

static id control(void *pointer, int64_t index) {
  NSView *view = (__bridge NSView *)pointer;
  id node = index < 0 ? view.accessibilityChildren.firstObject
                      : rowAt(table(pointer), index);
  return findCheckbox(node);
}

void *scoop_grid_selection_control(void *pointer, int64_t index) {
  return (__bridge_retained void *)control(pointer, index);
}

double scoop_grid_selection_coordinate(void *pointer, int64_t index,
                                       bool horizontal) {
  NSView *view = (__bridge NSView *)pointer;
  id checkbox = control(pointer, index);
  if (!checkbox)
    return NAN;
  NSRect frame = [checkbox accessibilityFrame];
  NSPoint location = [view.window
      convertPointFromScreen:NSMakePoint(NSMidX(frame), NSMidY(frame))];
  return horizontal ? location.x : location.y;
}

bool scoop_grid_selection_click(void *pointer, double x, double y, bool shift) {
  NSView *view = (__bridge NSView *)pointer;
  if (!view.window.keyWindow)
    return false;
  NSPoint location = NSMakePoint(x, y);
  for (int press = 1; press >= 0; press--) {
    NSEvent *event =
        [NSEvent mouseEventWithType:press ? NSEventTypeLeftMouseDown
                                          : NSEventTypeLeftMouseUp
                           location:location
                      modifierFlags:shift ? NSEventModifierFlagShift : 0
                          timestamp:NSProcessInfo.processInfo.systemUptime
                       windowNumber:view.window.windowNumber
                            context:nil
                        eventNumber:1
                         clickCount:1
                           pressure:press ? 1.0 : 0.0];
    if (press)
      [view mouseDown:event];
    else
      [view mouseUp:event];
  }
  return true;
}
