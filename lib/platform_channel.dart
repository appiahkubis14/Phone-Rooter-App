import 'package:flutter/services.dart';

class PlatformChannel {
  static const MethodChannel _channel = MethodChannel('com.yourapp/root');

  /// Sends a request to the native side to install an app.
  static Future<void> installApp(String apkPath) async {
    try {
      await _channel.invokeMethod('installApp', {'apkPath': apkPath});
    } catch (e) {
      throw Exception("Failed to install app: $e");
    }
  }
}
