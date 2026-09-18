import 'package:flutter/widgets.dart';

enum NavigationLayoutMode { compact, wide }

/// Width-only responsive breakpoint for the app's top-level navigation
/// shell. Deliberately ignores fold/hinge state.
class NavigationBreakpoint {
  const NavigationBreakpoint._();

  static const double widthThreshold = 600;

  static NavigationLayoutMode of(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= widthThreshold
        ? NavigationLayoutMode.wide
        : NavigationLayoutMode.compact;
  }
}
