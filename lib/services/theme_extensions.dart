import 'package:fluent_ui/fluent_ui.dart';

extension FluentTheming on FluentThemeData {
  FluentThemeData createFluentTheme(
    Color mainColor,
    Color textColor,
    AccentColor accentColor,
    Color highlightColor,
  ) {
    return copyWith(
      accentColor: accentColor,
      scaffoldBackgroundColor: mainColor,
      dividerTheme: DividerThemeData(
        decoration: BoxDecoration(
          color: textColor.withOpacity(.25),
        ),
      ),
      navigationPaneTheme: NavigationPaneThemeData(
        backgroundColor: mainColor,
        highlightColor: highlightColor,
      ),
    );
  }

  Color get textColor =>
      brightness == Brightness.dark ? Colors.white : Colors.black;

  static const String _darkReaderViewStyle =
      "<style>div {color:#FFFFFF;font-size:40px;} p {color:#FFFFFF;font-size:40px;} a {color:#CCFFFE;} h1 {color:#FFFFFF;font-size:120px;} h2 {color:#FFFFFF;font-size:80px;} h3 {color:#FFFFFF;font-size:60px;} li {color:#FFFFFF;font-size:40px;} ul {color:#FFFFFF;font-size:40px;} img {max-width:98%;height:auto;} pre {white-space:pre-wrap;max-width:98%;height:auto;}</style>";
  static const String _lightReaderViewStyle =
      "<style>div {color:#000000;font-size:40px;} p {color:#000000;font-size:40px;} h1 {color:#000000;font-size:120px;} h2 {color:#000000;font-size:80px;} h3 {color:#000000;font-size:60px;} li {color:#000000;font-size:40px;} ul {color:#000000;font-size:40px;} img {max-width:98%;height:auto;} pre {white-space:pre-wrap;max-width:98%;height:auto;}</style>";

  String get readerViewStyle => brightness == Brightness.dark
      ? _darkReaderViewStyle
      : _lightReaderViewStyle;
}
