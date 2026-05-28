import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class DfsSplashScreen extends StatelessWidget {
  const DfsSplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D0618), Color(0xFF1B0C30), Color(0xFF0B0414)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: AppColors.purple800.withOpacity(0.35),
                    blurRadius: 25.0,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Image.asset(
                'assets/images/logo.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: AppColors.purple950,
                    child: const Center(
                      child: Icon(
                        Icons.bedtime_outlined,
                        color: Colors.white,
                        size: 60,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 32),
            // App Title
            const Text(
              "Don't Forget Sleep",
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
                fontFamily: 'Outfit',
              ),
            ),
            const SizedBox(height: 24),
            // Sleek loading indicator
            SizedBox(
              width: 120,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: const LinearProgressIndicator(
                  color: AppColors.purple500,
                  backgroundColor: Color(0x1AFFFFFF),
                  minHeight: 3,
                ),
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}
