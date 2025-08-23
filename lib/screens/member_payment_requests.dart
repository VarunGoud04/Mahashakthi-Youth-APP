import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:android_intent_plus/android_intent.dart';

class MemberPaymentRequestsScreen extends StatefulWidget {
  const MemberPaymentRequestsScreen({super.key});

  @override
  State<MemberPaymentRequestsScreen> createState() =>
      _MemberPaymentRequestsScreenState();
}

class _MemberPaymentRequestsScreenState
    extends State<MemberPaymentRequestsScreen> {
  final currentUser = FirebaseAuth.instance.currentUser;

  Future<void> launchUPILink(String upiUrl) async {
    try {
      final intent = AndroidIntent(
        action: 'android.intent.action.VIEW',
        data: upiUrl,
      );
      await intent.launch();
    } catch (e) {
      debugPrint('UPI Intent Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No UPI app found or unable to launch')),
      );
    }
  }

  Future<void> submitTransactionId(String docId) async {
    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Enter Transaction ID'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'e.g., TXN1234567890'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final txnId = controller.text.trim();
              if (txnId.isEmpty) return;

              await FirebaseFirestore.instance
                  .collection('payment_requests')
                  .doc(docId)
                  .update({'paymentProofUrl': txnId});

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('✅ Transaction ID submitted')),
              );
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Payment Requests')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('payment_requests')
            .where('uid', isEqualTo: currentUser!.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final requests = snapshot.data!.docs;

          if (requests.isEmpty) {
            return const Center(child: Text('No payment requests yet.'));
          }

          requests.sort((a, b) {
            final aTime =
                (a['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
            final bTime =
                (b['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
            return bTime.compareTo(aTime);
          });

          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final doc = requests[index];
              final data = doc.data() as Map<String, dynamic>;
              final dueDate = (data['dueDate'] as Timestamp?)?.toDate();
              final status = data['status'];
              final txnId = data['paymentProofUrl'];

              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  title: Text('₹${data['amount']} - ${data['purpose']}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (dueDate != null)
                        Text('Due: ${DateFormat.yMMMd().format(dueDate)}'),
                      Text(
                        'Status: $status',
                        style: TextStyle(
                          color: status == 'Paid'
                              ? Colors.green
                              : Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (data['upiLink'] != null && data['upiLink'] != '')
                        TextButton(
                          onPressed: () => launchUPILink(data['upiLink']),
                          child: const Text('Pay via UPI'),
                        ),
                      if (status != 'Paid' && (txnId == null || txnId == ''))
                        TextButton.icon(
                          onPressed: () => submitTransactionId(doc.id),
                          icon: const Icon(Icons.payment),
                          label: const Text('Submit Transaction ID'),
                        ),
                      if (txnId != null && txnId != '')
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            '🧾 Transaction ID: $txnId',
                            style: const TextStyle(color: Colors.blue),
                          ),
                        ),
                    ],
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
