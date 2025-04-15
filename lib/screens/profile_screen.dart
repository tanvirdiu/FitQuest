import 'package:flutter/material.dart';
import '../widgets/bottom_nav_bar.dart';
import 'package:provider/provider.dart';
import '../providers/firebase_provider.dart';
import 'auth_screen.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends StatefulWidget {
  final String userName;
  final String fitnessLevel;
  final String goal;
  final int height;
  final int weight;
  final String memberSince;

  const ProfileScreen({
    Key? key,
    this.userName = 'Fitness Enthusiast',
    this.fitnessLevel = 'Intermediate',
    this.goal = 'Weight Loss',
    this.height = 175,
    this.weight = 70,
    this.memberSince = 'January 2023',
  }) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // User data
  late Map<String, dynamic> _userData;

  // BMI data
  late double _bmi;
  late String _bmiCategory;
  late Color _bmiColor;

  // User achievements
  final List<Map<String, dynamic>> _achievements = [];

  // Settings options
  bool _notificationsEnabled = true;
  String _selectedUnit = 'Metric'; // 'Metric' or 'Imperial'
  String _selectedTheme = 'Dark'; // 'Dark' or 'Light'
  bool _showCalories = true;

  // Available goals for selection
  final List<String> _availableGoals = [
    'Weight Loss',
    'Muscle Gain',
    'Improve Fitness',
    'Increase Flexibility',
    'Maintain Health'
  ];

  // Available fitness levels
  final List<String> _fitnessLevels = [
    'Beginner',
    'Intermediate',
    'Advanced',
    'Expert'
  ];

  // Firebase data
  bool _isLoading = true;
  Map<String, dynamic> _firestoreStats = {};

  @override
  void initState() {
    super.initState();
    // Initialize user data from widget parameters
    _userData = {
      'name': widget.userName,
      'email':
          '${widget.userName.toLowerCase().replaceAll(' ', '.')}@example.com',
      'memberSince': widget.memberSince,
      'workoutsCompleted': 0,
      'streakDays': 0,
      'fitnessLevel': widget.fitnessLevel,
      'height': widget.height,
      'weight': widget.weight,
      'goal': widget.goal,
      'profileImage': null,
    };

    // Calculate BMI
    _calculateBMI();

    // Load user stats from Firebase
    _loadUserStats();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF191414),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 4, // Profile tab
        userName: widget.userName,
        fitnessLevel: widget.fitnessLevel,
        goal: widget.goal,
        height: widget.height,
        weight: widget.weight,
        memberSince: widget.memberSince,
      ),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // App Bar
            SliverAppBar(
              backgroundColor: Colors.transparent,
              expandedHeight: 200,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFF1DB954).withOpacity(0.8),
                        const Color(0xFF191414),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Profile image
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey.shade800,
                            border: Border.all(
                              color: Colors.white,
                              width: 3,
                            ),
                          ),
                          child: const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 60,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // User name
                        Text(
                          _userData['name'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Fitness level
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            _userData['fitnessLevel'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                // Settings button
                IconButton(
                  icon: const Icon(Icons.settings),
                  color: Colors.white,
                  onPressed: () {
                    // Show settings dialog
                    showDialog(
                      context: context,
                      builder: (context) => StatefulBuilder(
                        builder: (context, setState) => AlertDialog(
                          backgroundColor: Colors.grey.shade900,
                          title: const Text(
                            'Settings',
                            style: TextStyle(color: Colors.white),
                          ),
                          content: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Notifications
                                const Text(
                                  'Notifications',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                ),
                                SwitchListTile(
                                  title: const Text('Enable Notifications',
                                      style: TextStyle(color: Colors.white)),
                                  value: _notificationsEnabled,
                                  activeColor: const Color(0xFF1DB954),
                                  onChanged: (value) {
                                    setState(() {
                                      _notificationsEnabled = value;
                                    });
                                  },
                                ),
                                const Divider(color: Colors.grey),

                                // Units
                                const Text(
                                  'Units',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                ),
                                RadioListTile<String>(
                                  title: const Text('Metric (kg, cm)',
                                      style: TextStyle(color: Colors.white)),
                                  value: 'Metric',
                                  groupValue: _selectedUnit,
                                  activeColor: const Color(0xFF1DB954),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedUnit = value!;
                                    });
                                  },
                                ),
                                RadioListTile<String>(
                                  title: const Text('Imperial (lb, ft)',
                                      style: TextStyle(color: Colors.white)),
                                  value: 'Imperial',
                                  groupValue: _selectedUnit,
                                  activeColor: const Color(0xFF1DB954),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedUnit = value!;
                                    });
                                  },
                                ),
                                const Divider(color: Colors.grey),

                                // Theme
                                const Text(
                                  'Theme',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                ),
                                RadioListTile<String>(
                                  title: const Text('Dark Theme',
                                      style: TextStyle(color: Colors.white)),
                                  value: 'Dark',
                                  groupValue: _selectedTheme,
                                  activeColor: const Color(0xFF1DB954),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedTheme = value!;
                                    });
                                  },
                                ),
                                RadioListTile<String>(
                                  title: const Text('Light Theme',
                                      style: TextStyle(color: Colors.white)),
                                  value: 'Light',
                                  groupValue: _selectedTheme,
                                  activeColor: const Color(0xFF1DB954),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedTheme = value!;
                                    });
                                  },
                                ),
                                const Divider(color: Colors.grey),

                                // Display options
                                const Text(
                                  'Display Options',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                ),
                                SwitchListTile(
                                  title: const Text('Show Calories',
                                      style: TextStyle(color: Colors.white)),
                                  value: _showCalories,
                                  activeColor: const Color(0xFF1DB954),
                                  onChanged: (value) {
                                    setState(() {
                                      _showCalories = value;
                                    });
                                  },
                                ),
                                const Divider(color: Colors.grey),

                                // Logout button
                                const Text(
                                  'Account',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                ),
                                ListTile(
                                  title: const Text('Logout',
                                      style: TextStyle(color: Colors.white)),
                                  leading: const Icon(Icons.logout,
                                      color: Colors.white),
                                  onTap: () async {
                                    try {
                                      // Get the FirebaseProvider instance
                                      final firebaseProvider =
                                          Provider.of<FirebaseProvider>(context,
                                              listen: false);

                                      // Close the settings dialog
                                      Navigator.pop(context);

                                      // Show loading indicator
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text('Logging out...'),
                                          duration: Duration(seconds: 1),
                                        ),
                                      );

                                      // Perform logout
                                      await firebaseProvider.signOut();

                                      // Navigate to auth screen
                                      if (context.mounted) {
                                        Navigator.of(context)
                                            .pushAndRemoveUntil(
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const AuthScreen(),
                                          ),
                                          (route) =>
                                              false, // Remove all previous routes
                                        );
                                      }
                                    } catch (e) {
                                      // Show error message if logout fails
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content:
                                                Text('Error during logout: $e'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                // Save settings
                                // In a real app, you would persist these settings
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Settings saved'),
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
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),

            // Stats Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your Stats',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Stats cards
                    _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF1DB954),
                            ),
                          )
                        : Column(
                            children: [
                              Row(
                                children: [
                                  _buildStatCard(
                                    'Workouts',
                                    _userData['workoutsCompleted'].toString(),
                                    Icons.fitness_center,
                                  ),
                                  const SizedBox(width: 16),
                                  _buildStatCard(
                                    'Streak',
                                    '${_userData['streakDays']} days',
                                    Icons.local_fire_department,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  _buildStatCard(
                                    'Steps',
                                    _userData.containsKey('stepsCount')
                                        ? _userData['stepsCount'].toString()
                                        : '0',
                                    Icons.directions_walk,
                                  ),
                                  const SizedBox(width: 16),
                                  _buildStatCard(
                                    'Calories',
                                    _userData.containsKey('caloriesBurned')
                                        ? '${_userData['caloriesBurned']} kcal'
                                        : '0 kcal',
                                    Icons.local_fire_department,
                                  ),
                                ],
                              ),
                            ],
                          ),
                    const SizedBox(height: 16),

                    // BMI Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade900,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _bmiColor.withOpacity(0.5),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'BMI (Body Mass Index)',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _bmiColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _bmiCategory,
                                  style: TextStyle(
                                    color: _bmiColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _bmi.toStringAsFixed(1),
                                style: TextStyle(
                                  color: _bmiColor,
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'BMI is a measure of body fat based on height and weight.',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // User details
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade900,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          _buildDetailRow('Goal', _userData['goal']),
                          const Divider(color: Colors.grey),
                          _buildDetailRow(
                            'Height',
                            '${_userData['height']} cm',
                          ),
                          const Divider(color: Colors.grey),
                          _buildDetailRow(
                            'Weight',
                            '${_userData['weight']} kg',
                          ),
                          const Divider(color: Colors.grey),
                          _buildDetailRow(
                            'Member Since',
                            _userData['memberSince'],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Achievements Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Achievements',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Achievements list
                    ..._achievements.map(
                        (achievement) => _buildAchievementCard(achievement)),
                  ],
                ),
              ),
            ),

            // Edit Profile Button
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: () {
                    // Create temporary variables to hold edited values
                    String tempName = _userData['name'];
                    String tempGoal = _userData['goal'];
                    String tempFitnessLevel = _userData['fitnessLevel'];
                    int tempHeight = _userData['height'];
                    int tempWeight = _userData['weight'];

                    // Show edit profile dialog
                    showDialog(
                      context: context,
                      builder: (context) => StatefulBuilder(
                        builder: (context, setState) => AlertDialog(
                          backgroundColor: Colors.grey.shade900,
                          title: const Text(
                            'Edit Profile',
                            style: TextStyle(color: Colors.white),
                          ),
                          content: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Profile picture
                                Stack(
                                  alignment: Alignment.bottomRight,
                                  children: [
                                    Container(
                                      width: 100,
                                      height: 100,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.grey.shade800,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 3,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.person,
                                        color: Colors.white,
                                        size: 60,
                                      ),
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1DB954),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: Colors.white, width: 2),
                                      ),
                                      child: IconButton(
                                        icon: const Icon(Icons.camera_alt,
                                            size: 16),
                                        color: Colors.white,
                                        onPressed: () {
                                          // In a real app, you would implement image picking
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  'Image picker would open here'),
                                              backgroundColor: Colors.blue,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // Name field
                                TextField(
                                  controller:
                                      TextEditingController(text: tempName),
                                  onChanged: (value) => tempName = value,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    labelText: 'Name',
                                    labelStyle:
                                        TextStyle(color: Colors.grey.shade400),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color: Colors.grey.shade700),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: const BorderSide(
                                          color: Color(0xFF1DB954)),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Goal dropdown
                                DropdownButtonFormField<String>(
                                  value: tempGoal,
                                  dropdownColor: Colors.grey.shade800,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    labelText: 'Fitness Goal',
                                    labelStyle:
                                        TextStyle(color: Colors.grey.shade400),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color: Colors.grey.shade700),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: const BorderSide(
                                          color: Color(0xFF1DB954)),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  items: _availableGoals.map((goal) {
                                    return DropdownMenuItem<String>(
                                      value: goal,
                                      child: Text(goal),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      tempGoal = value!;
                                    });
                                  },
                                ),
                                const SizedBox(height: 16),

                                // Fitness level dropdown
                                DropdownButtonFormField<String>(
                                  value: tempFitnessLevel,
                                  dropdownColor: Colors.grey.shade800,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    labelText: 'Fitness Level',
                                    labelStyle:
                                        TextStyle(color: Colors.grey.shade400),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color: Colors.grey.shade700),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: const BorderSide(
                                          color: Color(0xFF1DB954)),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  items: _fitnessLevels.map((level) {
                                    return DropdownMenuItem<String>(
                                      value: level,
                                      child: Text(level),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      tempFitnessLevel = value!;
                                    });
                                  },
                                ),
                                const SizedBox(height: 16),

                                // Height and weight fields in a row
                                Row(
                                  children: [
                                    // Height field
                                    Expanded(
                                      child: TextField(
                                        controller: TextEditingController(
                                            text: tempHeight.toString()),
                                        onChanged: (value) {
                                          if (value.isNotEmpty) {
                                            tempHeight = int.tryParse(value) ??
                                                tempHeight;
                                          }
                                        },
                                        keyboardType: TextInputType.number,
                                        style: const TextStyle(
                                            color: Colors.white),
                                        decoration: InputDecoration(
                                          labelText: 'Height (cm)',
                                          labelStyle: TextStyle(
                                              color: Colors.grey.shade400),
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                                color: Colors.grey.shade700),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: const BorderSide(
                                                color: Color(0xFF1DB954)),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    // Weight field
                                    Expanded(
                                      child: TextField(
                                        controller: TextEditingController(
                                            text: tempWeight.toString()),
                                        onChanged: (value) {
                                          if (value.isNotEmpty) {
                                            tempWeight = int.tryParse(value) ??
                                                tempWeight;
                                          }
                                        },
                                        keyboardType: TextInputType.number,
                                        style: const TextStyle(
                                            color: Colors.white),
                                        decoration: InputDecoration(
                                          labelText: 'Weight (kg)',
                                          labelStyle: TextStyle(
                                              color: Colors.grey.shade400),
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                                color: Colors.grey.shade700),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: const BorderSide(
                                                color: Color(0xFF1DB954)),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                            TextButton(
                              onPressed: () async {
                                // Update user data with edited values
                                setState(() {
                                  _userData['name'] = tempName;
                                  _userData['goal'] = tempGoal;
                                  _userData['fitnessLevel'] = tempFitnessLevel;
                                  _userData['height'] = tempHeight;
                                  _userData['weight'] = tempWeight;
                                });

                                // Get the FirebaseProvider instance
                                final firebaseProvider =
                                    Provider.of<FirebaseProvider>(context,
                                        listen: false);

                                try {
                                  // Update the user profile in Firebase
                                  await firebaseProvider.updateUserProfile({
                                    'name': tempName,
                                    'fitnessLevel': tempFitnessLevel,
                                    'fitnessGoals': [tempGoal],
                                    'height': tempHeight,
                                    'weight': tempWeight,
                                    'updatedAt': FieldValue.serverTimestamp(),
                                  });

                                  // Close dialog and update parent state
                                  Navigator.pop(context);

                                  // Recalculate BMI with new height/weight values
                                  final heightInMeters = tempHeight / 100;
                                  _bmi = tempWeight /
                                      (heightInMeters * heightInMeters);
                                  _calculateBMI(); // Update BMI category and color

                                  // Update the parent widget's state
                                  this.setState(() {});

                                  // Show success message
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content:
                                          Text('Profile updated successfully'),
                                      backgroundColor: Color(0xFF1DB954),
                                    ),
                                  );
                                } catch (e) {
                                  print('Error updating profile: $e');
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content:
                                          Text('Error updating profile: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  Navigator.pop(context);
                                }
                              },
                              child: const Text(
                                'Save',
                                style: TextStyle(color: Color(0xFF1DB954)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1DB954),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Edit Profile',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

            // Bottom padding
            const SliverToBoxAdapter(
              child: SizedBox(height: 80),
            ),
          ],
        ),
      ),
    );
  }

  // Calculate BMI and set category and color
  void _calculateBMI() {
    // Calculate BMI using the formula: weight (kg) / (height (m))²
    final heightInMeters = widget.height / 100;
    _bmi = widget.weight / (heightInMeters * heightInMeters);

    // Determine BMI category and color
    if (_bmi < 18.5) {
      _bmiCategory = 'Underweight';
      _bmiColor = Colors.blue;
    } else if (_bmi >= 18.5 && _bmi < 25) {
      _bmiCategory = 'Normal';
      _bmiColor = const Color(0xFF1DB954); // Green
    } else if (_bmi >= 25 && _bmi < 30) {
      _bmiCategory = 'Overweight';
      _bmiColor = Colors.orange;
    } else {
      _bmiCategory = 'Obese';
      _bmiColor = Colors.red;
    }
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF1DB954).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF1DB954),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 14,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 16,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementCard(Map<String, dynamic> achievement) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(16),
        border: achievement['completed']
            ? Border.all(color: const Color(0xFF1DB954), width: 2)
            : null,
      ),
      child: Row(
        children: [
          // Achievement icon
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: achievement['completed']
                  ? const Color(0xFF1DB954).withOpacity(0.2)
                  : Colors.grey.shade800,
              shape: BoxShape.circle,
            ),
            child: Icon(
              achievement['icon'],
              color: achievement['completed']
                  ? const Color(0xFF1DB954)
                  : Colors.grey,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),

          // Achievement details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement['title'],
                  style: TextStyle(
                    color: achievement['completed']
                        ? const Color(0xFF1DB954)
                        : Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  achievement['description'],
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),

                // Progress bar
                LinearProgressIndicator(
                  value: achievement['progress'],
                  backgroundColor: Colors.grey.shade800,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    achievement['completed']
                        ? const Color(0xFF1DB954)
                        : Colors.blue,
                  ),
                ),
                const SizedBox(height: 4),

                // Progress text
                Text(
                  achievement['completed']
                      ? 'Completed!'
                      : '${(achievement['progress'] * 100).toInt()}% completed',
                  style: TextStyle(
                    color: achievement['completed']
                        ? const Color(0xFF1DB954)
                        : Colors.grey.shade400,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Load user stats from Firebase
  Future<void> _loadUserStats() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final firebaseProvider =
          Provider.of<FirebaseProvider>(context, listen: false);

      // Get user stats from Firebase
      final userStats = await firebaseProvider.getUserStatsAsMap();
      print("User stats loaded: $userStats");

      // Also get workout history to count total workouts if needed
      final workoutHistory = await firebaseProvider.getWorkoutHistoryAsMaps();
      print("Workout history loaded: ${workoutHistory.length} workouts");

      setState(() {
        _firestoreStats = userStats;

        // Update workout stats in userData
        _userData['workoutsCompleted'] =
            userStats['workoutsCompleted'] ?? workoutHistory.length;
        _userData['streakDays'] =
            userStats['streakDays'] ?? userStats['currentStreak'] ?? 0;
        _userData['stepsCount'] = userStats['steps'] ?? 0;
        _userData['caloriesBurned'] = userStats['caloriesBurned'] ?? 0;

        // Generate dynamic achievements based on user data
        _generateAchievements(workoutHistory, userStats);

        _isLoading = false;
      });
    } catch (e) {
      print('Error loading user stats: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Generate achievements based on user data
  void _generateAchievements(List<Map<String, dynamic>> workoutHistory,
      Map<String, dynamic> userStats) {
    // Clear existing achievements
    _achievements.clear();

    // Total workouts achievement
    final totalWorkouts = _userData['workoutsCompleted'];
    const workoutGoal = 20; // Target: 20 workouts
    final workoutProgress = (totalWorkouts / workoutGoal).clamp(0.0, 1.0);

    _achievements.add({
      'title': 'Workout Warrior',
      'description': 'Complete $workoutGoal workouts',
      'icon': Icons.fitness_center,
      'progress': workoutProgress,
      'completed': totalWorkouts >= workoutGoal,
    });

    // Streak achievement
    final currentStreak = _userData['streakDays'];
    const streakGoal = 7; // Target: 7-day streak
    final streakProgress = (currentStreak / streakGoal).clamp(0.0, 1.0);

    _achievements.add({
      'title': 'Consistency Champion',
      'description': 'Maintain a $streakGoal-day workout streak',
      'icon': Icons.local_fire_department,
      'progress': streakProgress,
      'completed': currentStreak >= streakGoal,
    });

    // Steps achievement
    final totalSteps = _userData['stepsCount'];
    const stepsGoal = 100000; // Target: 100,000 steps
    final stepsProgress = (totalSteps / stepsGoal).clamp(0.0, 1.0);

    _achievements.add({
      'title': 'Step Master',
      'description': 'Reach $stepsGoal steps',
      'icon': Icons.directions_walk,
      'progress': stepsProgress,
      'completed': totalSteps >= stepsGoal,
    });

    // Calories burned achievement
    final caloriesBurned = _userData['caloriesBurned'];
    const caloriesGoal = 5000; // Target: 5,000 calories
    final caloriesProgress = (caloriesBurned / caloriesGoal).clamp(0.0, 1.0);

    _achievements.add({
      'title': 'Calorie Crusher',
      'description': 'Burn $caloriesGoal calories',
      'icon': Icons.whatshot,
      'progress': caloriesProgress,
      'completed': caloriesBurned >= caloriesGoal,
    });

    // Check for different workout types
    Set<String> workoutTypes = {};
    for (var workout in workoutHistory) {
      String workoutType = '';

      // Check different fields that might contain the workout type
      if (workout.containsKey('focusArea') && workout['focusArea'] != null) {
        workoutType = workout['focusArea'].toString();
      } else if (workout.containsKey('category') &&
          workout['category'] != null) {
        workoutType = workout['category'].toString();
      } else if (workout.containsKey('type') && workout['type'] != null) {
        workoutType = workout['type'].toString();
      }

      if (workoutType.isNotEmpty) {
        workoutTypes.add(workoutType);
      }
    }

    // Workout variety achievement
    const varietyGoal = 5; // Target: 5 different workout types
    final varietyProgress = (workoutTypes.length / varietyGoal).clamp(0.0, 1.0);

    _achievements.add({
      'title': 'Diversity Champion',
      'description': 'Try $varietyGoal different workout types',
      'icon': Icons.autorenew,
      'progress': varietyProgress,
      'completed': workoutTypes.length >= varietyGoal,
    });

    // If the user has been working out for some time, add a loyalty achievement
    final memberSinceMonths = _calculateMemberMonths(_userData['memberSince']);
    const loyaltyGoal = 3; // Target: 3 months of membership
    final loyaltyProgress = (memberSinceMonths / loyaltyGoal).clamp(0.0, 1.0);

    _achievements.add({
      'title': 'Fitness Loyal',
      'description': 'Member for $loyaltyGoal months',
      'icon': Icons.military_tech,
      'progress': loyaltyProgress,
      'completed': memberSinceMonths >= loyaltyGoal,
    });
  }

  // Calculate months since membership started
  int _calculateMemberMonths(String memberSince) {
    try {
      // Try to parse the membership date
      DateTime membershipDate;

      // Handle different date formats
      try {
        // Try MMMM yyyy format (e.g., "January 2023")
        membershipDate = DateFormat('MMMM yyyy').parse(memberSince);
      } catch (e) {
        try {
          // Try MMM yyyy format (e.g., "Jan 2023")
          membershipDate = DateFormat('MMM yyyy').parse(memberSince);
        } catch (e) {
          // Default to current date minus 1 month if parsing fails
          membershipDate = DateTime.now().subtract(const Duration(days: 30));
        }
      }

      // Calculate difference in months
      final now = DateTime.now();
      return (now.year - membershipDate.year) * 12 +
          now.month -
          membershipDate.month;
    } catch (e) {
      print('Error calculating member months: $e');
      return 1; // Default to 1 month if calculation fails
    }
  }
}
