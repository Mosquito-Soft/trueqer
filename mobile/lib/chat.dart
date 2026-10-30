import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_room_page.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final User? currentUser = FirebaseAuth.instance.currentUser;

  // Using 'var' avoids any angle-bracket parsing errors entirely
  final _mockChats = [
    {
      'chatId': 'ai_assistant_chat',
      'name': 'Trueqer AI Assistant',
      'avatar': '',
      'lastMessage': 'Ready to help you coordinate your skill swaps!',
      'time': 'Just now',
      'isAi': true,
      'unread': 1,
    },
    {
      'chatId': 'peer_chat_1',
      'name': 'Diana Smith',
      'avatar': '',
      'lastMessage': 'Let’s exchange Python tutoring for Spanish conversation!',
      'time': '10m ago',
      'isAi': false,
      'unread': 2,
    },
    {
      'chatId': 'peer_chat_2',
      'name': 'Luffy One Piece',
      'avatar': '',
      'lastMessage': 'Did you push the latest commit to the dev branch?',
      'time': '1h ago',
      'isAi': false,
      'unread': 0,
    },
    {
      'chatId': 'peer_chat_3',
      'name': 'Maria Hayek',
      'avatar': '',
      'lastMessage': 'Don’t forget we are meeting at the campus library.',
      'time': 'Yesterday',
      'isAi': false,
      'unread': 0,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D111A),
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Messages & Chats',
          style: TextStyle(color: Color(0xFFFFC107), fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Color(0xFFFFC107)),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _mockChats.length,
        itemBuilder: (context, index) {
          final chat = _mockChats[index];
          final bool isAi = chat['isAi'] as bool? ?? false;
          final String name = chat['name'] as String? ?? '';
          final String avatar = chat['avatar'] as String? ?? '';
          final String lastMessage = chat['lastMessage'] as String? ?? '';
          final String time = chat['time'] as String? ?? '';
          final String chatId = chat['chatId'] as String? ?? '';
          final int unread = chat['unread'] as int? ?? 0;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isAi
                    ? const Color(0xFFFFC107).withValues(alpha: 0.6)
                    : Colors.white.withValues(alpha: 0.1),
                width: isAi ? 1.5 : 1,
              ),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Stack(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: isAi ? const Color(0xFFFFC107) : Colors.white10,
                    child: isAi
                        ? const Icon(Icons.smart_toy, color: Colors.black, size: 28)
                        : const Icon(Icons.person, color: Color(0xFFFFC107), size: 28),
                  ),
                  if (isAi)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.greenAccent,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.star, size: 10, color: Colors.black),
                      ),
                    ),
                ],
              ),
              title: Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  lastMessage,
                  style: TextStyle(color: Colors.grey[400], fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    time,
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                  const SizedBox(height: 6),
                  if (unread > 0)
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFC107),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$unread',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatRoomPage(
                      chatId: chatId,
                      peerName: name,
                      peerAvatar: avatar,
                      isAiChat: isAi,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      // Bottom Navigation Bar integrated here:
      bottomNavigationBar: _buildBottomBar(),
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
                isActive: true, // Highlights Messages since we are on ChatPage
                onTap: () {},
              ),
              _navButton(
                icon: Icons.person_outline, // [P] Profile
                label: 'Profile',
                onTap: () => Navigator.pushNamed(context, '/profile'),
              ),
              _navButton(
                icon: Icons.home_rounded, // Home
                label: 'Home',
                onTap: () {
                  // Go back to the home/for you feed
                  Navigator.pop(context);
                },
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

  void _comingSoon(String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$title coming soon!')),
    );
  }
}