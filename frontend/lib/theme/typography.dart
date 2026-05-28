import 'package:flutter/material.dart';
import 'package:dont_forget_sleep/theme/app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static const TextStyle authTitle = TextStyle(
    color: Colors.white,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.3,
    fontFamily: 'Gabarito',
  );

  static const TextStyle label = TextStyle(
    color: Colors.white,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    fontFamily: 'Gabarito',
  );

  static const TextStyle input = TextStyle(
    color: Colors.white,
    fontSize: 15,
    fontFamily: 'Gabarito',
  );

  static const TextStyle hint = TextStyle(
    color: AppColors.neutral_400,
    fontSize: 15,
    fontFamily: 'Gabarito',
  );

  static const TextStyle helperSmall = TextStyle(
    color: Color(0xFF6B7280),
    fontSize: 12,
    decoration: TextDecoration.underline,
    decorationColor: Color(0xFF6B7280),
    fontFamily: 'Gabarito',
  );

  static const TextStyle terms = TextStyle(
    color: Colors.white,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    fontFamily: 'Gabarito',
  );

  static const TextStyle labelSecondary = TextStyle(
    color: Colors.white70,
    fontFamily: 'Gabarito',
  );

  static const TextStyle bold = TextStyle(
    fontWeight: FontWeight.bold,
    fontFamily: 'Gabarito',
  );
  static const TextStyle medium = TextStyle(
    fontWeight: FontWeight.w500,
    fontFamily: 'Gabarito',
  );

  static const TextStyle link = TextStyle(
    color: AppColors.bluePrimary,
    decoration: TextDecoration.underline,
    decorationColor: AppColors.bluePrimary,
    fontFamily: 'Gabarito',
  );

  static const TextStyle purple800Text = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
    color: AppColors.scaffoldBg,
    fontFamily: 'Gabarito',
  );

  // Redesign Text Styles
  static const String _defaultFont = 'Inter'; // Fallback for SF Pro

  static const TextStyle sectionTitle = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
    color: AppColors.textMain,
    fontFamily: _defaultFont,
  );

  static const TextStyle sectionDesc = TextStyle(
    fontSize: 13,
    height: 1.5,
    color: AppColors.textSecondary,
    fontFamily: _defaultFont,
  );

  static const TextStyle stepLabelActive = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.3,
    color: AppColors.textMain,
    fontFamily: _defaultFont,
  );

  static const TextStyle stepLabelPending = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.3,
    color: AppColors.textTertiary,
    fontFamily: _defaultFont,
  );

  static const TextStyle itemTitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.textMain,
    fontFamily: _defaultFont,
  );

  static const TextStyle itemMeta = TextStyle(
    fontSize: 12,
    color: AppColors.textSecondary,
    fontFamily: _defaultFont,
  );

  static const TextStyle buttonPrimary = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.2,
    color: Colors.white,
    fontFamily: _defaultFont,
  );
  
  static const TextStyle buttonSecondary = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.textSecondary,
    fontFamily: _defaultFont,
  );
}
