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

  String get readerViewStyle {
    final dark = brightness == Brightness.dark;
    final color = dark ? '#FFFFFF' : '#000000';
    final bg = dark ? '#000000' : '#FFFFFF';
    final linkColor = dark ? '#CCFFFE' : '#0066CC';
    final body = _readerBodySize;
    final h1 = _readerH1Size;
    final h2 = _readerH2Size;
    final h3 = _readerH3Size;
    return "<style>"
        "body{color:$color;background-color:$bg;font-size:${body}px;line-height:1.6;padding:16px;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;}"
        "h1{font-size:${h1}px;line-height:1.2;font-weight:700;margin-bottom:12px;}"
        "h2{font-size:${h2}px;line-height:1.3;font-weight:600;}"
        "h3{font-size:${h3}px;line-height:1.3;font-weight:600;}"
        "p{margin-bottom:12px;}"
        "a{color:$linkColor;}"
        "img{max-width:100%;height:auto;display:block;margin:12px 0;}"
        "pre{white-space:pre-wrap;max-width:100%;overflow-x:auto;font-size:${body - 2}px;}"
        "li{margin-bottom:4px;}"
        "</style>";
  }

  int get _readerBodySize {
    switch (settings.fontSize) {
      case SettingsFontSize.small: return 15;
      case SettingsFontSize.medium: return 17;
      case SettingsFontSize.large: return 19;
    }
  }

  int get _readerH1Size {
    switch (settings.fontSize) {
      case SettingsFontSize.small: return 24;
      case SettingsFontSize.medium: return 28;
      case SettingsFontSize.large: return 32;
    }
  }

  int get _readerH2Size {
    switch (settings.fontSize) {
      case SettingsFontSize.small: return 19;
      case SettingsFontSize.medium: return 22;
      case SettingsFontSize.large: return 25;
    }
  }

  int get _readerH3Size {
    switch (settings.fontSize) {
      case SettingsFontSize.small: return 17;
      case SettingsFontSize.medium: return 19;
      case SettingsFontSize.large: return 21;
    }
  }

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
