import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/firebase_provider.dart';
import 'workout_catalog_screen.dart';
import '../widgets/bottom_nav_bar.dart';

class HomeScreen extends StatefulWidget {
  final String userName;
  final String fitnessLevel;
  final String goal;
  final int height;
  final int weight;
  final String memberSince;

  const HomeScreen({
    Key? key,
    required this.userName,
    this.fitnessLevel = 'Intermediate',
    this.goal = 'Weight Loss',
    this.height = 170,
    this.weight = 70,
    this.memberSince = 'January 2023',
  }) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final int _selectedIndex = 0;
  late AnimationController _animationController;
  late AnimationController _confettiController;
  bool _showConfetti = false;

  // Firebase data
  int _steps = 0;
  int _stepsGoal = 10000;
  int _caloriesBurned = 0;
  int _caloriesGoal = 500;
  List<Map<String, dynamic>> _workoutRecommendations = [];
  List<Map<String, dynamic>> _recentActivities = [];

  // Loading states
  bool _loadingStats = true;
  bool _loadingWorkouts = true;
  bool _loadingActivities = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Load data from Firebase
    _loadUserStats();
    _loadWorkoutRecommendations();
    _loadRecentActivities();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // This ensures data is refreshed every time the screen becomes visible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  // Refresh all data from Firebase
  Future<void> _refreshData() async {
    print("Refreshing home screen data...");
    if (!mounted) return; // Check if widget is still mounted
    setState(() {
      _loadingStats = true;
      _loadingActivities = true;
    });

    try {
      await Future.wait([
        _loadUserStats(),
        _loadRecentActivities(),
      ]);
      print("Home screen data refreshed successfully");
    } catch (e) {
      print("Error refreshing home screen data: $e");
    } finally {
      if (!mounted) return; // Check if widget is still mounted
      setState(() {
        _loadingStats = false;
        _loadingActivities = false;
      });
    }
  }

  Future<void> _loadUserStats() async {
    final firebaseProvider =
        Provider.of<FirebaseProvider>(context, listen: false);

    try {
      final userStats = await firebaseProvider.getUserStats();

      if (!mounted) return; // Check if widget is still mounted

      if (userStats != null && userStats.exists) {
        final data = userStats.data() as Map<String, dynamic>;

        // Calculate BMI for dynamic goals
        double? bmi;
        if (widget.height > 0 && widget.weight > 0) {
          final heightInMeters = widget.height / 100;
          bmi = widget.weight / (heightInMeters * heightInMeters);
        }

        // Calculate dynamic goals based on BMI and fitness goal
        int dynamicStepsGoal = _calculateDynamicStepsGoal(bmi, widget.goal);
        int dynamicCaloriesGoal = _calculateDynamicCaloriesGoal(
            bmi, widget.goal, widget.fitnessLevel);

        // Get existing values or use the calculated dynamic goals
        int stepsGoal = data['stepsGoal'] ?? dynamicStepsGoal;
        int caloriesGoal = data['caloriesGoal'] ?? dynamicCaloriesGoal;

        // If the goals in Firebase are the default values, update them with our dynamic calculations
        bool updateGoals = false;
        if (data['stepsGoal'] == 10000 || data['caloriesGoal'] == 500) {
          updateGoals = true;
          stepsGoal = dynamicStepsGoal;
          caloriesGoal = dynamicCaloriesGoal;
        }

        setState(() {
          _steps = data['steps'] ?? 0;
          _stepsGoal = stepsGoal;
          _caloriesBurned = data['caloriesBurned'] ?? 0;
          _caloriesGoal = caloriesGoal;
          _loadingStats = false;

          // Check if any goals are met to show confetti
          if (_steps >= _stepsGoal || _caloriesBurned >= _caloriesGoal) {
            Future.delayed(const Duration(milliseconds: 1000), () {
              if (!mounted) return; // Check if widget is still mounted
              setState(() {
                _showConfetti = true;
              });
              _confettiController.forward();
            });
          }
        });

        // Update Firebase with dynamic goals if needed
        if (updateGoals) {
          await firebaseProvider.updateUserStats({
            'stepsGoal': dynamicStepsGoal,
            'caloriesGoal': dynamicCaloriesGoal,
          });
        }
      } else {
        // Calculate dynamic goals for new users
        double? bmi;
        if (widget.height > 0 && widget.weight > 0) {
          final heightInMeters = widget.height / 100;
          bmi = widget.weight / (heightInMeters * heightInMeters);
        }

        int dynamicStepsGoal = _calculateDynamicStepsGoal(bmi, widget.goal);
        int dynamicCaloriesGoal = _calculateDynamicCaloriesGoal(
            bmi, widget.goal, widget.fitnessLevel);

        // Create default stats if they don't exist, using dynamic goals
        await firebaseProvider.updateUserStats({
          'steps': 0,
          'stepsGoal': dynamicStepsGoal,
          'caloriesBurned': 0,
          'caloriesGoal': dynamicCaloriesGoal,
        });

        if (!mounted) return; // Check if widget is still mounted
        setState(() {
          _stepsGoal = dynamicStepsGoal;
          _caloriesGoal = dynamicCaloriesGoal;
          _loadingStats = false;
        });
      }
    } catch (e) {
      print('Error loading user stats: $e');
      if (!mounted) return; // Check if widget is still mounted
      setState(() {
        _loadingStats = false;
      });
    }
  }

  // Calculate dynamic steps goal based on BMI and fitness goal
  int _calculateDynamicStepsGoal(double? bmi, String goal) {
    // Default goal
    int baseGoal = 10000;

    // Adjust based on BMI if available
    if (bmi != null) {
      if (bmi < 18.5) {
        // Underweight - moderate step goals
        baseGoal = 8000;
      } else if (bmi >= 18.5 && bmi < 25) {
        // Normal weight - standard step goals
        baseGoal = 10000;
      } else if (bmi >= 25 && bmi < 30) {
        // Overweight - higher step goals
        baseGoal = 12000;
      } else {
        // Obese - start with moderate goals, increase gradually
        baseGoal = 8000;
      }
    }

    // Adjust based on fitness goal
    if (goal.toLowerCase().contains('weight loss')) {
      // Increase steps for weight loss
      baseGoal = (baseGoal * 1.2).round();
    } else if (goal.toLowerCase().contains('muscle')) {
      // Slightly fewer steps for muscle gain (focus on strength training)
      baseGoal = (baseGoal * 0.8).round();
    } else if (goal.toLowerCase().contains('endurance')) {
      // More steps for endurance
      baseGoal = (baseGoal * 1.3).round();
    }

    return baseGoal;
  }

  // Calculate dynamic calories goal based on BMI, fitness goal, and fitness level
  int _calculateDynamicCaloriesGoal(
      double? bmi, String goal, String fitnessLevel) {
    // Default goal
    int baseGoal = 500;

    // Adjust based on BMI if available
    if (bmi != null) {
      if (bmi < 18.5) {
        // Underweight - lower calorie burning goals
        baseGoal = 300;
      } else if (bmi >= 18.5 && bmi < 25) {
        // Normal weight - standard calorie goals
        baseGoal = 500;
      } else if (bmi >= 25 && bmi < 30) {
        // Overweight - higher calorie goals
        baseGoal = 700;
      } else {
        // Obese - higher calorie goals
        baseGoal = 800;
      }
    }

    // Adjust based on fitness goal
    if (goal.toLowerCase().contains('weight loss')) {
      // Increase calorie burn for weight loss
      baseGoal = (baseGoal * 1.3).round();
    } else if (goal.toLowerCase().contains('muscle')) {
      // Slightly lower calorie burn for muscle gain (focus on building not burning)
      baseGoal = (baseGoal * 0.8).round();
    }

    // Adjust based on fitness level
    if (fitnessLevel.toLowerCase() == 'beginner') {
      // Lower goals for beginners
      baseGoal = (baseGoal * 0.8).round();
    } else if (fitnessLevel.toLowerCase() == 'advanced' ||
        fitnessLevel.toLowerCase() == 'expert') {
      // Higher goals for advanced users
      baseGoal = (baseGoal * 1.2).round();
    }

    return baseGoal;
  }

  Future<void> _loadWorkoutRecommendations() async {
    final firebaseProvider =
        Provider.of<FirebaseProvider>(context, listen: false);

    try {
      // Create a placeholder list for workout recommendations
      List<Map<String, dynamic>> allWorkouts = [];

      // Try to get workouts from Firebase
      try {
        final workouts = await firebaseProvider.getWorkouts();
        print("HomeScreen: Got ${workouts.length} workouts from Firebase");

        // Convert Firebase workouts to list of maps
        for (var doc in workouts) {
          final data = doc.data() as Map<String, dynamic>;
          allWorkouts.add({
            'id': doc.id,
            'name': data['name'] ?? 'Unknown Workout',
            'duration': data['duration'] ?? 0,
            'category': data['category'] ?? 'Regular',
            'intensity': data['intensity'] ?? 'Moderate',
            'equipment': data['equipment'] ?? false,
            'difficulty': data['difficulty'] ?? 'Medium',
            'focusArea': data['focusArea'] ?? 'Full Body',
            'calories': data['calories'] ?? 150,
            'youtubeId': data['youtubeId'] ?? '',
          });
        }
      } catch (e) {
        print('Error fetching workouts from Firebase: $e');
      }

      // If no workouts were loaded from Firebase, use fallback workouts
      if (allWorkouts.isEmpty) {
        print(
            "HomeScreen: Using fallback workout data as Firebase returned empty");
        allWorkouts = [
          {
            'id': 'fallback1',
            'name': 'HIIT Blast',
            'duration': 12,
            'category': 'Quick',
            'intensity': 'Intense',
            'equipment': false,
            'difficulty': 'Hard',
            'focusArea': 'Full Body',
            'calories': 180,
            'youtubeId': 'ml6cT4AZdqI',
          },
          {
            'id': 'fallback2',
            'name': 'Morning Flow',
            'duration': 15,
            'category': 'Quick',
            'intensity': 'Moderate',
            'equipment': false,
            'difficulty': 'Medium',
            'focusArea': 'Flexibility',
            'calories': 120,
            'youtubeId': 'ETlbzlzyZw0',
          },
          {
            'id': 'fallback3',
            'name': 'Strength Builder',
            'duration': 25,
            'category': 'Regular',
            'intensity': 'Intense',
            'equipment': true,
            'difficulty': 'Hard',
            'focusArea': 'Upper Body',
            'calories': 250,
            'youtubeId': 'LhhWNixj5zE',
          },
          {
            'id': 'fallback4',
            'name': 'Core Crusher',
            'duration': 10,
            'category': 'Quick',
            'intensity': 'Moderate',
            'equipment': false,
            'difficulty': 'Medium',
            'focusArea': 'Core',
            'calories': 100,
            'youtubeId': 'J_mlZ-n0IG8',
          },
          {
            'id': 'fallback5',
            'name': 'Cardio Blast',
            'duration': 20,
            'category': 'Regular',
            'intensity': 'Intense',
            'equipment': false,
            'difficulty': 'Hard',
            'focusArea': 'Cardio',
            'calories': 220,
            'youtubeId': 'ZllXIKITzfg',
          },
        ];
      }

      // Get user profile and stats to personalize recommendations
      final userProfile = firebaseProvider.userProfile;
      final userStats = await firebaseProvider.getUserStatsAsMap();

      if (!mounted) return; // Check if widget is still mounted

      // Extract user's fitness goals and other relevant data
      List<String> fitnessGoals = [];
      double? bmi;
      String fitnessLevel = widget.fitnessLevel;

      // Get goals from user profile if available
      if (userProfile != null) {
        if (userProfile.fitnessGoals.isNotEmpty) {
          fitnessGoals = List<String>.from(userProfile.fitnessGoals);
        }
        fitnessLevel = userProfile.fitnessLevel ?? widget.fitnessLevel;
      }

      // If goals are not in profile, use the one from widget
      if (fitnessGoals.isEmpty && widget.goal.isNotEmpty) {
        fitnessGoals.add(widget.goal);
      }

      // Calculate BMI if height and weight are available
      if (widget.height > 0 && widget.weight > 0) {
        final heightInMeters = widget.height / 100;
        bmi = widget.weight / (heightInMeters * heightInMeters);
      }

      print("HomeScreen: User fitness goals: $fitnessGoals");
      print("HomeScreen: User BMI: $bmi");
      print("HomeScreen: User fitness level: $fitnessLevel");

      // Get personalized recommendations based on user profile
      final recommendations = _getPersonalizedWorkouts(
          allWorkouts, fitnessGoals, bmi, fitnessLevel);

      if (!mounted) return; // Check if widget is still mounted
      setState(() {
        _workoutRecommendations = recommendations;
        _loadingWorkouts = false;
      });

      print(
          "HomeScreen: Set ${_workoutRecommendations.length} workout recommendations");
    } catch (e) {
      print('Error loading workout recommendations: $e');
      if (!mounted) return; // Check if widget is still mounted
      setState(() {
        _loadingWorkouts = false;
        // Set fallback recommendation in case of error
        if (_workoutRecommendations.isEmpty) {
          _workoutRecommendations = [
            {
              'id': 'error1',
              'name': 'Quick HIIT Workout',
              'duration': 10,
              'category': 'Quick',
              'intensity': 'Moderate',
              'equipment': false,
              'difficulty': 'Medium',
              'focusArea': 'Full Body',
              'calories': 120,
              'youtubeId': '',
            }
          ];
        }
      });
    }
  }

  // New method to personalize workout recommendations
  List<Map<String, dynamic>> _getPersonalizedWorkouts(
      List<Map<String, dynamic>> workouts,
      List<String> fitnessGoals,
      double? bmi,
      String fitnessLevel) {
    // If we have no workouts, return an empty list
    if (workouts.isEmpty) return [];

    // Create a copy of the workouts list to avoid modifying the original
    final scoredWorkouts = List<Map<String, dynamic>>.from(workouts);

    // Score each workout based on how well it matches the user's profile
    for (var i = 0; i < scoredWorkouts.length; i++) {
      var workout = scoredWorkouts[i];
      double score = 0.0;

      // 1. Score based on fitness goals
      if (fitnessGoals.isNotEmpty) {
        final workoutFocus = workout['focusArea'].toString().toLowerCase();

        for (var goal in fitnessGoals) {
          // Check if workout focus matches user's goal
          if (goal.toLowerCase().contains('weight loss') &&
              (workoutFocus.contains('cardio') ||
                  workoutFocus.contains('full body'))) {
            score += 3.0;
          } else if (goal.toLowerCase().contains('muscle') &&
              (workoutFocus.contains('strength') ||
                  workoutFocus.contains('upper body') ||
                  workoutFocus.contains('lower body'))) {
            score += 3.0;
          } else if (goal.toLowerCase().contains('flexibility') &&
              workoutFocus.contains('flexibility')) {
            score += 3.0;
          } else if (goal.toLowerCase().contains('fitness') &&
              workoutFocus.contains('full body')) {
            score += 2.0;
          }
        }
      }

      // 2. Score based on BMI
      if (bmi != null) {
        final workoutIntensity = workout['intensity'].toString().toLowerCase();
        final workoutDifficulty =
            workout['difficulty'].toString().toLowerCase();

        if (bmi < 18.5) {
          // Underweight - recommend strength building
          if (workout['focusArea']
                  .toString()
                  .toLowerCase()
                  .contains('strength') ||
              workout['focusArea']
                  .toString()
                  .toLowerCase()
                  .contains('muscle')) {
            score += 2.0;
          }
          // Avoid very intense workouts for underweight
          if (workoutIntensity.contains('light') ||
              workoutIntensity.contains('moderate')) {
            score += 1.0;
          }
        } else if (bmi >= 18.5 && bmi < 25) {
          // Normal weight - balanced workouts
          score += 1.0; // All workouts are good
        } else if (bmi >= 25 && bmi < 30) {
          // Overweight - cardio and calorie burning
          if (workout['focusArea']
                  .toString()
                  .toLowerCase()
                  .contains('cardio') ||
              workout['calories'] > 200) {
            score += 2.0;
          }
        } else {
          // Obese - lower impact, more cardio
          if (workoutIntensity.contains('light') ||
              workoutIntensity.contains('moderate')) {
            score += 1.0;
          }
          if (workout['focusArea']
              .toString()
              .toLowerCase()
              .contains('cardio')) {
            score += 2.0;
          }
          // Shorter durations to start
          if (workout['duration'] <= 20) {
            score += 1.0;
          }
        }
      }

      // 3. Score based on fitness level
      final workoutDifficulty = workout['difficulty'].toString().toLowerCase();
      if (fitnessLevel.toLowerCase() == 'beginner') {
        if (workoutDifficulty.contains('easy')) {
          score += 2.0;
        } else if (workoutDifficulty.contains('medium')) {
          score += 1.0;
        }
      } else if (fitnessLevel.toLowerCase() == 'intermediate') {
        if (workoutDifficulty.contains('medium')) {
          score += 2.0;
        } else {
          score += 1.0; // Both easy and hard get some points
        }
      } else if (fitnessLevel.toLowerCase() == 'advanced' ||
          fitnessLevel.toLowerCase() == 'expert') {
        if (workoutDifficulty.contains('hard')) {
          score += 2.0;
        } else if (workoutDifficulty.contains('medium')) {
          score += 1.0;
        }
      }

      // Add the score to the workout
      workout['recommendationScore'] = score;
    }

    // Sort workouts by score (highest first)
    scoredWorkouts.sort((a, b) => (b['recommendationScore'] as double)
        .compareTo(a['recommendationScore'] as double));

    // Take the top 10 workouts or all if less than 10
    final recommendedWorkouts = scoredWorkouts.take(10).toList();

    // Print recommendations for debugging
    print("HomeScreen: Recommended workouts (score-based):");
    for (var workout in recommendedWorkouts) {
      print(
          "  - ${workout['name']} (Score: ${workout['recommendationScore']})");
    }

    return recommendedWorkouts;
  }

  Future<void> _loadRecentActivities() async {
    final firebaseProvider =
        Provider.of<FirebaseProvider>(context, listen: false);

    try {
      print("HomeScreen: Loading recent activities...");
      final workoutHistory = await firebaseProvider.getWorkoutHistory();
      print("HomeScreen: Got workout history, count: ${workoutHistory.length}");

      if (!mounted) return; // Check if widget is still mounted

      final List<Map<String, dynamic>> activities = [];
      for (var doc in workoutHistory) {
        final data = doc.data() as Map<String, dynamic>;
        print("HomeScreen: Workout history item: $data");

        final timestamp = data['timestamp'] as Timestamp?;
        print("HomeScreen: Timestamp: $timestamp");

        // Format date
        String dateText = 'Unknown';
        if (timestamp != null) {
          final now = DateTime.now();
          final date = timestamp.toDate();
          final difference = now.difference(date).inDays;

          if (difference == 0) {
            dateText = 'Today';
          } else if (difference == 1) {
            dateText = 'Yesterday';
          } else {
            dateText = '$difference days ago';
          }
        }

        activities.add({
          'date': dateText,
          'workout': data['workoutName'] ?? 'Unknown Workout',
          'duration': '${data['duration'] ?? 0} min',
          'calories': data['caloriesBurned'] ?? 0,
        });
        print("HomeScreen: Added activity: ${activities.last}");
      }

      // If we have no activities, let's try the getWorkoutHistoryAsMaps method for offline mode
      if (activities.isEmpty) {
        print(
            "HomeScreen: No activities found, trying getWorkoutHistoryAsMaps...");
        final maps = await firebaseProvider.getWorkoutHistoryAsMaps();
        print("HomeScreen: Got maps history, count: ${maps.length}");

        if (!mounted) return; // Check if widget is still mounted

        for (var data in maps) {
          print("HomeScreen: Map workout history item: $data");
          String dateText = 'Today'; // Default to today for offline mode

          if (data.containsKey('timestamp') && data['timestamp'] != null) {
            if (data['timestamp'] is Timestamp) {
              final timestamp = data['timestamp'] as Timestamp;
              final now = DateTime.now();
              final date = timestamp.toDate();
              final difference = now.difference(date).inDays;

              if (difference == 0) {
                dateText = 'Today';
              } else if (difference == 1) {
                dateText = 'Yesterday';
              } else {
                dateText = '$difference days ago';
              }
            }
          }

          activities.add({
            'date': dateText,
            'workout': data['workoutName'] ?? 'Unknown Workout',
            'duration': '${data['duration'] ?? 0} min',
            'calories': data['caloriesBurned'] ?? 0,
          });
          print("HomeScreen: Added map activity: ${activities.last}");
        }
      }

      if (!mounted) return; // Check if widget is still mounted
      setState(() {
        _recentActivities = activities;
        _loadingActivities = false;
      });
      print(
          "HomeScreen: Set recent activities, count: ${_recentActivities.length}");
    } catch (e) {
      print('Error loading recent activities: $e');
      if (!mounted) return; // Check if widget is still mounted
      setState(() {
        _loadingActivities = false;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Inside the build method of _HomeScreenState
    return Scaffold(
      backgroundColor: Colors.black,
      bottomNavigationBar: BottomNavBar(
        currentIndex: 0, // Home tab
        userName: widget.userName,
        fitnessLevel: widget.fitnessLevel,
        goal: widget.goal,
        height: widget.height,
        weight: widget.weight,
        memberSince: widget.memberSince,
      ),
      body: Stack(
        children: [
          // Animated background
          const ParticleBackground(),

          // Main content
          SafeArea(
            child: CustomScrollView(
              slivers: [
                // App Bar
                SliverAppBar(
                  backgroundColor: Colors.transparent,
                  floating: true,
                  title: Row(
                    children: [
                      // FitQuest logo
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: SvgPicture.asset(
                          'assets/icon/fitquest.svg',
                          width: 28,
                          height: 28,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'FitQuest',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  // Add settings button in the actions
                  actions: [
                    IconButton(
                      icon: const Icon(
                        Icons.fitness_center,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        // Navigate to settings or show settings dialog
                        _showSettingsDialog(context);
                      },
                    ),
                  ],
                ),

                // Main content
                SliverList(
                  delegate: SliverChildListDelegate([
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Greeting
                          Text(
                            'Good morning, ${widget.userName}!',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Let\'s crush your goals today',
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Today's Stats Card
                          AnimatedBuilder(
                            animation: _animationController,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _animationController.value,
                                child: child,
                              );
                            },
                            child: StatsCard(
                              steps: _steps,
                              stepsGoal: _stepsGoal,
                              caloriesBurned: _caloriesBurned,
                              caloriesGoal: _caloriesGoal,
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Workout Recommendations
                          const Text(
                            'Recommended For You',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 220, // Increased height to prevent overflow
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _workoutRecommendations.length,
                              itemBuilder: (context, index) {
                                // Improved animation for each card
                                return AnimatedBuilder(
                                  animation: _animationController,
                                  builder: (context, child) {
                                    // Adjusted delay calculation for smoother animation
                                    final delay = index * 0.1;
                                    final value = math.max(
                                      0.0,
                                      math.min(
                                          1.0,
                                          (_animationController.value - delay) *
                                              1.5),
                                    );
                                    return Transform.translate(
                                      offset: Offset(20 * (1 - value), 0),
                                      child: Opacity(
                                        opacity: value,
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 16.0),
                                    child: WorkoutCard(
                                      workout: _workoutRecommendations[index],
                                      userName: widget.userName,
                                      fitnessLevel: widget.fitnessLevel,
                                      goal: widget.goal,
                                      height: widget.height,
                                      weight: widget.weight,
                                      memberSince: widget.memberSince,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Recent Activity
                          const Text(
                            'Recent Activity',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _recentActivities.length,
                            itemBuilder: (context, index) {
                              // Modified animation for each activity - ensures full opacity after animation
                              return AnimatedBuilder(
                                animation: _animationController,
                                builder: (context, child) {
                                  // Calculate animation value with proper delay
                                  final delay = 0.3 + (index * 0.05);
                                  // Ensure animation value reaches 1.0 (full opacity) faster
                                  final value = math.max(
                                    0.0,
                                    math.min(
                                        1.0,
                                        (_animationController.value - delay) *
                                            3),
                                  );
                                  return Transform.translate(
                                    offset: Offset(0, 20 * (1 - value)),
                                    child: Opacity(
                                      // Set minimum opacity to 1.0 after animation completes
                                      opacity: value >= 0.9 ? 1.0 : value,
                                      child: child,
                                    ),
                                  );
                                },
                                child: ActivityTile(
                                  activity: _recentActivities[index],
                                ),
                              );
                            },
                          ),

                          const SizedBox(
                              height: 80), // Space for bottom nav bar
                        ],
                      ),
                    ),
                  ]),
                ),
              ],
            ),
          ),

          // Confetti animation when goals are met
          if (_showConfetti)
            Positioned.fill(
              child: IgnorePointer(
                child: Lottie.network(
                  'https://assets9.lottiefiles.com/packages/lf20_u4yrau.json',
                  controller: _confettiController,
                  animate: true,
                  repeat: false,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Show settings dialog
  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey.shade900,
          title: const Text(
            'Settings',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Reset Goals Option
              ListTile(
                leading: const Icon(
                  Icons.refresh,
                  color: Color(0xFF1DB954),
                ),
                title: const Text(
                  'Reset Daily Goals',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () async {
                  // Close the dialog
                  Navigator.pop(context);

                  // Calculate dynamic goals
                  double? bmi;
                  if (widget.height > 0 && widget.weight > 0) {
                    final heightInMeters = widget.height / 100;
                    bmi = widget.weight / (heightInMeters * heightInMeters);
                  }

                  int dynamicStepsGoal =
                      _calculateDynamicStepsGoal(bmi, widget.goal);
                  int dynamicCaloriesGoal = _calculateDynamicCaloriesGoal(
                      bmi, widget.goal, widget.fitnessLevel);

                  // Update Firebase with dynamic goals
                  final firebaseProvider =
                      Provider.of<FirebaseProvider>(context, listen: false);
                  await firebaseProvider.updateUserStats({
                    'stepsGoal': dynamicStepsGoal,
                    'caloriesGoal': dynamicCaloriesGoal,
                  });

                  // Update local state
                  setState(() {
                    _stepsGoal = dynamicStepsGoal;
                    _caloriesGoal = dynamicCaloriesGoal;
                  });

                  // Show confirmation
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('Goals have been reset based on your profile'),
                      backgroundColor: Color(0xFF1DB954),
                    ),
                  );
                },
              ),

              // Reset Progress Option
              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  color: Colors.orange,
                ),
                title: const Text(
                  'Reset Today\'s Progress',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () async {
                  // Close the dialog
                  Navigator.pop(context);

                  // Update Firebase with reset progress
                  final firebaseProvider =
                      Provider.of<FirebaseProvider>(context, listen: false);
                  await firebaseProvider.updateUserStats({
                    'steps': 0,
                    'caloriesBurned': 0,
                  });

                  // Update local state
                  setState(() {
                    _steps = 0;
                    _caloriesBurned = 0;
                    _showConfetti = false;
                  });

                  // Show confirmation
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Today\'s progress has been reset'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                },
              ),

              // Custom Goals Option
              ListTile(
                leading: const Icon(
                  Icons.edit,
                  color: Colors.blue,
                ),
                title: const Text(
                  'Set Custom Goals',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  // Close the current dialog
                  Navigator.pop(context);

                  // Show the custom goals dialog
                  _showCustomGoalsDialog(context);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Close',
                style: TextStyle(
                  color: Color(0xFF1DB954),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Show custom goals dialog
  void _showCustomGoalsDialog(BuildContext context) {
    int tempStepsGoal = _stepsGoal;
    int tempCaloriesGoal = _caloriesGoal;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey.shade900,
          title: const Text(
            'Set Custom Goals',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Steps Goal Field
              TextField(
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Steps Goal',
                  labelStyle: TextStyle(color: Colors.grey.shade400),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade700),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFF1DB954)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                controller: TextEditingController(text: _stepsGoal.toString()),
                onChanged: (value) {
                  if (value.isNotEmpty) {
                    tempStepsGoal = int.tryParse(value) ?? _stepsGoal;
                  }
                },
              ),
              const SizedBox(height: 16),

              // Calories Goal Field
              TextField(
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Calories Goal',
                  labelStyle: TextStyle(color: Colors.grey.shade400),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade700),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFF1DB954)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                controller:
                    TextEditingController(text: _caloriesGoal.toString()),
                onChanged: (value) {
                  if (value.isNotEmpty) {
                    tempCaloriesGoal = int.tryParse(value) ?? _caloriesGoal;
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () async {
                // Close the dialog
                Navigator.pop(context);

                // Validate goals
                if (tempStepsGoal <= 0 || tempCaloriesGoal <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Goals must be greater than 0'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                // Update Firebase with custom goals
                final firebaseProvider =
                    Provider.of<FirebaseProvider>(context, listen: false);
                await firebaseProvider.updateUserStats({
                  'stepsGoal': tempStepsGoal,
                  'caloriesGoal': tempCaloriesGoal,
                });

                // Update local state
                setState(() {
                  _stepsGoal = tempStepsGoal;
                  _caloriesGoal = tempCaloriesGoal;
                });

                // Show confirmation
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Custom goals have been set'),
                    backgroundColor: Color(0xFF1DB954),
                  ),
                );
              },
              child: const Text(
                'Save',
                style: TextStyle(color: Color(0xFF1DB954)),
              ),
            ),
          ],
        );
      },
    );
  }
}

// Stats Card Widget
class StatsCard extends StatelessWidget {
  final int steps;
  final int stepsGoal;
  final int caloriesBurned;
  final int caloriesGoal;

  const StatsCard({
    Key? key,
    required this.steps,
    required this.stepsGoal,
    required this.caloriesBurned,
    required this.caloriesGoal,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Calculate progress but cap it at 1.0 (100%) for display purposes
    final stepsProgress = steps >= stepsGoal ? 1.0 : steps / stepsGoal;
    final caloriesProgress =
        caloriesBurned >= caloriesGoal ? 1.0 : caloriesBurned / caloriesGoal;

    // Determine colors based on whether goals are achieved
    final stepsColor =
        steps >= stepsGoal ? const Color(0xFF1DB954) : const Color(0xFF1DB954);
    final caloriesColor = caloriesBurned >= caloriesGoal
        ? const Color(0xFF1DB954)
        : Colors.orange;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.grey.shade900,
            Colors.grey.shade800,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Today\'s Stats',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              // Steps progress ring
              Expanded(
                child: Column(
                  children: [
                    SizedBox(
                      height: 120,
                      width: 120,
                      child: Stack(
                        children: [
                          Center(
                            child: SizedBox(
                              height: 100,
                              width: 100,
                              child: PieChart(
                                PieChartData(
                                  sectionsSpace: 0,
                                  centerSpaceRadius: 40,
                                  sections: [
                                    PieChartSectionData(
                                      value: stepsProgress * 100,
                                      color: stepsColor,
                                      radius: 10,
                                      showTitle: false,
                                    ),
                                    PieChartSectionData(
                                      value: 100 - (stepsProgress * 100),
                                      color: Colors.grey.shade800,
                                      radius: 10,
                                      showTitle: false,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '$steps',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'steps',
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
                    const SizedBox(height: 8),
                    Text(
                      'Goal: $stepsGoal',
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              // Calories burned
              Expanded(
                child: Column(
                  children: [
                    SizedBox(
                      height: 120,
                      width: 120,
                      child: Stack(
                        children: [
                          Center(
                            child: SizedBox(
                              height: 100,
                              width: 100,
                              child: PieChart(
                                PieChartData(
                                  sectionsSpace: 0,
                                  centerSpaceRadius: 40,
                                  sections: [
                                    PieChartSectionData(
                                      value: caloriesProgress * 100,
                                      color: caloriesColor,
                                      radius: 10,
                                      showTitle: false,
                                    ),
                                    PieChartSectionData(
                                      value: 100 - (caloriesProgress * 100),
                                      color: Colors.grey.shade800,
                                      radius: 10,
                                      showTitle: false,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '$caloriesBurned',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'calories',
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
                    const SizedBox(height: 8),
                    Text(
                      'Goal: $caloriesGoal',
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
        ],
      ),
    );
  }
}

// Workout Card Widget
class WorkoutCard extends StatelessWidget {
  final Map<String, dynamic> workout;
  final String userName;
  final String fitnessLevel;
  final String goal;
  final int height;
  final int weight;
  final String memberSince;

  const WorkoutCard({
    Key? key,
    required this.workout,
    required this.userName,
    required this.fitnessLevel,
    required this.goal,
    required this.height,
    required this.weight,
    required this.memberSince,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigate to the WorkoutCatalogScreen with workout ID and pass all user data directly
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WorkoutCatalogScreen(
              workoutId: workout['id'], // Pass the workout ID
              userName: userName,
              goal: goal,
              fitnessLevel: fitnessLevel,
              height: height,
              weight: weight,
              memberSince: memberSince,
            ),
          ),
        );
      },
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Placeholder for workout image
            Container(
              height: 90,
              decoration: BoxDecoration(
                color: Colors.grey.shade800,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                gradient: LinearGradient(
                  colors: [
                    Colors.grey.shade800,
                    Colors.grey.shade900,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Center(
                child: Icon(
                  _getWorkoutIcon(workout['name']),
                  color: const Color(0xFF1DB954),
                  size: 36,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      workout['name'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${workout['duration']} • ${workout['intensity']}',
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1DB954),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Start',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getWorkoutIcon(String workoutName) {
    if (workoutName.toLowerCase().contains('hiit')) {
      return Icons.flash_on;
    } else if (workoutName.toLowerCase().contains('strength')) {
      return Icons.fitness_center;
    } else if (workoutName.toLowerCase().contains('yoga')) {
      return Icons.self_improvement;
    } else if (workoutName.toLowerCase().contains('cardio')) {
      return Icons.directions_run;
    } else if (workoutName.toLowerCase().contains('core')) {
      return Icons.accessibility_new;
    }
    return Icons.fitness_center;
  }
}

// Activity Tile Widget
class ActivityTile extends StatelessWidget {
  final Map<String, dynamic> activity;

  const ActivityTile({
    Key? key,
    required this.activity,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey.shade800,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getActivityIcon(activity['workout']),
            color: const Color(0xFF1DB954),
          ),
        ),
        title: Text(
          activity['workout'],
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '${activity['duration']} • ${activity['calories']} cal',
          style: TextStyle(
            color: Colors.grey.shade400,
          ),
        ),
        trailing: Text(
          activity['date'],
          style: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  IconData _getActivityIcon(String activityName) {
    if (activityName.toLowerCase().contains('run')) {
      return Icons.directions_run;
    } else if (activityName.toLowerCase().contains('workout')) {
      return Icons.fitness_center;
    } else if (activityName.toLowerCase().contains('yoga')) {
      return Icons.self_improvement;
    }
    return Icons.fitness_center;
  }
}

// Animated background with particles (reused from onboarding screen)
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

// Custom Plasma Renderer for animated particles (reused from onboarding screen)
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
        return CustomPaint(
          painter: ParticlePainter(
            particles: _particles,
            animation: _animationController.value,
            color: widget.color,
          ),
          child: Container(),
        );
      },
    );
  }
}

// Particle class
class Particle {
  Offset position;
  Offset speed;
  double radius;

  Particle({
    required this.position,
    required this.speed,
    required this.radius,
  });
}

// Particle painter
class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double animation;
  final Color color;

  ParticlePainter({
    required this.particles,
    required this.animation,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (var particle in particles) {
      // Update position based on animation
      final newX =
          (particle.position.dx + particle.speed.dx * animation) % size.width;
      final newY =
          (particle.position.dy + particle.speed.dy * animation) % size.height;

      // Draw the particle
      canvas.drawCircle(
        Offset(newX, newY),
        particle.radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) => true;
}

// Plasma type enum
enum PlasmaType {
  infinity,
  bubbles,
  circle,
}

// Particle type enum
enum ParticleType {
  circle,
  square,
}
