import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:hackernews/store/settings_store.dart';

import 'app_icon_favicon.dart' as favicon;

const _channel = MethodChannel('app_icons');

const Map<AppIcon, String> _faviconAssets = {
  AppIcon.icon: 'icons/favicon-icon.png',
  AppIcon.crayons: 'icons/favicon-crayons.png',
  AppIcon.lines: 'icons/favicon-lines.png',
};

class AppIconChannel {
  Future<void> setIcon(AppIcon icon) async {
    if (kIsWeb) {
      await favicon.updateFavicon(_faviconAssets[icon]!);
      return;
    }
    if (Platform.isAndroid || Platform.isIOS) {
      await _channel.invokeMethod('setIcon', {'icon': icon.name});
    }
  }
}
