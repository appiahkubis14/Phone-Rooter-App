import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'platform_channel.dart'; // Custom platform channel for communication with native code.

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Cocoa Monitor Installer",
      theme: ThemeData(primarySwatch: Colors.green),
      home: const InstallAppPage(),
    );
  }
}

class InstallAppPage extends StatefulWidget {
  const InstallAppPage({super.key});

  @override
  _InstallAppPageState createState() => _InstallAppPageState();
}

class _InstallAppPageState extends State<InstallAppPage> {
  final String apkUrl = "https://cocoarehabmonitor.com/media/Cocoa_Monitor_V5.apk";
  late final WebViewController _webViewController;
  bool _isLocked = true; // Start with the device locked.
  bool _isAppInstalled = false; // Track if the app is installed.

  @override
  void initState() {
    super.initState();
    _initializeWebView();
    _lockDevice(); // Lock the device in kiosk mode.
  }

  void _initializeWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.endsWith(".apk")) {
              debugPrint("APK download detected: ${request.url}");
              _downloadAndInstallApk(request.url);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onPageStarted: (String url) => debugPrint("Page started loading: $url"),
          onPageFinished: (String url) {
            debugPrint("Page finished loading: $url");
            _showSnackBar("Page loaded. Follow instructions to install.");
          },
        ),
      )
      ..loadRequest(Uri.parse(apkUrl));
  }

  Future<void> _downloadAndInstallApk(String url) async {
    try {
      debugPrint("Starting APK download from: $url");
      _showSnackBar("Downloading APK...");
      await _unlockDevice(); // Unlock the device for installation.
      await DeviceAdminManager.downloadAndInstallApp(url, "Cocoa Monitor");
      _showSnackBar("Download and installation started.");
      _showSnackBar("APK installation initiated. Please check your device.");
      await _lockDevice(); // Lock the device into kiosk mode after installation.

      // After installation, update the UI to show the app is installed
      setState(() {
        _isAppInstalled = true;
      });
    } catch (e) {
      debugPrint("Error downloading or installing APK: $e");
      _showSnackBar("Error: $e");
    }
  }

  Future<void> _lockDevice() async {
    try {
      await DeviceAdminManager.lockDevice(); // Lock the device in kiosk mode.
      setState(() {
        _isLocked = true;
      });
      _showSnackBar("Device locked into kiosk mode.");
    } catch (e) {
      debugPrint("Error locking device: $e");
      _showSnackBar("Error locking device: $e");
    }
  }

  Future<void> _unlockDevice() async {
    try {
      await DeviceAdminManager.unlockDevice(); // Unlock the device for installation.
      setState(() {
        _isLocked = false;
      });
      _showSnackBar("Device unlocked for installation.");
    } catch (e) {
      debugPrint("Error unlocking device: $e");
      _showSnackBar("Error unlocking device: $e");
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red,
      // appBar: AppBar(
      //   centerTitle: true,
      //   title: const Text("Cocoa Monitor Installer"),
      //   actions: [
      //     IconButton(
      //       icon: const Icon(Icons.lock),
      //       onPressed: () async {
      //         try {
      //           await DeviceAdminManager.lockDevice();
      //           _showSnackBar("Device locked successfully.");
      //         } catch (e) {
      //           debugPrint("Error locking device: $e");
      //           _showSnackBar("Error: $e");
      //         }
      //       },
      //     ),
      //   ],
      // ),
      body: _isLocked
          ? _isAppInstalled
              ? _buildPostInstallScreen() // Show the app after installation.
              : _buildKioskModeScreen() // Show kiosk mode screen during installation.
          : WebViewWidget(controller: _webViewController), // Show the WebView for installation instructions
    );
  }

  Widget _buildKioskModeScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 20),
          const Text(
            'Installing Cocoa Monitor...',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'Please wait while the app installs.',
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildPostInstallScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 50),
          const SizedBox(height: 20),
          const Text(
            'Installation Complete!',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'Cocoa Monitor is now installed and ready.',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _launchApp,
            child: const Text('Open Cocoa Monitor'),
          ),
        ],
      ),
    );
  }

  // Function to open the installed app (if applicable)
  Future<void> _launchApp() async {
    try {
      await DeviceAdminManager.launchApp("com.afarinick.kumad.cocoamonitor");
      _showSnackBar("Opening Cocoa Monitor...");
    } catch (e) {
      debugPrint("Error opening app: $e");
      _showSnackBar("Error: $e");
    }
  }
}
