import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
class NapCard extends StatelessWidget {
  final String title;
  final String duration;
  final String description;
  final bool isRecommended;

  const NapCard({
    Key? key,
    required this.title,
    required this.duration,
    required this.description,
    this.isRecommended = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isRecommended ? const Color(0xff1B2643) : Color(0xFF1C0E30),
        borderRadius: BorderRadius.circular(16),
        border: isRecommended
            ? Border.all(color: const Color(0xFF00BFA5), width: 1.5)
            : Border.all(color: const Color(0xff3F256C), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isRecommended)
            Row(
              children: const [
                Icon(Icons.star, color: Color(0xFF00BFA5), size: 12),
                SizedBox(width: 4),
                Text(
                  'RECOMMENDED',
                  style: TextStyle(
                    color: Color(0xFF00BFA5),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          if (isRecommended) const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            duration,
            style: const TextStyle(
              color: AppColors.purple300, // Purple pinkish accent
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: const TextStyle(
              color: AppColors.purple100,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
