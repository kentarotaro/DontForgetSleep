import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dont_forget_sleep/onboarding_page.dart';
import 'package:dont_forget_sleep/views/get_started/onboarding_questions_screen.dart';
import 'package:dont_forget_sleep/views/get_started/get_started_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:dont_forget_sleep/theme/app_colors.dart';

import 'package:dont_forget_sleep/navbar.dart';
import 'package:dont_forget_sleep/services/sleep_preferences_service.dart';

import 'package:dont_forget_sleep/services/notification_service.dart';
import 'package:dont_forget_sleep/views/splash/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notifications
  await notificationService.init();
  await notificationService.requestPermissions();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
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
    return MaterialApp(
      title: 'DFS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.scaffoldBg,
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  StreamSubscription<User?>? _authSub;
  User? _currentUser;
  bool _isAuthLoading = true;
  bool _isProfileLoading = false;
  String? _lastLoadedProfileUid;

  Future<void> _loadProfileForUser(String uid) async {
    try {
      await sleepPreferencesService.loadFromFirestore(uid);
    } finally {
      if (mounted) {
        setState(() {
          _isProfileLoading = false;
        });
      }
    }
  }

  Future<void> _handleAuthChanged(User? user) async {
    if (!mounted) return;

    setState(() {
      _currentUser = user;
      _isAuthLoading = false;
    });

    if (user != null && user.emailVerified) {
      // Only reload profile when switching account, not on duplicate auth events.
      if (_lastLoadedProfileUid != user.uid) {
        setState(() {
          _isProfileLoading = true;
        });
        _lastLoadedProfileUid = user.uid;
        await _loadProfileForUser(user.uid);
      }
    } else {
      _lastLoadedProfileUid = null;
      sleepPreferencesService.reset();
      if (mounted) {
        setState(() {
          _isProfileLoading = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();

    final initialUser = FirebaseAuth.instance.currentUser;
    _currentUser = initialUser;
    _isAuthLoading = false;

    if (initialUser != null && initialUser.emailVerified) {
      _isProfileLoading = true;
      _lastLoadedProfileUid = initialUser.uid;
      _loadProfileForUser(initialUser.uid);
    } else {
      sleepPreferencesService.reset();
    }

    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      _handleAuthChanged(user);
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isAuthLoading || _isProfileLoading) {
      return const DfsSplashScreen();
    }

    final user = _currentUser;
    if (user == null || !user.emailVerified) {
      return const OnboardingPage();
    }

    return ListenableBuilder(
      listenable: sleepPreferencesService,
      builder: (context, snapshot) {
        if (sleepPreferencesService.hasCompletedSettings) {
          return const HomePage();
        } else if (sleepPreferencesService.hasCompletedOnboarding) {
          return const GetStartedScreen();
        } else {
          return const OnboardingQuestionsScreen();
        }
      },
    );
  }
}

