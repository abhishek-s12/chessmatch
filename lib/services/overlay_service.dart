import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class OverlayService {
  static const MethodChannel _channel = MethodChannel('com.example.chess_engine_app/overlay');

  static Future<bool> checkPermission() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return true;
    }
    try {
      final bool hasPermission = await _channel.invokeMethod('checkPermission');
      return hasPermission;
    } catch (e) {
      debugPrint('Error checking overlay permission: $e');
      return false;
    }
  }

  static Future<bool> requestPermission() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return true;
    }
    try {
      final bool result = await _channel.invokeMethod('requestPermission');
      return result;
    } catch (e) {
      debugPrint('Error requesting overlay permission: $e');
      return false;
    }
  }

  static Future<void> startOverlay() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      debugPrint('Floating overlay is an Android native feature');
      return;
    }
    try {
      await _channel.invokeMethod('startOverlay');
    } catch (e) {
      debugPrint('Error starting overlay service: $e');
    }
  }

  static Future<void> stopOverlay() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }
    try {
      await _channel.invokeMethod('stopOverlay');
    } catch (e) {
      debugPrint('Error stopping overlay service: $e');
    }
  }

  static Future<void> updateOverlay({
    required String eval,
    required String bestMove,
    required bool isWhite,
    int depth = 12,
  }) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }
    try {
      await _channel.invokeMethod('updateOverlay', {
        'eval': eval,
        'bestMove': bestMove,
        'isWhite': isWhite,
        'depth': depth,
      });
    } catch (e) {
      debugPrint('Error updating overlay: $e');
    }
  }
}
