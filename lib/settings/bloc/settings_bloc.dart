import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hackernews/bloc/base_bloc.dart';
import 'package:hackernews/settings/bloc/settings_events.dart';
import 'package:hackernews/settings/bloc/settings_state.dart';
import 'package:hackernews/store/settings_store.dart';

class SettingsBloc extends ThrottledBloc<SettingsEvent, SettingsBlocUpdated> {
  SettingsBloc() : super(const SettingsBlocUpdated()) {
    on<UpdateFontSizeEvent>(_onUpdateFontSize,
        transformer: throttleDroppable());
  }

  void _onUpdateFontSize(
      UpdateFontSizeEvent event, Emitter<SettingsBlocUpdated> emit) {
    settings.fontSize = event.fontSize;
    // ignore: prefer_const_constructors force block to reload whenever something in settings change
    emit(SettingsBlocUpdated());
  }
}
