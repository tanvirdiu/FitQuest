import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/workout_catalog_screen.dart';
import '../screens/progress_screen.dart';
import '../screens/tips_screen.dart';
import '../screens/profile_screen.dart';

class BottomNavBar extends StatefulWidget {
  final int currentIndex;
  final String userName;
  final String fitnessLevel;
  final String goal;
  final int height;
  final int weight;
  final String memberSince;

  const BottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.userName,
    this.fitnessLevel = 'Intermediate',
    this.goal = 'Weight Loss',
    this.height = 170,
    this.weight = 70,
    this.memberSince = 'January 2023',
  }) : super(key: key);

  @override
  _BottomNavBarState createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 5,
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: widget.currentIndex,
        onTap: (index) => _onItemTapped(context, index),
        backgroundColor: Colors.grey.shade900,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF1DB954),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: 'Workouts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Progress',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.lightbulb_outline),
            label: 'Tips',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  void _onItemTapped(BuildContext context, int index) {
    // Don't navigate if we're already on the selected tab
    if (index == widget.currentIndex) return;

    // Navigate based on the selected tab
    if (index == 4) {
      // Profile tab
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ProfileScreen(
            userName: widget.userName,
            fitnessLevel: widget.fitnessLevel,
            goal: widget.goal,
            height: widget.height,
            weight: widget.weight,
            memberSince: widget.memberSince,
          ),
        ),
      );
    } else if (index == 3) {
      // Tips tab
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => TipsScreen(
            userName: widget.userName,
            fitnessLevel: widget.fitnessLevel,
            goal: widget.goal,
            height: widget.height,
            weight: widget.weight,
            memberSince: widget.memberSince,
          ),
        ),
      );
    } else if (index == 2) {
      // Progress tab
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ProgressScreen(
            userName: widget.userName,
            fitnessLevel: widget.fitnessLevel,
            goal: widget.goal,
            height: widget.height,
            weight: widget.weight,
            memberSince: widget.memberSince,
          ),
        ),
      );
    } else if (index == 1) {
      // Workouts tab
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => WorkoutCatalogScreen(
            userName: widget.userName,
            goal: widget.goal,
            fitnessLevel: widget.fitnessLevel,
            height: widget.height,
            weight: widget.weight,
            memberSince: widget.memberSince,
          ),
        ),
      );
    } else {
      // Home tab
      Navigator.pushReplacement(
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
      );
    }
  }
}
