import 'package:flutter/material.dart';
import 'signup_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isLampOn = true; // Controls the light beam & illumination state
  bool _rememberMe = false; // Controls Remember Me checkbox state
  bool _isLoading = false; // Firebase loading state

  late AnimationController _switchController;
  late Animation<double> _cordAnimation;

  @override
  void initState() {
    super.initState();
    _switchController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _cordAnimation = Tween<double>(begin: 0.0, end: 15.0).animate(
      CurvedAnimation(parent: _switchController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _switchController.dispose();
    super.dispose();
  }

  void _toggleLamp() {
    setState(() {
      _isLampOn = !_isLampOn;
    });
    // Brief cord pull bounce animation effect
    _switchController.forward().then((_) => _switchController.reverse());
  }

// --- Firebase Password Reset --- //
  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your email above to reset your password.'),
          backgroundColor: Colors.amber,
        ),
      );
      return;
    } 
    // 2. If we reach here, email is valid, so call Firebase!
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password reset link sent to $email'),
          backgroundColor: Colors.teal,
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? 'Failed to send reset email.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _handleLogin() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() {
    _isLoading = true;
  });

  try {
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Logging in... Welcome back to Trueqer!'),
        backgroundColor: Colors.teal,
      ),
    );

    Navigator.pushReplacementNamed(context, '/profile');
  } on FirebaseAuthException catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(e.message ?? 'Login failed. Please check your credentials.'),
        backgroundColor: Colors.redAccent,
      ),
    );
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('An unexpected error occurred: $e'),
        backgroundColor: Colors.redAccent,
      ),
    );
  } finally {
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D111A),
      body: Stack(
        children: [
          // 1. Background Scene (Gradient Base)
          Positioned.fill(
            child: Container(
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
            ),
          ),

          // 2. Interactive Light Beam & Illumination Cone
          AnimatedOpacity(
            duration: const Duration(milliseconds: 400),
            opacity: _isLampOn ? 1.0 : 0.05,
            child: CustomPaint(
              size: MediaQuery.of(context).size,
              painter: LightBeamPainter(),
            ),
          ),

          // 3. Back Button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          // 4. Main Content: Hanging Lamp + Login Form Card
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Hanging Lamp & Pull Cord Component
                    _buildHangingLamp(),
                    const SizedBox(height: 30),

                    // Glassmorphism Login Card
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: _isLampOn
                            ? Colors.white.withValues(alpha: 0.12)
                            : Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: _isLampOn
                              ? Colors.amber.withValues(alpha: 0.3)
                              : Colors.white.withValues(alpha: 0.08),
                          width: 1.5,
                        ),
                        boxShadow: [
                          if (_isLampOn)
                            BoxShadow(
                              color: Colors.amber.withValues(alpha: 0.15),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Welcome Back',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Trueqer Skill Swap',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.amber.shade100
                                    .withValues(alpha: 0.7),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Email Field
                            TextFormField(
                              controller: _emailController,
                              style: const TextStyle(color: Colors.white),
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                labelText: 'University Email',
                                labelStyle:
                                    const TextStyle(color: Colors.white70),
                                prefixIcon: const Icon(Icons.email_outlined,
                                    color: Colors.amberAccent),
                                filled: true,
                                fillColor: Colors.black.withValues(alpha: 0.3),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                      color: Colors.white.withValues(alpha: 0.2)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                      color: Colors.amberAccent, width: 2),
                                ),
                              ),
                              validator: (value) =>
                                  value == null || value.trim().isEmpty
                                      ? 'Please enter your email'
                                      : null,
                            ),
                            const SizedBox(height: 16),

                            // Password Field
                            TextFormField(
                              controller: _passwordController,
                              obscureText: !_isPasswordVisible,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Password',
                                labelStyle:
                                    const TextStyle(color: Colors.white70),
                                prefixIcon: const Icon(Icons.lock_outline,
                                    color: Colors.amberAccent),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isPasswordVisible
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                    color: Colors.white70,
                                  ),
                                  onPressed: () => setState(() =>
                                      _isPasswordVisible = !_isPasswordVisible),
                                ),
                                filled: true,
                                fillColor: Colors.black.withValues(alpha: 0.3),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                      color: Colors.white.withValues(alpha: 0.2)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Colors.amberAccent,
                                    width: 2,
                                  ),
                                ),
                              ),
                              validator: (value) =>
                                  value == null || value.isEmpty
                                      ? 'Please enter your password'
                                      : null,
                            ),
                            const SizedBox(height: 12),

                            // Remember Me & Forgot Password Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: Checkbox(
                                        value: _rememberMe,
                                        activeColor: Colors.amberAccent,
                                        checkColor: Colors.black87,
                                        side: BorderSide(
                                          color: Colors.white.withValues(alpha: 0.6),
                                        ),
                                        onChanged: (value) {
                                          setState(() {
                                            _rememberMe = value ?? false;
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Remember me',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                                TextButton(
                                  onPressed: _handleForgotPassword,
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Text(
                                    'Forgot password?',
                                    style: TextStyle(
                                      color: Colors.amberAccent,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Sign In Button
                            ElevatedButton(
                              onPressed: _isLoading ? null : _handleLogin, //This disables the button while is loading
                              style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                backgroundColor: Colors.amber.shade400,
                                foregroundColor: Colors.black87,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 6,
                              ),
                              child: _isLoading
                                ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                              : const Text(
                                'SIGN IN',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Redirect to Signup
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Don't have an account? ",
                            style: TextStyle(color: Colors.white70)),
                        GestureDetector(
                          onTap: () {
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
                              color: Colors.amberAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Hanging Lamp Widget with Pull Cord & Glowing Bulb
  Widget _buildHangingLamp() {
    return Column(
      children: [
        Container(
          width: 2,
          height: 35,
          color: Colors.grey.shade600,
        ),
        GestureDetector(
          onTap: _toggleLamp,
          child: Column(
            children: [
              Container(
                width: 70,
                height: 25,
                decoration: BoxDecoration(
                  color: const Color(0xFF2C344A),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(8)),
                  border: Border.all(color: Colors.grey.shade500, width: 1),
                ),
              ),
              Stack(
                alignment: Alignment.topCenter,
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: _isLampOn
                          ? Colors.amberAccent
                          : Colors.grey.shade700,
                      shape: BoxShape.circle,
                      boxShadow: [
                        if (_isLampOn)
                          const BoxShadow(
                            color: Colors.amber,
                            blurRadius: 18,
                            spreadRadius: 4,
                          ),
                      ],
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _cordAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _cordAnimation.value),
                        child: Container(
                          margin: const EdgeInsets.only(top: 15),
                          width: 2,
                          height: 35,
                          color: Colors.grey.shade400,
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              width: 8,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Colors.amber.shade200,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class LightBeamPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.amber.withValues(alpha: 0.35),
          Colors.amber.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path()
      ..moveTo(size.width / 2 - 25, 60)
      ..lineTo(size.width / 2 + 25, 60)
      ..lineTo(size.width + 100, size.height)
      ..lineTo(-100, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}