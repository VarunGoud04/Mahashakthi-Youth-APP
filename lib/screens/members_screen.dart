import 'package:flutter/material.dart';

class MembersScreen extends StatefulWidget {
  const MembersScreen({super.key});

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Color?> _colorAnimation;

  final List<String> _members = [
    'V. RajKummar',
    'G. Rishivardan',
    'CH. Manohar',
    'B. Varun',
    'S. Tharun',
    'P. Rathan',
    'M. Akhilesh',
    'S. Varun',
    'B. Abhinay',
    'CH. Mahender',
    'B. Narsa',
    'Rishith',
    'M. Sathish',
    'Ashwith',
    'N. Aushuthosh',
    'M. Siddu',
    'Dheeraj',
    'Laxman',
    'Cherry',
    'Abhishek',
  ];

  @override
  void initState() {
    super.initState();
    // Animate from blue → purple → pink → orange → blue in a loop
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    _colorAnimation = _controller.drive(
      ColorTween(
        begin: Colors.blue,
        end: Colors.pink,
      ).chain(CurveTween(curve: Curves.linear)),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildAnimatedName(String name) {
    return AnimatedBuilder(
      animation: _colorAnimation,
      builder: (context, child) {
        return Text(
          name,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: _colorAnimation.value,
            shadows: [
              Shadow(
                blurRadius: 4,
                color: _colorAnimation.value!.withOpacity(0.6),
                offset: const Offset(1, 1),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Youth Members'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView.separated(
          itemCount: _members.length,
          separatorBuilder: (_, __) => const Divider(height: 24),
          itemBuilder: (context, index) {
            return Center(child: _buildAnimatedName(_members[index]));
          },
        ),
      ),
    );
  }
}
