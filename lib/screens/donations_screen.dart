import 'package:flutter/material.dart';

class DonationsScreen extends StatelessWidget {
  const DonationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("విరాళం / Donate")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.block, color: Colors.redAccent, size: 60),
              SizedBox(height: 20),
              Text(
                "We are currently not accepting donations...\nCome back later.\n\n"
                "మేము ప్రస్తుతం విరాళాలు స్వీకరించడం లేదు...\n"
                "తర్వాత తిరిగి రండి..\n"
                "మేము ప్రస్తుతం విరాళాల ట్యాబ్‌ను మెరుగుపరుస్తున్నాము.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepOrange,
                ),
              ),
              SizedBox(height: 40),
              Text(
                "Developed by B. Varun Goud\nCommittee Member, Mahashakthi Youth",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.brown),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
