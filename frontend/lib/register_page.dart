import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dont_forget_sleep/models/register_item.dart';
import 'package:dont_forget_sleep/widgets/labeled_text_field.dart';
import 'package:dont_forget_sleep/widgets/name_row.dart';
import 'package:dont_forget_sleep/widgets/primary_button.dart';
import 'package:dont_forget_sleep/core/auth_service.dart';
import 'package:dont_forget_sleep/verify_page.dart';

import 'package:dont_forget_sleep/theme/typography.dart';
import 'package:dont_forget_sleep/theme/app_colors.dart';
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
    bool _isLoading = false;
  String? _formError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool get _hasPasswordMismatch {
    final password = _passwordController.text;
    final confirm = _confirmController.text;
    return confirm.isNotEmpty && password != confirm;
  }

  bool get _isEmailValid {
    final email = _emailController.text.trim();
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
  }

  void _onPasswordFieldChanged() {
    if (mounted) {
      setState(() {
        _passwordError = null;
        _confirmPasswordError = null;
      });
    }
  }

  void _onEmailFieldChanged() {
    if (mounted && _emailError != null && _isEmailValid) {
      setState(() {
        _emailError = null;
      });
    }
  }

  void _clearInlineErrors() {
    _formError = null;
    _emailError = null;
    _passwordError = null;
    _confirmPasswordError = null;
  }

  void _applyRegisterError(Object error) {
    _clearInlineErrors();

    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'email-already-in-use':
          _emailError = 'Email already in use. Try login or use another email.';
          return;
        case 'invalid-email':
          _emailError = 'Email format is invalid.';
          return;
        case 'operation-not-allowed':
          _formError = 'Email/password sign-up is not enabled in Firebase.';
          return;
        case 'weak-password':
          _passwordError = 'Password is too weak.';
          return;
        case 'network-request-failed':
          _formError = 'Network error. Check your internet connection.';
          return;
        case 'too-many-requests':
          _formError = 'Too many attempts. Please try again later.';
          return;
        default:
          _formError = error.message ?? 'Registration failed. Please try again.';
          return;
      }
    }

    _formError = 'Registration failed. Please try again.';
  }

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_onEmailFieldChanged);
    _passwordController.addListener(_onPasswordFieldChanged);
    _confirmController.addListener(_onPasswordFieldChanged);
  }

  @override
  void dispose() {
    _emailController.removeListener(_onEmailFieldChanged);
    _passwordController.removeListener(_onPasswordFieldChanged);
    _confirmController.removeListener(_onPasswordFieldChanged);
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmController.text;

    setState(() {
      _clearInlineErrors();
    });

    if (firstName.isEmpty || lastName.isEmpty) {
      setState(() {
        _formError = 'First name and last name are required.';
      });
      return;
    }

    if (email.isEmpty) {
      setState(() {
        _emailError = 'Email is required.';
      });
      return;
    }

    if (password.isEmpty) {
      setState(() {
        _passwordError = 'Password is required.';
      });
      return;
    }

    if (confirmPassword.isEmpty) {
      setState(() {
        _confirmPasswordError = 'Confirm password is required.';
      });
      return;
    }

    if (password.length < 8) {
      setState(() {
        _passwordError = 'Password must contain 8 characters.';
      });
      return;
    }

    if (password != confirmPassword) {
      setState(() {
        _confirmPasswordError = 'Password confirmation does not match.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _clearInlineErrors();
    });

    UserCredential? result;
    try {
      result = await AuthService().registerWithEmail(
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
      );
    } catch (error) {
      if (!mounted) return;
      // Log and show the raw error briefly for debugging.
      // We'll keep the user-friendly inline field mapping via _applyRegisterError,
      // but also expose a short debug message so the cause is clear during testing.
      // ignore: avoid_print
      print('Register error: $error');
      setState(() {
        _isLoading = false;
        _applyRegisterError(error);
        if (_formError == null) {
          if (error is FirebaseAuthException) {
            _formError = '${error.code}: ${error.message ?? ''}';
          } else {
            _formError = error.toString();
          }
        }
      });
      return;
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result == null) {
      setState(() {
        _formError = 'Registration failed. Please try again.';
      });
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => VerifyPage(email: email)),
    );

    final data = RegisterItem(
      firstName: firstName,
      lastName: lastName,
      email: email,
      password: password,
    );
    // ignore: avoid_print
    print('Register data: ${data.firstName} ${data.lastName} ${data.email}');
  }

  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: AppColors.scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            // Back button row
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

            // Scrollable content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  const SizedBox(height: 4),

                  // Title
                   Center(
                    child: Text(
                      'Register',
                      style: AppTextStyles.authTitle,
                    ),
                  ),

                  const SizedBox(height: 32),

                  NameRow(
                    firstController: _firstNameController,
                    lastController: _lastNameController,
                  ),
                  if (_formError != null) ...[
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text(
                        _formError!,
                        style: AppTextStyles.terms.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // E-mail
                  LabeledTextField(
                    key: const ValueKey('register_email'),
                    label: 'E-mail',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    hintText: 'Enter your email',
                  ),
                  if (_emailError != null) ...[
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text(
                        _emailError!,
                        style: AppTextStyles.terms.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Password
                  LabeledTextField(
                    key: const ValueKey('register_password'),
                    label: 'Password',
                    controller: _passwordController,
                    hintText: '••••••••••',
                    isPassword: true,
                    helperText: 'must contain 8 char.',
                  ),
                  if (_passwordError != null) ...[
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text(
                        _passwordError!,
                        style: AppTextStyles.terms.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16 ),

                  // Confirm Password
                  LabeledTextField(
                    key: const ValueKey('register_confirm'),
                    label: 'Confirm Password',
                    controller: _confirmController,
                    hintText: '••••••••••',
                    isPassword: true,
                  ),
                  if (_hasPasswordMismatch && _confirmPasswordError == null) ...[
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text(
                        'Password confirmation does not match.',
                        style: AppTextStyles.terms.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                  if (_confirmPasswordError != null) ...[
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text(
                        _confirmPasswordError!,
                        style: AppTextStyles.terms.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                children: [
                  PrimaryButton(
                    onPressed: _isLoading ? null : _handleRegister,
                    text: _isLoading ? 'Creating...' : 'Create Account',
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: AppTextStyles.terms,
                        children: [
                          const TextSpan(text: 'By continuing, you agree to our '),
                          TextSpan(
                            text: 'Terms of Service',
                            style: AppTextStyles.link,
                            recognizer: TapGestureRecognizer()..onTap = () {},
                          ),
                          const TextSpan(text: ' and\n'),
                          TextSpan(
                            text: 'Privacy Policy',
                            style: AppTextStyles.link,
                            recognizer: TapGestureRecognizer()..onTap = () {},
                          ),
                          const TextSpan(text: '.'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}