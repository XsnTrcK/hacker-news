import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hackernews/bloc/base_bloc.dart';
import 'package:hackernews/services/app_icon_channel.dart';
import 'package:hackernews/settings/bloc/settings_events.dart';
import 'package:hackernews/settings/bloc/settings_state.dart';
import 'package:hackernews/store/settings_store.dart';

class SettingsBloc extends ThrottledBloc<SettingsEvent, SettingsBlocUpdated> {
  final AppIconChannel _appIconChannel;
  final _iconUpdateFailedController = StreamController<void>.broadcast();

  // Emits when an UpdateAppIconEvent fails to apply at the platform level.
  // Bloc state deliberately stays untouched on failure (it keeps reflecting
  // the last successfully-applied icon), so the Settings UI listens here to
  // show a SnackBar instead of relying on a rebuild triggered by emit().
  Stream<void> get iconUpdateFailed => _iconUpdateFailedController.stream;

  SettingsBloc({AppIconChannel? appIconChannel})
      : _appIconChannel = appIconChannel ?? AppIconChannel(),
        super(const SettingsBlocUpdated()) {
    on<UpdateFontSizeEvent>(_onUpdateFontSize,
        transformer: throttleDroppable());
    on<UpdateThemeModeEvent>(_onUpdateThemeMode,
        transformer: throttleDroppable());
    on<UpdateAppIconEvent>(_onUpdateAppIcon,
        transformer: throttleDroppable());
  }

  void _onUpdateFontSize(
      UpdateFontSizeEvent event, Emitter<SettingsBlocUpdated> emit) {
    settings.fontSize = event.fontSize;
    // ignore: prefer_const_constructors force block to reload whenever something in settings change
    emit(SettingsBlocUpdated());
  }

  void _onUpdateThemeMode(
      UpdateThemeModeEvent event, Emitter<SettingsBlocUpdated> emit) {
    settings.themeMode = event.themeMode;
    // ignore: prefer_const_constructors force block to reload whenever something in settings change
    emit(SettingsBlocUpdated());
  }

  Future<void> _onUpdateAppIcon(
      UpdateAppIconEvent event, Emitter<SettingsBlocUpdated> emit) async {
    try {
      await _appIconChannel.setIcon(event.icon);
    } catch (_) {
      _iconUpdateFailedController.add(null);
      return;
    }
    settings.appIcon = event.icon;
    // ignore: prefer_const_constructors force block to reload whenever something in settings change
    emit(SettingsBlocUpdated());
  }

  @override
  Future<void> close() {
    _iconUpdateFailedController.close();
    return super.close();
  }
}
