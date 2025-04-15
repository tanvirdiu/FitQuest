import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import '../widgets/bottom_nav_bar.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'dart:async';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/firebase_provider.dart';
import '../screens/home_screen.dart';

class WorkoutCatalogScreen extends StatefulWidget {
  final String goal;
  final String userName;
  final String fitnessLevel;
  final int height;
  final int weight;
  final String memberSince;
  final String? workoutId; // Make sure this is nullable

  const WorkoutCatalogScreen({
    Key? key,
    required this.goal,
    required this.userName,
    required this.fitnessLevel,
    required this.height,
    required this.weight,
    required this.memberSince,
    this.workoutId, // Changed to nullable parameter
  }) : super(key: key);

  @override
  _WorkoutCatalogScreenState createState() => _WorkoutCatalogScreenState();
}

class _WorkoutCatalogScreenState extends State<WorkoutCatalogScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  String _selectedFilter = 'All';
  List<Map<String, dynamic>> _filteredWorkouts = [];

  // Mock workout data
  // First, update your workout data structure to include YouTube video IDs
  final List<Map<String, dynamic>> _workouts = [
    {
      'id': '1',
      'name': 'HIIT Blast',
      'duration': 12,
      'category': 'Quick',
      'intensity': 'Intense',
      'equipment': false,
      'calories': 180,
      'difficulty': 'Hard',
      'focusArea': 'Full Body',
      'imageUrl': 'assets/gifs/hiit.gif',
      'youtubeId': 'ml6cT4AZdqI', // Add YouTube video ID
      'exercises': [
        {'name': 'Jumping Jacks', 'sets': 1, 'reps': '30 sec'},
        {'name': 'Burpees', 'sets': 1, 'reps': '30 sec'},
        {'name': 'Mountain Climbers', 'sets': 1, 'reps': '30 sec'},
        {'name': 'High Knees', 'sets': 1, 'reps': '30 sec'},
        {'name': 'Rest', 'sets': 1, 'reps': '15 sec'},
        {'name': 'Repeat 2 more times', 'sets': 2, 'reps': ''},
      ],
    },
    {
      'id': '2',
      'name': 'Morning Flow',
      'duration': 15,
      'category': 'Quick',
      'intensity': 'Moderate',
      'equipment': false,
      'calories': 120,
      'difficulty': 'Medium',
      'focusArea': 'Flexibility',
      'imageUrl': 'assets/images/morning_flow.jpg',
      'youtubeId': 'ETlbzlzyZw0',
      'exercises': [
        {'name': 'Child\'s Pose', 'sets': 1, 'reps': '30 sec'},
        {'name': 'Cat-Cow Stretch', 'sets': 1, 'reps': '45 sec'},
        {'name': 'Downward Dog', 'sets': 1, 'reps': '30 sec'},
        {'name': 'Low Lunge', 'sets': 1, 'reps': '30 sec each side'},
        {'name': 'Warrior II', 'sets': 1, 'reps': '30 sec each side'},
        {'name': 'Sun Salutation', 'sets': 3, 'reps': ''},
      ],
    },
    {
      'id': '3',
      'name': 'Strength Builder',
      'duration': 25,
      'category': 'Regular',
      'intensity': 'Intense',
      'equipment': true,
      'calories': 250,
      'difficulty': 'Hard',
      'focusArea': 'Upper Body',
      'imageUrl': 'assets/images/strength_builder.jpg',
      'youtubeId': 'LhhWNixj5zE',
      'exercises': [
        {'name': 'Push-ups', 'sets': 3, 'reps': '12'},
        {'name': 'Dumbbell Rows', 'sets': 3, 'reps': '10 each arm'},
        {'name': 'Shoulder Press', 'sets': 3, 'reps': '10'},
        {'name': 'Bicep Curls', 'sets': 3, 'reps': '12'},
        {'name': 'Tricep Dips', 'sets': 3, 'reps': '15'},
      ],
    },
    {
      'id': '4',
      'name': 'Core Crusher',
      'duration': 10,
      'category': 'Quick',
      'intensity': 'Moderate',
      'equipment': false,
      'calories': 100,
      'difficulty': 'Medium',
      'focusArea': 'Core',
      'imageUrl': 'assets/images/core_crusher.jpg',
      'youtubeId': 'J_mlZ-n0IG8',
      'exercises': [
        {'name': 'Plank', 'sets': 1, 'reps': '45 sec'},
        {'name': 'Crunches', 'sets': 2, 'reps': '20'},
        {'name': 'Russian Twists', 'sets': 2, 'reps': '16'},
        {'name': 'Leg Raises', 'sets': 2, 'reps': '12'},
        {'name': 'Mountain Climbers', 'sets': 1, 'reps': '30 sec'},
      ],
    },
    {
      'id': '5',
      'name': 'Cardio Blast',
      'duration': 20,
      'category': 'Regular',
      'intensity': 'Intense',
      'equipment': false,
      'calories': 220,
      'difficulty': 'Hard',
      'focusArea': 'Cardio',
      'imageUrl': 'assets/images/cardio_blast.jpg',
      'youtubeId': 'ZllXIKITzfg',
      'exercises': [
        {'name': 'Jumping Jacks', 'sets': 1, 'reps': '60 sec'},
        {'name': 'High Knees', 'sets': 1, 'reps': '45 sec'},
        {'name': 'Butt Kicks', 'sets': 1, 'reps': '45 sec'},
        {'name': 'Jump Squats', 'sets': 3, 'reps': '15'},
        {'name': 'Burpees', 'sets': 3, 'reps': '10'},
      ],
    },
    {
      'id': '6',
      'name': 'Lower Body Focus',
      'duration': 18,
      'category': 'Regular',
      'intensity': 'Moderate',
      'equipment': false,
      'calories': 180,
      'difficulty': 'Medium',
      'focusArea': 'Lower Body',
      'imageUrl': 'assets/images/lower_body.jpg',
      'youtubeId': 'ay7iptD2m8M',
      'exercises': [
        {'name': 'Bodyweight Squats', 'sets': 3, 'reps': '20'},
        {'name': 'Lunges', 'sets': 3, 'reps': '12 each leg'},
        {'name': 'Glute Bridges', 'sets': 3, 'reps': '15'},
        {'name': 'Calf Raises', 'sets': 3, 'reps': '20'},
        {'name': 'Wall Sit', 'sets': 2, 'reps': '45 sec'},
      ],
    },
    {
      'id': '7',
      'name': 'Quick Burn',
      'duration': 8,
      'category': 'Quick',
      'intensity': 'Intense',
      'equipment': false,
      'calories': 90,
      'difficulty': 'Medium',
      'focusArea': 'Full Body',
      'imageUrl': 'assets/images/quick_burn.jpg',
      'youtubeId': 'KKevDYtxc-s',
      'exercises': [
        {'name': 'Jumping Jacks', 'sets': 1, 'reps': '30 sec'},
        {'name': 'Push-ups', 'sets': 1, 'reps': 'Max in 30 sec'},
        {'name': 'Squats', 'sets': 1, 'reps': 'Max in 30 sec'},
        {'name': 'Plank', 'sets': 1, 'reps': '30 sec'},
        {'name': 'Mountain Climbers', 'sets': 1, 'reps': '30 sec'},
        {'name': 'Burpees', 'sets': 1, 'reps': 'Max in 30 sec'},
      ],
    },
    {
      'id': '8',
      'name': 'Dumbbell Power',
      'duration': 30,
      'category': 'Regular',
      'intensity': 'Intense',
      'equipment': true,
      'calories': 280,
      'difficulty': 'Hard',
      'focusArea': 'Full Body',
      'imageUrl': 'assets/images/dumbbell_power.jpg',
      'youtubeId': 'xqVBoyKXbsA',
      'exercises': [
        {'name': 'Dumbbell Squats', 'sets': 3, 'reps': '12'},
        {'name': 'Dumbbell Bench Press', 'sets': 3, 'reps': '10'},
        {'name': 'Dumbbell Rows', 'sets': 3, 'reps': '12 each arm'},
        {'name': 'Dumbbell Lunges', 'sets': 3, 'reps': '10 each leg'},
        {'name': 'Dumbbell Shoulder Press', 'sets': 3, 'reps': '10'},
      ],
    },
    {
      'id': '9',
      'name': 'Stretching Routine',
      'duration': 12,
      'category': 'Quick',
      'intensity': 'Light',
      'equipment': false,
      'calories': 60,
      'difficulty': 'Easy',
      'focusArea': 'Flexibility',
      'imageUrl': 'assets/images/stretching.jpg',
      'youtubeId': 'FI51zRzgIe4',
      'exercises': [
        {'name': 'Neck Stretch', 'sets': 1, 'reps': '30 sec each side'},
        {'name': 'Shoulder Stretch', 'sets': 1, 'reps': '30 sec each side'},
        {'name': 'Hamstring Stretch', 'sets': 1, 'reps': '45 sec each leg'},
        {'name': 'Quad Stretch', 'sets': 1, 'reps': '30 sec each leg'},
        {'name': 'Hip Flexor Stretch', 'sets': 1, 'reps': '30 sec each side'},
        {'name': 'Child\'s Pose', 'sets': 1, 'reps': '60 sec'},
      ],
    },
    {
      'id': '10',
      'name': 'Tabata Challenge',
      'duration': 16,
      'category': 'Regular',
      'intensity': 'Intense',
      'equipment': false,
      'calories': 200,
      'difficulty': 'Hard',
      'focusArea': 'Full Body',
      'imageUrl': 'assets/images/tabata.jpg',
      'youtubeId': 'ft1NsrkLlg4',
      'exercises': [
        {
          'name': '20 sec work, 10 sec rest for each exercise',
          'sets': 1,
          'reps': ''
        },
        {'name': 'Push-ups', 'sets': 2, 'reps': '20 sec work, 10 sec rest'},
        {'name': 'Squats', 'sets': 2, 'reps': '20 sec work, 10 sec rest'},
        {
          'name': 'Mountain Climbers',
          'sets': 2,
          'reps': '20 sec work, 10 sec rest'
        },
        {'name': 'Plank Jacks', 'sets': 2, 'reps': '20 sec work, 10 sec rest'},
      ],
    },
  ];

  // Delete the second initState method (around line 280-289)
  // And keep only this combined version:
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // Apply personalization to the workout list based on user profile
    _personalizeWorkouts();

    // Add this code to show workout details if workoutId is provided
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.workoutId != null) {
        _loadAndShowWorkoutById(widget.workoutId!);
      }
    });
  }

  // Method to load workout by ID from Firebase or local data
  Future<void> _loadAndShowWorkoutById(String workoutId) async {
    try {
      print("Loading workout with ID: $workoutId");

      // First try to find the workout in the local _workouts list
      Map<String, dynamic>? selectedWorkout;

      // Look for the workout in the local list
      try {
        selectedWorkout = _workouts.firstWhere(
          (workout) => workout['id'] == workoutId,
        );
        print("Found workout locally: ${selectedWorkout['name']}");
      } catch (e) {
        // Workout not found in local list
        print("Workout not found locally, trying Firebase...");
        selectedWorkout = null;
      }

      // If not found locally, try to get it from Firebase
      if (selectedWorkout == null) {
        final firebaseProvider =
            Provider.of<FirebaseProvider>(context, listen: false);

        try {
          // Try to get the workout from Firebase
          final workoutDoc = await firebaseProvider.getWorkoutById(workoutId);

          if (workoutDoc != null && workoutDoc.exists) {
            final data = workoutDoc.data() as Map<String, dynamic>;

            // Create a properly formatted workout map from Firebase data
            selectedWorkout = {
              'id': workoutId,
              'name': data['name'] ?? 'Unknown Workout',
              'duration': data['duration'] ?? 0,
              'category': data['category'] ?? 'Regular',
              'intensity': data['intensity'] ?? 'Moderate',
              'equipment': data['equipment'] ?? false,
              'difficulty': data['difficulty'] ?? 'Medium',
              'focusArea': data['focusArea'] ?? 'Full Body',
              'calories': data['calories'] ?? 150,
              'youtubeId': data['youtubeId'] ?? '',
              'exercises': data['exercises'] ?? [],
            };

            print("Found workout in Firebase: ${selectedWorkout['name']}");
          } else {
            print("Workout not found in Firebase either");
          }
        } catch (e) {
          print("Error fetching workout from Firebase: $e");
        }
      }

      // If we found the workout, show its details
      if (selectedWorkout != null) {
        _showWorkoutDetails(context, selectedWorkout);
      } else {
        // If workout wasn't found, try to find a fallback with the right ID
        try {
          // Try to find a fallback workout that matches the ID pattern
          if (workoutId.contains('fallback')) {
            int fallbackNumber =
                int.tryParse(workoutId.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1;
            // Make sure the fallback number is within the valid range
            fallbackNumber = fallbackNumber.clamp(1, _workouts.length);

            // Use the workout at the specific index (subtract 1 because IDs start at 1)
            _showWorkoutDetails(context, _workouts[fallbackNumber - 1]);
            print(
                "Using specific fallback workout: ${_workouts[fallbackNumber - 1]['name']}");
          } else {
            // If we still couldn't find the workout and it's not a fallback ID, show a default one
            print(
                "No matching workout found for ID: $workoutId. Using first workout as fallback.");
            _showWorkoutDetails(context, _workouts[0]);
          }
        } catch (e) {
          // If all else fails, use the first workout
          print("Error finding fallback workout: $e. Using first workout.");
          _showWorkoutDetails(context, _workouts[0]);
        }
      }
    } catch (e) {
      print("Error in _loadAndShowWorkoutById: $e");
      // Default to first workout if there's an error
      _showWorkoutDetails(context, _workouts[0]);
    }
  }

  // New method to personalize workouts based on user's profile
  void _personalizeWorkouts() {
    // Create personalized workout list based on user profile
    List<Map<String, dynamic>> personalizedWorkouts = List.from(_workouts);

    // Score each workout based on fitness goals, BMI, and fitness level
    for (var workout in personalizedWorkouts) {
      double score = 0.0;

      // Get user's fitness goal from widget parameters
      final goal = widget.goal.toLowerCase();
      final fitnessLevel = widget.fitnessLevel.toLowerCase();

      // Calculate BMI if height and weight are available
      double? bmi;
      if (widget.height > 0 && widget.weight > 0) {
        final heightInMeters = widget.height / 100;
        bmi = widget.weight / (heightInMeters * heightInMeters);
      }

      // Score based on fitness goal
      final workoutFocus = workout['focusArea'].toString().toLowerCase();
      if (goal.contains('weight loss') &&
          (workoutFocus.contains('cardio') ||
              workoutFocus.contains('full body'))) {
        score += 3.0;
      } else if (goal.contains('muscle') &&
          (workoutFocus.contains('strength') ||
              workoutFocus.contains('upper body') ||
              workoutFocus.contains('lower body'))) {
        score += 3.0;
      } else if (goal.contains('flexibility') &&
          workoutFocus.contains('flexibility')) {
        score += 3.0;
      } else if (goal.contains('fitness') &&
          workoutFocus.contains('full body')) {
        score += 2.0;
      }

      // Score based on BMI
      if (bmi != null) {
        final workoutIntensity = workout['intensity'].toString().toLowerCase();

        if (bmi < 18.5) {
          // Underweight - recommend strength building
          if (workoutFocus.contains('strength') ||
              workoutFocus.contains('muscle')) {
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
          if (workoutFocus.contains('cardio') || workout['calories'] > 200) {
            score += 2.0;
          }
        } else {
          // Obese - lower impact, more cardio
          if (workoutIntensity.contains('light') ||
              workoutIntensity.contains('moderate')) {
            score += 1.0;
          }
          if (workoutFocus.contains('cardio')) {
            score += 2.0;
          }
          // Shorter durations to start
          if (workout['duration'] <= 20) {
            score += 1.0;
          }
        }
      }

      // Score based on fitness level
      final workoutDifficulty = workout['difficulty'].toString().toLowerCase();
      if (fitnessLevel == 'beginner') {
        if (workoutDifficulty.contains('easy')) {
          score += 2.0;
        } else if (workoutDifficulty.contains('medium')) {
          score += 1.0;
        }
      } else if (fitnessLevel == 'intermediate') {
        if (workoutDifficulty.contains('medium')) {
          score += 2.0;
        } else {
          score += 1.0; // Both easy and hard get some points
        }
      } else if (fitnessLevel == 'advanced' || fitnessLevel == 'expert') {
        if (workoutDifficulty.contains('hard')) {
          score += 2.0;
        } else if (workoutDifficulty.contains('medium')) {
          score += 1.0;
        }
      }

      // Add recommendation score to workout
      workout['recommendationScore'] = score;
    }

    // Sort workouts by recommendation score (highest first)
    personalizedWorkouts.sort((a, b) => (b['recommendationScore'] as double)
        .compareTo(a['recommendationScore'] as double));

    // Update the filteredWorkouts list with personalized order
    setState(() {
      _filteredWorkouts = personalizedWorkouts;
      _selectedFilter =
          'All'; // Start with 'All' filter but with personalized order
    });

    // Print recommendations for debugging
    print("Catalog Screen: Workout recommendations by score:");
    for (var workout in personalizedWorkouts.take(5)) {
      print(
          "  - ${workout['name']} (Score: ${workout['recommendationScore']})");
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _filterWorkouts(String filter) {
    setState(() {
      _selectedFilter = filter;
      if (filter == 'All') {
        _filteredWorkouts = List.from(_workouts);
      } else if (filter == 'Quick') {
        _filteredWorkouts =
            _workouts.where((workout) => workout['duration'] < 15).toList();
      } else if (filter == 'Intense') {
        _filteredWorkouts = _workouts
            .where((workout) => workout['intensity'] == 'Intense')
            .toList();
      } else if (filter == 'Equipment-Free') {
        _filteredWorkouts = _workouts
            .where((workout) => workout['equipment'] == false)
            .toList();
      }
    });
  }

  void _showWorkoutDetails(BuildContext context, Map<String, dynamic> workout) {
    showMaterialModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => WorkoutDetailSheet(
        workout: workout,
        userName: widget.userName,
        fitnessLevel: widget.fitnessLevel,
        goal: widget.goal,
        height: widget.height,
        weight: widget.weight,
        memberSince: widget.memberSince,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF191414),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Header Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your Workout Playlists',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Based on your goal: ${widget.goal}',
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Filter chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          _buildFilterChip('All'),
                          const SizedBox(width: 8),
                          _buildFilterChip('Quick'),
                          const SizedBox(width: 8),
                          _buildFilterChip('Intense'),
                          const SizedBox(width: 8),
                          _buildFilterChip('Equipment-Free'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // Workout Grid
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverMasonryGrid.count(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childCount: _filteredWorkouts.length,
                itemBuilder: (context, index) {
                  final workout = _filteredWorkouts[index];
                  return _buildWorkoutCard(context, workout);
                },
              ),
            ),

            // Bottom padding
            const SliverToBoxAdapter(
              child: SizedBox(height: 80),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 1, // Workouts tab
        userName: widget.userName,
        goal: widget.goal,
        fitnessLevel: widget.fitnessLevel,
        height: widget.height,
        weight: widget.weight,
        memberSince: widget.memberSince,
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;

    return GestureDetector(
      onTap: () => _filterWorkouts(label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1DB954) : Colors.grey.shade800,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // Then modify the _buildWorkoutCard method to handle YouTube thumbnails
  Widget _buildWorkoutCard(BuildContext context, Map<String, dynamic> workout) {
    return GestureDetector(
      onTap: () => _showWorkoutDetails(context, workout),
      child: TweenAnimationBuilder(
        tween: Tween<double>(begin: 0.95, end: 1.0),
        duration: const Duration(milliseconds: 200),
        builder: (context, double scale, child) {
          return Transform.scale(
            scale: scale,
            child: child,
          );
        },
        child: Container(
          height: workout['id'].hashCode % 3 == 0
              ? 220
              : 180, // Varied heights for visual interest
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Workout image or YouTube thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  'https://img.youtube.com/vi/${workout['youtubeId']}/0.jpg',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildFallbackImage(workout['focusArea']);
                  },
                ),
              ),

              // YouTube play button overlay
              if (workout.containsKey('youtubeId') &&
                  workout['youtubeId'] != null)
                Center(
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),

              // Gradient overlay
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
              ),

              // Workout info
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      workout['name'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      workout['focusArea'],
                      style: TextStyle(
                        color: Colors.grey.shade300,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              // Duration badge
              Positioned(
                bottom: 12,
                right: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1DB954),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${workout['duration']} MIN',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Add a helper method for fallback images
  Widget _buildFallbackImage(String focusArea) {
    return Container(
      color: Colors.grey.shade800,
      child: Icon(
        _getWorkoutIcon(focusArea),
        color: const Color(0xFF1DB954),
        size: 48,
      ),
    );
  }

  IconData _getWorkoutIcon(String focusArea) {
    switch (focusArea.toLowerCase()) {
      case 'full body':
        return Icons.fitness_center;
      case 'upper body':
        return Icons.accessibility_new;
      case 'lower body':
        return Icons.directions_run;
      case 'core':
        return Icons.crop_square;
      case 'cardio':
        return Icons.favorite;
      case 'flexibility':
        return Icons.self_improvement;
      default:
        return Icons.fitness_center;
    }
  }
}

class WorkoutDetailSheet extends StatefulWidget {
  final Map<String, dynamic> workout;
  final String userName;
  final String fitnessLevel;
  final String goal;
  final int height;
  final int weight;
  final String memberSince;

  const WorkoutDetailSheet({
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
  _WorkoutDetailSheetState createState() => _WorkoutDetailSheetState();
}

class _WorkoutDetailSheetState extends State<WorkoutDetailSheet> {
  late YoutubePlayerController _controller;
  bool _isVideoPlaying = false;

  @override
  void initState() {
    super.initState();
    if (widget.workout.containsKey('youtubeId') &&
        widget.workout['youtubeId'] != null) {
      _controller = YoutubePlayerController.fromVideoId(
        videoId: widget.workout['youtubeId'],
        params: const YoutubePlayerParams(
          showControls: true,
          showFullscreenButton: true,
          enableCaption: true,
          mute: false,
          strictRelatedVideos: true,
          interfaceLanguage: 'en',
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF191414),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade600,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Workout video or image
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: widget.workout.containsKey('youtubeId') &&
                        widget.workout['youtubeId'] != null
                    ? _isVideoPlaying
                        ? SizedBox(
                            width: double.infinity,
                            height: MediaQuery.of(context).size.width *
                                9 /
                                16, // Maintain 16:9 aspect ratio
                            child: YoutubePlayer(
                              controller: _controller,
                              aspectRatio: 16 / 9,
                              backgroundColor: Colors.black,
                            ),
                          )
                        : GestureDetector(
                            onTap: () {
                              setState(() {
                                _isVideoPlaying = true;
                                Future.delayed(
                                    const Duration(milliseconds: 500), () {
                                  _controller.playVideo();
                                });
                              });
                            },
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.network(
                                  'https://img.youtube.com/vi/${widget.workout['youtubeId']}/0.jpg',
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey.shade800,
                                      child: Icon(
                                        _getWorkoutIcon(
                                            widget.workout['focusArea']),
                                        color: const Color(0xFF1DB954),
                                        size: 48,
                                      ),
                                    );
                                  },
                                ),
                                Center(
                                  child: Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    child: const Icon(
                                      Icons.play_arrow,
                                      color: Colors.white,
                                      size: 40,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                    : Image.asset(
                        widget.workout['imageUrl'],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey.shade800,
                            child: Icon(
                              _getWorkoutIcon(widget.workout['focusArea']),
                              color: const Color(0xFF1DB954),
                              size: 48,
                            ),
                          );
                        },
                      ),
              ),
            ),
          ),

          // Workout title
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              widget.workout['name'],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Workout stats
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildStatItem(Icons.local_fire_department,
                    '${widget.workout['calories']} cal'),
                const SizedBox(width: 24),
                _buildStatItem(Icons.speed, widget.workout['difficulty']),
                const SizedBox(width: 24),
                _buildStatItem(
                    Icons.fitness_center, widget.workout['focusArea']),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Start workout button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton(
              onPressed: () {
                // Navigate to workout session screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WorkoutTimerScreen(
                      workout: widget.workout,
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
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1DB954),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.play_circle_filled),
                  SizedBox(width: 8),
                  Text(
                    'START WORKOUT',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Exercise list header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Text(
                  'Exercises',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${widget.workout['exercises'].length} items',
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Exercise list
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 24),
              itemCount: widget.workout['exercises'].length,
              itemBuilder: (context, index) {
                final exercise = widget.workout['exercises'][index];
                return ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade800,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Color(0xFF1DB954),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    exercise['name'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: exercise['reps'].isNotEmpty
                      ? Text(
                          '${exercise['sets']} ${exercise['sets'] > 1 ? 'sets' : 'set'} × ${exercise['reps']}',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                          ),
                        )
                      : null,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          color: const Color(0xFF1DB954),
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: Colors.grey.shade300,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  IconData _getWorkoutIcon(String focusArea) {
    switch (focusArea.toLowerCase()) {
      case 'full body':
        return Icons.fitness_center;
      case 'upper body':
        return Icons.accessibility_new;
      case 'lower body':
        return Icons.directions_run;
      case 'core':
        return Icons.crop_square;
      case 'cardio':
        return Icons.favorite;
      case 'flexibility':
        return Icons.self_improvement;
      default:
        return Icons.fitness_center;
    }
  }
}

// Add this class at the end of the file
class WorkoutTimerScreen extends StatefulWidget {
  final Map<String, dynamic> workout;
  final String userName;
  final String fitnessLevel;
  final String goal;
  final int height;
  final int weight;
  final String memberSince;

  const WorkoutTimerScreen({
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
  _WorkoutTimerScreenState createState() => _WorkoutTimerScreenState();
}

class _WorkoutTimerScreenState extends State<WorkoutTimerScreen> {
  late List<Map<String, dynamic>> exercises;
  int currentExerciseIndex = 0;
  int currentSetIndex = 0;
  int secondsRemaining = 0;
  bool isResting = false;
  bool isPaused = false;
  bool isCompleted = false;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    exercises = List<Map<String, dynamic>>.from(widget.workout['exercises']);
    _setupNextExercise();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void _setupNextExercise() {
    if (currentExerciseIndex >= exercises.length) {
      setState(() {
        isCompleted = true;
      });
      return;
    }

    final exercise = exercises[currentExerciseIndex];

    // Parse the reps string to get seconds if it's a timed exercise
    if (exercise['reps'].toString().contains('sec')) {
      String repString = exercise['reps'].toString();
      int seconds = int.tryParse(
            repString.replaceAll(RegExp(r'[^0-9]'), ''),
          ) ??
          30;

      setState(() {
        secondsRemaining = seconds;
        isResting = false;
      });
    } else {
      // For rep-based exercises, give them 3 seconds per rep as a guideline
      int reps = 12; // Default
      if (exercise['reps'].toString().isNotEmpty &&
          !exercise['reps'].toString().contains('Max')) {
        reps = int.tryParse(
              exercise['reps'].toString().replaceAll(RegExp(r'[^0-9]'), ''),
            ) ??
            12;
      }

      setState(() {
        secondsRemaining = reps * 3;
        isResting = false;
      });
    }

    _startTimer();
  }

  void _startTimer() {
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (isPaused) return;

      if (secondsRemaining > 0) {
        setState(() {
          secondsRemaining--;
        });
      } else {
        timer.cancel();

        // Check if we need to move to the next set or exercise
        final exercise = exercises[currentExerciseIndex];
        int totalSets = exercise['sets'] ?? 1;

        if (isResting) {
          setState(() {
            isResting = false;
            _setupNextExercise();
          });
        } else if (currentSetIndex < totalSets - 1) {
          // Move to next set with a rest period
          setState(() {
            currentSetIndex++;
            secondsRemaining = 15; // 15 seconds rest between sets
            isResting = true;
          });
          _startTimer();
        } else {
          // Move to next exercise
          setState(() {
            currentExerciseIndex++;
            currentSetIndex = 0;
            _setupNextExercise();
          });
        }
      }
    });
  }

  void _togglePause() {
    setState(() {
      isPaused = !isPaused;
    });
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF191414),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          widget.workout['name'],
          style: const TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: const Color(0xFF191414),
                title: const Text(
                  'Quit Workout?',
                  style: TextStyle(color: Colors.white),
                ),
                content: const Text(
                  'Are you sure you want to quit this workout?',
                  style: TextStyle(color: Colors.white70),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('CANCEL'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    child: const Text('QUIT'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      body: isCompleted ? _buildCompletedView() : _buildWorkoutTimerView(),
    );
  }

  // Save workout progress to Firebase
  Future<void> _saveWorkoutProgress() async {
    try {
      // Create a BuildContext variable that won't be disposed when the widget tree rebuilds
      final scaffoldContext = context;

      // Use the correct context to get the provider
      final firebaseProvider =
          Provider.of<FirebaseProvider>(scaffoldContext, listen: false);

      print("Saving workout progress...");

      // Create workout progress data
      final progressData = {
        'workoutId': widget.workout['id'],
        'workoutName': widget.workout['name'],
        'duration': widget.workout['duration'],
        'caloriesBurned': widget.workout['calories'],
        'completedAt': DateTime.now().toIso8601String(),
        'focusArea': widget.workout['focusArea'],
        // Add timestamp explicitly here, even though server will set it
        'timestamp': Timestamp.now(),
      };

      print("Progress data: $progressData");

      // Save workout progress to user's history
      await firebaseProvider.saveWorkoutProgress(progressData);
      print("Workout progress saved to history");

      // Get current user stats
      final userStats = await firebaseProvider.getUserStats();
      print("Retrieved user stats: ${userStats?.exists}");

      if (userStats != null && userStats.exists) {
        final data = userStats.data() as Map<String, dynamic>;
        print("Current stats data: $data");

        // Update stats with new workout data
        final updatedStats = {
          'steps': (data['steps'] ?? 0) +
              (widget.workout['duration'] *
                  100), // Approximate steps based on duration
          'caloriesBurned':
              (data['caloriesBurned'] ?? 0) + widget.workout['calories'],
          'workoutsCompleted': (data['workoutsCompleted'] ?? 0) + 1,
          'lastWorkoutDate': DateTime.now().toIso8601String(),
        };

        print("Updating stats with: $updatedStats");

        // Update user stats in Firebase
        await firebaseProvider.updateUserStats(updatedStats);
        print("User stats updated successfully");
      } else {
        print("No existing user stats found, creating default stats");
        // Create default stats if they don't exist
        final defaultStats = {
          'steps': widget.workout['duration'] * 100,
          'stepsGoal': 10000,
          'caloriesBurned': widget.workout['calories'],
          'caloriesGoal': 500,
          'workoutsCompleted': 1,
          'lastWorkoutDate': DateTime.now().toIso8601String(),
        };

        await firebaseProvider.updateUserStats(defaultStats);
        print("Default user stats created successfully");
      }
    } catch (e) {
      print('Error saving workout progress: $e');
    }
  }

  Widget _buildWorkoutTimerView() {
    final exercise = currentExerciseIndex < exercises.length
        ? exercises[currentExerciseIndex]
        : {'name': 'Rest', 'sets': 1, 'reps': ''};

    return Column(
      children: [
        // Progress indicator
        LinearProgressIndicator(
          value: currentExerciseIndex / exercises.length,
          backgroundColor: Colors.grey.shade800,
          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1DB954)),
        ),

        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Current status
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isResting ? Colors.orange : const Color(0xFF1DB954),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isResting ? 'REST' : 'WORK',
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Exercise name
                Text(
                  isResting ? 'Rest' : exercise['name'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),

                // Set information
                if (!isResting && exercise['sets'] > 1)
                  Text(
                    'Set ${currentSetIndex + 1} of ${exercise['sets']}',
                    style: TextStyle(
                      color: Colors.grey.shade300,
                      fontSize: 18,
                    ),
                  ),

                const SizedBox(height: 16),

                // Reps information
                if (!isResting && exercise['reps'].toString().isNotEmpty)
                  Text(
                    exercise['reps'],
                    style: TextStyle(
                      color: Colors.grey.shade300,
                      fontSize: 18,
                    ),
                  ),

                const SizedBox(height: 60),

                // Timer
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color:
                          isResting ? Colors.orange : const Color(0xFF1DB954),
                      width: 8,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _formatTime(secondsRemaining),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 60),

                // Next exercise
                if (currentExerciseIndex < exercises.length - 1)
                  Column(
                    children: [
                      Text(
                        'Next:',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        exercises[currentExerciseIndex + 1]['name'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),

        // Control buttons
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                onPressed: () {
                  // Skip to next exercise
                  timer?.cancel();
                  setState(() {
                    currentExerciseIndex++;
                    currentSetIndex = 0;
                    _setupNextExercise();
                  });
                },
                icon:
                    const Icon(Icons.skip_next, color: Colors.white, size: 36),
              ),
              FloatingActionButton(
                onPressed: _togglePause,
                backgroundColor: const Color(0xFF1DB954),
                child: Icon(
                  isPaused ? Icons.play_arrow : Icons.pause,
                  size: 36,
                ),
              ),
              IconButton(
                onPressed: () {
                  // Add 10 seconds
                  setState(() {
                    secondsRemaining += 10;
                  });
                },
                icon: const Icon(Icons.add_circle_outline,
                    color: Colors.white, size: 36),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompletedView() {
    // Save workout progress to Firebase when workout is completed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _saveWorkoutProgress();
    });

    return Center(
      child: Stack(
        children: [
          // Confetti animation overlay
          Positioned.fill(
            child: Lottie.asset(
              'assets/animations/confetti.json',
              repeat: true,
              reverse: false,
              animate: true,
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.emoji_events,
                  color: Color(0xFF1DB954),
                  size: 100,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Workout Complete!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'You completed ${widget.workout['name']}',
                  style: TextStyle(
                    color: Colors.grey.shade300,
                    fontSize: 18,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Calories burned: ~${widget.workout['calories']}',
                  style: TextStyle(
                    color: Colors.grey.shade300,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 48),
                ElevatedButton(
                  onPressed: () {
                    // Navigate back to the home screen
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HomeScreen(
                          userName: widget.userName,
                          fitnessLevel: widget.fitnessLevel,
                          goal: widget.goal,
                          height: widget.height,
                          weight: widget.weight,
                          memberSince: widget.memberSince,
                        ),
                      ),
                      (route) => false, // Remove all previous routes
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1DB954),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'FINISH',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
