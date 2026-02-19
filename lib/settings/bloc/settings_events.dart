import 'package:flutter/material.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:hackernews/store/settings_store.dart';

abstract class SettingsEvent {
  const SettingsEvent();
}

class UpdateFontSizeEvent extends SettingsEvent {
  final SettingsFontSize fontSize;
  const UpdateFontSizeEvent(this.fontSize) : super();
}

class UpdateFabPositionEvent extends SettingsEvent {
  final ExpandableFabPos fabPosition;
  const UpdateFabPositionEvent(this.fabPosition) : super();
}

class UpdateThemeModeEvent extends SettingsEvent {
  final ThemeMode themeMode;
  const UpdateThemeModeEvent(this.themeMode) : super();
}
