import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';

class FilterFabOption<T> {
  final T value;
  final String label;

  const FilterFabOption(this.value, this.label);
}

/// A FAB that fans out into one small extended FAB per option, showing the
/// current selection as the closed button's label. For a small, fixed
/// option count (e.g. the 6 HN categories) — the fan is a fixed geometric
/// arrangement with no scrolling, so it doesn't suit an unbounded list; see
/// `DropdownFilterFab` for that case (e.g. RSS feeds).
class FilterFab<T> extends StatefulWidget {
  final IconData icon;
  final String selectedLabel;
  final List<FilterFabOption<T>> options;
  final bool Function(T value) isSelected;
  final ValueChanged<T> onChanged;

  const FilterFab({
    super.key,
    required this.icon,
    required this.selectedLabel,
    required this.options,
    required this.isSelected,
    required this.onChanged,
  });

  @override
  State<FilterFab<T>> createState() => _FilterFabState<T>();
}

class _FilterFabState<T> extends State<FilterFab<T>> {
  final _key = GlobalKey<ExpandableFabState>();

  void _select(T value) {
    widget.onChanged(value);
    _key.currentState?.toggle();
  }

  @override
  Widget build(BuildContext context) {
    // Matches HnTypeSelector's compact FilterChip look exactly — see
    // DropdownFilterFab's build() comment for why these particular
    // ColorScheme tokens are the right match (confirmed by inspecting
    // FilterChip's actually-resolved colors, not assumed).
    final colorScheme = Theme.of(context).colorScheme;
    // `colorScheme.surface` (and Material's own `Theme.scaffoldBackgroundColor`)
    // are both ~70% alpha under this app's fluent-bridged theme (Fluent's
    // "acrylic" translucent-surface look) — use Fluent's own, unbridged
    // scaffoldBackgroundColor instead, which is fully opaque and is what
    // the rest of this app's Scaffolds already use for backgrounds.
    final unselectedBackground = fluent.FluentTheme.of(context).scaffoldBackgroundColor;

    return ExpandableFab(
      key: _key,
      type: ExpandableFabType.fan,
      // `distance` is the fan's radius, not the gap between buttons: the
      // visual gap is `distance * angleBetweenItemsInRadians`. With 6 items
      // over the default 90° fanAngle (18° apart, ~0.314 rad), a gap wide
      // enough for text-label pills needs a much larger radius than a
      // straight-line layout would.
      distance: 275,
      // A transparent overlay adds no visual change but gives the package a
      // full-screen barrier to catch outside taps, so tapping away from the
      // fanned-out options closes them without selecting one.
      overlayStyle: const ExpandableFabOverlayStyle(color: Colors.transparent),
      openButtonBuilder: FloatingActionButtonBuilder(
        size: 56,
        builder: (context, onPressed, progress) =>
            FloatingActionButton.extended(
          key: const ValueKey('filter_fab_trigger'),
          heroTag: null,
          icon: Icon(widget.icon),
          label: Text(widget.selectedLabel),
          onPressed: onPressed,
        ),
      ),
      closeButtonBuilder: DefaultFloatingActionButtonBuilder(
        fabSize: ExpandableFabSize.small,
        child: const Icon(Icons.close),
      ),
      children: [
        for (final option in widget.options)
          FloatingActionButton.extended(
            key: ValueKey(option.value),
            heroTag: null,
            backgroundColor: widget.isSelected(option.value)
                ? colorScheme.secondaryContainer
                : unselectedBackground,
            foregroundColor: widget.isSelected(option.value)
                ? colorScheme.onSecondaryContainer
                : colorScheme.onSurface,
            shape: widget.isSelected(option.value)
                ? null
                : StadiumBorder(side: BorderSide(color: colorScheme.onSurface)),
            label: Text(option.label),
            onPressed: () => _select(option.value),
          ),
      ],
    );
  }
}

/// A FAB that opens a scrollable dropdown of options, showing the current
/// selection as the closed button's label. Unlike `FilterFab`'s fan-out,
/// this scrolls past a fixed max height instead of spreading arbitrarily
/// far, so it suits an unbounded option count (e.g. user-added RSS feeds).
/// Menu items are styled to resemble small FABs, echoing `FilterFab`'s look.
class DropdownFilterFab<T> extends StatelessWidget {
  final IconData icon;
  final String selectedLabel;
  final List<FilterFabOption<T>> options;
  final bool Function(T value) isSelected;
  final ValueChanged<T> onChanged;

  /// Roughly 5 items tall before scrolling kicks in.
  static const _maxMenuHeight = 320.0;
  static const _maxMenuWidth = 260.0;

  const DropdownFilterFab({
    super.key,
    required this.icon,
    required this.selectedLabel,
    required this.options,
    required this.isSelected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Matches HnTypeSelector's compact FilterChip look exactly: with no
    // custom ChipTheme in this app, FilterChip's selected state already
    // resolves to these same ColorScheme tokens (fluent_ui's FluentApp
    // bridges its accentColor into the ambient Material ColorScheme, which
    // is why a plain, unthemed FilterChip already shows the app's orange
    // accent when selected — confirmed by inspecting the resolved colors
    // directly rather than assuming).
    final colorScheme = Theme.of(context).colorScheme;
    // `colorScheme.surface` (and Material's own `Theme.scaffoldBackgroundColor`)
    // are both ~70% alpha under this app's fluent-bridged theme (Fluent's
    // "acrylic" translucent-surface look) — use Fluent's own, unbridged
    // scaffoldBackgroundColor instead, which is fully opaque and is what
    // the rest of this app's Scaffolds already use for backgrounds.
    final unselectedBackground = fluent.FluentTheme.of(context).scaffoldBackgroundColor;

    ButtonStyle styleFor(bool selected) => MenuItemButton.styleFrom(
          backgroundColor:
              selected ? colorScheme.secondaryContainer : unselectedBackground,
          foregroundColor:
              selected ? colorScheme.onSecondaryContainer : colorScheme.onSurface,
          shape: selected
              ? const StadiumBorder()
              : StadiumBorder(side: BorderSide(color: colorScheme.onSurface)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        );

    return MenuAnchor(
      style: const MenuStyle(
        backgroundColor: WidgetStatePropertyAll(Colors.transparent),
        elevation: WidgetStatePropertyAll(0),
        shadowColor: WidgetStatePropertyAll(Colors.transparent),
        surfaceTintColor: WidgetStatePropertyAll(Colors.transparent),
        maximumSize:
            WidgetStatePropertyAll(Size(_maxMenuWidth, _maxMenuHeight)),
        padding: WidgetStatePropertyAll(EdgeInsets.zero),
      ),
      menuChildren: [
        for (final option in options)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
            child: MenuItemButton(
              style: styleFor(isSelected(option.value)),
              onPressed: () => onChanged(option.value),
              child: Text(option.label),
            ),
          ),
      ],
      builder: (context, controller, child) => FloatingActionButton.extended(
        key: const ValueKey('filter_fab_trigger'),
        heroTag: null,
        icon: Icon(icon),
        label: Text(selectedLabel),
        onPressed: () {
          if (controller.isOpen) {
            controller.close();
          } else {
            controller.open();
          }
        },
      ),
    );
  }
}
