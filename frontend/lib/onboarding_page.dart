import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:dont_forget_sleep/theme/app_colors.dart';
import '../models/onboard_item.dart';
import '../widgets/auth_button.dart';
import 'package:dont_forget_sleep/core/auth_service.dart';
import 'package:dont_forget_sleep/register_page.dart';
import 'package:dont_forget_sleep/login_page.dart';
import 'package:dont_forget_sleep/main.dart';
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  bool _isLoading = false;

  String _friendlyAuthMessage(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'account-exists-with-different-credential':
          return 'Akun ini sudah terdaftar dengan metode login lain. Coba login dengan metode yang dipakai saat daftar.';
        case 'invalid-credential':
          return 'Kredensial Google tidak valid. Coba lagi.';
        case 'operation-not-allowed':
          return 'Metode login ini belum diaktifkan di Firebase.';
        case 'network-request-failed':
          return 'Koneksi internet bermasalah.';
        default:
          return error.message ?? 'Google Sign-In gagal.';
      }
    }

    if (error is PlatformException) {
      final details = error.message ?? error.code;
      if (details.contains('ApiException: 10') ||
          details.contains('12500') ||
          details.contains('DEVELOPER_ERROR')) {
        return 'Google Sign-In Android belum aktif untuk debug key laptop ini. Login pakai email/password dulu atau minta pemilik Firebase menambahkan SHA-1 dan SHA-256 debug laptop ini.';
      }

      if (details.contains('sign_in_failed') ||
          details.contains('GoogleSignIn')) {
        return 'Google Sign-In gagal. Cek konfigurasi Firebase Android dan koneksi internet.';
      }

      return details.isNotEmpty ? details : 'Google Sign-In gagal.';
    }

    return 'Google Sign-In gagal.';
  }

  @override
  Widget build(BuildContext context) {
    final onboardData = OnboardItem(image: 'assets/images/logo.png');

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 20.0),
          child: Column(
            children: [
              Expanded(
                flex: 3,
                child: Center(
                  child: Image.asset(
                    onboardData.image,
                    width: 225,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: AuthButton(
                              isOutlined: true,
                              text: "Register",
                              onPressed: _isLoading
                                  ? () {}
                                  : () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const RegisterPage()),
                                      );
                                    },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AuthButton(
                              textColor: Colors.white,
                              text: "Login",
                              onPressed: _isLoading
                                  ? () {}
                                  : () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const LoginPage(),
                                        ),
                                      );
                                    },
                              backgroundColor: AppColors.purple800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      AuthButton(
                        isOutlined: true,
                        text: _isLoading ? 'Signing in...' : 'Login with Google',
                        onPressed: _isLoading
                            ? () {}
                            : () async {
                                setState(() {
                                  _isLoading = true;
                                });
                                try {
                                  final user =
                                      await AuthService().signInWithGoogle();
                                  if (user == null) {
                                    if (!context.mounted) return;
                                    setState(() {
                                      _isLoading = false;
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content:
                                              Text('Google Sign-In failed.')),
                                    );
                                    return;
                                  }

                                  if (!context.mounted) return;
                                  setState(() {
                                    _isLoading = false;
                                  });
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => const AuthWrapper()),
                                    (route) => false,
                                  );
                                } on FirebaseAuthException catch (error) {
                                  if (!context.mounted) return;
                                  setState(() {
                                    _isLoading = false;
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            _friendlyAuthMessage(error))),
                                  );
                                } on PlatformException catch (error) {
                                  if (!context.mounted) return;
                                  setState(() {
                                    _isLoading = false;
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(_friendlyAuthMessage(error)),
                                    ),
                                  );
                                } catch (error) {
                                  if (!context.mounted) return;
                                  setState(() {
                                    _isLoading = false;
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            _friendlyAuthMessage(error))),
                                  );
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
