import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class FirebaseDebugScreen extends StatefulWidget {
  const FirebaseDebugScreen({Key? key}) : super(key: key);

  @override
  _FirebaseDebugScreenState createState() => _FirebaseDebugScreenState();
}

class _FirebaseDebugScreenState extends State<FirebaseDebugScreen> {
  String _status = "Checking Firebase status...";
  bool _isLoading = true;
  String _error = "";

  @override
  void initState() {
    super.initState();
    _checkFirebaseStatus();
  }

  Future<void> _checkFirebaseStatus() async {
    try {
      // Check if Firebase is initialized
      bool isInitialized = Firebase.apps.isNotEmpty;
      setState(() {
        _status = "Firebase initialized: $isInitialized\n";
        if (isInitialized) {
          _status += "Number of Firebase apps: ${Firebase.apps.length}\n";
          _status += "App name: ${Firebase.app().name}\n";
          _status += "Options available: ${Firebase.app().options != null}\n";

          _status += "\nFirebase Options:\n";
          _status += "API Key: ${Firebase.app().options.apiKey}\n";
          _status += "App ID: ${Firebase.app().options.appId}\n";
          _status += "Project ID: ${Firebase.app().options.projectId}\n";
          _status +=
              "Messaging Sender ID: ${Firebase.app().options.messagingSenderId}\n";
                }
      });

      // Try a test authentication operation
      try {
        final methods = await FirebaseAuth.instance
            .fetchSignInMethodsForEmail('test@example.com');
        setState(() {
          _status += "\nFetch sign-in methods test: SUCCESS\n";
          _status +=
              "Available methods: ${methods.isEmpty ? 'None (which is expected for a test email)' : methods.join(', ')}\n";
        });
      } catch (e) {
        setState(() {
          _status += "\nFetch sign-in methods test: FAILED\n";
          _status += "Error: $e\n";
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title:
            const Text('Firebase Debug', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.grey[900],
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _isLoading = true;
                _status = "Checking Firebase status...";
                _error = "";
              });
              _checkFirebaseStatus();
            },
          )
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1DB954)))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Firebase Status',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_error.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(8),
                      color: Colors.red.withOpacity(0.2),
                      width: double.infinity,
                      child: Text(
                        'Error: $_error',
                        style: const TextStyle(color: Colors.red),
                      ),
                    )
                  else
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        color: Colors.grey[850],
                        width: double.infinity,
                        child: SingleChildScrollView(
                          child: Text(
                            _status,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1DB954),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Back to Login'),
                  ),
                ],
              ),
            ),
    );
  }
}
