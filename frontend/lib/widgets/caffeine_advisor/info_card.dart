import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color valueColor;


  const InfoCard({
    Key? key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.valueColor,

  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1C0E30), // Dark inner card
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              color:  AppColors.purple300,
              fontSize: 12,
              // fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.purple300,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
