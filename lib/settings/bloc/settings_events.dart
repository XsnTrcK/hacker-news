import 'package:hackernews/store/settings_store.dart';

abstract class SettingsEvent {
  const SettingsEvent();
}

class UpdateFontSizeEvent extends SettingsEvent {
  final SettingsFontSize fontSize;
  const UpdateFontSizeEvent(this.fontSize) : super();
}
