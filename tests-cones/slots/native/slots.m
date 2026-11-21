#import <AppKit/AppKit.h>
#include <stdbool.h>

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

void *scoop_grid_slots_table(void *view) {
  return (__bridge_retained void *)table(view);
}

bool scoop_grid_slots_busy(void *view) {
  return [[table(view) accessibilityValueDescription] isEqualToString:@"Busy"];
}
