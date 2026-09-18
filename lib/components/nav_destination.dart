import 'package:flutter/widgets.dart';

/// A single navigation destination shared between a compact-mode
/// `NavigationBar`/`NavigationDestination` and a wide-mode
/// `NavigationRail`/`NavigationRailDestination`.
class NavDestination {
  final IconData icon;
  final IconData? selectedIcon;
  final String label;
  final VoidCallback onSelected;

  const NavDestination({
    required this.icon,
    this.selectedIcon,
    required this.label,
    required this.onSelected,
  });
}
