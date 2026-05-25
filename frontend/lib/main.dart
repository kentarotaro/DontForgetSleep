import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dont_forget_sleep/onboarding_page.dart';
import 'package:dont_forget_sleep/views/get_started/onboarding_questions_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
// import 'firebase_options.dart';
import'package:dont_forget_sleep/features/history/pages/sleep_history_page.dart';
import 'package:dont_forget_sleep/theme/app_colors.dart';

import 'package:dont_forget_sleep/navbar.dart';
import 'package:dont_forget_sleep/services/sleep_preferences_service.dart';
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    if (kIsWeb) {
      // Skip default web Firebase initialization when no FirebaseOptions are provided
      // (this project doesn't include generated firebase_options.dart).
      // This avoids the "FirebaseOptions cannot be null" assertion during web runs.
      // Remove this guard and provide proper options when configuring Firebase for web.
      // ignore: avoid_print
      print('Running on web: skipping Firebase.initializeApp() (no web options)');
    } else {
      await Firebase.initializeApp();
    }
  } catch (e, st) {
    // Log but continue so UI can show even if Firebase isn't configured yet
    // ignore: avoid_print
    print('Firebase initialization failed: $e');
    // ignore: avoid_print
    print(st);
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return MaterialApp(
      title: 'DFS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.scaffoldBg,
        
      ),
      home: 
      // currentUser == null || !(currentUser.emailVerified)
      //     ? const OnboardingPage()
      //     : (sleepPreferencesService.hasCompletedOnboarding
      //           ? const HomePage()
      //           : const OnboardingQuestionsScreen()),
      const SleepHistoryPage(),
    );
  }
}

