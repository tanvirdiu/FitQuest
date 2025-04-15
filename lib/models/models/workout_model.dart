import 'package:cloud_firestore/cloud_firestore.dart';

class WorkoutModel {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String difficulty; // beginner, intermediate, advanced
  final int durationMinutes;
  final List<String> categories; // cardio, strength, yoga, etc.
  final List<WorkoutExercise> exercises;
  final int caloriesBurned;

  WorkoutModel({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.difficulty,
    required this.durationMinutes,
    required this.categories,
    required this.exercises,
    required this.caloriesBurned,
  });

  factory WorkoutModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    List<WorkoutExercise> exerciseList = [];
    if (data['exercises'] != null) {
      for (var exercise in data['exercises']) {
        exerciseList.add(WorkoutExercise.fromMap(exercise));
      }
    }

    return WorkoutModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      difficulty: data['difficulty'] ?? 'beginner',
      durationMinutes: data['durationMinutes'] ?? 0,
      categories: List<String>.from(data['categories'] ?? []),
      exercises: exerciseList,
      caloriesBurned: data['caloriesBurned'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'difficulty': difficulty,
      'durationMinutes': durationMinutes,
      'categories': categories,
      'exercises': exercises.map((e) => e.toMap()).toList(),
      'caloriesBurned': caloriesBurned,
    };
  }
}

class WorkoutExercise {
  final String name;
  final String description;
  final String imageUrl;
  final String videoUrl;
  final int durationSeconds; // duration in seconds or number of reps
  final bool isTimeBased; // if false, then it's rep-based

  WorkoutExercise({
    required this.name,
    required this.description,
    this.imageUrl = '',
    this.videoUrl = '',
    required this.durationSeconds,
    required this.isTimeBased,
  });

  factory WorkoutExercise.fromMap(Map<String, dynamic> map) {
    return WorkoutExercise(
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      videoUrl: map['videoUrl'] ?? '',
      durationSeconds: map['durationSeconds'] ?? 0,
      isTimeBased: map['isTimeBased'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'videoUrl': videoUrl,
      'durationSeconds': durationSeconds,
      'isTimeBased': isTimeBased,
    };
  }
}
