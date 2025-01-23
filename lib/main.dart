import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'platform_channel.dart'; // Custom platform channel for communication with native code.
import 'package:flutter/services.dart';

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
  final String apkUrl =
      "https://cocoarehabmonitor.com/media/Cocoa_Monitor_V5.apk";
  late final WebViewController _webViewController;
  bool _isLocked = true;
  bool _isAppInstalled = false;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
    _lockDevice();
    // SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _lockDevice();
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
          onPageStarted: (String url) =>
              debugPrint("Page started loading: $url"),
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
      // SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
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

  int _unlockAttempts = 0;
  bool _isLockedForever = false;

  Future<void> _unlockDevice() async {
    try {
      if (_isLockedForever) {
        _showSnackBar(
            "Device is permanently locked. No further unlock attempts allowed.");
        return;
      }
      bool isPinCorrect = await _showPinDialog();
      if (isPinCorrect) {
        await DeviceAdminManager.unlockDevice();
        setState(() {
          _isLocked = false;
        });
        _showSnackBar("Device unlocked for installation.");
      } else {
        _unlockAttempts++;
        if (_unlockAttempts >= 3) {
          _isLockedForever = true;
          _showSnackBar(
              "Incorrect PIN entered 3 times. Device locked forever.");
        } else {
          _showSnackBar(
              "Incorrect PIN. You have ${3 - _unlockAttempts} attempts left.");
        }
      }
    } catch (e) {
      debugPrint("Error unlocking device: $e");
      _showSnackBar("Error unlocking device: $e");
    }
  }

  Future<bool> _showPinDialog() async {
    final TextEditingController pinController = TextEditingController();
    bool isPinCorrect = false;

    return await showDialog<bool>(
          context: context,
          barrierDismissible: false, // Prevent closing by tapping outside
          builder: (BuildContext context) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 10,
              child: Container(
                height: 300,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color.fromARGB(255, 235, 40, 6),
                      const Color.fromARGB(255, 244, 3, 224)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Enter Admin PIN",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: TextField(
                          controller: pinController,
                          obscureText: true,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign
                              .center, // Center the text inside the TextField
                          style: TextStyle(
                            fontSize:
                                24, // Increase font size for better readability
                            color: Colors.white,
                          ),
                          decoration: InputDecoration(
                            labelText: "PIN",
                            labelStyle: TextStyle(color: Colors.white70),
                            hintText: "Enter your PIN",
                            hintStyle: TextStyle(color: Colors.white54),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white54),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                                vertical: 18.0,
                                horizontal: 16.0), // Increase padding
                          ),
                        )),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: ElevatedButton(
                        onPressed: () {
                          if (pinController.text == '1234') {
                            // Replace '1234' with actual PIN
                            isPinCorrect = true;
                            Navigator.of(context).pop(true);
                          } else {
                            isPinCorrect = false;
                            Navigator.of(context).pop(false);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.green,
                          padding: EdgeInsets.symmetric(
                              horizontal: 40, vertical: 12),
                        ),
                        child: Text(
                          "Unlock",
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(false);
                        },
                        child: Text(
                          "Cancel",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    if (_unlockAttempts >= 3)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          "Device permanently locked after 3 failed attempts.",
                          style:
                              TextStyle(color: Colors.redAccent, fontSize: 14),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ) ??
        false;
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _toggleLock() async {
    try {
      if (_isLocked) {
        // Unlock the device
        await _unlockDevice();
        setState(() {
          _isLocked = false;
        });
        _showSnackBar("Device unlocked successfully.");
      } else {
        // Lock the device
        await _lockDevice();
        setState(() {
          _isLocked = true;
        });
        _showSnackBar("Device locked successfully.");
      }
    } catch (e) {
      debugPrint("Error toggling device lock: $e");
      _showSnackBar("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red,
      appBar: AppBar(
        backgroundColor: Colors.red,
        centerTitle: true,
        // title: const Text("Cocoa Monitor Installer"),
        actions: [
          IconButton(
            icon: Icon(
              _isLocked
                  ? Icons.lock
                  : Icons.lock_open, // Change icon based on lock state
              color: _isLocked
                  ? const Color.fromARGB(255, 54, 4, 46)
                  : Colors.green, // Change color based on lock state
              size: 50,
            ),
            onPressed: _toggleLock,
          ),
        ],
      ),
      body: _isLocked
          ? _isAppInstalled
              ? _buildPostInstallScreen()
              : _buildKioskModeScreen()
          : WebViewWidget(controller: _webViewController),
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
          Column(
            children: [
              IconButton(
                onPressed: _launchApp,
                icon: Image.asset(
                  'assets/images/cocoa_monitor.png', // Custom image asset
                  width: 50, // Set the size as needed
                  height: 50,
                ),
              ),
              const Text(
                'Cocoa Monitor',
                style: TextStyle(fontSize: 16),
              ),
            ],
          )
        ],
      ),
    );
  }

  Future<void> _launchApp() async {
    try {
      // SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      await _unlockDevice();
      // SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      await DeviceAdminManager.launchApp("com.afarinick.kumad.cocoamonitor");
      await _lockDevice();
      // SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      // await DeviceAdminManager.setLock("com.afarinick.kumad.cocoamonitor");
    } catch (e) {
      debugPrint("Error opening app: $e");
      _showSnackBar("Error: $e");
    }
  }
}
