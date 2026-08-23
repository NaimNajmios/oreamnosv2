import 'package:flutter/services.dart';
import 'package:quick_settings/quick_settings.dart';

import 'log_service.dart';

class QuickSettingsService {
  static Future<void> init() async {
    try {
      // Setup the tile's default state
      QuickSettings.setup(
        onTileClicked: _onTileClicked,
        onTileAdded: _onTileAdded,
        onTileRemoved: _onTileRemoved,
      );
      
      // Update the tile UI
      await QuickSettings.addTileToQuickSettings(
        label: "Paste to AI",
        drawableName: "ic_launcher",
      );
      
    } on PlatformException catch (e) {
      LogService().error('Quick Settings not supported or error', e);
    }
  }

  static Tile? _onTileClicked(Tile tile) {
    LogService().info('Quick Settings tile clicked');
    
    return Tile(
      label: "Oreamnos",
      subtitle: "Paste to AI",
      tileStatus: TileStatus.active,
    );
  }

  static Tile? _onTileAdded(Tile tile) {
    LogService().info('Quick Settings tile added');
    return Tile(
      label: "Paste to AI",
      tileStatus: TileStatus.inactive,
    );
  }

  static void _onTileRemoved() {
    LogService().info('Quick Settings tile removed');
  }
}

