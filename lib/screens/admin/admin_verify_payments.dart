import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AdminVerifyPaymentsScreen extends StatelessWidget {
  const AdminVerifyPaymentsScreen({super.key});

  Future<void> markAsPaid(
    BuildContext context,
    String docId,
    Map<String, dynamic> data,
  ) async {
    try {
      final paidAmount = data['amount'];

      // Step 1: Add to committee_payments collection
      await FirebaseFirestore.instance.collection('committee_payments').add({
        'uid': data['uid'],
        'name': data['name'],
        'email': data['email'],
        'amount': paidAmount,
        'purpose': data['purpose'],
        'transactionId': data['paymentProofUrl'] ?? '',
        'date': Timestamp.now(),
        'addedBy': 'Admin',
      });

      // Step 2: Delete from payment_requests collection
      await FirebaseFirestore.instance
          .collection('payment_requests')
          .doc(docId)
          .delete();

      // Step 3: Show success snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ ₹$paidAmount Paid Successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ Error: ${e.toString()}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify Payments')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('payment_requests')
            .where('status', isEqualTo: 'Pending')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final requests = snapshot.data!.docs;

          if (requests.isEmpty) {
            return const Center(child: Text('No pending payments.'));
          }

          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final doc = requests[index];
              final data = doc.data() as Map<String, dynamic>;
              final dueDate = (data['dueDate'] as Timestamp).toDate();
              final transactionId =
                  data['paymentProofUrl'] ?? ''; // Used as transaction ID

              final hasProof = transactionId.isNotEmpty;

              return Card(
                margin: const EdgeInsets.all(12),
                child: ListTile(
                  title: Text('${data['name']} • ₹${data['amount']}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Purpose: ${data['purpose']}'),
                      Text('Due: ${DateFormat.yMMMd().format(dueDate)}'),
                      if (hasProof)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '🧾 Transaction ID: $transactionId',
                            style: const TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  trailing: ElevatedButton(
                    onPressed: hasProof
                        ? () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Confirm Payment'),
                                content: const Text(
                                  'Are you sure you want to mark this payment as Paid?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text('Yes'),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await markAsPaid(context, doc.id, data);
                            }
                          }
                        : null,
                    child: const Text('Mark as Paid'),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
