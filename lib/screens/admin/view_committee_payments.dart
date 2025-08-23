// screens/view_committee_payments.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ViewCommitteePaymentsScreen extends StatelessWidget {
  const ViewCommitteePaymentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Committee Payments')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('committee_payments')
            .orderBy('date', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          final payments = snapshot.data!.docs;

          if (payments.isEmpty)
            return const Center(child: Text('No payments recorded.'));

          return ListView.builder(
            itemCount: payments.length,
            itemBuilder: (context, index) {
              final data = payments[index].data() as Map<String, dynamic>;
              final date = (data['date'] as Timestamp).toDate();
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: ListTile(
                  title: Text('${data['name']} paid ₹${data['amount']}'),
                  subtitle: Text(
                    '${data['purpose']} • ${DateFormat.yMMMd().format(date)}',
                  ),
                  trailing: Text(data['addedBy'] ?? 'Admin'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
