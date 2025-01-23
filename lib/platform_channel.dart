import 'package:flutter/services.dart';

class DeviceAdminManager {
  static const platform = MethodChannel('com.example.controller');

  static Future<void> enableDeviceAdmin() async {
    try {
      final result = await platform.invokeMethod('enableDeviceAdmin');
      print(result);
    } on PlatformException catch (e) {
      print('Error enabling device admin: ${e.message}');
    }
  }

  static Future<void> lockDevice() async {
    try {
      final result = await platform.invokeMethod('lockDevice');
      print(result);
    } on PlatformException catch (e) {
      print('Error locking device: ${e.message}');
    }
  }

  static Future<void> unlockDevice() async {
    try {
      final result = await platform.invokeMethod('unlockDevice');
      print(result);
    } on PlatformException catch (e) {
      print('Error unlocking device: ${e.message}');
    }
  }

  static Future<void> downloadAndInstallApp(String url, String appName) async {
    try {
      final result = await platform.invokeMethod('downloadAndInstallApp', {
        'url': url,
        'appName': appName,
      });
      print(result);
    } on PlatformException catch (e) {
      print('Error downloading and installing APK: ${e.message}');
    }
  }

  static Future<void> launchApp(String packageName) async {
    try {
      final result = await platform.invokeMethod('launchApp', {'packageName': packageName});
      print(result);
    } on PlatformException catch (e) {
      print("Error launching app: ${e.message}");
    }
  }

  static Future<void> setLock(String packageName) async {
    try {
      final result = await platform.invokeMethod('setLock', {'packageName': packageName});
      print(result);
    } on PlatformException catch (e) {
      print("Error setting lock: ${e.message}");
    }
  }
}
