import 'dart:convert';
import 'package:http/http.dart' as http;

class NotificationService {
  static const String oneSignalAppId = '54e93a9a-ab26-4602-be24-90b7d452c6a8';
  static const String restApiKey =
      'os_v2_app_ktutvgvlezdafpresc35iuwgvaopwae4wqauuzepgn2ubdpspjbpkfthjafxwmul4zvj3tswlfc5u6cr56ouj2euheuwsin7br3rx3a';

  static Future<void> sendNotification({
    required String title,
    required String message,
    required String sound,
  }) async {
    final url = Uri.parse('https://onesignal.com/api/v1/notifications');

    final headers = {
      'Content-Type': 'application/json; charset=utf-8',
      'Authorization': 'Basic $restApiKey',
    };

    final body = jsonEncode({
      'app_id': oneSignalAppId,
      'included_segments': ['All'],
      'headings': {'en': title},
      'contents': {'en': message},
      'android_sound': 'msy_alert',
      'android_channel_id': '96c7d976-d4a0-465c-9a2b-83280137ba20',
    });

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      print('✅ Notification sent successfully.');
    } else {
      print('❌ Error sending notification: ${response.body}');
    }
  }
}
