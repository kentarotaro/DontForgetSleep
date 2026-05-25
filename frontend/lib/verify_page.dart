import 'dart:async';

import 'package:dont_forget_sleep/theme/app_colors.dart';
import 'package:dont_forget_sleep/theme/typography.dart';
import 'package:dont_forget_sleep/widgets/primary_button.dart';
import 'package:dont_forget_sleep/core/auth_service.dart';
import 'package:dont_forget_sleep/views/get_started/onboarding_questions_screen.dart';
import 'package:flutter/material.dart';

class VerifyPage extends StatefulWidget {
  final String email;

  const VerifyPage({super.key, required this.email});

  @override
  State<VerifyPage> createState() => _VerifyPageState();
}

class _VerifyPageState extends State<VerifyPage> {
  static const int _resendSeconds = 59;

  final TextEditingController _codeController = TextEditingController();
  final AuthService _authService = AuthService();

  Timer? _resendTimer;
  int _secondsRemaining = _resendSeconds;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _startResendCountdown();
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  void _startResendCountdown() {
    _resendTimer?.cancel();
    setState(() {
      _secondsRemaining = _resendSeconds;
    });

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining <= 1) {
        timer.cancel();
        if (mounted) {
          setState(() {
            _secondsRemaining = 0;
          });
        }
        return;
      }

      if (mounted) {
        setState(() {
          _secondsRemaining -= 1;
        });
      }
    });
  }

  void _handleResendCode() {
    if (_secondsRemaining > 0) {
      return;
    }

    _authService.resendEmailVerification().then((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Verification email sent to ${widget.email}.')),
      );
      _startResendCountdown();
    });
  }

  Future<void> _handleSubmit() async {
    setState(() => _isSubmitting = true);
    final isVerified = await _authService.reloadAndCheckEmailVerified();
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (isVerified) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const OnboardingQuestionsScreen()),
        (route) => false,
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Email not verified yet. Please check your inbox and click the verification link.'),
      ),
    );
  }

  String _formatSeconds(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => Navigator.maybePop(context),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 12),
                      Text(
                        'Verify Account',
                        style: AppTextStyles.authTitle,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'A verification email has been sent to ${widget.email}.',
                        style: AppTextStyles.terms,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Open the email and tap the verification link to continue.',
                        style: AppTextStyles.terms,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),
                      Text(
                        'Enter Code',
                        style: AppTextStyles.label,
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _codeController,
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                        textAlignVertical: TextAlignVertical.center,
                        style: AppTextStyles.input,
                        decoration: InputDecoration(
                          counterText: '',
                          hintText: 'Verification code (not used)',
                          hintStyle: AppTextStyles.hint,
                          filled: true,
                          fillColor: Colors.transparent,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 17,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: Colors.white,
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: AppColors.purple800,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Center(
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              "Didn't receive the verification email? ",
                              style: AppTextStyles.terms.copyWith(
                                color: Colors.white,
                              ),
                            ),
                            GestureDetector(
                              onTap: _secondsRemaining == 0
                                  ? _handleResendCode
                                  : null,
                              child: Text(
                                'Resend Email',
                                style: AppTextStyles.link.copyWith(
                                  color: _secondsRemaining == 0
                                      ? AppColors.neutral_400
                                      : Colors.white,
                                  decorationColor: _secondsRemaining == 0
                                      ? AppColors.neutral_400
                                      : Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _secondsRemaining == 0
                            ? 'You can resend the email now.'
                            : 'Resend email in ${_formatSeconds(_secondsRemaining)}',
                        style: AppTextStyles.terms.copyWith(
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const Spacer(), // 
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: PrimaryButton(
                  onPressed: _isSubmitting ? null : _handleSubmit,
                  text: _isSubmitting ? 'Checking...' : 'I Have Verified My Email',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

