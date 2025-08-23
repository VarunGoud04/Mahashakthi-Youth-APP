import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AdminVerifyPaymentsScreen extends StatelessWidget {
  const AdminVerifyPaymentsScreen({super.key});

  Future<void> markAsPaid(String docId, Map<String, dynamic> data) async {
    await FirebaseFirestore.instance
        .collection('payment_requests')
        .doc(docId)
        .update({'status': 'Paid'});

    await FirebaseFirestore.instance.collection('committee_payments').add({
      'uid': data['uid'],
      'name': data['name'],
      'email': data['email'],
      'amount': data['amount'],
      'purpose': data['purpose'],
      'date': Timestamp.now(),
      'addedBy': 'Admin',
    });
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
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          final requests = snapshot.data!.docs;

          if (requests.isEmpty)
            return const Center(child: Text('No pending payments.'));

          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final doc = requests[index];
              final data = doc.data() as Map<String, dynamic>;
              final dueDate = (data['dueDate'] as Timestamp).toDate();

              return Card(
                margin: const EdgeInsets.all(12),
                child: ListTile(
                  title: Text('${data['name']} • ₹${data['amount']}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Purpose: ${data['purpose']}'),
                      Text('Due: ${DateFormat.yMMMd().format(dueDate)}'),
                      if (data['paymentProofUrl'] != null &&
                          data['paymentProofUrl'] != '')
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: GestureDetector(
                            onTap: () => showDialog(
                              context: context,
                              builder: (_) => Dialog(
                                child: Image.network(data['paymentProofUrl']),
                              ),
                            ),
                            child: const Text(
                              'View Proof',
                              style: TextStyle(color: Colors.blue),
                            ),
                          ),
                        ),
                    ],
                  ),
                  trailing: ElevatedButton(
                    onPressed: () => markAsPaid(doc.id, data),
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
