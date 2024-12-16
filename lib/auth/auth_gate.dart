import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:authenticationapp2/pages/home_page.dart';
import 'package:authenticationapp2/pages/login_page.dart';

class AuthGate extends StatefulWidget {
  final String? savedEmail;
  final String? savedName;

  const AuthGate({super.key, this.savedEmail, this.savedName});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Display a loading indicator while waiting for authentication state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Check if the user is logged in
        final user = snapshot.data;
        if (user != null) {
          // User is logged in, navigate to HomePage
          return const HomePage();
        } else {
          // User is not logged in, navigate to LoginPage
          return const LoginPage();
        }
      },
    );
  }
}
