import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:lottie/lottie.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'dart:math' as math;
import 'dart:typed_data'; // Add this import for ByteData
import 'package:intl/intl.dart';
import '../widgets/bottom_nav_bar.dart';
import 'package:provider/provider.dart';
import '../providers/firebase_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProgressScreen extends StatefulWidget {
  final String userName;
  final String fitnessLevel;
  final String goal;
  final int height;
  final int weight;
  final String memberSince;

  const ProgressScreen({
    Key? key,
    this.userName = 'Fitness Enthusiast',
    this.fitnessLevel = 'Intermediate',
    this.goal = 'Weight Loss',
    this.height = 175,
    this.weight = 68,
    this.memberSince = 'January 2023',
  }) : super(key: key);

  @override
  _ProgressScreenState createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen>
    with TickerProviderStateMixin {
  late CalendarFormat _calendarFormat;
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  late AnimationController _confettiController;
  late AnimationController _statsAnimationController;
  final GlobalKey _calendarKey = GlobalKey();
  bool _showConfetti = false;
  int _selectedTabIndex = 0;
  bool _isLoading = true;

  // Real workout data
  List<DateTime> _workoutDates = [];
  Map<String, int> _workoutTypes = {};
  Map<DateTime, List<Map<String, dynamic>>> _workoutsByDate =
      {}; // Changed from Map to List of Maps
  int _monthlyWorkoutCount = 0;
  final int _monthlyGoal = 20;
  String _topActivity = '';

  @override
  void initState() {
    super.initState();
    _calendarFormat = CalendarFormat.month;
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();

    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _statsAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Load real workout data
    _loadWorkoutData();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _statsAnimationController.dispose();
    super.dispose();
  }

  // Load real workout data from Firebase
  Future<void> _loadWorkoutData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final firebaseProvider =
          Provider.of<FirebaseProvider>(context, listen: false);
      final workoutHistory = await firebaseProvider.getWorkoutHistory();

      print(
          "Progress screen: Loading workout history, found ${workoutHistory.length} workouts");

      final dates = <DateTime>[];
      final typeCount = <String, int>{};
      final byDate = <DateTime, List<Map<String, dynamic>>>{};

      // Combined approach: process both document snapshots and maps
      await _processWorkoutDocuments(workoutHistory, dates, typeCount, byDate);

      // Always try the alternative method to ensure we get all workouts
      await _processWorkoutMaps(dates, typeCount, byDate);

      // Debug information
      for (var entry in byDate.entries) {
        print("Date ${entry.key}: ${entry.value.length} workouts");
        for (int i = 0; i < entry.value.length; i++) {
          final workout = entry.value[i];
          print(
              "  Workout $i: title=${workout['workoutTitle'] ?? workout['title'] ?? 'N/A'}, "
              "startTime=${workout['startTime']}, endTime=${workout['endTime']}");
        }
      }

      // Count workouts in current month
      final currentMonth = _getMonthlyWorkoutCount(dates);
      print("Progress screen: Current month workout count: $currentMonth");

      // Find top activity
      String topActivity = 'Other';
      int maxCount = 0;
      typeCount.forEach((key, value) {
        if (value > maxCount) {
          maxCount = value;
          topActivity = key;
        }
      });

      print(
          "Progress screen: Top activity: $topActivity with count: $maxCount");
      print("Progress screen: Total workouts found: ${dates.length}");

      setState(() {
        _workoutDates = dates;
        _workoutTypes = typeCount;
        _workoutsByDate = byDate;
        _monthlyWorkoutCount = currentMonth;
        _topActivity = topActivity.isEmpty ? 'Other' : topActivity;
        _isLoading = false;
      });

      // Start stats animation after data is loaded
      _statsAnimationController.forward();
    } catch (e) {
      print('Error loading workout data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Process workout documents from Firestore
  Future<void> _processWorkoutDocuments(
      List<QueryDocumentSnapshot> workoutHistory,
      List<DateTime> dates,
      Map<String, int> typeCount,
      Map<DateTime, List<Map<String, dynamic>>> byDate) async {
    for (var doc in workoutHistory) {
      try {
        final data = doc.data() as Map<String, dynamic>;
        print("Processing workout doc ID: ${doc.id}");

        // Extract all the required data
        final Map<String, dynamic> workoutData =
            await _extractWorkoutData(data);

        if (workoutData.containsKey('dateOnly') &&
            workoutData['dateOnly'] != null) {
          final dateOnly = workoutData['dateOnly'] as DateTime;

          // Add workout date to list if not already present
          if (!dates.contains(dateOnly)) {
            dates.add(dateOnly);
          }

          // Count workout by focus area
          final focusArea = workoutData['focusArea'] ?? 'Other';
          typeCount[focusArea] = (typeCount[focusArea] ?? 0) + 1;

          // Store workout data by date
          if (!byDate.containsKey(dateOnly)) {
            byDate[dateOnly] = [];
          }

          // Avoid duplicates by checking for existing entries with the same ID
          final String workoutId = doc.id;
          final bool alreadyExists = byDate[dateOnly]!.any((w) =>
              w['id'] == workoutId ||
              (w['workoutId'] == workoutData['workoutId'] &&
                  w['timestamp'] == workoutData['timestamp']));

          if (!alreadyExists) {
            // Add document ID for tracking
            workoutData['id'] = workoutId;
            byDate[dateOnly]!.add(workoutData);
            print(
                "Added workout doc to date: $dateOnly, title: ${workoutData['workoutTitle'] ?? 'N/A'}");
          } else {
            print("Skipped duplicate workout doc: $workoutId");
          }
        }
      } catch (e) {
        print("Error processing workout document: $e");
      }
    }
  }

  // Process workout maps from offline storage or alternative sources
  Future<void> _processWorkoutMaps(
      List<DateTime> dates,
      Map<String, int> typeCount,
      Map<DateTime, List<Map<String, dynamic>>> byDate) async {
    try {
      final firebaseProvider =
          Provider.of<FirebaseProvider>(context, listen: false);
      final maps = await firebaseProvider.getWorkoutHistoryAsMaps();
      print("Found ${maps.length} workout maps");

      for (var data in maps) {
        try {
          // Extract all the required data
          final Map<String, dynamic> workoutData =
              await _extractWorkoutData(data);

          if (workoutData.containsKey('dateOnly') &&
              workoutData['dateOnly'] != null) {
            final dateOnly = workoutData['dateOnly'] as DateTime;

            // Add workout date to list if not already present
            if (!dates.contains(dateOnly)) {
              dates.add(dateOnly);
            }

            // Count workout by focus area
            final focusArea = workoutData['focusArea'] ?? 'Other';
            typeCount[focusArea] = (typeCount[focusArea] ?? 0) + 1;

            // Store workout data by date
            if (!byDate.containsKey(dateOnly)) {
              byDate[dateOnly] = [];
            }

            // Check for duplicates based on available identifiers
            final workoutId = workoutData['id'] ?? '';
            final timestamp = workoutData['timestamp'];
            final workoutTitle =
                workoutData['workoutTitle'] ?? workoutData['title'] ?? '';

            bool isDuplicate = false;
            if (byDate[dateOnly]!.isNotEmpty) {
              // Check if this workout is already in the list for this day
              isDuplicate = byDate[dateOnly]!.any((w) =>
                  (workoutId.isNotEmpty && w['id'] == workoutId) ||
                  (timestamp != null && w['timestamp'] == timestamp) ||
                  (workoutTitle.isNotEmpty &&
                      w['startTime'] == workoutData['startTime'] &&
                      (w['workoutTitle'] == workoutTitle ||
                          w['title'] == workoutTitle)));
            }

            if (!isDuplicate) {
              byDate[dateOnly]!.add(workoutData);
              print(
                  "Added workout map to date: $dateOnly, title: ${workoutData['workoutTitle'] ?? workoutData['title'] ?? 'N/A'}");
            } else {
              print("Skipped duplicate workout map: $workoutTitle");
            }
          } else {
            print("Workout map missing date information");
          }
        } catch (e) {
          print("Error processing workout map: $e");
        }
      }
    } catch (e) {
      print("Error in _processWorkoutMaps: $e");
    }
  }

  // Extract and normalize workout data from various sources
  Future<Map<String, dynamic>> _extractWorkoutData(
      Map<String, dynamic> data) async {
    Map<String, dynamic> workoutData = {...data};

    // Extract date information
    DateTime? date;
    DateTime? startTime;
    DateTime? endTime;

    // Try to get timestamp from multiple possible fields
    Timestamp? timestamp;

    if (data.containsKey('timestamp') && data['timestamp'] != null) {
      if (data['timestamp'] is Timestamp) {
        timestamp = data['timestamp'] as Timestamp;
        date = timestamp.toDate();
      }
    }

    if (date == null &&
        data.containsKey('completedDate') &&
        data['completedDate'] != null) {
      if (data['completedDate'] is Timestamp) {
        date = (data['completedDate'] as Timestamp).toDate();
      } else if (data['completedDate'] is String) {
        try {
          date = DateTime.parse(data['completedDate']);
        } catch (e) {
          print("Error parsing completedDate: $e");
        }
      }
    }

    if (date == null &&
        data.containsKey('completedAt') &&
        data['completedAt'] != null) {
      try {
        if (data['completedAt'] is Timestamp) {
          date = (data['completedAt'] as Timestamp).toDate();
        } else if (data['completedAt'] is String) {
          date = DateTime.parse(data['completedAt']);
        }
      } catch (e) {
        print("Error parsing completedAt: $e");
      }
    }

    // Extract start time
    if (data.containsKey('startTime') && data['startTime'] != null) {
      if (data['startTime'] is Timestamp) {
        startTime = (data['startTime'] as Timestamp).toDate();
      } else if (data['startTime'] is DateTime) {
        startTime = data['startTime'] as DateTime;
      } else if (data['startTime'] is String) {
        try {
          startTime = DateTime.parse(data['startTime']);
        } catch (e) {
          print("Error parsing startTime string: $e");
        }
      }
    }

    // Extract end time
    if (data.containsKey('endTime') && data['endTime'] != null) {
      if (data['endTime'] is Timestamp) {
        endTime = (data['endTime'] as Timestamp).toDate();
      } else if (data['endTime'] is DateTime) {
        endTime = data['endTime'] as DateTime;
      } else if (data['endTime'] is String) {
        try {
          endTime = DateTime.parse(data['endTime']);
        } catch (e) {
          print("Error parsing endTime string: $e");
        }
      }
    }

    // Use date as a fallback for start time
    if (startTime == null && date != null) {
      startTime = date;
    }

    // If we have a start time but no end time, calculate it from duration
    if (startTime != null && endTime == null) {
      final duration = data['durationMinutes'] ?? data['duration'] ?? 30;
      endTime = startTime.add(Duration(minutes: duration));
    }

    // If we have end time but no start time, calculate it from duration
    if (endTime != null && startTime == null) {
      final duration = data['durationMinutes'] ?? data['duration'] ?? 30;
      startTime = endTime.subtract(Duration(minutes: duration));
    }

    // Normalize date (without time) for grouping
    DateTime? dateOnly;
    if (date != null) {
      dateOnly = DateTime(date.year, date.month, date.day);
    } else if (startTime != null) {
      dateOnly = DateTime(startTime.year, startTime.month, startTime.day);
    }

    // Add normalized data to workout
    if (dateOnly != null) {
      workoutData['dateOnly'] = dateOnly;
    }

    if (startTime != null) {
      workoutData['startTime'] = startTime;
    }

    if (endTime != null) {
      workoutData['endTime'] = endTime;
    }

    // IMPORTANT: Extract the workout name from various fields - prioritize actual names
    // Check for workout name in all possible fields, matching what's used in the HomeScreen
    String? workoutTitle;

    // Check all possible field names for workout title, in order of priority
    if (data.containsKey('workoutName') &&
        data['workoutName'] != null &&
        data['workoutName'].toString().isNotEmpty) {
      // This is the field used in home_screen.dart for the workout name
      workoutTitle = data['workoutName'].toString();
      print("Found workoutName: $workoutTitle");
    } else if (data.containsKey('workoutTitle') &&
        data['workoutTitle'] != null &&
        data['workoutTitle'].toString().isNotEmpty) {
      workoutTitle = data['workoutTitle'].toString();
      print("Found workoutTitle: $workoutTitle");
    } else if (data.containsKey('title') &&
        data['title'] != null &&
        data['title'].toString().isNotEmpty) {
      workoutTitle = data['title'].toString();
      print("Found title: $workoutTitle");
    } else if (data.containsKey('name') &&
        data['name'] != null &&
        data['name'].toString().isNotEmpty) {
      workoutTitle = data['name'].toString();
      print("Found name: $workoutTitle");
    } else if (data.containsKey('workout') &&
        data['workout'] != null &&
        data['workout'].toString().isNotEmpty) {
      workoutTitle = data['workout'].toString();
      print("Found workout: $workoutTitle");
    }

    // Set the workout title, but only if we found a valid one
    if (workoutTitle != null) {
      // Store in both fields to ensure compatibility
      workoutData['workoutTitle'] = workoutTitle;
      workoutData['workoutName'] = workoutTitle;
      print("Using actual workout title: $workoutTitle");
    }

    return workoutData;
  }

  // Get workouts for the selected month
  int _getMonthlyWorkoutCount([List<DateTime>? dates]) {
    final datesToUse = dates ?? _workoutDates;
    return datesToUse
        .where((date) =>
            date.month == _focusedDay.month && date.year == _focusedDay.year)
        .length;
  }

  // Check if a date has a workout
  bool _hasWorkout(DateTime day) {
    // Normalize the date to remove time component
    final dateOnly = DateTime(day.year, day.month, day.day);

    // First check if date exists directly in the workoutsByDate map
    if (_workoutsByDate.containsKey(dateOnly)) {
      return true;
    }

    // Then check the workoutDates list using proper date comparison
    for (final date in _workoutDates) {
      final normalizedDate = DateTime(date.year, date.month, date.day);
      if (normalizedDate.year == dateOnly.year &&
          normalizedDate.month == dateOnly.month &&
          normalizedDate.day == dateOnly.day) {
        return true;
      }
    }

    return false;
  }

  // Show workout details for a selected day
  void _showWorkoutDetails(BuildContext context, DateTime day) {
    // Normalize the date to remove time component
    final dateOnly = DateTime(day.year, day.month, day.day);

    if (_hasWorkout(dateOnly)) {
      // Play confetti animation when tapping a completed day
      setState(() {
        _showConfetti = true;
        _confettiController.reset();
        _confettiController.forward();
      });

      // Find the workouts for this day
      List<Map<String, dynamic>> workouts = [];

      // First check if date exists directly in the workoutsByDate map
      if (_workoutsByDate.containsKey(dateOnly)) {
        workouts = _workoutsByDate[dateOnly]!;
      } else {
        // If not found directly, try to find the matching date
        for (final entry in _workoutsByDate.entries) {
          final entryDate = entry.key;
          if (entryDate.year == dateOnly.year &&
              entryDate.month == dateOnly.month &&
              entryDate.day == dateOnly.day) {
            workouts = entry.value;
            break;
          }
        }
      }

      // Sort workouts by start time if available
      workouts.sort((a, b) {
        final aStartTime = a['startTime'] as DateTime?;
        final bStartTime = b['startTime'] as DateTime?;

        if (aStartTime == null && bStartTime == null) return 0;
        if (aStartTime == null) return 1;
        if (bStartTime == null) return -1;

        return aStartTime.compareTo(bStartTime);
      });

      if (workouts.isNotEmpty) {
        showModalBottomSheet(
          context: context,
          backgroundColor: const Color(0xFF282828),
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
          ),
          builder: (context) => _buildWorkoutDetailsSheet(day, workouts),
        );
      }
    }
  }

  String _getRandomWorkoutName() {
    final workouts = [
      'Morning HIIT',
      'Full Body Strength',
      'Cardio Blast',
      'Core Crusher',
      'Yoga Flow',
      'Upper Body Focus',
      'Lower Body Burn',
      'Tabata Challenge',
      'Stretching Routine',
      'Quick Burn',
    ];
    return workouts[math.Random().nextInt(workouts.length)];
  }

  // Export calendar as image
  Future<void> _exportCalendar() async {
    try {
      // Capture the calendar widget as an image
      RenderRepaintBoundary boundary = _calendarKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData != null) {
        // Create a temporary file
        final tempDir = Directory.systemTemp;
        final file = File('${tempDir.path}/fitness_progress.png');

        // Fix: Properly convert ByteData to Uint8List with null safety
        final Uint8List pngBytes = byteData.buffer
            .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);

        // Write the bytes to file
        await file.writeAsBytes(pngBytes);

        // Share the image
        await Share.shareXFiles(
          [XFile(file.path)],
          text:
              'My Fitness Progress in ${DateFormat('MMMM yyyy').format(_focusedDay)}',
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Progress shared successfully!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to share: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF191414),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 2, // Progress tab
        userName: widget.userName,
        fitnessLevel: widget.fitnessLevel,
        goal: widget.goal,
        height: widget.height,
        weight: widget.weight,
        memberSince: widget.memberSince,
      ),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Your Fitness Journey',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        // Removed the leading back button
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: _exportCalendar,
            tooltip: 'Export Progress',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Made the Column inside a SingleChildScrollView
          SingleChildScrollView(
            child: Column(
              children: [
                // Calendar section
                RepaintBoundary(
                  key: _calendarKey,
                  child: Container(
                    color: const Color(0xFF191414),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        TableCalendar(
                          firstDay: DateTime.utc(2020, 1, 1),
                          lastDay: DateTime.utc(2030, 12, 31),
                          focusedDay: _focusedDay,
                          calendarFormat: _calendarFormat,
                          availableCalendarFormats: const {
                            CalendarFormat.month: 'Month',
                          },
                          selectedDayPredicate: (day) {
                            return isSameDay(_selectedDay, day);
                          },
                          onDaySelected: (selectedDay, focusedDay) {
                            setState(() {
                              _selectedDay = selectedDay;
                              _focusedDay = focusedDay;
                            });
                            _showWorkoutDetails(context, selectedDay);
                          },
                          onPageChanged: (focusedDay) {
                            setState(() {
                              _focusedDay = focusedDay;
                            });
                          },
                          calendarStyle: CalendarStyle(
                            isTodayHighlighted: true,
                            selectedDecoration: const BoxDecoration(
                              color: Color(0xFF1DB954),
                              shape: BoxShape.circle,
                            ),
                            todayDecoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            defaultTextStyle:
                                const TextStyle(color: Colors.white),
                            weekendTextStyle:
                                const TextStyle(color: Colors.white70),
                            outsideTextStyle:
                                TextStyle(color: Colors.white.withOpacity(0.4)),
                            markersMaxCount: 1,
                            markerDecoration: const BoxDecoration(
                              color: Color(0xFF1DB954),
                              shape: BoxShape.circle,
                            ),
                          ),
                          headerStyle: const HeaderStyle(
                            formatButtonVisible: false,
                            titleTextStyle: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            leftChevronIcon: Icon(
                              Icons.chevron_left,
                              color: Colors.white,
                            ),
                            rightChevronIcon: Icon(
                              Icons.chevron_right,
                              color: Colors.white,
                            ),
                          ),
                          calendarBuilders: CalendarBuilders(
                            markerBuilder: (context, date, events) {
                              // Get normalized date (without time)
                              final dateOnly =
                                  DateTime(date.year, date.month, date.day);

                              // Check if there are workouts for this date
                              if (_hasWorkout(dateOnly)) {
                                // Get number of workouts for this date
                                int workoutCount = 0;
                                if (_workoutsByDate.containsKey(dateOnly)) {
                                  workoutCount =
                                      _workoutsByDate[dateOnly]!.length;
                                }

                                // Show different markers based on workout count
                                if (workoutCount > 1) {
                                  // Multiple workouts - show a badge with count
                                  return Positioned(
                                    right: 1,
                                    bottom: 1,
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Color(0xFF1DB954),
                                      ),
                                      width: 16,
                                      height: 16,
                                      child: Center(
                                        child: Text(
                                          '$workoutCount',
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                } else {
                                  // Single workout - show a simple dot
                                  return Positioned(
                                    right: 1,
                                    bottom: 1,
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Color(0xFF1DB954),
                                      ),
                                      width: 8,
                                      height: 8,
                                    ),
                                  );
                                }
                              }
                              return null;
                            },
                            defaultBuilder: (context, day, focusedDay) {
                              if (_hasWorkout(day)) {
                                return Container(
                                  margin: const EdgeInsets.all(4.0),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade800,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '${day.day}',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                );
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Stats panel
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Monthly Stats',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Monthly goal progress
                      Row(
                        children: [
                          AnimatedBuilder(
                            animation: _statsAnimationController,
                            builder: (context, child) {
                              return SizedBox(
                                width: 80,
                                height: 80,
                                child: Stack(
                                  children: [
                                    CircularProgressIndicator(
                                      value: _statsAnimationController.value *
                                          _monthlyWorkoutCount /
                                          _monthlyGoal,
                                      strokeWidth: 8,
                                      backgroundColor: Colors.grey.shade800,
                                      valueColor:
                                          const AlwaysStoppedAnimation<Color>(
                                        Color(0xFF1DB954),
                                      ),
                                    ),
                                    Center(
                                      child: Text(
                                        '${(_statsAnimationController.value * _monthlyWorkoutCount).toInt()}/$_monthlyGoal',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Monthly Goal',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'You\'ve worked out $_monthlyWorkoutCount days this month',
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

                      const SizedBox(height: 24),

                      // Top activity card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade900,
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.grey.shade800,
                              const Color(0xFF282828),
                            ],
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1DB954),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.fitness_center,
                                color: Colors.black,
                                size: 30,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Top Activity',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _topActivity,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_workoutTypes[_topActivity]} workouts this month',
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

                      const SizedBox(height: 24),

                      // Workout type tabs - keeping this section non-scrollable
                      SizedBox(
                        height: 40,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            _buildTab('All', 0),
                            _buildTab('HIIT', 1),
                            _buildTab('Strength', 2),
                            _buildTab('Cardio', 3),
                            _buildTab('Yoga', 4),
                            _buildTab('Core', 5),
                          ],
                        ),
                      ),

                      // Display filtered workout list
                      const SizedBox(height: 16),
                      // Use SizedBox with fixed height to avoid nested scrolling issues
                      SizedBox(
                        height: 300, // Fixed height for the workout list
                        child: _isLoading
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFF1DB954),
                                ),
                              )
                            : _buildFilteredWorkoutList(),
                      ),

                      // Extra space at bottom for better UX
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Confetti animation overlay
          if (_showConfetti)
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _confettiController,
                  builder: (context, child) {
                    if (_confettiController.status ==
                        AnimationStatus.completed) {
                      _showConfetti = false;
                    }
                    return Opacity(
                      opacity: 1.0 - _confettiController.value,
                      child: Lottie.asset(
                        'assets/animations/confetti.json',
                        fit: BoxFit.cover,
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    final isSelected = _selectedTabIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTabIndex = index;
          // TODO: Filter workout history by type
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1DB954) : Colors.grey.shade800,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.black : Colors.white,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWorkoutDetailsSheet(
      DateTime day, List<Map<String, dynamic>> workouts) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade600,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Date
          Text(
            DateFormat('EEEE, MMMM d, y').format(day),
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),

          // Workout count
          Text(
            '${workouts.length} ${workouts.length == 1 ? 'Workout' : 'Workouts'} Completed',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          // List of workouts
          Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5,
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: workouts.length,
              itemBuilder: (context, index) {
                final workout = workouts[index];

                // Get the actual workout title using the same field priority as in home_screen.dart
                String title;
                // First check workoutName (used in the home screen)
                if (workout.containsKey('workoutName') &&
                    workout['workoutName'] != null &&
                    workout['workoutName'].toString().isNotEmpty) {
                  title = workout['workoutName'].toString();
                }
                // Then check workoutTitle
                else if (workout.containsKey('workoutTitle') &&
                    workout['workoutTitle'] != null &&
                    workout['workoutTitle'].toString().isNotEmpty) {
                  title = workout['workoutTitle'].toString();
                }
                // Then check workout (another field used in home screen)
                else if (workout.containsKey('workout') &&
                    workout['workout'] != null &&
                    workout['workout'].toString().isNotEmpty) {
                  title = workout['workout'].toString();
                }
                // Then check title
                else if (workout.containsKey('title') &&
                    workout['title'] != null &&
                    workout['title'].toString().isNotEmpty) {
                  title = workout['title'].toString();
                }
                // Then check name
                else if (workout.containsKey('name') &&
                    workout['name'] != null &&
                    workout['name'].toString().isNotEmpty) {
                  title = workout['name'].toString();
                } else {
                  // Use the same format as in home screen: "Unknown Workout" rather than "Workout 1"
                  title = "Unknown Workout";
                }

                // Get accurate duration
                final duration =
                    workout['durationMinutes'] ?? workout['duration'] ?? 30;

                // Get accurate calories
                final calories = workout['caloriesBurned'] ?? (duration * 7);

                // Format start and end times
                String timeInfo = 'Time not available';
                if (workout['startTime'] != null &&
                    workout['endTime'] != null) {
                  final startTime = workout['startTime'] as DateTime;
                  final endTime = workout['endTime'] as DateTime;
                  timeInfo =
                      '${DateFormat('h:mm a').format(startTime)} - ${DateFormat('h:mm a').format(endTime)}';
                }

                // Get accurate focus area - use the same field names as in home screen
                final focusArea = workout['focusArea'] ??
                    workout['category'] ??
                    workout['type'] ??
                    'Workout';

                // Create a layout similar to the ActivityTile in home_screen.dart
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade900,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade800,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getActivityIcon(title),
                        color: const Color(0xFF1DB954),
                      ),
                    ),
                    title: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          '$duration min • $calories cal',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          timeInfo,
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade800,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        focusArea,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Get an appropriate icon for the activity, matching what's used in home_screen.dart
  IconData _getActivityIcon(String activityName) {
    final lowerName = activityName.toLowerCase();
    if (lowerName.contains('hiit')) {
      return Icons.flash_on;
    } else if (lowerName.contains('run') || lowerName.contains('cardio')) {
      return Icons.directions_run;
    } else if (lowerName.contains('strength') || lowerName.contains('body')) {
      return Icons.fitness_center;
    } else if (lowerName.contains('yoga')) {
      return Icons.self_improvement;
    } else if (lowerName.contains('core')) {
      return Icons.accessibility_new;
    }
    return Icons.fitness_center;
  }

  Widget _buildExercisesList(Map<String, dynamic> exercises) {
    if (exercises.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Container(
          height: 1,
          color: Colors.grey.shade800,
        ),
        const SizedBox(height: 16),
        const Text(
          'Exercises',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...exercises.entries
            .map((entry) => _buildExerciseItem(
                entry.key,
                entry.value is int
                    ? '${entry.value} reps'
                    : entry.value.toString(),
                true))
            .toList(),
      ],
    );
  }

  Widget _buildStatItem(IconData icon, String text) {
    return Column(
      children: [
        Icon(
          icon,
          color: const Color(0xFF1DB954),
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildExerciseItem(String name, String duration, bool completed) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: completed ? const Color(0xFF1DB954) : Colors.grey.shade800,
              border: Border.all(
                color: completed ? const Color(0xFF1DB954) : Colors.grey,
                width: 2,
              ),
            ),
            child: completed
                ? const Icon(
                    Icons.check,
                    size: 16,
                    color: Colors.black,
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ),
          Text(
            duration,
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // Build filtered workout list based on selected tab
  Widget _buildFilteredWorkoutList() {
    if (_workoutsByDate.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.fitness_center, color: Colors.grey.shade600, size: 48),
            const SizedBox(height: 16),
            Text(
              'No workouts found',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete workouts to see them here',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          ],
        ),
      );
    }

    // Flatten all workouts into a single list
    List<Map<String, dynamic>> allWorkouts = [];
    _workoutsByDate.forEach((date, workouts) {
      allWorkouts.addAll(workouts);
    });

    // Filter workouts based on selected tab
    List<Map<String, dynamic>> filteredWorkouts = [];

    if (_selectedTabIndex == 0) {
      // All workouts
      filteredWorkouts = allWorkouts;
    } else {
      // Filter by workout type based on the selected tab
      String filterType = '';
      switch (_selectedTabIndex) {
        case 1:
          filterType = 'HIIT';
          break;
        case 2:
          filterType = 'Strength';
          break;
        case 3:
          filterType = 'Cardio';
          break;
        case 4:
          filterType = 'Yoga';
          break;
        case 5:
          filterType = 'Core';
          break;
      }

      filteredWorkouts = allWorkouts.where((workout) {
        // Check all possible fields that might contain the workout type
        final focusArea = (workout['focusArea'] ?? '').toString().toLowerCase();
        final category = (workout['category'] ?? '').toString().toLowerCase();
        final type = (workout['type'] ?? '').toString().toLowerCase();
        final title = (workout['workoutTitle'] ?? workout['title'] ?? '')
            .toString()
            .toLowerCase();
        final name = (workout['workoutName'] ?? '').toString().toLowerCase();

        return focusArea.contains(filterType.toLowerCase()) ||
            category.contains(filterType.toLowerCase()) ||
            type.contains(filterType.toLowerCase()) ||
            title.contains(filterType.toLowerCase()) ||
            name.contains(filterType.toLowerCase());
      }).toList();
    }

    // Sort workouts by date, most recent first
    filteredWorkouts.sort((a, b) {
      final aDate =
          a['startTime'] ?? a['timestamp']?.toDate() ?? DateTime.now();
      final bDate =
          b['startTime'] ?? b['timestamp']?.toDate() ?? DateTime.now();
      return bDate.compareTo(aDate); // Descending order
    });

    // Limit to most recent 10 workouts for performance
    final displayWorkouts = filteredWorkouts.take(10).toList();

    if (displayWorkouts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.filter_list, color: Colors.grey.shade600, size: 48),
            const SizedBox(height: 16),
            Text(
              'No ${_selectedTabIndex == 0 ? '' : _getFilterTypeName(_selectedTabIndex)} workouts found',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: displayWorkouts.length,
      itemBuilder: (context, index) {
        final workout = displayWorkouts[index];

        // Get the workout title
        String title = '';
        if (workout['workoutName'] != null &&
            workout['workoutName'].toString().isNotEmpty) {
          title = workout['workoutName'].toString();
        } else if (workout['workoutTitle'] != null &&
            workout['workoutTitle'].toString().isNotEmpty) {
          title = workout['workoutTitle'].toString();
        } else if (workout['title'] != null &&
            workout['title'].toString().isNotEmpty) {
          title = workout['title'].toString();
        } else {
          title = "Unknown Workout";
        }

        // Get date and workout details
        final startTime = workout['startTime'] as DateTime?;
        final dateStr = startTime != null
            ? DateFormat('MMM d, yyyy').format(startTime)
            : 'Date unknown';

        final duration =
            workout['durationMinutes'] ?? workout['duration'] ?? 30;
        final calories = workout['caloriesBurned'] ?? (duration * 7);

        // Get workout type/category
        final focusArea = workout['focusArea'] ??
            workout['category'] ??
            workout['type'] ??
            'Workout';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade900,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey.shade800,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getActivityIcon(title),
                color: const Color(0xFF1DB954),
              ),
            ),
            title: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  '$dateStr · $duration min · $calories cal',
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade800,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                focusArea.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Helper to get the filter type name for display
  String _getFilterTypeName(int tabIndex) {
    switch (tabIndex) {
      case 1:
        return 'HIIT';
      case 2:
        return 'Strength';
      case 3:
        return 'Cardio';
      case 4:
        return 'Yoga';
      case 5:
        return 'Core';
      default:
        return '';
    }
  }
}
