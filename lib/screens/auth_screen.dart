import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../providers/firebase_provider.dart';
import 'onboarding_screen.dart';
import 'firebase_debug_screen.dart';
import 'home_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;

  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  // Animation controller
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final firebaseProvider =
          Provider.of<FirebaseProvider>(context, listen: false);

      if (_isLogin) {
        // Login
        final userCredential = await firebaseProvider.signIn(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );

        // Important: Check if widget is still mounted before continuing
        if (!mounted) return;

        // Add debug information
        print("==== AUTH DEBUG INFO ====");
        print("User authenticated: ${firebaseProvider.user?.uid}");
        print("User profile exists: ${firebaseProvider.userProfile != null}");

        // Check if user has a profile (has previously completed setup)
        if (firebaseProvider.user != null &&
            firebaseProvider.userProfile != null) {
          print("Height: ${firebaseProvider.userProfile!.height}");
          print("Weight: ${firebaseProvider.userProfile!.weight}");
          print("User profile data: ${firebaseProvider.userProfile!.toMap()}");

          // Check if onboardingComplete flag exists in user profile
          bool onboardingComplete = false;
          try {
            // Try to get the onboardingComplete status from the user profile
            var userData = await firebaseProvider.getUserStatsAsMap();
            print("User stats data: $userData");

            onboardingComplete = userData['onboardingComplete'] ??
                firebaseProvider.userProfile!.toMap()['onboardingComplete'] ??
                false;

            print("onboardingComplete flag value: $onboardingComplete");
          } catch (e) {
            print('Error checking onboarding status: $e');
            // If there's an error, assume it's not complete
            onboardingComplete = false;
          }

          // If the user profile exists and has height/weight data, we can assume onboarding is complete
          // This is a fallback in case the onboardingComplete flag isn't explicitly set
          if (!onboardingComplete &&
              firebaseProvider.userProfile!.height > 0 &&
              firebaseProvider.userProfile!.weight > 0) {
            onboardingComplete = true;
          }

          if (onboardingComplete) {
            // User has completed onboarding before, go directly to home screen
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => HomeScreen(
                  userName: firebaseProvider.userProfile!.name,
                  fitnessLevel: firebaseProvider.userProfile!.fitnessLevel,
                  goal: firebaseProvider.userProfile!.fitnessGoals.isNotEmpty
                      ? firebaseProvider.userProfile!.fitnessGoals.first
                      : 'Weight Loss',
                  height: firebaseProvider.userProfile!.height.toInt(),
                  weight: firebaseProvider.userProfile!.weight.toInt(),
                  memberSince: DateFormat('MMMM yyyy')
                      .format(firebaseProvider.userProfile!.createdAt),
                ),
              ),
            );
          } else {
            // User has a profile but hasn't completed onboarding
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const OnboardingScreen(),
              ),
            );
          }
        } else {
          // User logged in but profile not complete, go to onboarding
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const OnboardingScreen(),
            ),
          );
        }
      } else {
        // Sign up - Removed name field from signup process
        final userCredential = await firebaseProvider.signUp(
          _emailController.text.trim(),
          _passwordController.text.trim(),
          {
            'email': _emailController.text.trim(),
            'createdAt': FieldValue.serverTimestamp(),
            'onboardingComplete':
                false, // Explicitly mark onboarding as incomplete
          },
        );

        // Important: Check if widget is still mounted before continuing
        if (!mounted) return;

        // For new signup, always go to onboarding
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const OnboardingScreen(),
          ),
        );
      }
    } catch (e) {
      print('Authentication error: $e');

      // Important: Check if widget is still mounted before continuing
      if (!mounted) return;

      // Transform Firebase auth error messages into user-friendly messages
      String errorMessage = 'Authentication failed. Please try again.';

      if (e.toString().contains('user-not-found') ||
          e.toString().contains('wrong-password')) {
        errorMessage = 'Invalid email or password. Please try again.';
      } else if (e.toString().contains('email-already-in-use')) {
        errorMessage =
            'This email is already registered. Try logging in instead.';
      } else if (e.toString().contains('weak-password')) {
        errorMessage = 'Password is too weak. Please use a stronger password.';
      } else if (e.toString().contains('invalid-email')) {
        errorMessage = 'Please enter a valid email address.';
      } else if (e.toString().contains('network-request-failed')) {
        errorMessage = 'Network error. Please check your internet connection.';
      }

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      // Only update state if widget is still mounted
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
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF191414), Colors.black],
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),

                      // App logo
                      Container(
                        width: 100,
                        height: 100,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: SvgPicture.asset(
                            'assets/icon/fitquest.svg',
                            width: 70,
                            height: 70,
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      // App name
                      const Text(
                        'FitQuest',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Tagline
                      Text(
                        'Your fitness journey begins here',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 16,
                        ),
                      ),

                      const SizedBox(height: 50),

                      // Auth form
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title
                            Text(
                              _isLogin ? 'Login' : 'Create Account',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Email field
                            _buildTextField(
                              controller: _emailController,
                              label: 'Email',
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your email';
                                }
                                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                    .hasMatch(value)) {
                                  return 'Please enter a valid email';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 16),

                            // Password field
                            _buildTextField(
                              controller: _passwordController,
                              label: 'Password',
                              icon: Icons.lock_outline,
                              obscureText: _obscurePassword,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: Colors.grey,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your password';
                                }
                                if (!_isLogin && value.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 30),

                            // Submit button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _submitForm,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1DB954),
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  elevation: 0,
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        _isLogin ? 'LOGIN' : 'SIGN UP',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Switch mode text
                            Center(
                              child: RichText(
                                text: TextSpan(
                                  text: _isLogin
                                      ? 'Don\'t have an account? '
                                      : 'Already have an account? ',
                                  style: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontSize: 14,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: _isLogin ? 'Sign Up' : 'Login',
                                      style: const TextStyle(
                                        color: Color(0xFF1DB954),
                                        fontWeight: FontWeight.bold,
                                      ),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () {
                                          setState(() {
                                            _isLogin = !_isLogin;
                                          });
                                        },
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Add the debug button
                            const SizedBox(height: 40),
                            Center(
                              child: TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const FirebaseDebugScreen(),
                                    ),
                                  );
                                },
                                child: const Text(
                                  'Debug Firebase',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade400),
        prefixIcon: Icon(icon, color: Colors.grey.shade400),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.grey.shade900,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1DB954), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        errorStyle: const TextStyle(color: Colors.red),
      ),
      validator: validator,
    );
  }
}
