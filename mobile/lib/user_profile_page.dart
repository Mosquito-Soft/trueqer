import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// TODO: Create this file later as search_skills.dart
import 'search_skills.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final User? currentUser = FirebaseAuth.instance.currentUser;

  // Function to handle user logout and return to login screen
  Future<void> _handleLogout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  // Function to show Edit Profile Dialog (Bio, Social Link, Profile Image)
  void _showEditProfileDialog(BuildContext context, Map<String, dynamic> currentData) {
    final TextEditingController bioController =
        TextEditingController(text: currentData['bio'] ?? '');
    final TextEditingController socialController =
        TextEditingController(text: currentData['socialLink'] ?? '');
    final TextEditingController imageController =
        TextEditingController(text: currentData['profileImageUrl'] ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text(
            'Edit Profile',
            style: TextStyle(color: Color(0xFFFFC107), fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: imageController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Profile Image URL',
                    labelStyle: TextStyle(color: Colors.grey),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFFFC107)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: bioController,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Bio / About Me',
                    labelStyle: TextStyle(color: Colors.grey),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFFFC107)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: socialController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Social Link / Handle',
                    labelStyle: TextStyle(color: Colors.grey),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFFFC107)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFC107),
                foregroundColor: Colors.black,
              ),
              onPressed: () async {
                if (currentUser != null) {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(currentUser!.uid)
                      .update({
                    'profileImageUrl': imageController.text.trim(),
                    'bio': bioController.text.trim(),
                    'socialLink': socialController.text.trim(),
                  });
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  setState(() {}); // Refresh UI
                }
              },
              child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Deep dark theme background
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'My Profile',
          style: TextStyle(color: Color(0xFFFFC107), fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Color(0xFFFFC107)),
        actions: [
          // Search button taking user to search_skills.dart
          // Search button taking user to search_skills.dart
          IconButton(
            icon: const Icon(Icons.search, color: Color(0xFFFFC107)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SearchSkillsPage(),
                ),
              );
            },
            tooltip: 'Search Profiles & Skills',
          ),
          // Logout button
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () => _handleLogout(context),
            tooltip: 'Log Out',
          ),
        ],
      ),
      body: currentUser == null
          ? const Center(
              child: Text(
                'No user logged in.',
                style: TextStyle(color: Colors.white),
              ),
            )
          : FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(currentUser!.uid)
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFFFFC107)),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading profile data.',
                      style: TextStyle(color: Colors.red[300]),
                    ),
                  );
                }

                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Center(
                    child: Text(
                      'User profile data not found in Firestore.',
                      style: TextStyle(color: Colors.white54),
                    ),
                  );
                }

                // Extract user data from Firestore document
                var userData = snapshot.data!.data() as Map<String, dynamic>;
                String fullName = userData['fullName'] ?? 'Trueqer User';
                String email = userData['email'] ?? currentUser!.email ?? '';
                String skillsOffer = userData['skillsToOffer'] ?? 'Not specified';
                String skillsLearn = userData['skillsToLearn'] ?? 'Not specified';
                String bio = userData['bio'] ?? 'Tap edit profile to add your bio and social link.';
                String socialLink = userData['socialLink'] ?? 'No social link added';
                String? profileImageUrl = userData['profileImageUrl'];

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 10),
                      
                      // Edit Profile Button Action
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () => _showEditProfileDialog(context, userData),
                          icon: const Icon(Icons.edit, color: Color(0xFFFFC107), size: 18),
                          label: const Text(
                            'Edit Profile',
                            style: TextStyle(color: Color(0xFFFFC107), fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Circular Profile Picture with Camera Badge
                      Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFFFC107),
                                width: 3,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 60,
                              backgroundColor: Colors.white10,
                              backgroundImage: (profileImageUrl != null && profileImageUrl.isNotEmpty)
                                  ? NetworkImage(profileImageUrl)
                                  : null,
                              child: (profileImageUrl == null || profileImageUrl.isEmpty)
                                  ? const Icon(
                                      Icons.person,
                                      size: 70,
                                      color: Color(0xFFFFC107),
                                    )
                                  : null,
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () => _showEditProfileDialog(context, userData),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFFC107),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  size: 18,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // User Full Name
                      Text(
                        fullName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // User Email
                      Text(
                        email,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[400],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Bio & Social Media Card
                      _buildBioCard(bio: bio, socialLink: socialLink),
                      const SizedBox(height: 20),

                      // Skills Section Cards
                      _buildSkillCard(
                        title: 'Skills Offered',
                        skills: skillsOffer,
                        icon: Icons.handshake_outlined,
                      ),
                      const SizedBox(height: 16),
                      _buildSkillCard(
                        title: 'Skills Wanted',
                        skills: skillsLearn,
                        icon: Icons.school_outlined,
                      ),
                      const SizedBox(height: 36),

                      // Back to Main / Home Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pushReplacementNamed(context, '/home');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFC107),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.home, color: Colors.black),
                          label: const Text(
                            'Back to Main Dashboard',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  // Bio & Social Media Card Widget
  Widget _buildBioCard({required String bio, required String socialLink}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFC107).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.badge_outlined, color: Color(0xFFFFC107), size: 20),
              SizedBox(width: 8),
              Text(
                'Bio & Social',
                style: TextStyle(
                  color: Color(0xFFFFC107),
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            bio,
            style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.3),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.link, color: Colors.grey, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  socialLink,
                  style: const TextStyle(color: Color(0xFFFFC107), fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Reusable Skill Info Card Widget
  Widget _buildSkillCard({required String title, required String skills, required IconData icon}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFC107).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFFFFC107), size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFFFFC107),
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            skills,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}