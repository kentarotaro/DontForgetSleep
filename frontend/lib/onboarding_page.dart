import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dont_forget_sleep/theme/app_colors.dart';
import '../models/onboard_item.dart';
import '../widgets/auth_button.dart';
import 'package:dont_forget_sleep/core/auth_service.dart';
import 'package:dont_forget_sleep/register_page.dart';
import 'package:dont_forget_sleep/login_page.dart';
import 'package:dont_forget_sleep/views/get_started/onboarding_questions_screen.dart';
class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

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
                              onPressed: () {

                              
                              Navigator.push(
                                context,
                                MaterialPageRoute
                                (builder: (context) => const RegisterPage()),
    );
                              }
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AuthButton(
                              textColor: Colors.white,
                              text: "Login",
                              onPressed: (){
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const LoginPage(),
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
                        text: 'Login with Google',
                        // onPressed: () => print("login goggle"),
                        onPressed: () async {
                            try {
                              final user = await AuthService().signInWithGoogle();
                              if (user == null) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Google Sign-In failed.')),
                                );
                                return;
                              }

                              if (!context.mounted) return;
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(builder: (_) => const OnboardingQuestionsScreen()),
                                (route) => false,
                              );
                            } on FirebaseAuthException catch (error) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(_friendlyAuthMessage(error))),
                              );
                            } catch (error) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(_friendlyAuthMessage(error))),
                              );
                            }
                        },
                        icon: Image.asset(
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