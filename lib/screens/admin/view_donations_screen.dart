import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AdminDonationsScreen extends StatefulWidget {
  const AdminDonationsScreen({super.key});

  @override
  State<AdminDonationsScreen> createState() => _AdminDonationsScreenState();
}

class _AdminDonationsScreenState extends State<AdminDonationsScreen> {
  String selectedFilter = "Pending";
  bool isLoading = false;

  Future<void> updateStatus(
    String docId,
    String newStatus,
    Map<String, dynamic> data,
  ) async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text("Processing..."),
          ],
        ),
      ),
    );

    try {
      // ✅ Update Firestore status
      await FirebaseFirestore.instance
          .collection('donation_requests')
          .doc(docId)
          .update({'status': newStatus});

      if (newStatus == "Approved") {
        // ✅ Send confirmation email
        final response = await http.post(
          Uri.parse("https://mahashakthiyouth21.vercel.app/api/send-email"),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            "name": data['name'],
            "email": data['email'],
            "amount": data['amount'].toString(),
            "transactionId": data['transactionId'],
          }),
        );

        Navigator.pop(context); // close dialog

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("✅ Donation approved & email sent")),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("⚠️ Approved but failed to send email"),
            ),
          );
        }
      } else {
        Navigator.pop(context); // just close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ Donation marked as Rejected")),
        );
      }
    } catch (e) {
      Navigator.pop(context); // close on error
      print("❌ Error: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Something went wrong")));
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Donations"),
        backgroundColor: Colors.brown.shade700,
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          DropdownButton<String>(
            value: selectedFilter,
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  selectedFilter = value;
                });
              }
            },
            items: ["Pending", "Approved", "Rejected", "All"]
                .map(
                  (status) =>
                      DropdownMenuItem(value: status, child: Text(status)),
                )
                .toList(),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('donation_requests')
                  .orderBy('submittedAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No donations found."));
                }

                final filteredDocs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  if (selectedFilter == "All") return true;
                  return data['status'] == selectedFilter;
                }).toList();

                return ListView.builder(
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final doc = filteredDocs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final amount = data['amount'];
                    final txnId = data['transactionId'];
                    final email = data['email'];
                    final name = data['name'];
                    final status = data['status'];
                    final submittedAt = (data['submittedAt'] as Timestamp)
                        .toDate();

                    return Card(
                      margin: const EdgeInsets.all(10),
                      child: ListTile(
                        title: Text("₹$amount from $name"),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Txn ID: $txnId"),
                            Text("Email: $email"),
                            Text(
                              "Submitted: ${submittedAt.toString().substring(0, 16)}",
                            ),
                            Text("Status: $status"),
                          ],
                        ),
                        trailing: status == "Pending"
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.check,
                                      color: Colors.green,
                                    ),
                                    onPressed: () =>
                                        updateStatus(doc.id, "Approved", data),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.close,
                                      color: Colors.red,
                                    ),
                                    onPressed: () =>
                                        updateStatus(doc.id, "Rejected", data),
                                  ),
                                ],
                              )
                            : const Icon(Icons.done_outline),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
