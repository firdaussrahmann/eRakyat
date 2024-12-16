import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'dart:convert'; // For JSON encoding/decoding
import 'dart:math'; // For generating unique tokens

class ProfilePage extends StatefulWidget {
  final Map<String, String> scannedData;

  const ProfilePage({super.key, required this.scannedData});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isSaving = false;
  bool isEditing = false;

  late String _uniqueToken;
  late String _qrData;

  @override
  void initState() {
    super.initState();
    _fetchUserData(); // Fetch user data when the page loads
    _generateQRCode(); // Generate QR code initially
  }

  // Fetch user data from Firebase
  Future<void> _fetchUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final docSnapshot = await FirebaseFirestore.instance
            .collection('userInformation')
            .doc(user.uid)
            .get();

        if (docSnapshot.exists) {
          final data = docSnapshot.data();
          setState(() {
            _idController.text = data?['icNumber'] ?? '';
            _nameController.text = data?['name'] ?? '';
            _addressController.text = data?['address'] ?? '';
            _dobController.text = data?['dob'] ?? '';
            _generateQRCode(); // Update QR code data
          });
        }
      }
    } catch (e) {
      _showErrorSnackBar('Failed to fetch user data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _generateQRCode() {
    // Generate unique token
    _uniqueToken = _generateUniqueToken();

    // Combine user data with the token
    final data = {
      'icNumber': _idController.text,
      'name': _nameController.text,
      'address': _addressController.text,
      'dob': _dobController.text,
      'token': _uniqueToken,
      'timestamp': DateTime.now().toIso8601String(),
    };

    // Encode the data as JSON and then as Base64
    _qrData = base64Encode(utf8.encode(jsonEncode(data)));

    setState(() {});
  }

  String _generateUniqueToken() {
    // Generate a secure random token
    final random = Random.secure();
    return List<int>.generate(16, (_) => random.nextInt(256))
        .map((e) => e.toRadixString(16).padLeft(2, '0'))
        .join();
  }

  Future<void> saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDocRef = FirebaseFirestore.instance
            .collection('userInformation')
            .doc(user.uid);

        await userDocRef.update({
          'icNumber': _idController.text,
          'name': _nameController.text,
          'address': _addressController.text,
          'dob': _dobController.text,
        });

        _showSuccessSnackBar('Profile saved successfully!');
        setState(() => isEditing = false);
        _generateQRCode(); // Update QR code after saving
      }
    } catch (e) {
      _showErrorSnackBar('Failed to save profile: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildQrCode() {
    return _qrData.isNotEmpty
        ? Column(
            children: [
              const Text(
                'Your QR Code:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Container(
                width: 200,
                height: 200,
                child: BarcodeWidget(
                  data: _qrData,
                  barcode: Barcode.qrCode(),
                  errorBuilder: (context, error) =>
                      const Center(child: Text('Error generating QR code')),
                ),
              ),
              FilledButton(
                onPressed: _generateQRCode,
                style: FilledButton.styleFrom(
                  backgroundColor:
                      Colors.orange, // Sets the button's background color
                ),
                child: const Text('Refresh QR Code'),
              ),
            ],
          )
        : const Center(child: Text('No QR Code available'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4169E1),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Expanded(
                    child: Form(
                      key: _formKey,
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            // IC Number field with icon and Material 3 style
                            TextFormField(
                              controller: _idController,
                              decoration: InputDecoration(
                                labelText: 'IC Number',
                                labelStyle:
                                    const TextStyle(color: Colors.white),
                                prefixIcon: const Icon(
                                  Icons.credit_card,
                                  color: Colors.white,
                                ),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.2),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                  borderSide:
                                      const BorderSide(color: Colors.white),
                                ),
                              ),
                              readOnly: !isEditing,
                              validator: (value) =>
                                  value == null || value.isEmpty
                                      ? 'Required'
                                      : null,
                            ),
                            const SizedBox(height: 12),
                            // Full Name field with icon and Material 3 style
                            TextFormField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                labelText: 'Full Name',
                                labelStyle:
                                    const TextStyle(color: Colors.white),
                                prefixIcon: const Icon(
                                  Icons.person,
                                  color: Colors.white,
                                ),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.2),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                  borderSide:
                                      const BorderSide(color: Colors.white),
                                ),
                              ),
                              readOnly: !isEditing,
                              validator: (value) =>
                                  value == null || value.isEmpty
                                      ? 'Required'
                                      : null,
                            ),
                            const SizedBox(height: 12),
                            // Address field with icon and Material 3 style
                            TextFormField(
                              controller: _addressController,
                              decoration: InputDecoration(
                                labelText: 'Address',
                                labelStyle:
                                    const TextStyle(color: Colors.white),
                                prefixIcon: const Icon(
                                  Icons.home,
                                  color: Colors.white,
                                ),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.2),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                  borderSide:
                                      const BorderSide(color: Colors.white),
                                ),
                              ),
                              readOnly: !isEditing,
                              validator: (value) =>
                                  value == null || value.isEmpty
                                      ? 'Required'
                                      : null,
                            ),
                            const SizedBox(height: 12),
                            // Date of Birth field with icon and Material 3 style
                            TextFormField(
                              controller: _dobController,
                              decoration: InputDecoration(
                                labelText: 'Date of Birth',
                                labelStyle:
                                    const TextStyle(color: Colors.white),
                                prefixIcon: const Icon(
                                  Icons.calendar_today,
                                  color: Colors.white,
                                ),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.2),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                  borderSide:
                                      const BorderSide(color: Colors.white),
                                ),
                              ),
                              readOnly: true,
                            ),
                            const SizedBox(height: 20),
                            _buildQrCode(), // Keep the QR Code widget here
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Row for side by side buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      FilledButton(
                        onPressed: () => setState(() => isEditing = !isEditing),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors
                              .orange, // Sets the button's background color
                        ),
                        child: Text(isEditing ? 'Cancel' : 'Edit'),
                      ),
                      if (isEditing)
                        FilledButton(
                          onPressed: _isSaving ? null : saveProfile,
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors
                                .orange, // Sets the button's background color
                          ),
                          child: _isSaving
                              ? const CircularProgressIndicator()
                              : const Text('Save'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
