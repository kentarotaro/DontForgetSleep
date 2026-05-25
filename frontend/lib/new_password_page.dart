import 'package:flutter/material.dart';
import 'package:dont_forget_sleep/theme/app_colors.dart';
import 'package:dont_forget_sleep/theme/typography.dart';
import 'package:dont_forget_sleep/widgets/primary_button.dart';
import 'package:dont_forget_sleep/widgets/labeled_text_field.dart';

class NewPassword extends StatefulWidget {
  const NewPassword({super.key});

  @override
  State<NewPassword> createState() => _NewPasswordState();
}

class _NewPasswordState extends State<NewPassword> {
  final TextEditingController _passwordCtrl = TextEditingController();
  final TextEditingController _confirmCtrl = TextEditingController();

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
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
                    'Please enter and confirm your new password.\nYou will need to login after you reset.',
                    style: AppTextStyles.terms,
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 24),

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
                onPressed: () {
                  // UI-only for now: simply pop back or show snackbar
                  if (Navigator.of(context).canPop()) Navigator.of(context).pop();
                },
                text: 'Reset Password',
              ),
            ),
          ],
        ),
      ),
    );
  }
}