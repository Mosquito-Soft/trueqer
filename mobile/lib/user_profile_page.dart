import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Deep dark theme background
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'My Profile',
          style: TextStyle(color: Color(0xFFFFC107), fontWeight: FontWeight.bold), // Striking yellow
        ),
        iconTheme: const IconThemeData(color: Color(0xFFFFC107)),
        actions: [
          // Search button to look for other profiles
          IconButton(
            icon: const Icon(Icons.search, color: Color(0xFFFFC107)),
            onPressed: () {
              // TODO: Navigate to Search / Peer Discovery Screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Search profiles feature coming soon!')),
              );
            },
            tooltip: 'Search Profiles',
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

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      // Circular Profile Picture Placeholder
                      Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFFFC107), // Yellow accent border
                                width: 3,
                              ),
                            ),
                            child: const CircleAvatar(
                              radius: 60,
                              backgroundColor: Colors.white10,
                              child: Icon(
                                Icons.person,
                                size: 70,
                                color: Color(0xFFFFC107),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
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
                      const SizedBox(height: 32),

                      // Skills Section (Glassmorphic Black & Yellow Cards)
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
                      const SizedBox(height: 40),

                      // Back to Main / Home Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Navigate back to main/home dashboard route
                            Navigator.pushReplacementNamed(context, '/home');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFC107), // Yellow button
                            foregroundColor: Colors.black, // Black text
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

  // Reusable Skill Info Card Widget
  Widget _buildSkillCard({required String title, required String skills, required IconData icon}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05), // Glassmorphic dark fill
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