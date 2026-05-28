import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dont_forget_sleep/theme/app_colors.dart';
import 'package:dont_forget_sleep/models/onboard_item.dart';
import 'package:dont_forget_sleep/services/sleep_preferences_service.dart';
import 'package:dont_forget_sleep/views/get_started/get_started_screen.dart';

class OnboardingQuestionsScreen extends StatefulWidget {
  const OnboardingQuestionsScreen({super.key});

  @override
  State<OnboardingQuestionsScreen> createState() => _OnboardingQuestionsScreenState();
}

class _OnboardingQuestionsScreenState extends State<OnboardingQuestionsScreen> {
  final PageController _pageController = PageController();
  int _currentQuestionIndex = 0;
  bool _isSubmitting = false;

  // Selected values
  String? _tiredFrequency;
  String? _sleepAmount;
  final List<String> _selectedHabits = [];

  void _nextPage() {
    if (_currentQuestionIndex < 2) {
      setState(() {
        _currentQuestionIndex++;
      });
      _pageController.animateToPage(
        _currentQuestionIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
      });
      _pageController.animateToPage(
        _currentQuestionIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _submit() {
    if (_isSubmitting) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final user = FirebaseAuth.instance.currentUser;
    final habitsMapped = _selectedHabits.map((h) {
      switch (h) {
        case 'Stay up late':
          return 'stayUpLate';
        case 'Sleep with wet hair':
          return 'sleepWetHair';
        case 'Heavy food before sleep':
          return 'heavyFoodBeforeSleep';
        case 'Sleep with light on':
          return 'sleepWithLightOn';
        default:
          return 'noneOfThese';
      }
    }).toList();

    final tiredFreqMapped = (_tiredFrequency ?? 'Rarely').toLowerCase();
    final chronotype = tiredFreqMapped == 'rarely'
        ? 'morning'
        : (tiredFreqMapped == 'always' ? 'evening' : 'intermediate');

    String sleepDurationMapped = '6to8h';
    final sleepAmount = _sleepAmount ?? '6-8 hours';
    if (sleepAmount.contains('less') || sleepAmount.contains('6 hours or less')) {
      sleepDurationMapped = 'under6h';
    } else if (sleepAmount.contains('8-10') || sleepAmount.contains('8-10 hours')) {
      sleepDurationMapped = '8to10h';
    } else if (sleepAmount.contains('more') || sleepAmount.contains('10 hours or more')) {
      sleepDurationMapped = 'over10h';
    }

    sleepPreferencesService.setPersonalizationData(
      tiredFrequency: _tiredFrequency ?? 'Rarely',
      sleepAmount: _sleepAmount ?? '6-8 hours',
      habits: _selectedHabits,
    );
    sleepPreferencesService.completeOnboarding();

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const GetStartedScreen()),
        (route) => false,
      );
    }

    if (user != null) {
      unawaited(() async {
        try {
          await FirebaseFirestore.instance.collection('userProfiles').doc(user.uid).set({
            'morningTirednessFrequency': tiredFreqMapped,
            'chronotype': chronotype,
            'usualSleepDuration': sleepDurationMapped,
            'sleepHabits': habitsMapped,
            'onboardingCompleted': true,
          }, SetOptions(merge: true));
        } catch (e) {
          // ignore: avoid_print
          print('Error updating onboarding questions in Firestore: $e');
        } finally {
          if (mounted) {
            setState(() {
              _isSubmitting = false;
            });
          }
        }
      }());
      return;
    }

    if (mounted) {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Widget _buildAppLogo() {
    final onboardData = OnboardItem(image: 'assets/images/logo.png');

    return Image.asset(
      onboardData.image,
      width: 64,
      height: 64,
      fit: BoxFit.contain,
    );
  }

  Widget _buildQuestionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
          height: 1.3,
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required Widget leading,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? const  Color(0xff2C3A50): Color(0xFF2D2D2D), // Dark tile background
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF73A8FF) : Colors.transparent,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            trailing ?? const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionFour() {
    final options = [
      {'label': 'Always', 'emoji': '😫'},
      {'label': 'Usually', 'emoji': '😣'},
      {'label': 'Sometimes', 'emoji': '🧐'},
      {'label': 'Rarely', 'emoji': '😊'},
    ];

    return Column(
      children: [
        const SizedBox(height: 40),
        _buildAppLogo(),
        const SizedBox(height: 24),
        _buildQuestionTitle('How often do you wake up tired in the morning?'),
        const SizedBox(height: 48),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: options.length,
            itemBuilder: (context, index) {
              final opt = options[index];
                      final label = opt['label']!;
                      final emoji = opt['emoji']!;
              final isSelected = _tiredFrequency == label;

              return _buildOptionCard(
                leading: Text(
                  emoji,
                  style: const TextStyle(fontSize: 20),
                ),
                label: label,
                isSelected: isSelected,
                onTap: () {
                  setState(() {
                    _tiredFrequency = label;
                  });
                  Future.delayed(const Duration(milliseconds: 200), _nextPage);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionFive() {
    final options = [
    {'label': '6 hours or less', 'emoji': '🕕'},
    {'label': '6-8 hours', 'emoji': '🕖'},
    {'label': '8-10 hours', 'emoji': '🕘'},
    {'label': '10 hours or more', 'emoji': '🕙'},
    ];
   

    return Column(
      children: [
        const SizedBox(height: 40),
        _buildAppLogo(),
        const SizedBox(height: 24),
        _buildQuestionTitle('How much sleep do you usually get at night?'),
        const SizedBox(height: 48),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: options.length,
            itemBuilder: (context, index) {
              // final opt = options[index];
              final opt = options[index];
                      final label = opt['label']!;
                      final emoji = opt['emoji']!;
              final isSelected = _sleepAmount == label;

              return _buildOptionCard(
                leading: Text(
                  emoji,
                  style: const TextStyle(fontSize: 20),
                ),
                label: label,
                isSelected: isSelected,
                onTap: () {
                  setState(() {
                    _sleepAmount = label;
                  });
                  Future.delayed(const Duration(milliseconds: 200), _nextPage);
                },
                  
                  
              
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionSix() {
    final options = [
      {'label': 'Stay up late', 'emoji': '🌝'},
      {'label': 'Sleep with wet hair', 'emoji': '💦'},
      {'label': 'Heavy food before sleep', 'emoji': '🍔'},
      {'label': 'Sleep with light on', 'emoji': '💡'},
      {'label': 'None of these', 'emoji': '🚫'},
    ];

    return Column(
      children: [
        const SizedBox(height: 40),
        _buildAppLogo(),
        const SizedBox(height: 24),
        _buildQuestionTitle('Which habit do you have that may affect your sleep quality?'),
        const SizedBox(height: 48),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: options.length,
            itemBuilder: (context, index) {
              final opt = options[index];
              final label = opt['label']!;
              final emoji = opt['emoji']!;
              final isSelected = _selectedHabits.contains(label);

              return _buildOptionCard(
                leading: Text(
                  emoji,
                  style: const TextStyle(fontSize: 20),
                ),
                label: label,
                isSelected: isSelected,
                trailing: isSelected
                    ? Container(
                        width: 22,
                        height: 22,
                        decoration: const BoxDecoration(
                          color: Color(0xFF3B82F6), // blue color check
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 14,
                        ),
                      )
                    : null,
                onTap: () {
                  setState(() {
                    if (label == 'None of these') {
                      if (isSelected) {
                        _selectedHabits.remove(label);
                      } else {
                        _selectedHabits.clear();
                        _selectedHabits.add(label);
                      }
                    } else {
                      _selectedHabits.remove('None of these');
                      if (isSelected) {
                        _selectedHabits.remove(label);
                      } else {
                        _selectedHabits.add(label);
                      }
                    }
                  });
                },
              );
            },
          ),
        ),
        // Submit Button Row at the bottom
        Padding(
          padding: const EdgeInsets.only(bottom: 24.0),
          child: Center(
            child: GestureDetector(
              onTap: _isSubmitting ? null : _submit,
              child: Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: Color(0xFF3B82F6), // blue button color
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDotIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (index) {
          final isSelected = _currentQuestionIndex == index;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 4.0),
            width: 6.0,
            height: 6.0,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? Colors.white : Colors.white24,
            ),
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _currentQuestionIndex > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white70, size: 20),
                onPressed: _previousPage,
              )
            : const SizedBox.shrink(),
        title: const SizedBox.shrink(),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildQuestionFour(),
                  _buildQuestionFive(),
                  _buildQuestionSix(),
                ],
              ),
            ),
            // Hide dot indicators on page 3 (Question 6) since we have the submit button at the bottom
            if (_currentQuestionIndex < 2) _buildDotIndicator(),
          ],
        ),
      ),
    );
  }
}
