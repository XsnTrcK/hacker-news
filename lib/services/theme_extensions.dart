import 'package:fluent_ui/fluent_ui.dart';
import 'package:hackernews/store/settings_store.dart';

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
          color: textColor.withValues(alpha: .25),
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

  Typography get dynamicTypography {
    return typography.merge(
      Typography.raw(
        caption: typography.caption!.merge(
          TextStyle(
            fontSize: _captionFontSize,
          ),
        ),
        body: typography.body!.merge(
          TextStyle(
            fontSize: _bodyFontSize,
          ),
        ),
        bodyLarge: typography.bodyLarge!.merge(
          TextStyle(
            fontSize: _bodyLargeFontSize,
          ),
        ),
        bodyStrong: typography.bodyStrong!.merge(
          TextStyle(
            fontSize: _bodyFontSize,
          ),
        ),
        display: typography.display!.merge(
          TextStyle(
            fontSize: _displayFontSize,
          ),
        ),
        subtitle: typography.subtitle!.merge(
          TextStyle(
            fontSize: _subTitleFontSize,
          ),
        ),
        title: typography.title!.merge(
          TextStyle(
            fontSize: _titleFontSize,
          ),
        ),
        titleLarge: typography.titleLarge!.merge(
          TextStyle(
            fontSize: _titleLargeFontSize,
          ),
        ),
      ),
    );
  }

  double get _captionFontSize {
    switch (settings.fontSize) {
      case SettingsFontSize.small:
        return 11;
      case SettingsFontSize.medium:
        return 13;
      case SettingsFontSize.large:
        return 15;
    }
  }

  double get _bodyFontSize {
    switch (settings.fontSize) {
      case SettingsFontSize.small:
        return 13;
      case SettingsFontSize.medium:
        return 15;
      case SettingsFontSize.large:
        return 17;
    }
  }

  double get _bodyLargeFontSize {
    switch (settings.fontSize) {
      case SettingsFontSize.small:
        return 17;
      case SettingsFontSize.medium:
        return 19;
      case SettingsFontSize.large:
        return 21;
    }
  }

  double get _subTitleFontSize {
    switch (settings.fontSize) {
      case SettingsFontSize.small:
        return 19;
      case SettingsFontSize.medium:
        return 21;
      case SettingsFontSize.large:
        return 23;
    }
  }

  double get _titleFontSize {
    switch (settings.fontSize) {
      case SettingsFontSize.small:
        return 27;
      case SettingsFontSize.medium:
        return 29;
      case SettingsFontSize.large:
        return 31;
    }
  }

  double get _titleLargeFontSize {
    switch (settings.fontSize) {
      case SettingsFontSize.small:
        return 39;
      case SettingsFontSize.medium:
        return 41;
      case SettingsFontSize.large:
        return 43;
    }
  }

  double get _displayFontSize {
    switch (settings.fontSize) {
      case SettingsFontSize.small:
        return 67;
      case SettingsFontSize.medium:
        return 69;
      case SettingsFontSize.large:
        return 71;
    }
  }
}
