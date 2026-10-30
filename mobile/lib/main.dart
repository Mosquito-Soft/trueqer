import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:trueqer/chat.dart';
import 'firebase_options.dart'; // Automatically generated!
import 'signup_screen.dart';
import 'login_screen.dart';
import 'user_profile_page.dart';
import 'for_you_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const TrueqerApp());
}

class TrueqerApp extends StatelessWidget {
  const TrueqerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trueqer',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.amber,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const TrueqerHomeScreen(),
      debugShowCheckedModeBanner: false,
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/profile': (context) => const UserProfilePage(),
        '/home': (context) => const TrueqerHomeScreen(),
        '/foryou':(context) => const ForYouPage(),
        '/chat': (context) => const ChatPage(),
      },
    );
  }
}

class TrueqerHomeScreen extends StatefulWidget {
  const TrueqerHomeScreen({super.key});

  @override
  State<TrueqerHomeScreen> createState() => _TrueqerHomeScreenState();
}

class _TrueqerHomeScreenState extends State<TrueqerHomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late Timer _timer;

  // Skill highlights for the auto-sliding banner
  // Skills samples (Showcase)
  final List<Map<String, String>> _skillHighlights = [
    {
      'title': 'Learn Acoustic Guitar',
      'offeredBy': 'Alex M. • University Student',
      'image': 'https://plus.unsplash.com/premium_photo-1682097225321-86a911d37366?auto=format&fit=crop&w=800&q=80',
    },
    {
      'title': 'Advanced Calculus & Linear Algebra',
      'offeredBy': 'Steven K. • Math Tutor',
      'image': 'https://res.cloudinary.com/digicomm/image/upload/t_metadata/news-magazine/2023/_assets/calculus.png',
    },
    {
      'title': 'Master Italian Cooking',
      'offeredBy': 'Marco P. • Culinary Enthusiast',
      'image': 'https://images.unsplash.com/photo-1556910103-1c02745aae4d?auto=format&fit=crop&w=800&q=80',
    },
    {
      'title': 'Artisan Baking & Cake Decorating',
      'offeredBy': 'Chef Chloe • Pastry Arts',
      'image': 'https://classbento.com/images/article/best-couples-baking-classes-in-nyc-800.jpg?1715214978',
    },
    {
      'title': 'Self-Defense & Personal Safety',
      'offeredBy': 'Alex M. • Campus Safety Club',
      'image': 'https://npr.brightspotcdn.com/0c/80/8a4c3cdb48849778641cb11e4e63/img-6855.jpg',
    },
  ];

  @override
  void initState() {
    super.initState();
    // Auto-advance the banner every 4 seconds
    _timer = Timer.periodic(const Duration(seconds: 4), (Timer timer) {
      if (_currentPage < _skillHighlights.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D111A),
      appBar: AppBar(
        title: const Text(
          'Trueqer',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // 1. Bartering / Community Background Image with Dark Atmospheric Overlay
          Positioned.fill(
            child: Stack(
              children: [
                Image.network(
                  'https://images.unsplash.com/photo-1517245386807-bb43f82c33c4?auto=format&fit=crop&w=1200&q=80',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFF161B2E).withValues(alpha: 0.92),
                        const Color(0xFF261A24).withValues(alpha: 0.94),
                        const Color(0xFF3B201A).withValues(alpha: 0.96),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. Scrollable Content Layout
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero section with auto-sliding images
                SizedBox(
                  height: 280,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _skillHighlights.length,
                    onPageChanged: (int index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      final item = _skillHighlights[index];
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.amber.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                          image: DecorationImage(
                            image: item['image']!.startsWith('assets/')
                                ? AssetImage(item['image']!) as ImageProvider
                                : NetworkImage(item['image']!) as ImageProvider,
                            fit: BoxFit.cover,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.85),
                                Colors.transparent,
                              ],
                            ),
                          ),
                          padding: const EdgeInsets.all(16.0),
                          alignment: Alignment.bottomLeft,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['title']!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item['offeredBy']!,
                                style: TextStyle(
                                  color: Colors.amber.shade100.withValues(alpha: 0.8),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Indicator dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_skillHighlights.length, (index) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: _currentPage == index ? 22.0 : 8.0,
                      height: 8.0,
                      margin: const EdgeInsets.symmetric(horizontal: 4.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: _currentPage == index
                            ? Colors.amberAccent
                            : Colors.white24,
                      ),
                    );
                  }),
                ),

                const Padding(
                  padding: EdgeInsets.fromLTRB(24, 24, 24, 8),
                  child: Text(
                    'Barter Skills, Build Community',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Connect with fellow students to exchange what you know for what you want to learn. No money needed—just pure skill sharing.',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey.shade300,
                      height: 1.4,
                    ),
                  ),
                ),

                const SizedBox(height: 36),

                // Login and Sign Up Action Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber.shade400,
                            foregroundColor: Colors.black87,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 6,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LoginScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            'Log In',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: Colors.amberAccent,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            backgroundColor: Colors.white.withValues(alpha: 0.05),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SignupScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            'Sign Up',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.amberAccent,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}