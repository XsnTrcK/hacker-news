import 'package:flutter/material.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:hive_flutter/hive_flutter.dart';

const _fontSizeKey = 'fontSize';
const _fabPositionKey = 'fabPosition';
const _themeModeKey = 'themeMode';

enum SettingsFontSize {
  small,
  medium,
  large,
}

abstract class Settings {
  late SettingsFontSize fontSize;
  late ExpandableFabPos fabPosition;
  late ThemeMode themeMode;
}

class SettingsStore implements Settings {
  late Box<String> _settingsBox;
  SettingsFontSize _fontSize = SettingsFontSize.small;
  ExpandableFabPos _fabPosition = ExpandableFabPos.right;
  ThemeMode _themeMode = ThemeMode.system;

  Future _init() async {
    _settingsBox = await Hive.openBox<String>("settings");
    final fontSizeName = _settingsBox.get(_fontSizeKey);
    for (var fontSize in SettingsFontSize.values) {
      if (fontSize.name == fontSizeName) {
        _fontSize = fontSize;
      }
    }
    final fabPositionName = _settingsBox.get(_fabPositionKey);
    for (var fabPosition in ExpandableFabPos.values) {
      if (fabPosition.name == fabPositionName) {
        _fabPosition = fabPosition;
      }
    }

    final themeModeName = _settingsBox.get(_themeModeKey);
    for (var themeMode in ThemeMode.values) {
      if (themeMode.name == themeModeName) {
        _themeMode = themeMode;
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
  ExpandableFabPos get fabPosition {
    return _fabPosition;
  }

  @override
  set fabPosition(ExpandableFabPos value) {
    _fabPosition = value;
    _settingsBox.put(_fabPositionKey, value.name);
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
