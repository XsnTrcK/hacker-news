import 'package:fluent_ui/fluent_ui.dart';

extension FluentTheming on ThemeData {
  Color _applyOpacity(Color color, Set<ButtonStates> states) {
    return color.withOpacity(
      states.isPressing
          ? 0.925
          : states.isFocused
              ? 0.4
              : states.isHovering
                  ? 0.85
                  : 1.0,
    );
  }

  ThemeData createFluentTheme(
    Color mainColor,
    Color textColor,
    AccentColor accentColor,
    Color highlightColor,
  ) {
    return copyWith(
      accentColor: accentColor,
      scaffoldBackgroundColor: mainColor,
      dividerTheme:
          DividerThemeData(decoration: BoxDecoration(color: textColor)),
      navigationPaneTheme: NavigationPaneThemeData(
        backgroundColor: mainColor,
        highlightColor: highlightColor,
      ),
      pillButtonBarTheme: PillButtonBarThemeData(
        backgroundColor: mainColor,
        selectedColor: ButtonState.resolveWith(
          (states) => _applyOpacity(highlightColor, states),
        ),
      ),
    );
  }

  Color get textColor =>
      brightness == Brightness.dark ? Colors.white : Colors.black;
}
