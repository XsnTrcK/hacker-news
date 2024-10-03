import 'package:hive_flutter/hive_flutter.dart';

const _fontSizeKey = 'fontSize';

enum SettingsFontSize {
  small,
  medium,
  large,
}

abstract class Settings {
  late SettingsFontSize fontSize;
}

class SettingsStore implements Settings {
  late Box<String> _settingsBox;
  SettingsFontSize _fontSize = SettingsFontSize.small;

  Future _init() async {
    _settingsBox = await Hive.openBox<String>("settings");
    final fontSizeName = _settingsBox.get(_fontSizeKey);
    for (var fontSize in SettingsFontSize.values) {
      if (fontSize.name == fontSizeName) {
        _fontSize = fontSize;
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
