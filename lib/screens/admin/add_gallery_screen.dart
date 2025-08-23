import 'package:flutter/material.dart';

class AddGalleryScreen extends StatelessWidget {
  const AddGalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Gallery Item")),
      body: const Center(
        child: Text("Upload Gallery Images/Videos Coming Soon"),
      ),
    );
  }
}
