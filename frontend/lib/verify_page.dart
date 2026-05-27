import 'dart:async';

import 'package:dont_forget_sleep/theme/app_colors.dart';
import 'package:dont_forget_sleep/theme/typography.dart';
import 'package:dont_forget_sleep/widgets/primary_button.dart';
import 'package:dont_forget_sleep/core/auth_service.dart';
import 'package:dont_forget_sleep/main.dart';
import 'package:flutter/material.dart';

class VerifyPage extends StatefulWidget {
  final String email;

  const VerifyPage({super.key, required this.email});

  @override
  State<VerifyPage> createState() => _VerifyPageState();
}

class _VerifyPageState extends State<VerifyPage> {
  static const int _resendSeconds = 59;
  static const Duration _pollInterval = Duration(seconds: 5);

  final AuthService _authService = AuthService();

  Timer? _resendTimer;
  Timer? _verificationTimer;
  int _secondsRemaining = _resendSeconds;
  bool _isSubmitting = false;
  bool _isCheckingVerification = false;
  bool _hasNavigatedAway = false;

  @override
  void initState() {
    super.initState();
    _startResendCountdown();
    _startVerificationPolling();
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _verificationTimer?.cancel();
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

  void _startVerificationPolling() {
    _verificationTimer?.cancel();
    _verificationTimer = Timer.periodic(_pollInterval, (_) {
      if (!mounted || _hasNavigatedAway || _isCheckingVerification) {
        return;
      }
      _checkVerification(silent: true);
    });
  }

  Future<void> _checkVerification({bool silent = false}) async {
    if (_isCheckingVerification || _hasNavigatedAway) {
      return;
    }

    setState(() => _isCheckingVerification = true);
    final isVerified = await _authService.reloadAndCheckEmailVerified();
    if (!mounted || _hasNavigatedAway) return;
    setState(() => _isCheckingVerification = false);

    if (isVerified) {
      _hasNavigatedAway = true;
      _verificationTimer?.cancel();
      _resendTimer?.cancel();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AuthWrapper()),
        (route) => false,
      );
      return;
    }

    if (!silent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email not verified yet. Please open the link in your inbox.'),
        ),
      );
    }
  }

  Future<void> _handleResendCode() async {
    if (_secondsRemaining > 0) {
      return;
    }

    try {
      await _authService.resendEmailVerification();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Verification email sent to ${widget.email}.')),
      );
      _startResendCountdown();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not resend the email. Please try again.'),
        ),
      );
    }
  }

  Future<void> _handleSubmit() async {
    setState(() => _isSubmitting = true);
    try {
      await _checkVerification();
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
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
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Next step',
                              style: AppTextStyles.label.copyWith(color: Colors.white),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Open the email we sent, tap the verification link, then come back here. This screen checks automatically every few seconds.',
                              style: AppTextStyles.terms.copyWith(color: Colors.white),
                            ),
                          ],
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
                      const SizedBox(height: 8),
                      Text(
                        _isCheckingVerification ? 'Checking verification status...' : 'Waiting for your email confirmation.',
                        style: AppTextStyles.terms.copyWith(color: Colors.white70),
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

