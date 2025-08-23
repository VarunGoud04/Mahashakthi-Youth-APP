import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mahashakthiyouthapp/screens/full_screen_image.dart';
import 'package:mahashakthiyouthapp/screens/full_screen_video.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class GalleryScreen extends StatelessWidget {
  const GalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1),
      appBar: AppBar(
        title: const Text("Gallery"),
        backgroundColor: const Color(0xFF8E3200),
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          const Text(
            "Moments from Mahashakthi Youth Events",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.brown,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('gallery')
                  .orderBy('uploadedAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return const Center(child: Text("No gallery items found."));
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: docs.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemBuilder: (context, index) {
                    final docData = docs[index].data();
                    if (docData == null || docData is! Map<String, dynamic>) {
                      return const SizedBox(); // Skip invalid items
                    }

                    final Map<String, dynamic> data = Map<String, dynamic>.from(
                      docData,
                    );
                    final String url = data['url'] ?? '';
                    final String type = data['type'] ?? '';

                    return GestureDetector(
                      onTap: () {
                        if (type == 'image') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FullScreenImage(imagePath: url),
                            ),
                          );
                        } else if (type == 'video') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  FullScreenVideo(videoAssetPath: url),
                            ),
                          );
                        } else if (type == 'youtube') {
                          final videoId = YoutubePlayer.convertUrlToId(url);
                          if (videoId != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => YoutubePlayerBuilder(
                                  player: YoutubePlayer(
                                    controller: YoutubePlayerController(
                                      initialVideoId: videoId,
                                      flags: const YoutubePlayerFlags(
                                        autoPlay: true,
                                        mute: false,
                                      ),
                                    ),
                                    showVideoProgressIndicator: true,
                                  ),
                                  builder: (context, player) => Scaffold(
                                    appBar: AppBar(
                                      title: const Text('YouTube Video'),
                                    ),
                                    body: Center(child: player),
                                  ),
                                ),
                              ),
                            );
                          }
                        }
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: type == 'image'
                            ? Image.network(url, fit: BoxFit.cover)
                            : Container(
                                color: Colors.black,
                                child: const Center(
                                  child: Icon(
                                    Icons.play_circle_fill,
                                    color: Colors.white,
                                    size: 40,
                                  ),
                                ),
                              ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              "Developed by B. Varun Goud, Committee Member\nContact: +91 9014075885",
              style: TextStyle(
                fontSize: 12,
                color: Color.fromARGB(137, 208, 16, 16),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
