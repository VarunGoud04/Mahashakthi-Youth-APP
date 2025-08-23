import 'package:flutter/material.dart';

class RegistrationsScreen extends StatelessWidget {
  const RegistrationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Registrations")),
      body: const Center(child: Text("All registered users will appear here")),
    );
  }
}
