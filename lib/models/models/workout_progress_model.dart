import 'package:cloud_firestore/cloud_firestore.dart';

class WorkoutProgressModel {
  final String id;
  final String userId;
  final String workoutId;
  final String workoutTitle;
  final DateTime completedDate;
  final int durationMinutes;
  final int caloriesBurned;
  final Map<String, dynamic>
      exercises; // Map of exercise name to completed reps/time
  final String userFeedback; // rating or feedback
  final DateTime? startTime; // Added start time field
  final DateTime? endTime; // Added end time field

  WorkoutProgressModel({
    required this.id,
    required this.userId,
    required this.workoutId,
    required this.workoutTitle,
    required this.completedDate,
    required this.durationMinutes,
    required this.caloriesBurned,
    required this.exercises,
    this.userFeedback = '',
    this.startTime, // Optional but recommended for time tracking
    this.endTime, // Optional but recommended for time tracking
  });

  factory WorkoutProgressModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Convert timestamp to DateTime for start and end times if they exist
    DateTime? startTime;
    if (data['startTime'] != null) {
      startTime = (data['startTime'] as Timestamp).toDate();
    }

    DateTime? endTime;
    if (data['endTime'] != null) {
      endTime = (data['endTime'] as Timestamp).toDate();
    }

    return WorkoutProgressModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      workoutId: data['workoutId'] ?? '',
      workoutTitle: data['workoutTitle'] ?? '',
      completedDate:
          (data['completedDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      durationMinutes: data['durationMinutes'] ?? 0,
      caloriesBurned: data['caloriesBurned'] ?? 0,
      exercises: data['exercises'] ?? {},
      userFeedback: data['userFeedback'] ?? '',
      startTime: startTime,
      endTime: endTime,
    );
  }

  Map<String, dynamic> toFirestore() {
    Map<String, dynamic> data = {
      'userId': userId,
      'workoutId': workoutId,
      'workoutTitle': workoutTitle,
      'completedDate': Timestamp.fromDate(completedDate),
      'durationMinutes': durationMinutes,
      'caloriesBurned': caloriesBurned,
      'exercises': exercises,
      'userFeedback': userFeedback,
    };

    // Only add start and end times if they are available
    if (startTime != null) {
      data['startTime'] = Timestamp.fromDate(startTime!);
    }

    if (endTime != null) {
      data['endTime'] = Timestamp.fromDate(endTime!);
    }

    return data;
  }
}
