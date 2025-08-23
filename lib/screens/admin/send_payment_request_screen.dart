import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class SendPaymentRequestScreen extends StatefulWidget {
  const SendPaymentRequestScreen({super.key});

  @override
  State<SendPaymentRequestScreen> createState() =>
      _SendPaymentRequestScreenState();
}

class _SendPaymentRequestScreenState extends State<SendPaymentRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  String? selectedUid;
  String? selectedEmail;
  String? selectedName;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _purposeController = TextEditingController();
  DateTime? _selectedDate;
  File? _qrImage;

  Future<void> _pickQrImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _qrImage = File(picked.path);
      });
    }
  }

  Future<File?> _compressImage(File file) async {
    final result = await FlutterImageCompress.compressWithFile(
      file.absolute.path,
      minWidth: 720,
      minHeight: 720,
      quality: 70,
    );
    if (result == null) return null;

    final compressed = File('${file.path}_compressed.jpg');
    return compressed.writeAsBytes(result);
  }

  Future<String?> _uploadQrToStorage(File file) async {
    try {
      if (!await file.exists()) throw Exception('QR Image file does not exist');

      final filename = 'qr_codes/${DateTime.now().millisecondsSinceEpoch}.png';
      final ref = FirebaseStorage.instance.ref().child(filename);

      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask;

      if (snapshot.state == TaskState.success) {
        return await snapshot.ref.getDownloadURL();
      } else {
        throw Exception("Upload task failed");
      }
    } catch (e) {
      debugPrint("Upload failed: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('QR upload failed: ${e.toString()}')),
      );
      return null;
    }
  }

  Future<void> sendNotification(
    String token,
    String title,
    String message,
  ) async {
    const serverKey =
        'YOUR_SERVER_KEY_HERE'; // Replace with your real FCM server key

    final url = Uri.parse('https://fcm.googleapis.com/fcm/send');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'key=$serverKey',
    };

    final body = jsonEncode({
      'to': token,
      'notification': {'title': title, 'body': message},
    });

    await http.post(url, headers: headers, body: body);
  }

  Future<void> _sendRequest() async {
    if (_formKey.currentState!.validate() &&
        selectedUid != null &&
        _selectedDate != null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      String? qrUrl;
      if (_qrImage != null) {
        final compressed = await _compressImage(_qrImage!);
        qrUrl = await _uploadQrToStorage(compressed ?? _qrImage!);
        if (qrUrl == null) {
          Navigator.pop(context);
          return;
        }
      }

      final amount = _amountController.text.trim();
      final purpose = _purposeController.text.trim();

      // ✅ UPI Link with your correct ID
      final upiLink = Uri.encodeFull(
        'upi://pay?pa=killimanjaro43@ybl&pn=Mahashakti Youth&am=$amount&cu=INR',
      );

      await FirebaseFirestore.instance.collection('payment_requests').add({
        'uid': selectedUid,
        'email': selectedEmail,
        'name': selectedName,
        'amount': int.parse(amount),
        'purpose': purpose,
        'dueDate': Timestamp.fromDate(_selectedDate!),
        'upiLink': upiLink,
        'qrImageUrl': qrUrl ?? '',
        'status': 'Pending',
        'paymentProofUrl': '',
        'createdBy': 'Admin',
        'createdAt': Timestamp.now(),
      });

      // Send notification (non-blocking)
      FirebaseFirestore.instance
          .collection('users')
          .doc(selectedUid)
          .get()
          .then((doc) {
            final token = doc.data()?['fcmToken'];
            if (token != null) {
              sendNotification(
                token,
                'Payment Request',
                '₹$amount for "$purpose"',
              );
            }
          });

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Payment request sent successfully')),
      );

      _formKey.currentState!.reset();
      setState(() {
        _selectedDate = null;
        _qrImage = null;
      });
    }
  }

  Future<List<Map<String, dynamic>>> _fetchCommitteeMembers() async {
    final snapshot = await FirebaseFirestore.instance.collection('users').get();

    return snapshot.docs
        .where((doc) {
          final data = doc.data();
          return data['role'] == 'Committee Member' &&
              data.containsKey('fullName') &&
              data.containsKey('email');
        })
        .map(
          (doc) => {
            'uid': doc.id,
            'name': doc['fullName'],
            'email': doc['email'],
          },
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Send Payment Request')),
      body: FutureBuilder(
        future: _fetchCommitteeMembers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final members = snapshot.data ?? [];

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  DropdownButtonFormField(
                    hint: const Text('Select Committee Member'),
                    isExpanded: true,
                    items: members.map((member) {
                      return DropdownMenuItem(
                        value: member,
                        child: Text(
                          '${member['name']} (${member['email']})',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      final selected = value as Map<String, dynamic>;
                      selectedUid = selected['uid'];
                      selectedEmail = selected['email'];
                      selectedName = selected['name'];
                    },
                    validator: (value) =>
                        value == null ? 'Please select a member' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Amount'),
                    validator: (value) =>
                        value!.isEmpty ? 'Enter amount' : null,
                  ),
                  TextFormField(
                    controller: _purposeController,
                    decoration: const InputDecoration(labelText: 'Purpose'),
                    validator: (value) =>
                        value!.isEmpty ? 'Enter purpose' : null,
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      _selectedDate == null
                          ? 'Select Due Date'
                          : 'Due: ${_selectedDate!.toLocal()}'.split(' ')[0],
                    ),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().add(
                          const Duration(days: 1),
                        ),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setState(() {
                          _selectedDate = picked;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.qr_code),
                    label: const Text('Upload QR Code Image (optional)'),
                    onPressed: _pickQrImage,
                  ),
                  if (_qrImage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Image.file(_qrImage!, height: 100),
                    ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _sendRequest,
                    child: const Text('Send Payment Request'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
