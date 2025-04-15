import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'dart:math' as math;
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/firebase_provider.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final _formKey = GlobalKey<FormBuilderState>();
  int _currentPage = 0;
  final int _totalPages = 3;

  // Default values
  String _name = '';
  double _height = 170; // cm
  bool _isHeightMetric = true;
  double _weight = 70; // kg
  bool _isWeightMetric = true;
  String _goal = 'Weight Loss';
  bool _isLoading = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    // If on the personal info page (page 1), validate the name field before proceeding
    if (_currentPage == 1) {
      // Validate only the name field
      if (_formKey.currentState?.fields['name']?.validate() ?? false) {
        if (_name.trim().isEmpty) {
          // Show error if name is empty or just whitespace
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enter your name to continue'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        _pageController.nextPage(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      } else {
        // Show error message if validation fails
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter your name to continue'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      // Submit form and navigate to home screen
      if (_formKey.currentState?.saveAndValidate() ?? false) {
        // Get the name from the form
        _name = _formKey.currentState?.value['name'] ?? '';

        // Ensure name is not empty
        if (_name.trim().isEmpty) {
          // Show error if name is empty or just whitespace
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enter your name to continue'),
              backgroundColor: Colors.red,
            ),
          );
          // Go back to the personal info page
          _pageController.animateToPage(
            1,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
          );
          return;
        }

        // Calculate fitness level based on BMI or other metrics
        // This is a simple placeholder - you might want a more sophisticated algorithm
        String fitnessLevel = 'Beginner';
        if (_isHeightMetric && _isWeightMetric) {
          double bmi = _weight / ((_height / 100) * (_height / 100));
          if (bmi > 18.5 && bmi < 25) {
            fitnessLevel = 'Intermediate';
          } else if (bmi >= 25) {
            fitnessLevel = 'Advanced';
          }
        }

        // Get the current date formatted
        final memberSince = DateFormat('MMMM yyyy').format(DateTime.now());

        // Save user profile data to Firebase
        _saveUserProfile(fitnessLevel, memberSince);
      }
    }
  }

  Future<void> _saveUserProfile(String fitnessLevel, String memberSince) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final firebaseProvider =
          Provider.of<FirebaseProvider>(context, listen: false);

      // Calculate height and weight in metric units
      final height = _isHeightMetric ? _height : (_height * 30.48);
      final weight = _isWeightMetric ? _weight : (_weight * 0.453592);

      // Create user profile data
      final userData = {
        'name': _name,
        'height': height,
        'weight': weight,
        'fitnessLevel': fitnessLevel,
        'fitnessGoals': [_goal],
        'age': 25, // Default age, you can add this to the form if needed
        'updatedAt': FieldValue.serverTimestamp(),
        'onboardingComplete': true, // Mark onboarding as complete
      };

      // Update user profile in Firebase
      await firebaseProvider.updateUserProfile(userData);

      // Create default stats - ALSO include onboardingComplete flag here
      await firebaseProvider.updateUserStats({
        'steps': 0,
        'stepsGoal': 10000,
        'caloriesBurned': 0,
        'caloriesGoal': 500,
        'workoutsCompleted': 0,
        'onboardingComplete': true, // Add this flag to stats as well
      });

      print('User profile and stats updated with onboardingComplete = true');

      // Make sure to check if the widget is still mounted before proceeding
      if (!mounted) return;

      // Navigate to home screen - create a local variable for the context
      final BuildContext currentContext = context;
      Navigator.pushReplacement(
        currentContext,
        MaterialPageRoute(
          builder: (context) => HomeScreen(
            userName: _name,
            fitnessLevel: fitnessLevel,
            goal: _goal,
            height:
                _isHeightMetric ? _height.toInt() : (_height * 30.48).toInt(),
            weight: _isWeightMetric
                ? _weight.toInt()
                : (_weight * 0.453592).toInt(),
            memberSince: memberSince,
          ),
        ),
      );

      // Only show success message if still mounted and has context
      if (mounted) {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          const SnackBar(content: Text('Profile created successfully!')),
        );
      }
    } catch (e) {
      print('Error saving user profile: $e');

      // Only show error message if still mounted
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating profile: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Animated background
          const ParticleBackground(),

          // Content
          SafeArea(
            child: FormBuilder(
              key: _formKey,
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  _buildWelcomePage(),
                  _buildPersonalInfoPage(),
                  _buildGoalSelectionPage(),
                ],
              ),
            ),
          ),

          // Progress indicator
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _totalPages,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  height: 10,
                  width: _currentPage == index ? 30 : 10,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? const Color(0xFF1DB954)
                        : Colors.grey.shade600,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
            ),
          ),

          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF1DB954),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // App logo
          Container(
            width: 120,
            height: 120,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: SvgPicture.asset(
                'assets/icon/fitquest.svg',
                width: 90,
                height: 90,
              ),
            ),
          ),
          // Remove this extra closing parenthesis
          const SizedBox(height: 40),
          // Headline
          const Text(
            "Let's build your fitness journey",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          // Subtitle
          const Text(
            "Tell us a few details to personalize your plan",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 60),
          // Next button
          _buildNextButton("Get Started"),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoPage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          const Text(
            "Personal Details",
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Let's get to know you better",
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 40),
          // Name input
          FormBuilderTextField(
            name: 'name',
            initialValue: _name,
            onChanged: (value) => _name = value ?? '',
            decoration: InputDecoration(
              labelText: 'Name *',
              labelStyle: const TextStyle(color: Colors.grey),
              prefixIcon: const Icon(Icons.person, color: Colors.grey),
              filled: true,
              fillColor: Colors.grey.shade900,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF1DB954)),
              ),
              errorStyle: const TextStyle(color: Colors.redAccent),
              helperText: 'Required',
              helperStyle: const TextStyle(color: Colors.grey),
            ),
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(
                  errorText: 'Please enter your name'),
              FormBuilderValidators.minLength(2,
                  errorText: 'Name must be at least 2 characters'),
            ]),
            style: const TextStyle(color: Colors.white),
            autovalidateMode: AutovalidateMode.onUserInteraction,
          ),
          const SizedBox(height: 20),
          // Height input
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Height: ${_formatHeight()}',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            if (!_isHeightMetric) {
                              // Convert from ft to cm
                              _height = (_height * 30.48).clamp(120.0, 220.0);
                            }
                            _isHeightMetric = true;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _isHeightMetric
                                ? const Color(0xFF1DB954)
                                : Colors.grey.shade800,
                            borderRadius: const BorderRadius.horizontal(
                                left: Radius.circular(20)),
                          ),
                          child: const Text(
                            'cm',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            if (_isHeightMetric) {
                              // Convert from cm to ft
                              _height = (_height / 30.48).clamp(4.0, 7.2);
                            }
                            _isHeightMetric = false;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: !_isHeightMetric
                                ? const Color(0xFF1DB954)
                                : Colors.grey.shade800,
                            borderRadius: const BorderRadius.horizontal(
                                right: Radius.circular(20)),
                          ),
                          child: const Text(
                            'ft',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: const Color(0xFF1DB954),
                  inactiveTrackColor: Colors.grey.shade800,
                  thumbColor: Colors.white,
                  overlayColor: const Color(0xFF1DB954).withOpacity(0.2),
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 12),
                ),
                child: Slider(
                  min: _isHeightMetric ? 120 : 4,
                  max: _isHeightMetric ? 220 : 7.2,
                  value: _height.clamp(_isHeightMetric ? 120.0 : 4.0,
                      _isHeightMetric ? 220.0 : 7.2),
                  onChanged: (value) {
                    setState(() {
                      _height = value;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Weight input
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Weight: ${_formatWeight()}',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            if (!_isWeightMetric) {
                              // Convert from lbs to kg
                              _weight = (_weight * 0.453592).clamp(40.0, 150.0);
                            }
                            _isWeightMetric = true;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _isWeightMetric
                                ? const Color(0xFF1DB954)
                                : Colors.grey.shade800,
                            borderRadius: const BorderRadius.horizontal(
                                left: Radius.circular(20)),
                          ),
                          child: const Text(
                            'kg',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            if (_isWeightMetric) {
                              // Convert from kg to lbs
                              _weight = (_weight / 0.453592).clamp(88.0, 330.0);
                            }
                            _isWeightMetric = false;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: !_isWeightMetric
                                ? const Color(0xFF1DB954)
                                : Colors.grey.shade800,
                            borderRadius: const BorderRadius.horizontal(
                                right: Radius.circular(20)),
                          ),
                          child: const Text(
                            'lbs',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: const Color(0xFF1DB954),
                  inactiveTrackColor: Colors.grey.shade800,
                  thumbColor: Colors.white,
                  overlayColor: const Color(0xFF1DB954).withOpacity(0.2),
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 12),
                ),
                child: Slider(
                  min: _isWeightMetric ? 40 : 88,
                  max: _isWeightMetric ? 150 : 330,
                  value: _weight.clamp(_isWeightMetric ? 40.0 : 88.0,
                      _isWeightMetric ? 150.0 : 330.0),
                  onChanged: (value) {
                    setState(() {
                      _weight = value;
                    });
                  },
                ),
              ),
            ],
          ),
          const Spacer(),
          _buildNextButton("Continue"),
        ],
      ),
    );
  }

  Widget _buildGoalSelectionPage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          const Text(
            "What's your goal?",
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "We'll customize your plan based on your goal",
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 40),
          // Goal selection
          Column(
            children: [
              _buildGoalOption('Weight Loss', 'Burn fat and get leaner'),
              const SizedBox(height: 16),
              _buildGoalOption('Muscle Gain', 'Build strength and muscle mass'),
              const SizedBox(height: 16),
              _buildGoalOption('Endurance', 'Improve stamina and performance'),
            ],
          ),
          const Spacer(),
          _buildNextButton("Create My Plan"),
        ],
      ),
    );
  }

  Widget _buildGoalOption(String title, String description) {
    final isSelected = _goal == title;

    return GestureDetector(
      onTap: () {
        setState(() {
          _goal = title;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF1DB954) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    isSelected ? const Color(0xFF1DB954) : Colors.grey.shade800,
                border: Border.all(
                  color: isSelected ? const Color(0xFF1DB954) : Colors.grey,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      size: 16,
                      color: Colors.white,
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNextButton(String text) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 1.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: GestureDetector(
            onTapDown: (_) => setState(() {}),
            onTapUp: (_) => setState(() {}),
            onTapCancel: () => setState(() {}),
            child: InkWell(
              onTap: _nextPage,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1DB954), Color(0xFF1ED760)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Center(
                  child: Text(
                    text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatHeight() {
    if (_isHeightMetric) {
      return '${_height.toInt()} cm';
    } else {
      final feet = _height.floor();
      final inches = ((_height - feet) * 12).round();
      return '$feet\' $inches"';
    }
  }

  String _formatWeight() {
    if (_isWeightMetric) {
      return '${_weight.toInt()} kg';
    } else {
      return '${_weight.toInt()} lbs';
    }
  }
}

// Animated background with particles
class ParticleBackground extends StatelessWidget {
  const ParticleBackground({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF191414), Colors.black],
        ),
      ),
      child: PlasmaRenderer(
        type: PlasmaType.infinity,
        particles: 10,
        color: const Color(0xFF1DB954).withOpacity(0.07),
        blur: 0.5,
        size: 1.0,
        speed: 1.5,
        offset: 0,
        blendMode: BlendMode.plus,
        particleType: ParticleType.circle,
        variation1: 0,
        variation2: 0,
        variation3: 0,
        rotation: 0,
      ),
    );
  }
}

// Custom Plasma Renderer for animated particles
class PlasmaRenderer extends StatefulWidget {
  final PlasmaType type;
  final int particles;
  final Color color;
  final double blur;
  final double size;
  final double speed;
  final double offset;
  final BlendMode blendMode;
  final ParticleType particleType;
  final double variation1;
  final double variation2;
  final double variation3;
  final double rotation;

  const PlasmaRenderer({
    Key? key,
    required this.type,
    required this.particles,
    required this.color,
    required this.blur,
    required this.size,
    required this.speed,
    required this.offset,
    required this.blendMode,
    required this.particleType,
    required this.variation1,
    required this.variation2,
    required this.variation3,
    required this.rotation,
  }) : super(key: key);

  @override
  _PlasmaRendererState createState() => _PlasmaRendererState();
}

class _PlasmaRendererState extends State<PlasmaRenderer>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final List<Particle> _particles = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    // Initialize particles
    for (int i = 0; i < widget.particles; i++) {
      _particles.add(Particle(
        position: Offset(
          math.Random().nextDouble() * 400,
          math.Random().nextDouble() * 800,
        ),
        speed: Offset(
          (math.Random().nextDouble() - 0.5) * widget.speed,
          (math.Random().nextDouble() - 0.5) * widget.speed,
        ),
        radius: math.Random().nextDouble() * 5 + 2,
      ));
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        // Update particle positions
        for (var particle in _particles) {
          particle.position += particle.speed;

          // Bounce off edges
          final size = MediaQuery.of(context).size;
          if (particle.position.dx < 0 || particle.position.dx > size.width) {
            particle.speed = Offset(-particle.speed.dx, particle.speed.dy);
          }
          if (particle.position.dy < 0 || particle.position.dy > size.height) {
            particle.speed = Offset(particle.speed.dx, -particle.speed.dy);
          }
        }

        return CustomPaint(
          painter: ParticlePainter(
            particles: _particles,
            color: widget.color,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class Particle {
  Offset position;
  Offset speed;
  final double radius;

  Particle({
    required this.position,
    required this.speed,
    required this.radius,
  });
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final Color color;

  ParticlePainter({
    required this.particles,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (var particle in particles) {
      canvas.drawCircle(particle.position, particle.radius, paint);
    }
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) => true;
}

enum PlasmaType { infinity, bubbles, circle }

enum ParticleType { circle, square }
