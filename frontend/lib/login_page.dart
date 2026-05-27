import 'package:dont_forget_sleep/widgets/auth_button.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:dont_forget_sleep/models/login_item.dart';
import 'package:dont_forget_sleep/theme/app_colors.dart';
import 'package:dont_forget_sleep/widgets/labeled_text_field.dart';
import 'package:dont_forget_sleep/widgets/primary_button.dart';
import 'package:dont_forget_sleep/theme/typography.dart';
import 'package:dont_forget_sleep/core/auth_service.dart';
import 'package:dont_forget_sleep/forgot_password_page.dart';
import 'package:dont_forget_sleep/verify_page.dart';
import 'package:dont_forget_sleep/main.dart';
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _loginError;

  String _friendlyAuthMessage(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'wrong-password':
          return 'Email atau password salah.';
        case 'user-not-found':
          return 'Akun tidak ditemukan.';
        case 'invalid-email':
          return 'Format email tidak valid.';
        case 'user-disabled':
          return 'Akun ini dinonaktifkan.';
        case 'account-exists-with-different-credential':
          return 'Akun ini sudah terdaftar dengan metode login lain. Coba login dengan metode yang dipakai saat daftar.';
        case 'invalid-credential':
          return 'Kredensial login tidak valid. Coba lagi.';
        case 'operation-not-allowed':
          return 'Metode login ini belum diaktifkan di Firebase.';
        case 'network-request-failed':
          return 'Koneksi internet bermasalah.';
        default:
          return error.message ?? 'Login gagal. Coba lagi.';
      }
    }

    if (error is PlatformException) {
      final details = error.message ?? error.code;
      if (details.contains('ApiException: 10') ||
          details.contains('12500') ||
          details.contains('DEVELOPER_ERROR')) {
        return 'Google Sign-In belum dikonfigurasi untuk Android. Tambahkan SHA-1/SHA-256 di Firebase Console lalu unduh ulang google-services.json.';
      }

      if (details.contains('sign_in_failed') || details.contains('GoogleSignIn')) {
        return 'Google Sign-In gagal. Cek konfigurasi Firebase Android dan koneksi internet.';
      }

      return details.isNotEmpty ? details : 'Google Sign-In gagal. Coba lagi.';
    }

    if (error is UnsupportedError) {
      return error.message ?? 'Google Sign-In belum didukung di platform ini.';
    }

    return 'Login gagal. Coba lagi.';
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _loginError = 'Login or password invalid.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _loginError = null;
    });
    UserCredential? result;
    try {
      result = await AuthService().signInWithEmail(
        email: email,
        password: password,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loginError = _friendlyAuthMessage(error);
      });
      return;
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result == null) {
      setState(() {
        _loginError = 'Login or password invalid.';
      });
      return;
    }

    setState(() {
      _loginError = null;
    });

    if (!(result.user?.emailVerified ?? false)) {
      await AuthService().resendEmailVerification();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => VerifyPage(email: email)),
      );
      return;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AuthWrapper()),
      (route) => false,
    );

    final data = LoginItem(
      email: email,
      password: password,
    );
    // ignore: avoid_print
    print('Login data: ${data.email} ${data.password}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
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
                      child: Text('Login', style: AppTextStyles.authTitle),
                    ),
                    const SizedBox(height: 32),
                    LabeledTextField(
                      label: 'E-mail',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      hintText: 'Enter your email',
                    ),
                    const SizedBox(height: 20),
                    LabeledTextField(
                      label: 'Password',
                      controller: _passwordController,
                      hintText: '••••••••••',
                      isPassword: true,
                    ),
                    if (_loginError != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _loginError!,
                        style: AppTextStyles.terms.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ForgotPasswordPage(),
                            ),
                          );
                        },
                        child: Text(
                          'Forgot Password?',
                          style: AppTextStyles.helperSmall.copyWith(
                            color: AppColors.bluePrimary,
                            decoration: TextDecoration.underline,
                            decorationColor: AppColors.bluePrimary,
                            decorationThickness: 2.0,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    PrimaryButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      text: _isLoading ? 'Loading...' : 'Login',
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  children: [
                    Center(
                      child: Text(
                        'Or login with',
                        style: AppTextStyles.terms,
                      ),
                    ),
                    const SizedBox(height: 16),
                    AuthButton(
                      isOutlined: true,
                      text: _isLoading ? 'Signing in...' : 'Login with Google',
                      onPressed: _isLoading
                          ? () {} // Use empty callback or null to avoid multiple triggers
                          : () async {
                              setState(() {
                                _isLoading = true;
                                _loginError = null;
                              });
                              try {
                                final user = await AuthService().signInWithGoogle();
                                if (user == null) {
                                  if (!context.mounted) return;
                                  setState(() {
                                    _isLoading = false;
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Google Sign-In dibatalkan.')),
                                  );
                                  return;
                                }

                                if (!context.mounted) return;
                                setState(() {
                                  _isLoading = false;
                                });
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(builder: (_) => const AuthWrapper()),
                                  (route) => false,
                                );
                              } on FirebaseAuthException catch (error) {
                                if (!context.mounted) return;
                                setState(() {
                                  _isLoading = false;
                                  _loginError = _friendlyAuthMessage(error);
                                });
                              } on PlatformException catch (error) {
                                if (!context.mounted) return;
                                setState(() {
                                  _isLoading = false;
                                  _loginError = _friendlyAuthMessage(error);
                                });
                              } on UnsupportedError catch (error) {
                                if (!context.mounted) return;
                                setState(() {
                                  _isLoading = false;
                                  _loginError = _friendlyAuthMessage(error);
                                });
                              } catch (error) {
                                if (!context.mounted) return;
                                setState(() {
                                  _isLoading = false;
                                  _loginError = _friendlyAuthMessage(error);
                                });
                              }
                            },
                      icon: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Image.asset(
                              'assets/images/googleLogo.png',
                              width: 24,
                              height: 24,
                              fit: BoxFit.contain,
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}