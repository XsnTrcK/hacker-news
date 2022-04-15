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

  static const String _darkReaderViewStyle =
      "<style>div {color:#FFFFFF;font-size:40px;} p {color:#FFFFFF;font-size:40px;} a {color:#CCFFFE;} h1 {color:#FFFFFF;font-size:120px;} h2 {color:#FFFFFF;font-size:80px;} h3 {color:#FFFFFF;font-size:60px;} li {color:#FFFFFF;font-size:40px;} ul {color:#FFFFFF;font-size:40px;}</style>";
  static const String _lightReaderViewStyle =
      "<style>div {color:#000000;font-size:40px;} p {color:#000000;font-size:40px;} h1 {color:#000000;font-size:120px;} h2 {color:#000000;font-size:80px;} h3 {color:#000000;font-size:60px;} li {color:#000000;font-size:40px;} ul {color:#000000;font-size:40px;}</style>";

  String get readerViewStyle => brightness == Brightness.dark
      ? _darkReaderViewStyle
      : _lightReaderViewStyle;
}
