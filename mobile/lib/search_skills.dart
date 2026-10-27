import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SearchSkillsPage extends StatefulWidget {
  const SearchSkillsPage({super.key});

  @override
  State<SearchSkillsPage> createState() => _SearchSkillsPageState();
}

class _SearchSkillsPageState extends State<SearchSkillsPage>
    with SingleTickerProviderStateMixin {
  final User? currentUser = FirebaseAuth.instance.currentUser;

  List<Map<String, dynamic>> _profiles = [];
  bool _isLoading = true;
  int _currentIndex = 0;

  // Animation controller for smooth card swiping/sliding
  late AnimationController _controller;
  Offset _dragOffset = Offset.zero;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fetchProfiles();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Fetch all other users from Firestore excluding the currently logged-in user
  Future<void> _fetchProfiles() async {
    try {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('users').get();

      List<Map<String, dynamic>> loadedProfiles = [];
      for (var doc in snapshot.docs) {
        if (doc.id != currentUser?.uid) {
          var data = doc.data() as Map<String, dynamic>;
          data['uid'] = doc.id; // Store document ID for matching/favorites
          loadedProfiles.add(data);
        }
      }

      setState(() {
        _profiles = loadedProfiles;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading peer profiles: $e')),
      );
    }
  }

  // Handle Swipe Right / Match / Checkmark Click
  void _matchProfile() async {
    if (_currentIndex >= _profiles.length) return;
    var matchedUser = _profiles[_currentIndex];

    // Optional: Save match to Firestore subcollection if needed
    if (currentUser != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser!.uid)
            .collection('matches')
            .doc(matchedUser['uid'])
            .set({
          'matchedWith': matchedUser['uid'],
          'fullName': matchedUser['fullName'],
          'timestamp': FieldValue.serverTimestamp(),
        });
      } catch (_) {}
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🎉 It\'s a Trueqer Match with ${matchedUser['fullName']}!'),
        backgroundColor: const Color(0xFFFFC107),
        behavior: SnackBarBehavior.floating,
      ),
    );

    _nextCard();
  }

  // Handle Swipe Left / Reject / X Click
  void _rejectProfile() {
    _nextCard();
  }

  // Handle Star / Favorite Bookmark
  void _favoriteProfile() async {
    if (_currentIndex >= _profiles.length) return;
    var favUser = _profiles[_currentIndex];

    if (currentUser != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser!.uid)
            .collection('favorites')
            .doc(favUser['uid'])
            .set({
          'favoriteId': favUser['uid'],
          'fullName': favUser['fullName'],
          'skillsToOffer': favUser['skillsToOffer'],
          'timestamp': FieldValue.serverTimestamp(),
        });
      } catch (_) {}
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('⭐ Saved to Favorites!'),
        backgroundColor: Colors.amberAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _nextCard() {
    setState(() {
      _dragOffset = Offset.zero;
      _currentIndex++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Pitch dark theme
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Discover Skills',
          style: TextStyle(
            color: Color(0xFFFFC107),
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFFFFC107)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFFC107)),
            )
          : _profiles.isEmpty || _currentIndex >= _profiles.length
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.waves, size: 80, color: Color(0xFFFFC107)),
                      const SizedBox(height: 16),
                      const Text(
                        'No more skill profiles nearby!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Check back later or expand your search radius.',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFC107),
                          foregroundColor: Colors.black,
                        ),
                        onPressed: () {
                          setState(() {
                            _currentIndex = 0;
                            _isLoading = true;
                          });
                          _fetchProfiles();
                        },
                        child: const Text('Reload Profiles'),
                      ),
                    ],
                  ),
                )
              : SafeArea(
                  child: Column(
                    children: [
                      // Swipe Card Stack Area
                      Expanded(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                var profile = _profiles[_currentIndex];
                                return GestureDetector(
                                  onPanUpdate: (details) {
                                    setState(() {
                                      _dragOffset += details.delta;
                                    });
                                  },
                                  onPanEnd: (details) {
                                    if (_dragOffset.dx > 120) {
                                      _matchProfile(); // Swiped Right
                                    } else if (_dragOffset.dx < -120) {
                                      _rejectProfile(); // Swiped Left
                                    } else {
                                      setState(() {
                                        _dragOffset = Offset.zero;
                                      });
                                    }
                                  },
                                  child: AnimatedBuilder(
                                    animation: _controller,
                                    builder: (context, child) {
                                      return Transform.translate(
                                        offset: _dragOffset,
                                        child: Transform.rotate(
                                          angle: _dragOffset.dx * 0.0015,
                                          child: _buildSkillCard(profile, constraints),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),

                      // Tinder Action Buttons (X, Star, Checkmark)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Reject / Swipe Left Button (X)
                            _buildActionButton(
                              icon: Icons.close,
                              color: Colors.redAccent,
                              size: 56,
                              onPressed: _rejectProfile,
                            ),
                            const SizedBox(width: 24),
                            // Favorite / Star Bookmark Button
                            _buildActionButton(
                              icon: Icons.star,
                              color: Colors.amberAccent,
                              size: 48,
                              onPressed: _favoriteProfile,
                            ),
                            const SizedBox(width: 24),
                            // Match / Swipe Right Button (Checkmark)
                            _buildActionButton(
                              icon: Icons.check,
                              color: const Color(0xFFFFC107),
                              size: 56,
                              onPressed: _matchProfile,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  // The Tinder Card UI Widget showing Photo, Bio, and Skills Exchange
  Widget _buildSkillCard(Map<String, dynamic> profile, BoxConstraints constraints) {
    String fullName = profile['fullName'] ?? 'Trueqer User';
    String bio = profile['bio'] ?? 'Passionate learner and skill trader.';
    String skillsOffer = profile['skillsToOffer'] ?? 'General Skills';
    String skillsLearn = profile['skillsToLearn'] ?? 'Open to learning';
    String? imageUrl = profile['profileImageUrl'];
    String socialLink = profile['socialLink'] ?? '';

    return Container(
      width: constraints.maxWidth,
      height: constraints.maxHeight * 0.82,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFFC107).withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Image / Avatar Box
              Stack(
                children: [
                  Container(
                    height: 240,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      image: (imageUrl != null && imageUrl.isNotEmpty)
                          ? DecorationImage(
                              image: NetworkImage(imageUrl),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: (imageUrl == null || imageUrl.isEmpty)
                        ? const Center(
                            child: Icon(Icons.person, size: 90, color: Color(0xFFFFC107)),
                          )
                        : null,
                  ),
                  // Gradient Overlay for readability
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            const Color(0xFF1E1E1E),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Profile Details
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (socialLink.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.link, size: 14, color: Color(0xFFFFC107)),
                          const SizedBox(width: 6),
                          Text(
                            socialLink,
                            style: const TextStyle(color: Color(0xFFFFC107), fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                    Text(
                      bio,
                      style: TextStyle(color: Colors.grey[300], fontSize: 14, height: 1.4),
                    ),
                    const SizedBox(height: 20),

                    // Skill Offering Badge Card
                    _buildSkillPill(
                      title: 'OFFERING SKILL',
                      skillText: skillsOffer,
                      icon: Icons.handshake_outlined,
                      accentColor: const Color(0xFFFFC107),
                    ),
                    const SizedBox(height: 12),

                    // Skill Wanted Badge Card
                    _buildSkillPill(
                      title: 'WANTS TO LEARN',
                      skillText: skillsLearn,
                      icon: Icons.school_outlined,
                      accentColor: Colors.amberAccent,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Reusable Skill Pill Card Inside Swipe Card
  Widget _buildSkillPill({
    required String title,
    required String skillText,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accentColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accentColor, size: 16),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  color: accentColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            skillText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Action Button Builder (X, Star, Check)
  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required double size,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onPressed,
        iconSize: size * 0.5,
        icon: Icon(icon, color: color),
        style: IconButton.styleFrom(
          backgroundColor: Colors.black,
          side: BorderSide(color: color, width: 2),
          padding: EdgeInsets.all(size * 0.25),
        ),
      ),
    );
  }
}