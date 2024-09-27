// ignore_for_file: deprecated_member_use_from_same_package

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';

const double _kMinHeight = 28.0;

const double _kButtonsSpacing = 8.0;

const double _kMinButtonWidth = 56.0;
const double _kMaxButtonHeight = _kMinHeight;

class PillButtonBarItem extends CommandBarItem {
  const PillButtonBarItem({
    required this.item,
    this.onPressed,
    this.selected = false,
    Key? key,
  }) : super(key: key);

  final Widget item;
  final VoidCallback? onPressed;
  final bool selected;

  Color _applyOpacity(Color? color, Set<WidgetState> states) {
    return color?.withOpacity(
          states.isPressed
              ? 0.925
              : states.isFocused
                  ? 0.4
                  : states.isHovered
                      ? 0.85
                      : 1.0,
        ) ??
        Colors.transparent;
  }

  @override
  Widget build(BuildContext context, displayMode) {
    final fluentTheme = FluentTheme.of(context);
    final visualDensity = fluentTheme.visualDensity;
    final isLight = fluentTheme.brightness.isLight;
    return HoverButton(
      onPressed: onPressed,
      builder: (context, states) {
        final selectedColor = _applyOpacity(
            fluentTheme.navigationPaneTheme.highlightColor, states);
        final unselectedColor = FluentTheme.of(context).accentColor.dark;
        return Align(
          alignment: AlignmentDirectional.center,
          child: Container(
            decoration: BoxDecoration(
              color: selected ? selectedColor : unselectedColor,
              borderRadius: BorderRadius.circular(20.0),
            ),
            constraints: BoxConstraints(
              minWidth: _kMinButtonWidth + visualDensity.horizontal,
              maxHeight: _kMaxButtonHeight + visualDensity.vertical,
            ),
            alignment: AlignmentDirectional.center,
            padding: EdgeInsets.symmetric(
              horizontal: 16.0 + visualDensity.horizontal,
              vertical: 3.0,
            ),
            margin: EdgeInsets.symmetric(
              horizontal: _kButtonsSpacing + visualDensity.horizontal,
              vertical: _kButtonsSpacing + visualDensity.vertical,
            ),
            child: DefaultTextStyle.merge(
              style: (selected
                  ? TextStyle(color: isLight ? Colors.black : Colors.white)
                  : TextStyle(
                      color: isLight
                          ? unselectedColor.basedOnLuminance()
                          : Colors.white)),
              child: item,
            ),
          ),
        );
      },
    );
  }
}
