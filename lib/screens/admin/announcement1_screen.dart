import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ManageAnnouncementsScreen extends StatefulWidget {
  const ManageAnnouncementsScreen({super.key});

  @override
  State<ManageAnnouncementsScreen> createState() =>
      _ManageAnnouncementsScreenState();
}

class _ManageAnnouncementsScreenState extends State<ManageAnnouncementsScreen> {
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();

  Future<void> _postAnnouncement() async {
    final title = _titleController.text.trim();
    final message = _messageController.text.trim();

    if (title.isEmpty || message.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Both fields are required')));
      return;
    }

    try {
      // 🔸 Store announcement in Firestore
      await FirebaseFirestore.instance.collection('announcements').add({
        'title': title,
        'message': message,
        'timestamp': Timestamp.now(),
      });

      // 🔸 Send OneSignal Notification
      await _sendNotification(title, message);

      _titleController.clear();
      _messageController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Announcement posted & notified')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  Future<void> _sendNotification(String title, String message) async {
    const String oneSignalAppId =
        '54e93a9a-ab26-4602-be24-90b7d452c6a8'; // ✅ Replace this
    const String restApiKey =
        'os_v2_app_ktutvgvlezdafpresc35iuwgvaopwae4wqauuzepgn2ubdpspjbpkfthjafxwmul4zvj3tswlfc5u6cr56ouj2euheuwsin7br3rx3a'; // ✅ Replace this

    final url = Uri.parse('https://onesignal.com/api/v1/notifications');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Basic $restApiKey',
      },
      body: jsonEncode({
        'app_id': oneSignalAppId,
        'included_segments': ['All'],
        'headings': {'en': "📢 $title"},
        'contents': {'en': message},
        'android_sound': 'msy_alert',
        'android_channel_id': '96c7d976-d4a0-465c-9a2b-83280137ba20',
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Push notification failed: ${response.body}');
    }
  }

  Future<void> _deleteAnnouncement(String docId) async {
    try {
      await FirebaseFirestore.instance
          .collection('announcements')
          .doc(docId)
          .delete();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Announcement deleted')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting announcement: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Post Announcement')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _messageController,
              decoration: const InputDecoration(labelText: 'Message'),
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _postAnnouncement,
              child: const Text('Post'),
            ),
            const SizedBox(height: 30),
            const Divider(),
            const Text('Posted Announcements', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('announcements')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text('No announcements posted yet.'),
                    );
                  }

                  final docs = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final timestamp = data['timestamp'] is Timestamp
                          ? (data['timestamp'] as Timestamp).toDate()
                          : DateTime.now();

                      final formattedDate = DateFormat(
                        'dd MMM yyyy, hh:mm a',
                      ).format(timestamp);

                      return Card(
                        child: ListTile(
                          title: Text(data['title'] ?? ''),
                          subtitle: Text(
                            "${data['message'] ?? ''}\nPosted on: $formattedDate",
                          ),
                          isThreeLine: true,
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () =>
                                _deleteAnnouncement(docs[index].id),
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
