import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Service managing the native Android Floating Overlay and Screen Capture
class OverlayService {
  static const MethodChannel _channel = MethodChannel('com.example.chess_engine_app/overlay');

  static final StreamController<Map<String, dynamic>> _moveEventController =
      StreamController<Map<String, dynamic>>.broadcast();

  /// Stream of live move detection events from the overlay
  static Stream<Map<String, dynamic>> get onMoveDetected => _moveEventController.stream;

  /// Check if the app has Android "Display over other apps" permission
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

  /// Open Android System Settings to grant "Display over other apps"
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

  /// Launch the Floating Assistant Bubble
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

  /// Request Android MediaProjection Screen Capture permission
  static Future<bool> startScreenCapture() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return true;
    }
    try {
      final bool? result = await _channel.invokeMethod<bool>('startScreenCapture');
      return result ?? false;
    } catch (e) {
      debugPrint('Error starting screen capture: $e');
      return false;
    }
  }

  /// Close and remove the Floating Assistant Bubble
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

  /// Push an evaluation, best move, and depth to the Floating Overlay
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

  /// Sync/Reset the match state to move 1
  static Future<void> syncMatch({bool isWhite = true}) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }
    try {
      await updateOverlay(
        eval: '+0.3',
        bestMove: isWhite ? 'e4' : 'c5',
        isWhite: isWhite,
      );
    } catch (e) {
      debugPrint('Error syncing match state: $e');
    }
  }
}
