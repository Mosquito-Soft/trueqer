import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat.dart';
 
class ForYouPage extends StatefulWidget {
  const ForYouPage({super.key});
 
  @override
  State<ForYouPage> createState() => _ForYouPageState();
}
 
class _ForYouPageState extends State<ForYouPage> {
  // Sample feed data. Replace with Firestore data later.
  final List<_Post> _posts = [
    _Post(
      name: 'Maya Johnson',
      time: '2h ago',
      offered: 'Guitar',
      wanted: 'Spanish',
      text:
          'Just finished my first swap! Taught Daniel three chords and '
          'he taught me how to order food in Spanish. Best trade ever!',
      likes: 24,
      comments: 5,
    ),
    _Post(
      name: 'Daniel Rivera',
      time: '4h ago',
      offered: 'Spanish',
      wanted: 'Photography',
      text:
          'Looking for someone who can teach me photo editing. '
          'I can help with conversational Spanish in return.',
      likes: 12,
      comments: 3,
    ),
    _Post(
      name: 'Aisha Khan',
      time: 'Yesterday',
      offered: 'Python',
      wanted: 'Graphic Design',
      text:
          'Swapped Python basics for logo design with Chris. '
          'I now have a logo for my side project and he built his first script!',
      likes: 41,
      comments: 9,
    ),
    _Post(
      name: 'Chris Lee',
      time: 'Yesterday',
      offered: 'Graphic Design',
      wanted: 'Python',
      text: 'Thank you Aisha! Highly recommend swapping skills on Trueqer.',
      likes: 18,
      comments: 2,
    ),
  ];
 
  String _displayName = 'Trueqer User';
 
  @override
  void initState() {
    super.initState();
    _loadUserName();
  }
 
  // Shows a quick fallback name, then replaces it with the real
  // "fullName" saved in Firestore during signup.
  Future<void> _loadUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
 
    final email = user.email ?? '';
    final fallback =
        (user.displayName != null && user.displayName!.trim().isNotEmpty)
            ? user.displayName!
            : (email.contains('@') ? email.split('@').first : 'Trueqer User');
    if (mounted) setState(() => _displayName = fallback);
 
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final fullName = doc.data()?['fullName'] as String?;
      if (fullName != null && fullName.trim().isNotEmpty && mounted) {
        setState(() => _displayName = fullName.trim());
      }
    } catch (_) {
      // Keep the fallback name if Firestore can't be reached.
    }
  }
 
  String? get _photoUrl => FirebaseAuth.instance.currentUser?.photoURL;
 
  void _comingSoon(String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label page coming soon'),
        backgroundColor: Colors.teal,
        duration: const Duration(seconds: 1),
      ),
    );
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D111A),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF161B2E),
              Color(0xFF261A24),
              Color(0xFF3B201A),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: _posts.length,
                  itemBuilder: (context, index) => _buildPostCard(_posts[index]),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }
 
  // ---------- Top bar: logged-in user's name + profile picture ----------
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back,',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.amber.shade100.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _buildAvatar(
            name: _displayName,
            photoUrl: _photoUrl,
            radius: 24,
          ),
        ],
      ),
    );
  }
 
  Widget _buildAvatar({
    required String name,
    String? photoUrl,
    double radius = 20,
  }) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.amberAccent, width: 2),
      ),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: const Color(0xFF2C344A),
        backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
        child: photoUrl == null
            ? Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: TextStyle(
                  color: Colors.amberAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: radius * 0.9,
                ),
              )
            : null,
      ),
    );
  }
 
  // ---------- Feed post card ----------
  Widget _buildPostCard(_Post post) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author row
          Row(
            children: [
              _buildAvatar(name: post.name, radius: 18),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      post.time,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.more_horiz, color: Colors.white54),
            ],
          ),
          const SizedBox(height: 12),
 
          // Skill swap tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _skillChip(post.offered),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.swap_horiz,
                      color: Colors.amberAccent, size: 20),
                ),
                _skillChip(post.wanted),
              ],
            ),
          ),
          const SizedBox(height: 12),
 
          // Post text
          Text(
            post.text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.white.withValues(alpha: 0.12), height: 1),
          const SizedBox(height: 4),
 
          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _postAction(
                icon: post.liked ? Icons.favorite : Icons.favorite_border,
                label: '${post.likes}',
                color: post.liked ? Colors.redAccent : Colors.white70,
                onTap: () {
                  setState(() {
                    post.liked = !post.liked;
                    post.likes += post.liked ? 1 : -1;
                  });
                },
              ),
              _postAction(
                icon: Icons.mode_comment_outlined,
                label: '${post.comments}',
                onTap: () => _comingSoon('Comments'),
              ),
              _postAction(
                icon: Icons.share_outlined,
                label: 'Share',
                onTap: () => _comingSoon('Share'),
              ),
            ],
          ),
        ],
      ),
    );
  }
 
  Widget _skillChip(String label) {
    return Text(
      label,
      style: const TextStyle(
        color: Colors.amberAccent,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
    );
  }
 
  Widget _postAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = Colors.white70,
  }) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: color, size: 20),
      label: Text(label, style: TextStyle(color: color, fontSize: 13)),
    );
  }
 
  // ---------- Bottom bar: Request, Messages, Profile, Home ----------
  Widget _buildBottomBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161B2E),
        border: Border(
          top: BorderSide(color: Colors.amber.withValues(alpha: 0.3)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navButton(
                icon: Icons.swap_horizontal_circle_outlined, // [R] Request
                label: 'Request',
                onTap: () => _comingSoon('Request'),
              ),
              _navButton(
                icon: Icons.chat_bubble_outline,
                label: 'Messages',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ChatPage()),
                  );
                },
              ),
              _navButton(
                icon: Icons.person_outline, // [P] Profile
                label: 'Profile',
                onTap: () => Navigator.pushNamed(context, '/profile'),
              ),
              _navButton(
                icon: Icons.home_rounded, // Home (house icon)
                label: 'Home',
                isActive: true, // This page is the home feed
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
 
  Widget _navButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    final color = isActive ? Colors.amberAccent : Colors.white70;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
 
// Simple model for sample posts. Swap for a Firestore model later.
class _Post {
  final String name;
  final String time;
  final String offered;
  final String wanted;
  final String text;
  int likes;
  final int comments;
  bool liked;
 
  _Post({
    required this.name,
    required this.time,
    required this.offered,
    required this.wanted,
    required this.text,
    required this.likes,
    required this.comments,
  }) : liked = false;
}
 