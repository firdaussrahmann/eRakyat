import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/auth_service.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService _authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  bool _isAuthenticated = false;
  bool _isLoading = false;
  bool _isBiometricLoading = false;
  bool _isBiometricAvailable = false;
  static const int tokenValidityDuration =
      3600; // Token validity in seconds (1 hour)

  @override
  void initState() {
    super.initState();
    _checkUserLoggedIn();
  }

  // Check token validity
  Future<bool> _isTokenValid() async {
    final savedTokenTimestamp =
        await _secureStorage.read(key: 'token_timestamp');
    if (savedTokenTimestamp != null) {
      final tokenTime = DateTime.parse(savedTokenTimestamp);
      final currentTime = DateTime.now();
      return currentTime.difference(tokenTime).inSeconds <=
          tokenValidityDuration;
    }
    return false;
  }

  // Check if user is already logged in or if there's a valid stored token
  Future<void> _checkUserLoggedIn() async {
    final user = FirebaseAuth.instance.currentUser;
    final savedEmail = await _secureStorage.read(key: 'user_email');
    final isTokenStillValid = await _isTokenValid();

    setState(() {
      _isAuthenticated = user != null && isTokenStillValid;
      if (savedEmail != null) {
        _emailController.text = savedEmail;
      }
    });

    // Invalidate token if expired
    if (!isTokenStillValid) {
      await _secureStorage.delete(key: 'user_token');
    }

    // Check if biometric authentication is possible
    _checkBiometricAvailability();
  }

  // Check if biometric authentication is available
  Future<void> _checkBiometricAvailability() async {
    final canAuthenticateWithBiometrics = await _localAuth.canCheckBiometrics;
    final hasBiometricHardware = await _localAuth.isDeviceSupported();
    setState(() {
      _isBiometricAvailable =
          canAuthenticateWithBiometrics && hasBiometricHardware;
    });
  }

  // Log in with email and password
  Future<void> login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    setState(() {
      _isLoading = true; // Show loading state
    });

    try {
      final response =
          await _authService.signInWithEmailPassword(email, password);

      if (response.user != null) {
        // Save token and timestamp
        final userToken = response.user?.uid ?? '';
        await _secureStorage.write(key: 'user_token', value: userToken);
        await _secureStorage.write(
            key: 'token_timestamp', value: DateTime.now().toIso8601String());

        setState(() {
          _isAuthenticated = true;
        });

        // Do not trigger biometric auth immediately; move to home page
        _navigateToHome();
      } else {
        _showSnackbar("Login failed: No user found");
      }
    } catch (e) {
      _showSnackbar("Error: $e");
    } finally {
      setState(() {
        _isLoading = false; // Hide loading state
      });
    }
  }

  // Biometric authentication
  Future<void> _authenticateWithBiometrics() async {
    if (!mounted) return;

    setState(() => _isBiometricLoading = true);

    try {
      final isAuthenticated = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to continue',
        options: const AuthenticationOptions(biometricOnly: true),
      );

      if (isAuthenticated) {
        _navigateToHome();
      } else {
        _showSnackbar("Authentication failed");
      }
    } catch (e) {
      _showSnackbar("Error: $e");
    } finally {
      setState(() => _isBiometricLoading = false);
    }
  }

  // Navigate to Home page
  void _navigateToHome() {
    Navigator.pushReplacementNamed(context, '/home');
  }

  // Show a snackbar with a message
  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  // Show biometric prompt if available
  void _showBiometricPrompt() {
    if (_isBiometricAvailable) {
      _authenticateWithBiometrics();
    } else {
      _navigateToHome();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4169E1),
      appBar: AppBar(
        title: const Text(
          "Login",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF4169E1),
      ),
      body: Stack(
        children: [
          // Main login form
          ListView(
            padding: const EdgeInsets.symmetric(horizontal: 75, vertical: 100),
            children: [
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: "Email",
                  labelStyle: const TextStyle(color: Colors.white),
                  prefixIcon: const Icon(Icons.email, color: Colors.white),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white, width: 1),
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.orange, width: 2),
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: "Password",
                  labelStyle: const TextStyle(color: Colors.white),
                  prefixIcon: const Icon(Icons.lock, color: Colors.white),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white, width: 1),
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.orange, width: 2),
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 30),
              FilledButton(
                onPressed: _isLoading ? null : login,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.orange, // Button color
                ),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text("Login"),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const RegisterPage()),
                  );
                },
                child: const Text(
                  "No account? Sign up now!",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          // FAB for biometric login if token is valid
          if (_isAuthenticated && _isBiometricAvailable && !_isBiometricLoading)
            Positioned(
              bottom: 40,
              right: 20,
              child: FloatingActionButton.extended(
                backgroundColor: Colors.orange,
                elevation: 70.00,
                enableFeedback: true,
                onPressed:
                    _isBiometricLoading ? null : _authenticateWithBiometrics,
                label: const Text('Biometric Login'),
                icon: _isBiometricLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Icon(Icons.fingerprint_rounded),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
