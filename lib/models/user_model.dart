import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String profileImageUrl;
  final int age;
  final double height; // in cm
  final double weight; // in kg
  final String fitnessLevel; // beginner, intermediate, advanced
  final List<String> fitnessGoals;
  final DateTime createdAt;
  final bool onboardingComplete; // Track whether onboarding is complete

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.profileImageUrl = '',
    required this.age,
    required this.height,
    required this.weight,
    required this.fitnessLevel,
    required this.fitnessGoals,
    required this.createdAt,
    this.onboardingComplete = false,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      profileImageUrl: data['profileImageUrl'] ?? '',
      age: data['age'] ?? 0,
      height: (data['height'] ?? 0).toDouble(),
      weight: (data['weight'] ?? 0).toDouble(),
      fitnessLevel: data['fitnessLevel'] ?? 'beginner',
      fitnessGoals: List<String>.from(data['fitnessGoals'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      onboardingComplete: data['onboardingComplete'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'profileImageUrl': profileImageUrl,
      'age': age,
      'height': height,
      'weight': weight,
      'fitnessLevel': fitnessLevel,
      'fitnessGoals': fitnessGoals,
      'createdAt': Timestamp.fromDate(createdAt),
      'onboardingComplete': onboardingComplete,
    };
  }

  // Helper method to get model as map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'profileImageUrl': profileImageUrl,
      'age': age,
      'height': height,
      'weight': weight,
      'fitnessLevel': fitnessLevel,
      'fitnessGoals': fitnessGoals,
      'createdAt': createdAt,
      'onboardingComplete': onboardingComplete,
    };
  }
}
