import 'package:flutter/material.dart';

class SecretPage extends StatelessWidget {
  const SecretPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4169E1),
      appBar: AppBar(
        title: const Text("Private Space"),
        titleTextStyle: const TextStyle(color: Colors.white),
        backgroundColor: const Color(0xFF4169E1),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
            style: TextStyle(color: Colors.white),
            'Welcome to the private space! This space is only accesible to users who are located in Malaysia.'),
      ),
    );
  }
}
