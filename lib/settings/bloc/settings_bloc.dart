import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hackernews/bloc/base_bloc.dart';
import 'package:hackernews/settings/bloc/settings_events.dart';
import 'package:hackernews/settings/bloc/settings_state.dart';
import 'package:hackernews/store/settings_store.dart';

class SettingsBloc extends ThrottledBloc<SettingsEvent, SettingsBlocUpdated> {
  SettingsBloc() : super(const SettingsBlocUpdated()) {
    on<UpdateFontSizeEvent>(_onUpdateFontSize,
        transformer: throttleDroppable());
    on<UpdateFabPositionEvent>(_onUpdateFabPosition,
        transformer: throttleDroppable());
    on<UpdateThemeModeEvent>(_onUpdateThemeMode,
        transformer: throttleDroppable());
  }

  void _onUpdateFontSize(
      UpdateFontSizeEvent event, Emitter<SettingsBlocUpdated> emit) {
    settings.fontSize = event.fontSize;
    // ignore: prefer_const_constructors force block to reload whenever something in settings change
    emit(SettingsBlocUpdated());
  }

  void _onUpdateFabPosition(
      UpdateFabPositionEvent event, Emitter<SettingsBlocUpdated> emit) {
    settings.fabPosition = event.fabPosition;
    // ignore: prefer_const_constructors force block to reload whenever something in settings change
    emit(SettingsBlocUpdated());
  }

  void _onUpdateThemeMode(
      UpdateThemeModeEvent event, Emitter<SettingsBlocUpdated> emit) {
    settings.themeMode = event.themeMode;
    // ignore: prefer_const_constructors force block to reload whenever something in settings change
    emit(SettingsBlocUpdated());
  }
}
