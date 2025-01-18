import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:controller/api_service.dart';
import 'package:controller/app_download.dart';
import 'package:controller/platform_channel.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: AppListScreen(),
    );
  }
}

class AppListScreen extends StatefulWidget {
  const AppListScreen({super.key});

  @override
  _AppListScreenState createState() => _AppListScreenState();
}

class _AppListScreenState extends State<AppListScreen> {
  late Future<List<Map<String, String>>> _apps;

  @override
  void initState() {
    super.initState();
    _apps = ApiService.fetchApps();
  }

  void _installApp(String apkUrl, String appName) async {
    try {
      final apkPath = await AppDownloader.downloadApk(apkUrl, appName);
      await PlatformChannel.installApp(apkPath);

      // Lock the phone into kiosk mode after installation
      await PlatformChannel.lockDevice();

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("$appName installed and device locked successfully"),
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Failed to install $appName: $e"),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Available Apps")),
      body: FutureBuilder<List<Map<String, String>>>(

        future: _apps,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text("No apps available"));
          } else {
            final apps = snapshot.data!;
            return ListView.builder(
              itemCount: apps.length,
              itemBuilder: (context, index) {
                final app = apps[index];
                return ListTile(
                  title: Text(app["app_name"]!),
                  trailing: ElevatedButton(
                    onPressed: () => _installApp(app["apk_url"]!, app["app_name"]!),
                    child: Text("Install"),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
