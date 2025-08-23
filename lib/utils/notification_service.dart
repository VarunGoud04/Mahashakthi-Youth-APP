// lib/services/notification_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

class NotificationService {
  static const String _appId = '54e93a9a-ab26-4602-be24-90b7d452c6a8';
  static const String _apiKey =
      'os_v2_app_ktutvgvlezdafpresc35iuwgvaopwae4wqauuzepgn2ubdpspjbpkfthjafxwmul4zvj3tswlfc5u6cr56ouj2euheuwsin7br3rx3a';
  static const String _channelId =
      '96c7d976-d4a0-465c-9a2b-83280137ba20'; // Optional

  static Future<void> sendNotification({
    required String title,
    required String message,
    String sound = 'msy_alert', // ✅ Added optional sound parameter with default
  }) async {
    final url = Uri.parse('https://onesignal.com/api/v1/notifications');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Basic $_apiKey',
      },
      body: jsonEncode({
        'app_id': _appId,
        'included_segments': ['All'],
        'headings': {'en': title},
        'contents': {'en': message},
        'android_sound': sound, // ✅ Use custom sound
        'android_channel_id': _channelId,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Push notification failed: ${response.body}');
    }
  }
}
