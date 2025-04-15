import 'package:flutter/material.dart';
import '../widgets/bottom_nav_bar.dart';

class TipsScreen extends StatefulWidget {
  final String userName;
  final String fitnessLevel;
  final String goal;
  final int height;
  final int weight;
  final String memberSince;

  const TipsScreen({
    Key? key,
    this.userName = 'Fitness Enthusiast',
    this.fitnessLevel = 'Intermediate',
    this.goal = 'Weight Loss',
    this.height = 175,
    this.weight = 68,
    this.memberSince = 'January 2023',
  }) : super(key: key);

  @override
  _TipsScreenState createState() => _TipsScreenState();
}

class _TipsScreenState extends State<TipsScreen> {
  // Mock tips data
  final List<Map<String, dynamic>> _tips = [
    {
      'title': 'Stay Hydrated',
      'description':
          'Drink at least 8 glasses of water daily to maintain optimal performance during workouts.',
      'icon': Icons.water_drop,
      'color': Colors.blue,
    },
    {
      'title': 'Proper Warm-up',
      'description':
          'Always spend 5-10 minutes warming up before intense exercise to prevent injuries.',
      'icon': Icons.whatshot,
      'color': Colors.orange,
    },
    {
      'title': 'Balanced Nutrition',
      'description':
          'Ensure your diet includes proteins, carbs, and healthy fats to fuel your workouts effectively.',
      'icon': Icons.restaurant,
      'color': Colors.green,
    },
    {
      'title': 'Rest Days Matter',
      'description':
          'Schedule 1-2 rest days per week to allow your muscles to recover and grow stronger.',
      'icon': Icons.hotel,
      'color': Colors.purple,
    },
    {
      'title': 'Track Progress',
      'description':
          'Keep a workout journal or use the app to track your progress and stay motivated.',
      'icon': Icons.trending_up,
      'color': Colors.red,
    },
    {
      'title': 'Sleep Well',
      'description':
          'Aim for 7-9 hours of quality sleep to enhance recovery and overall fitness results.',
      'icon': Icons.nightlight_round,
      'color': Colors.indigo,
    },
    {
      'title': 'Consistency is Key',
      'description':
          'Regular, consistent workouts yield better results than occasional intense sessions.',
      'icon': Icons.calendar_today,
      'color': Colors.teal,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF191414),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 3, // Tips tab
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
            // Header Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Fitness Tips & Advice',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Boost your fitness journey with expert tips',
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Tips List
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final tip = _tips[index];
                  return _buildTipCard(tip);
                },
                childCount: _tips.length,
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

  Widget _buildTipCard(Map<String, dynamic> tip) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              // Show detailed tip in a modal bottom sheet
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                builder: (context) => _buildTipDetailSheet(tip),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Tip icon
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: tip['color'].withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      tip['icon'],
                      color: tip['color'],
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Tip content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tip['title'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tip['description'],
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Arrow icon
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.grey.shade600,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTipDetailSheet(Map<String, dynamic> tip) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF191414),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Center(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade600,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Tip icon and title
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: tip['color'].withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  tip['icon'],
                  color: tip['color'],
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  tip['title'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Tip description
          Text(
            tip['description'],
            style: TextStyle(
              color: Colors.grey.shade300,
              fontSize: 16,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 30),

          // Additional information (mock data)
          const Text(
            'Why This Matters:',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Implementing this tip can significantly improve your workout efficiency and overall fitness results. Many fitness experts recommend this approach for both beginners and advanced athletes.',
            style: TextStyle(
              color: Colors.grey.shade300,
              fontSize: 16,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 30),

          // Share button
          ElevatedButton.icon(
            onPressed: () {
              // Share functionality would go here
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Tip shared successfully!'),
                  backgroundColor: Color(0xFF1DB954),
                ),
              );
            },
            icon: const Icon(Icons.share, color: Colors.black),
            label: const Text(
              'Share This Tip',
              style: TextStyle(color: Colors.black),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1DB954),
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
