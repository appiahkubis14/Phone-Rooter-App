// // ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api

// import 'package:controller/api_service.dart';
// import 'package:controller/app_download.dart';
// import 'package:controller/platform_channel.dart';
// import 'package:flutter/material.dart';

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       home: AppListScreen(),
//     );
//   }
// }

// class AppListScreen extends StatefulWidget {
//   const AppListScreen({super.key});

//   @override
//   _AppListScreenState createState() => _AppListScreenState();
// }

// class _AppListScreenState extends State<AppListScreen> {
//   late Future<List<Map<String, String>>> _apps;
//   bool _isKioskMode = false;

//   @override
//   void initState() {
//     super.initState();
//     _checkKioskMode();
//     // _apps = ApiService.fetchApps();
//   }

//   Future<void> _checkKioskMode() async {
//     final isKiosk = await PlatformChannel.isKioskModeActive();
//     setState(() {
//       _isKioskMode = isKiosk;
//     });
//   }

//   void _installApp(String apkUrl, String appName) async {
//     try {
//       final apkPath = await AppDownloader.downloadApk(apkUrl, appName);
//       await PlatformChannel.installApp(apkPath);
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//         content: Text("$appName installed successfully"),
//       ));
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//         content: Text("Failed to install $appName: $e"),
//       ));
//     }
//   }

//   Future<void> _exitKioskMode() async {
//     final success = await PlatformChannel.exitKioskMode();
//     if (success) {
//       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
//         content: Text("Exited kiosk mode"),
//       ));
//       setState(() {
//         _isKioskMode = false;
//       });
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
//         content: Text("Failed to exit kiosk mode"),
//       ));
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_isKioskMode) {
//       return Scaffold(
//         body: Center(
//           child: ElevatedButton(
//             onPressed: _exitKioskMode,
//             child: const Text("Exit Kiosk Mode"),
//           ),
//         ),
//       );
//     }

//     return Scaffold(
//       appBar: AppBar(title: const Text("Available Apps")),
//       body: FutureBuilder<List<Map<String, String>>>(
//         future: _apps,
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           } else if (snapshot.hasError) {
//             return Center(child: Text("Error: ${snapshot.error}"));
//           } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
//             return const Center(child: Text("No apps available"));
//           } else {
//             final apps = snapshot.data!;
//             return ListView.builder(
//               itemCount: apps.length,
//               itemBuilder: (context, index) {
//                 final app = apps[index];
//                 return ListTile(
//                   title: Text(app["app_name"]!),
//                   trailing: ElevatedButton(
//                     onPressed: () => _installApp(app["apk_url"]!, app["app_name"]!),
//                     child: const Text("Install"),
//                   ),
//                 );
//               },
//             );
//           }
//         },
//       ),
//     );
//   }
// }
