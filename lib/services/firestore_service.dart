import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // User related methods
  Future<void> createUser(String userId, Map<String, dynamic> userData) async {
    await _firestore.collection('users').doc(userId).set(userData);
  }

  Future<DocumentSnapshot> getUserProfile(String userId) async {
    return await _firestore.collection('users').doc(userId).get();
  }

  Future<void> updateUserProfile(
      String userId, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(userId).update(data);
  }

  // Workout related methods
  Future<List<QueryDocumentSnapshot>> getWorkouts() async {
    QuerySnapshot snapshot = await _firestore.collection('workouts').get();
    return snapshot.docs;
  }

  Future<DocumentSnapshot> getWorkoutById(String workoutId) async {
    return await _firestore.collection('workouts').doc(workoutId).get();
  }

  // User workout progress methods
  Future<void> saveWorkoutProgress(
      String userId, Map<String, dynamic> progressData) async {
    print("FirestoreService: Saving workout progress for user $userId");
    print("FirestoreService: Progress data: $progressData");

    try {
      DocumentReference docRef = await _firestore
          .collection('users')
          .doc(userId)
          .collection('workout_history')
          .add({
        ...progressData,
        'timestamp': FieldValue.serverTimestamp(),
      });

      print("FirestoreService: Workout saved with document ID: ${docRef.id}");
    } catch (e) {
      print("FirestoreService: Error saving workout progress: $e");
      rethrow;
    }
  }

  Future<List<QueryDocumentSnapshot>> getUserWorkoutHistory(
      String userId) async {
    print("FirestoreService: Getting workout history for user $userId");
    
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('workout_history')
          .orderBy('timestamp', descending: true)
          .get();
          
      print("FirestoreService: Found ${snapshot.docs.length} workout history items");
      
      // Print some details of each item for debugging
      if (snapshot.docs.isNotEmpty) {
        for (var doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          print("FirestoreService: Workout history item ID ${doc.id}: ${data['workoutName'] ?? 'Unknown'}");
        }
      } else {
        print("FirestoreService: No workout history found");
      }
      
      return snapshot.docs;
    } catch (e) {
      print("FirestoreService: Error getting workout history: $e");
      rethrow;
    }
  }

  // User fitness stats methods
  Future<void> updateUserStats(
      String userId, Map<String, dynamic> statsData) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('fitness_stats')
        .doc('current')
        .set(statsData, SetOptions(merge: true));
  }

  Future<DocumentSnapshot> getUserStats(String userId) async {
    return await _firestore
        .collection('users')
        .doc(userId)
        .collection('fitness_stats')
        .doc('current')
        .get();
  }

  // Fitness tips methods
  Future<List<QueryDocumentSnapshot>> getFitnessTips() async {
    QuerySnapshot snapshot = await _firestore.collection('fitness_tips').get();
    return snapshot.docs;
  }
}
