// TaskMapFlow – application entry point.
// Firebase initialisation is deferred until a valid GoogleService-Info.plist
// is present. Until then, the app shows a clear setup-required state.
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_map_flow/app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  bool firebaseReady = false;
  try {
    // Will throw if GoogleService-Info.plist / google-services.json is absent.
    await Firebase.initializeApp();
    firebaseReady = true;
  } catch (e) {
    // No production Firebase project configured yet or initialization error.
    // The app renders a setup-required screen instead of a fake backend.
    debugPrint('[TaskMapFlow] Firebase initialization guard: $e');
  }

  runApp(
    ProviderScope(
      child: TaskMapFlowApp(firebaseReady: firebaseReady),
    ),
  );
}
