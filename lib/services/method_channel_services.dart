import 'package:echo_share/models/swipe_event.dart';
import 'package:echo_share/models/tap_event.dart';
import 'package:flutter/services.dart';

class MethodChannelServices {
  late final MethodChannel _channel;
  bool _isOpenSettingsCalled = false;

  static final MethodChannelServices screenRecordChannel =
      MethodChannelServices._internal("screen_record");
  static final MethodChannelServices controlChannel =
      MethodChannelServices._internal("control_channel");

  MethodChannelServices._internal(String name) {
    _channel = MethodChannel(name);
  }
  configImageRecieved(void Function(Uint8List) callback) {
    _channel.setMethodCallHandler(null);
    _channel.setMethodCallHandler((call) async {
      var data = call.arguments as Uint8List;
      callback(data);
    });
  }

  configControlRecieved(void Function(MethodCall) callback) {
    _channel.setMethodCallHandler(null);
    _channel.setMethodCallHandler((call) async {
      callback(call);
    });
  }

  Future<bool> checkAccessibilityService() async {
    try {
      final bool result =
          await _channel.invokeMethod('checkAccessibilityService');
      if (result) {
        return result;
      } else if (!_isOpenSettingsCalled) {
        _isOpenSettingsCalled = true;
        return await openAccessibilitySettings();
      }
      return false;
    } on PlatformException catch (e) {
      print("Failed to check accessibility service: '${e.message}'.");
    }
    return false;
  }

  Future<bool> openAccessibilitySettings() async {
    try {
      final result = await _channel.invokeMethod('openAccessibilitySettings');
      _isOpenSettingsCalled = false;
      return result;
    } on PlatformException catch (e) {
      // Handle platform exceptions
      print("Failed to open accessibility settings: '${e.message}'.");
    }
    return false;
  }

  Future<String?> startRecording(Size screenSize) async {
    try {
      return await _channel.invokeMethod('startRecording', {
        'width': screenSize.height.toInt(),
        'height': screenSize.width.toInt(),
      });
    } on PlatformException catch (e) {
      print("Error starting recording: ${e.message}");
      return null;
    }
  }

  tap(TapEvent event) async {
    _tryInvokeMethod(() async {
      await _channel.invokeMethod('simulateTap', {'x': event.x, 'y': event.y});
    });
  }

  swipe(SwipeEvent event) async {
    _tryInvokeMethod(() async {
      await _channel.invokeMethod('simulateSwipe', {
        'startX': event.startX,
        'startY': event.startY,
        'endX': event.endX,
        'endY': event.endY,
        'duration': event.duration,
      });
    });
  }

  _tryInvokeMethod(Future<void> Function() callback) async {
    if (!await checkAccessibilityService()) {
      return;
    }
    try {
      await callback();
    } on PlatformException catch (e) {
      print("Failed to move app to background: ${e.message}");
    }
  }

  Future<void> moveToBackground() async {
    try {
      await _channel.invokeMethod('moveToBackground');
    } on PlatformException catch (e) {
      print("Failed to move app to background: ${e.message}");
    }
  }

  Future<void> stopRecording() async {
    try {
      await _channel.invokeMethod('stopRecording');
    } on PlatformException catch (e) {
      print("Error stopping recording: ${e.message}");
    }
  }
}
