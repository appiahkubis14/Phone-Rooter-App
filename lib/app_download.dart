import 'dart:io';
import 'package:http/http.dart' as http;

class AppDownloader {
  /// Downloads an APK file from a URL and saves it to the specified directory.
  static Future<String> downloadApk(String url, String fileName) async {
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        // Specify a custom directory path (e.g., Downloads folder)
        final directoryPath = "/storage/emulated/0/Download";

        // Ensure the directory exists
        final directory = Directory(directoryPath);
        if (!directory.existsSync()) {
          directory.createSync(recursive: true);
        }

        // Define the file path
        final filePath = "$directoryPath/$fileName.apk";

        // Save the APK file
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        return filePath; // Return the path of the downloaded file
      } else {
        throw Exception("Failed to download APK: HTTP ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error downloading APK: $e");
    }
  }
}
