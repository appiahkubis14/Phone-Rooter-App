class ApiService {
  static const String apiUrl = "https://cocoarehabmonitor.com/media/Cocoa_Monitor_V5.apk";

  static Future<String> getApkUrl() async {
    try {
      return apiUrl;
    } catch (e) {
      throw Exception("Error fetching APK URL: $e");
    }
  }
}
