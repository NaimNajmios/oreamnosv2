import 'package:flutter/services.dart';
import 'package:quick_settings/quick_settings.dart';

import 'log_service.dart';

import 'package:oreamnos/core/di/injection.dart';

@pragma('vm:entry-point')
Tile? quickSettingsOnTileClicked(Tile tile) {
  getIt<LogService>().info('Quick Settings tile clicked');
  return Tile(
    label: "Oreamnos",
    subtitle: "Paste to AI",
    tileStatus: TileStatus.active,
  );
}

@pragma('vm:entry-point')
Tile? quickSettingsOnTileAdded(Tile tile) {
  getIt<LogService>().info('Quick Settings tile added');
  return Tile(label: "Paste to AI", tileStatus: TileStatus.inactive);
}

@pragma('vm:entry-point')
void quickSettingsOnTileRemoved() {
  getIt<LogService>().info('Quick Settings tile removed');
}

@pragma('vm:entry-point')
class QuickSettingsService {
  static Future<void> init() async {
    try {
      // Setup the tile's default state - use top-level entry-point functions
      // so PluginUtilities.getCallbackHandle can resolve them in AOT/release.
      QuickSettings.setup(
        onTileClicked: quickSettingsOnTileClicked,
        onTileAdded: quickSettingsOnTileAdded,
        onTileRemoved: quickSettingsOnTileRemoved,
      );

      // Update the tile UI
      await QuickSettings.addTileToQuickSettings(
        label: "Paste to AI",
        drawableName: "ic_launcher",
      );
    } on PlatformException catch (e) {
      getIt<LogService>().error('Quick Settings not supported or error', e);
    }
  }
}
