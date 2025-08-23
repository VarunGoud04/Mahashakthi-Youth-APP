import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mahashakthiyouthapp/services/notification_service.dart'; // 👈 Import this

class AddEventsScreen extends StatefulWidget {
  const AddEventsScreen({super.key});

  @override
  State<AddEventsScreen> createState() => _AddEventsScreenState();
}

class _AddEventsScreenState extends State<AddEventsScreen> {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  DateTime? selectedDate;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> _submitEvent() async {
    if (titleController.text.trim().isEmpty ||
        descriptionController.text.trim().isEmpty ||
        selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields and pick a date')),
      );
      return;
    }

    try {
      final title = titleController.text.trim();
      final description = descriptionController.text.trim();

      await FirebaseFirestore.instance.collection('events').add({
        'title': title,
        'description': description,
        'date': Timestamp.fromDate(selectedDate!),
        'createdAt': Timestamp.now(),
        'postedBy': 'admin',
      });

      await NotificationService.sendNotification(
        title: 'New Event: $title',
        message:
            '📅 $description on ${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
        sound: 'msy_alert', // ✅ Custom sound key
      );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('✅ Event Added & Notified')));

      titleController.clear();
      descriptionController.clear();
      setState(() {
        selectedDate = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _deleteEvent(String docId) async {
    try {
      await FirebaseFirestore.instance.collection('events').doc(docId).delete();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('🗑️ Event deleted')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateText = selectedDate == null
        ? 'Pick Date'
        : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}';

    return Scaffold(
      appBar: AppBar(title: const Text("Add Event")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(dateText),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: _pickDate,
                  child: const Text('Select Date'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submitEvent,
              child: const Text("Submit Event"),
            ),
            const SizedBox(height: 30),
            const Divider(),
            const Text('📅 Upcoming Events', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('events')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("No events found."));
                  }

                  final docs = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      DateTime date;

                      try {
                        if (data['date'] is Timestamp) {
                          date = (data['date'] as Timestamp).toDate();
                        } else if (data['date'] is String) {
                          date = DateTime.parse(data['date']);
                        } else {
                          date = DateTime.now(); // fallback
                        }
                      } catch (_) {
                        date = DateTime.now(); // fallback on error
                      }

                      return Card(
                        child: ListTile(
                          title: Text(data['title'] ?? 'No Title'),
                          subtitle: Text(
                            "${data['description'] ?? 'No Description'}\n"
                            "📅 Date: ${date.day}/${date.month}/${date.year}",
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteEvent(docs[index].id),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
