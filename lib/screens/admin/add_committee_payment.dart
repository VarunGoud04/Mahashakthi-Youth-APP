// screens/add_committee_payment.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AddCommitteePaymentScreen extends StatefulWidget {
  const AddCommitteePaymentScreen({super.key});

  @override
  State<AddCommitteePaymentScreen> createState() =>
      _AddCommitteePaymentScreenState();
}

class _AddCommitteePaymentScreenState extends State<AddCommitteePaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _purposeController = TextEditingController();

  Future<void> _submitPayment() async {
    if (_formKey.currentState!.validate()) {
      await FirebaseFirestore.instance.collection('committee_payments').add({
        'name': _nameController.text,
        'amount': int.parse(_amountController.text),
        'purpose': _purposeController.text,
        'date': Timestamp.now(),
        'addedBy':
            "Admin", // Replace with actual logged-in admin name if available
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment added successfully')),
      );
      _nameController.clear();
      _amountController.clear();
      _purposeController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Committee Payment')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Member Name'),
                validator: (value) => value!.isEmpty ? 'Enter name' : null,
              ),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: 'Amount'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Enter amount' : null,
              ),
              TextFormField(
                controller: _purposeController,
                decoration: const InputDecoration(labelText: 'Purpose'),
                validator: (value) => value!.isEmpty ? 'Enter purpose' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitPayment,
                child: const Text('Add Payment'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
