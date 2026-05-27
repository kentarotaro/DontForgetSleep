import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dont_forget_sleep/theme/app_colors.dart';
import 'package:dont_forget_sleep/theme/typography.dart';
import 'package:dont_forget_sleep/widgets/primary_button.dart';
import 'package:dont_forget_sleep/widgets/labeled_text_field.dart';

class NewPassword extends StatefulWidget {
  final String? email;

  const NewPassword({super.key, this.email});

  @override
  State<NewPassword> createState() => _NewPasswordState();
}

class _NewPasswordState extends State<NewPassword> {
  final TextEditingController _resetCodeCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  final TextEditingController _confirmCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _resetCodeCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  String _extractOobCode(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return '';

    final parsed = Uri.tryParse(trimmed);
    if (parsed != null && parsed.hasQuery) {
      final queryCode = parsed.queryParameters['oobCode'];
      if (queryCode != null && queryCode.isNotEmpty) {
        return queryCode;
      }
    }

    if (trimmed.contains('oobCode=')) {
      final uri = Uri.tryParse(trimmed);
      if (uri != null) {
        final queryCode = uri.queryParameters['oobCode'];
        if (queryCode != null && queryCode.isNotEmpty) {
          return queryCode;
        }
      }
    }

    return trimmed;
  }

  Future<void> _handleReset() async {
    final code = _extractOobCode(_resetCodeCtrl.text);
    final password = _passwordCtrl.text;
    final confirm = _confirmCtrl.text;

    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reset code or link is required.')),
      );
      return;
    }

    if (password.isEmpty || confirm.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill both password fields.')),
      );
      return;
    }

    if (password != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match.')),
      );
      return;
    }

    if (password.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 8 characters.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseAuth.instance.confirmPasswordReset(
        code: code,
        newPassword: password,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset successfully. Please login again.')),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Reset password failed.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reset password failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => Navigator.maybePop(context),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                ),
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  const SizedBox(height: 4),
                  Center(
                    child: Text('Create New Password', style: AppTextStyles.authTitle),
                  ),
                  const SizedBox(height: 8),

                  Text(
                    widget.email == null
                        ? 'Please enter the reset code from your email, then create a new password.'
                        : 'We sent a reset link to ${widget.email}. Open the email, copy the reset link or code, then create a new password.',
                    style: AppTextStyles.terms,
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 24),

                  LabeledTextField(
                    label: 'Reset code or link',
                    controller: _resetCodeCtrl,
                    hintText: 'Paste the code or full reset link',
                    keyboardType: TextInputType.url,
                  ),

                  const SizedBox(height: 16),

                  LabeledTextField(
                    label: 'Password',
                    controller: _passwordCtrl,
                    hintText: '••••••••••',
                    isPassword: true,
                    helperText: 'must contain 8 char.',
                  ),

                  const SizedBox(height: 16),

                  LabeledTextField(
                    label: 'Confirm Password',
                    controller: _confirmCtrl,
                    hintText: '••••••••••',
                    isPassword: true,
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),

            // Bottom button area
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: PrimaryButton(
                onPressed: _isLoading ? null : _handleReset,
                text: _isLoading ? 'Resetting...' : 'Reset Password',
              ),
            ),
          ],
        ),
      ),
    );
  }
}