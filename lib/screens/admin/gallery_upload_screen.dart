import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mahashakthiyouthapp/services/notification_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
// ✅ Push Notification Service

class GalleryUploadScreen extends StatefulWidget {
  const GalleryUploadScreen({Key? key}) : super(key: key);

  @override
  State<GalleryUploadScreen> createState() => _GalleryUploadScreenState();
}

class _GalleryUploadScreenState extends State<GalleryUploadScreen> {
  File? _file;
  Uint8List? _webFile;
  String? _fileName;
  final ImagePicker picker = ImagePicker();
  String _selectedType = 'image';
  final TextEditingController _youtubeUrlController = TextEditingController();
  bool _isUploading = false;
  bool _isAdmin = false;

  final String cloudName = 'dvrx7rbk5';
  final String uploadPreset = 'flutter_uploads';
  final String cloudinaryApiKey = '613496915784467';
  final String cloudinaryApiSecret = 'yhv7lMg4beodFj6Q06du0Ldyb3k';

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    setState(() {
      _isAdmin = doc.data()?['role'] == 'Admin';
    });
  }

  Future<void> _pickFile() async {
    XFile? pickedFile;
    if (_selectedType == 'image') {
      pickedFile = await picker.pickImage(source: ImageSource.gallery);
    } else if (_selectedType == 'video') {
      pickedFile = await picker.pickVideo(source: ImageSource.gallery);
    }

    if (pickedFile != null) {
      if (kIsWeb) {
        _webFile = await pickedFile.readAsBytes();
        _fileName = pickedFile.name;
      } else {
        _file = File(pickedFile.path);
      }
      setState(() {});
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("No file selected")));
    }
  }

  Future<void> _upload() async {
    if (_selectedType == 'youtube' &&
        _youtubeUrlController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a YouTube link")),
      );
      return;
    }

    if (_selectedType != 'youtube' && _file == null && _webFile == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please select a file")));
      return;
    }

    setState(() => _isUploading = true);
    String? url;
    String? publicId;

    try {
      if (_selectedType == 'youtube') {
        url = _youtubeUrlController.text.trim();
      } else {
        final uploadUrl = Uri.parse(
          'https://api.cloudinary.com/v1_1/$cloudName/${_selectedType == 'video' ? 'video' : 'image'}/upload',
        );
        var request = http.MultipartRequest('POST', uploadUrl)
          ..fields['upload_preset'] = uploadPreset;

        if (kIsWeb && _webFile != null) {
          request.files.add(
            http.MultipartFile.fromBytes(
              'file',
              _webFile!,
              filename: _fileName,
            ),
          );
        } else if (_file != null) {
          request.files.add(
            await http.MultipartFile.fromPath('file', _file!.path),
          );
        }

        final response = await request.send();
        final resBody = await response.stream.bytesToString();

        if (response.statusCode == 200) {
          final responseData = jsonDecode(resBody);
          url = responseData['secure_url'];
          publicId = responseData['public_id'];
        } else {
          throw Exception("Upload failed: $resBody");
        }
      }

      if (url != null && url.isNotEmpty) {
        await FirebaseFirestore.instance.collection('gallery').add({
          'url': url,
          'type': _selectedType,
          'public_id': publicId,
          'uploadedAt': Timestamp.now(),
        });

        // ✅ Send Push Notification Automatically
        await NotificationService.sendNotification(
          title: 'New Upload in Gallery',
          message:
              'New ${_selectedType.toUpperCase()} added. Check the gallery now!',
          sound: 'msy_alert', // 🔔 Custom sound
        );

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Uploaded successfully')));
        setState(() {
          _file = null;
          _webFile = null;
          _fileName = null;
          _youtubeUrlController.clear();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Upload failed: $e")));
    }

    setState(() => _isUploading = false);
  }

  Future<void> _deleteItem(String docId, String type, String? publicId) async {
    if (!_isAdmin) return;
    try {
      if (type != 'youtube' && publicId != null) {
        await deleteFromCloudinary(publicId, type);
      }
      await FirebaseFirestore.instance
          .collection('gallery')
          .doc(docId)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Item deleted successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error deleting item: $e")));
    }
  }

  Future<void> deleteFromCloudinary(String publicId, String type) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final signatureRaw =
        'public_id=$publicId&timestamp=$timestamp$cloudinaryApiSecret';
    final signature = sha1.convert(utf8.encode(signatureRaw)).toString();
    final url = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/${type == 'video' ? 'video' : 'image'}/destroy',
    );
    final response = await http.post(
      url,
      body: {
        'public_id': publicId,
        'api_key': cloudinaryApiKey,
        'timestamp': timestamp.toString(),
        'signature': signature,
      },
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete from Cloudinary: ${response.body}');
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await canLaunchUrl(uri)) {
      throw Exception('Could not launch $url');
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Upload to Gallery")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButton<String>(
              value: _selectedType,
              items: const [
                DropdownMenuItem(value: 'image', child: Text('Image')),
                DropdownMenuItem(value: 'video', child: Text('Video')),
                DropdownMenuItem(value: 'youtube', child: Text('YouTube Link')),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedType = val;
                    _file = null;
                    _webFile = null;
                  });
                }
              },
            ),
            const SizedBox(height: 10),
            if (_selectedType == 'youtube')
              TextField(
                controller: _youtubeUrlController,
                decoration: const InputDecoration(
                  labelText: 'YouTube Video URL',
                ),
              )
            else
              Column(
                children: [
                  ElevatedButton(
                    onPressed: _pickFile,
                    child: Text("Pick ${_selectedType.capitalize()}"),
                  ),
                  const SizedBox(height: 10),
                  if (_webFile != null && kIsWeb)
                    Image.memory(_webFile!, height: 150)
                  else if (_file != null && _selectedType == 'image')
                    Image.file(_file!, height: 150)
                  else if (_file != null)
                    Text("Video selected: ${_file!.path.split('/').last}"),
                ],
              ),
            const SizedBox(height: 20),
            _isUploading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _upload,
                    child: const Text("Upload"),
                  ),
            const SizedBox(height: 30),
            const Divider(),
            const Text(
              "Uploaded Items",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('gallery')
                  .orderBy('uploadedAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Text("No items uploaded yet.");
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final url = data['url'];
                    final type = data['type'];
                    final publicId = data['public_id'];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        leading: type == 'image'
                            ? Image.network(url, width: 50, fit: BoxFit.cover)
                            : const Icon(Icons.play_circle_fill),
                        title: Text(type.toUpperCase()),
                        subtitle: Text(
                          url.length > 40 ? '${url.substring(0, 40)}...' : url,
                        ),
                        onTap: () => type == 'youtube' ? _launchUrl(url) : null,
                        trailing: _isAdmin
                            ? IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () =>
                                    _deleteItem(doc.id, type, publicId),
                              )
                            : null,
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() => isEmpty ? this : this[0].toUpperCase() + substring(1);
}
