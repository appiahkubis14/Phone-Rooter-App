import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String apiUrl = "https://yourapi.com/apps";

  static Future<List<Map<String, String>>> fetchApps() async {
  try {
    final response = await http.get(Uri.parse(apiUrl));
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((app) {
        return {
          "app_name": app["app_name"] as String,
          "apk_url": app["apk_url"] as String,
        };
      }).toList();
    } else {
      throw Exception("Failed to load apps");
    }
  } catch (e) {
    throw Exception("Error fetching apps: $e");
  }
}

}
