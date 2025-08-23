import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import './auth/login_screen.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'admin/admin_panel_screen.dart'; // Import your admin panel

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? userRole;

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
  }

  Future<void> _fetchUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final data = doc.data();
      setState(() {
        userRole = data?['role'];
      });
    }
  }

  Future<void> _showProfileDialog(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final data = doc.data();
    if (data == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Profile Information"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Name: ${data['fullName'] ?? ''}"),
            Text("Contact: ${data['contactNumber'] ?? ''}"),
            Text("Role: ${data['role'] ?? ''}"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
          TextButton(
            onPressed: () async {
              final confirmed = await showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text("Logout Confirmation"),
                  content: const Text("Are you sure you want to logout?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text("No"),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text("Yes"),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                await FirebaseAuth.instance.signOut();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
            child: const Text("Logout"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1), // Golden background
      appBar: AppBar(
        title: const Text("Mahashakthi Youth"),
        backgroundColor: const Color(0xFF8E3200),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () => _showProfileDialog(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Image.asset(
              'assets/banner.jpeg',
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
            ),
            const SizedBox(height: 40),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                "Mahashakthi Youth is a vibrant devotional and cultural group based in Chityal. "
                "Our aim is to bring together like-minded individuals who are passionate about "
                "preserving tradition, promoting unity, and serving the community through events, "
                " We are community of 24 members Same Kinded People",
                style: TextStyle(
                  fontSize: 18,
                  color: Color.fromARGB(255, 54, 139, 189),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 120),
            AnimatedTextKit(
              animatedTexts: [
                ColorizeAnimatedText(
                  'Developed by B. Varun Goud Committee Member.          Contact: +91 9014075885',
                  textStyle: const TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                  ),
                  colors: [
                    Colors.red,
                    Colors.orange,
                    Colors.purple,
                    Colors.blue,
                  ],
                ),
              ],
              isRepeatingAnimation: true,
              repeatForever: true,
            ),
            const SizedBox(height: 20),

            // ✅ Show admin button only if role is Admin
            if (userRole == "Admin")
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminPanelScreen()),
                  );
                },
                icon: const Icon(Icons.admin_panel_settings),
                label: const Text("Go to Admin Panel"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
