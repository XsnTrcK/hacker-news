import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

const _fontSizeKey = 'fontSize';
const _themeModeKey = 'themeMode';
const _appIconKey = 'appIcon';

enum SettingsFontSize {
  small,
  medium,
  large,
}

enum AppIcon {
  icon,
  crayons,
  lines,
}

abstract class Settings {
  late SettingsFontSize fontSize;
  late ThemeMode themeMode;
  late AppIcon appIcon;
}

class SettingsStore implements Settings {
  late Box<String> _settingsBox;
  SettingsFontSize _fontSize = SettingsFontSize.small;
  ThemeMode _themeMode = ThemeMode.system;
  AppIcon _appIcon = AppIcon.icon;

  Future _init() async {
    _settingsBox = await Hive.openBox<String>("settings");
    final fontSizeName = _settingsBox.get(_fontSizeKey);
    for (var fontSize in SettingsFontSize.values) {
      if (fontSize.name == fontSizeName) {
        _fontSize = fontSize;
      }
    }
    final themeModeName = _settingsBox.get(_themeModeKey);
    for (var themeMode in ThemeMode.values) {
      if (themeMode.name == themeModeName) {
        _themeMode = themeMode;
      }
    }
    final appIconName = _settingsBox.get(_appIconKey);
    for (var appIcon in AppIcon.values) {
      if (appIcon.name == appIconName) {
        _appIcon = appIcon;
      }
    }
  }

  @override
  SettingsFontSize get fontSize {
    return _fontSize;
  }

  @override
  set fontSize(SettingsFontSize value) {
    _fontSize = value;
    _settingsBox.put(_fontSizeKey, value.name);
  }

  @override
  ThemeMode get themeMode {
    return _themeMode;
  }

  @override
  set themeMode(ThemeMode value) {
    _themeMode = value;
    _settingsBox.put(_themeModeKey, value.name);
  }

  @override
  AppIcon get appIcon {
    return _appIcon;
  }

  @override
  set appIcon(AppIcon value) {
    _appIcon = value;
    _settingsBox.put(_appIconKey, value.name);
  }

  static Future<SettingsStore> create() async {
    final settingsStore = SettingsStore();
    await settingsStore._init();
    return settingsStore;
  }
}

Settings? _settings;
Settings get settings {
  if (_settings == null) {
    throw Exception("Should only retrieve once initialized");
  }
  return _settings!;
}

Future<void> initSettings() async {
  _settings = await SettingsStore.create();
}
