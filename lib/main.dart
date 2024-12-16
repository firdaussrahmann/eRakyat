import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:root_checker_plus/root_checker_plus.dart';
import 'package:vpn_connection_detector/vpn_connection_detector.dart';
import 'pages/home_page.dart';
import 'pages/profile_page.dart';
import 'pages/login_page.dart';
import 'pages/secretpage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // make navigation bar transparent
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
    ),
  );
  // make flutter draw behind navigation bar
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Preserve splash screen
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Simulate a delay for splash
  await Future.delayed(const Duration(seconds: 1));

  // Remove splash screen
  FlutterNativeSplash.remove();

  // Check root and VPN status
  bool isBlocked = await _isBlocked();
  if (isBlocked) {
    runApp(const BlockedAppScreen());
  } else {
    runApp(const AuthenticationApp());
  }
}

// Function to check root and VPN
Future<bool> _isBlocked() async {
  bool isRooted = false;

  // Check for root access
  try {
    isRooted = (await RootCheckerPlus.isRootChecker())!;
  } catch (e) {
    // If an exception is thrown, it indicates root access is detected
    isRooted = true;
  }

  // Check VPN status
  bool isVpnConnected = await VpnConnectionDetector.isVpnActive();

  return isRooted || isVpnConnected;
}

class AuthenticationApp extends StatelessWidget {
  const AuthenticationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Authentication App',
      theme: ThemeData(),
      initialRoute: '/login', // Default route to login page
      routes: <String, WidgetBuilder>{
        '/home': (context) => const HomePage(),
        '/login': (context) => const LoginPage(),
        '/secretpage': (context) => const SecretPage(),
        '/profile': (context) => const ProfilePage(
              scannedData: {},
            ),
      },
    );
  }
}

class BlockedAppScreen extends StatelessWidget {
  const BlockedAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF4169E1),
          title: const Text(
            "Access Blocked",
            style: TextStyle(color: Colors.white),
          ),
          centerTitle: true,
        ),
        backgroundColor: const Color(0xFF4169E1),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Your device is either rooted or you're using a VPN.",
                style: TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 20),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.orange, // Button color
                ),
                onPressed: () {
                  SystemNavigator.pop();
                },
                child: const Text("Close App"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
