import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart'; // For storing biometric flag

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  // Sign up with email and password and store additional user data
  Future<UserCredential> signUpWithEmailPassword(
    String email,
    String password,
    String name,
    String icNumber,
    String dob,
    String address,
  ) async {
    try {
      final response = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name
      await response.user?.updateDisplayName(name);

      // Store additional user details in Firestore (example)
      await FirebaseFirestore.instance
          .collection('userInformation')
          .doc(response.user?.uid)
          .set({
        'name': name,
        'icNumber': icNumber,
        'dob': dob,
        'address': address,
      });

      return response;
    } catch (e) {
      throw Exception('Sign-up failed: ${e.toString()}');
    }
  }

  // Sign-in with email and password
  Future<UserCredential> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    try {
      final response = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return response;
    } catch (e) {
      throw Exception('Sign-in failed: ${e.toString()}');
    }
  }

  // Check if biometric authentication is enabled
  Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('biometric_enabled') ??
        false; // Default to false if not set
  }

  // Enable or disable biometric authentication
  Future<void> setBiometricEnabled(bool isEnabled) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('biometric_enabled', isEnabled); // Set the flag for biometric
  }

  // Sign out
  Future<void> signOut() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      prefs.remove('biometric_enabled'); // Clear biometric flag on logout
      await _firebaseAuth.signOut();
    } catch (e) {
      throw Exception('Sign-out failed: ${e.toString()}');
    }
  }
}
