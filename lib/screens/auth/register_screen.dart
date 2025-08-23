import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart'; // <-- Import your login screen here

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  final _phonePeCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  String? _selectedRole;
  bool _isLoading = false;

  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    for (final c in [
      _nameCtrl,
      _emailCtrl,
      _contactCtrl,
      _phonePeCtrl,
      _passwordCtrl,
      _confirmCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();
    final isGuest = _selectedRole == 'Guest (Visitor)';

    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = cred.user!.uid;

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'fullName': _nameCtrl.text.trim(),
        'email': email,
        'contactNumber': _contactCtrl.text.trim(),
        'phonePeNumber': _phonePeCtrl.text.trim(),
        'role': _selectedRole,
        'isApproved': isGuest,
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isGuest
                ? 'Registration successful! You can now log in.'
                : 'Submitted! Please wait for admin approval.',
          ),
        ),
      );

      // **Always** navigate back to login screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } on FirebaseAuthException catch (e) {
      var msg = 'Registration failed.';
      if (e.code == 'email-already-in-use') msg = 'Email already in use.';
      if (e.code == 'invalid-email') msg = 'Invalid email format.';
      if (e.code == 'weak-password') msg = 'Password too weak.';
      _showError(msg);
    } catch (e) {
      _showError('Unexpected error. Try again.');
      print(e);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF3594C0), Color(0xFF7F55D3)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                const Text(
                  'Register',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                _buildTextField(_nameCtrl, 'Full Name'),
                _buildEmailField(),
                _buildTextField(
                  _contactCtrl,
                  'Contact Number',
                  keyboard: TextInputType.phone,
                  maxLen: 10,
                ),
                _buildTextField(
                  _phonePeCtrl,
                  'PhonePe Number',
                  keyboard: TextInputType.phone,
                  maxLen: 10,
                ),
                _buildPasswordField(),
                _buildConfirmField(),
                _buildRoleDropdown(),
                const SizedBox(height: 20),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Register',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                const SizedBox(height: 30),
                const Center(
                  child: Text(
                    'Powered by Mahashakthi Youth | B. Varun Goud',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController ctrl,
    String labelText, {
    TextInputType keyboard = TextInputType.text,
    int? maxLen,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: TextFormField(
      controller: ctrl,
      keyboardType: keyboard,
      inputFormatters: maxLen != null
          ? [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(maxLen),
            ]
          : null,
      style: const TextStyle(color: Colors.white),
      decoration: _inputDecoration(labelText),
      validator: (v) => v == null || v.isEmpty ? 'Enter $labelText' : null,
    ),
  );

  Widget _buildEmailField() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: TextFormField(
      controller: _emailCtrl,
      keyboardType: TextInputType.emailAddress,
      style: const TextStyle(color: Colors.white),
      decoration: _inputDecoration('Email'),
      validator: (v) => v == null || !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)
          ? 'Enter a valid email'
          : null,
    ),
  );

  Widget _buildPasswordField() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: TextFormField(
      controller: _passwordCtrl,
      obscureText: true,
      style: const TextStyle(color: Colors.white),
      decoration: _inputDecoration('Password'),
      validator: (v) => v == null || v.length < 6
          ? 'Password must be at least 6 characters'
          : null,
    ),
  );

  Widget _buildConfirmField() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: TextFormField(
      controller: _confirmCtrl,
      obscureText: true,
      style: const TextStyle(color: Colors.white),
      decoration: _inputDecoration('Confirm Password'),
      validator: (v) =>
          v != _passwordCtrl.text ? 'Passwords do not match' : null,
    ),
  );

  Widget _buildRoleDropdown() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: DropdownButtonFormField<String>(
      value: _selectedRole,
      dropdownColor: Colors.deepPurple,
      decoration: _inputDecoration('Select Role'),
      items: ['Committee Member', 'Guest (Visitor)']
          .map(
            (role) => DropdownMenuItem(
              value: role,
              child: Text(role, style: const TextStyle(color: Colors.white)),
            ),
          )
          .toList(),
      onChanged: (v) => setState(() => _selectedRole = v),
      validator: (v) => v == null ? 'Please select your role' : null,
    ),
  );

  InputDecoration _inputDecoration(String labelText) => InputDecoration(
    labelText: labelText,
    labelStyle: const TextStyle(color: Colors.white70),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.white24),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.white),
    ),
  );
}
