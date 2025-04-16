import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fitness_quest/services/firestore_service.dart';
import 'package:fitness_quest/models/user_model.dart';
import 'dart:async';

class FirebaseProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();

  User? _user;
  UserModel? _userProfile;
  bool _isLoading = false;

  FirebaseProvider() {
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      if (user != null) {
        _loadUserProfile();
      } else {
        _userProfile = null;
      }
      notifyListeners();
    });
  }

  User? get user => _user;
  UserModel? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null;

  Future<void> _loadUserProfile() async {
    if (_user == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      // Online mode - use Firebase
      DocumentSnapshot userDoc =
          await _firestoreService.getUserProfile(_user!.uid);
      if (userDoc.exists) {
        _userProfile = UserModel.fromFirestore(userDoc);
      }
    } catch (e) {
      print('Error loading user profile: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Auth methods
  Future<UserCredential> signUp(
      String email, String password, Map<String, dynamic> userData) async {
    try {
      _isLoading = true;
      notifyListeners();

      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Add user data to Firestore
        await _firestoreService.createUser(credential.user!.uid, {
          ...userData,
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
        });

        await _loadUserProfile();
      }

      return credential;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<UserCredential> signIn(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Error during sign out: $e');
      rethrow;
    }
  }

  // User data methods
  Future<void> updateUserProfile(Map<String, dynamic> data) async {
    if (_user == null) return;

    try {
      _isLoading = true;
      notifyListeners();

      // Update Firebase user data
      await _firestoreService.updateUserProfile(_user!.uid, data);
      await _loadUserProfile();
    } catch (e) {
      print('Error updating user profile: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Workout methods
  Future<List<QueryDocumentSnapshot>> getWorkouts() async {
    try {
      return await _firestoreService.getWorkouts();
    } catch (e) {
      print('Error getting workouts: $e');
      rethrow;
    }
  }

  Future<void> saveWorkoutProgress(Map<String, dynamic> progressData) async {
    if (_user == null) return;

    try {
      // Ensure we have start and end time in the workout data
      if (!progressData.containsKey('startTime')) {
        // If no start time is provided, use current time
        progressData['startTime'] = Timestamp.now();
      }

      if (!progressData.containsKey('endTime')) {
        // If no end time is provided, calculate it from duration
        final startTime = progressData['startTime'] is Timestamp
            ? (progressData['startTime'] as Timestamp).toDate()
            : DateTime.now();

        final duration =
            progressData['durationMinutes'] ?? progressData['duration'] ?? 30;
        final endTime = startTime.add(Duration(minutes: duration));
        progressData['endTime'] = Timestamp.fromDate(endTime);
      }

      // Always include a completedDate for compatibility
      if (!progressData.containsKey('completedDate')) {
        progressData['completedDate'] = progressData['startTime'];
      }

      await _firestoreService.saveWorkoutProgress(_user!.uid, progressData);
    } catch (e) {
      print('Error saving workout progress: $e');
      rethrow;
    }
  }

  Future<List<QueryDocumentSnapshot>> getWorkoutHistory() async {
    if (_user == null) return [];

    try {
      return await _firestoreService.getUserWorkoutHistory(_user!.uid);
    } catch (e) {
      print('Error getting workout history: $e');
      return [];
    }
  }

  // Get workout history as a List<Map> for easier handling
  Future<List<Map<String, dynamic>>> getWorkoutHistoryAsMaps() async {
    try {
      final snapshots = await getWorkoutHistory();
      return snapshots
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print('Error getting workout history as maps: $e');
      return [];
    }
  }

  // Get a specific workout by ID
  Future<DocumentSnapshot?> getWorkoutById(String workoutId) async {
    try {
      return await _firestoreService.getWorkoutById(workoutId);
    } catch (e) {
      print('Error getting workout by ID: $e');
      return null;
    }
  }

  // User fitness stats methods
  Future<void> updateUserStats(Map<String, dynamic> statsData) async {
    if (_user == null) return;

    try {
      await _firestoreService.updateUserStats(_user!.uid, statsData);
    } catch (e) {
      print('Error updating user stats: $e');
      rethrow;
    }
  }

  Future<DocumentSnapshot?> getUserStats() async {
    if (_user == null) return null;

    try {
      return await _firestoreService.getUserStats(_user!.uid);
    } catch (e) {
      print('Error getting user stats: $e');
      return null;
    }
  }

  // Get user stats as a Map for easier handling
  Future<Map<String, dynamic>> getUserStatsAsMap() async {
    try {
      final snapshot = await getUserStats();
      if (snapshot != null && snapshot.exists) {
        return snapshot.data() as Map<String, dynamic>;
      }
      return {};
    } catch (e) {
      print('Error getting user stats as map: $e');
      return {};
    }
  }

  // Fitness tips methods
  Future<List<QueryDocumentSnapshot>> getFitnessTips() async {
    try {
      return await _firestoreService.getFitnessTips();
    } catch (e) {
      print('Error getting fitness tips: $e');
      return [];
    }
  }
}
