#import <AppKit/AppKit.h>
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
