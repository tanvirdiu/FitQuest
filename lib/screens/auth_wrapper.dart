import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/firebase_provider.dart';
import 'auth_screen.dart';
import 'onboarding_screen.dart';
import 'home_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final firebaseProvider = Provider.of<FirebaseProvider>(context);

    // Show loading indicator while checking auth state
    if (firebaseProvider.isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF1DB954),
          ),
        ),
      );
    }

    // If user is logged in
    if (firebaseProvider.isLoggedIn) {
      // Check if user has a profile (completed onboarding)
      if (firebaseProvider.userProfile != null) {
        // Check if onboarding is complete
        bool onboardingComplete = false;

        try {
          // Try to access the onboardingComplete flag from the userProfile
          var userData = firebaseProvider.userProfile!.toMap();
          onboardingComplete = userData['onboardingComplete'] ?? false;
        } catch (e) {
          print('Error checking onboarding status: $e');
          // Default to false if there's an error
          onboardingComplete = false;
        }

        // If onboarding is complete, go to home screen
        if (onboardingComplete) {
          return HomeScreen(
            userName: firebaseProvider.userProfile!.name,
            fitnessLevel: firebaseProvider.userProfile!.fitnessLevel,
            goal: firebaseProvider.userProfile!.fitnessGoals.isNotEmpty
                ? firebaseProvider.userProfile!.fitnessGoals.first
                : 'Weight Loss',
            height: firebaseProvider.userProfile!.height.toInt(),
            weight: firebaseProvider.userProfile!.weight.toInt(),
            memberSince: DateFormat('MMMM yyyy')
                .format(firebaseProvider.userProfile!.createdAt),
          );
        } else {
          // User is logged in but hasn't completed onboarding
          return const OnboardingScreen();
        }
      } else {
        // User is logged in but hasn't completed onboarding
        return const OnboardingScreen();
      }
    }

    // User is not logged in, show auth screen
    return const AuthScreen();
  }
}
