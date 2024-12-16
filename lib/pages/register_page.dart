import 'package:authenticationapp2/pages/idscanner.dart';
import 'package:flutter/material.dart';
import '../auth/auth_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final AuthService _authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _icController = TextEditingController();
  final _nameController = TextEditingController();
  final _dobController = TextEditingController();
  final _addressController = TextEditingController();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Method to register the user
  Future<void> register() async {
    if (!_isValidForm()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields correctly")),
      );
      return;
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final icNumber = _icController.text.trim();
    final name = _nameController.text.trim();
    final dob = _dobController.text.trim();
    final address = _addressController.text.trim();

    try {
      final response = await _authService.signUpWithEmailPassword(
        email,
        password,
        icNumber,
        name,
        dob,
        address,
      );

      if (response.user != null) {
        // Save email and name to secure storage for future login
        await _secureStorage.write(key: 'user_email', value: email);
        await _secureStorage.write(key: 'user_full_name', value: name);

        // Navigate to login page after successful registration
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Registration failed")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  // Method to trigger the MyKad scanning
  Future<void> scanMyKadAndPopulate() async {
    await scanAndPopulateMyKad(
      context,
      _nameController,
      _icController,
      _dobController,
      _addressController,
    );
  }

  // Form validation
  bool _isValidForm() {
    if (_emailController.text.isEmpty || !_emailController.text.contains('@')) {
      return false; // Invalid email
    }
    if (_passwordController.text.length < 6) {
      return false; // Weak password
    }
    if (_icController.text.isEmpty || _icController.text.length < 12) {
      return false; // Invalid IC number
    }
    if (_nameController.text.isEmpty) {
      return false; // Name is required
    }
    if (_dobController.text.isEmpty) {
      return false; // DOB is required
    }
    if (_addressController.text.isEmpty) {
      return false; // Address is required
    }
    return true;
  }

  // Date picker for DOB
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (selectedDate != null) {
      setState(() {
        _dobController.text = "${selectedDate.toLocal()}".split(' ')[0];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4169E1),
      appBar: AppBar(
        title: const Text(
          "Register",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF4169E1),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Email field with icon and Material 3 style
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: "Email",
                labelStyle: const TextStyle(color: Colors.white),
                filled: true,
                fillColor: Colors.white.withOpacity(0.2),
                prefixIcon: const Icon(Icons.email, color: Colors.white),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: const BorderSide(color: Colors.white),
                ),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            // Password field with icon and Material 3 style
            TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: "Password",
                labelStyle: const TextStyle(color: Colors.white),
                filled: true,
                fillColor: Colors.white.withOpacity(0.2),
                prefixIcon: const Icon(Icons.lock, color: Colors.white),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: const BorderSide(color: Colors.white),
                ),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            // IC Number field with icon and Material 3 style
            TextFormField(
              controller: _icController,
              decoration: InputDecoration(
                labelText: "IC Number",
                labelStyle: const TextStyle(color: Colors.white),
                filled: true,
                fillColor: Colors.white.withOpacity(0.2),
                prefixIcon: const Icon(Icons.credit_card, color: Colors.white),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: const BorderSide(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Name field with icon and Material 3 style
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: "Name",
                labelStyle: const TextStyle(color: Colors.white),
                filled: true,
                fillColor: Colors.white.withOpacity(0.2),
                prefixIcon: const Icon(Icons.person, color: Colors.white),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: const BorderSide(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Date of Birth field with date picker, icon, and Material 3 style
            TextFormField(
              controller: _dobController,
              decoration: InputDecoration(
                labelText: "Date of Birth",
                labelStyle: const TextStyle(color: Colors.white),
                filled: true,
                fillColor: Colors.white.withOpacity(0.2),
                prefixIcon:
                    const Icon(Icons.calendar_today, color: Colors.white),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: const BorderSide(color: Colors.white),
                ),
              ),
              readOnly: true,
              onTap: () => _selectDate(context),
            ),
            const SizedBox(height: 12),
            // Address field with icon and Material 3 style
            TextFormField(
              controller: _addressController,
              decoration: InputDecoration(
                labelText: "Address",
                labelStyle: const TextStyle(color: Colors.white),
                filled: true,
                fillColor: Colors.white.withOpacity(0.2),
                prefixIcon: const Icon(Icons.home, color: Colors.white),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: const BorderSide(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Button to scan and populate MyKad data
            FilledButton(
              onPressed: scanMyKadAndPopulate,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
              child: const Text("Scan MyKad"),
            ),
            const SizedBox(height: 20),
            // Register button
            FilledButton(
              onPressed: register,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
              child: const Text("Register"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _icController.dispose();
    _nameController.dispose();
    _dobController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}
