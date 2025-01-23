import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class AppDownloader {
  static Future<String> downloadApk(String url, String fileName) async {
    try {
      if (Platform.isAndroid) {
        PermissionStatus storagePermission = await Permission.storage.request();
        if (!storagePermission.isGranted) {
          throw Exception("Storage permission denied.");
        }
      }

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final directory = await getExternalStorageDirectory();
        final directoryPath = directory?.path ?? "/storage/emulated/0/Download";

        final dir = Directory(directoryPath);
        if (!dir.existsSync()) {
          dir.createSync(recursive: true);
        }

        final filePath = "$directoryPath/$fileName.apk";
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        return filePath;
      } else {
        throw Exception("Failed to download APK: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error downloading APK: $e");
    }
  }
}
