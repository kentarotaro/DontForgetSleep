import 'package:flutter/material.dart';
import 'package:dont_forget_sleep/theme/typography.dart';
import 'package:dont_forget_sleep/widgets/labeled_text_field.dart';
import 'package:dont_forget_sleep/widgets/primary_button.dart';
import 'package:dont_forget_sleep/models/forgot_password_item.dart';
import 'package:dont_forget_sleep/core/auth_service.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email is required.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.sendPasswordResetEmail(email);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password reset link sent to $email.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send reset link. Please try again.')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }

    final data = ForgotPasswordItem(
      email: email,
    );
    // ignore: avoid_print
    print('Forgot Password data: ${data.email}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
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
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    const SizedBox(height: 4),
                    Center(
                      child:
                          Text('Forgot Password', style: AppTextStyles.authTitle),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No worries! Enter your email address below and we will send you a reset link.',
                      style: AppTextStyles.terms,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    LabeledTextField(
                      label: 'Email',
                      hintText: 'Enter your email',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 32),
                    
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  children: [
                    
                    PrimaryButton(
                      onPressed: _isLoading ? null : _handleSubmit,
                      text: _isLoading ? 'Sending...' : 'Send Reset Link',
                    ),

                  ]
                  
                )
              )
            ],
          ),
        ),
      ),
    );
  }
}