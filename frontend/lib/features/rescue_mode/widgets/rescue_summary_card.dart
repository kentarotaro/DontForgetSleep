import 'package:flutter/material.dart';
import '../models/rescue_plan_model.dart';

class RescueSummaryCard extends StatelessWidget {
  final RescuePlan plan;

  const RescueSummaryCard({Key? key, required this.plan}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isUnderslept = plan.type == RescueType.underslept;
    
    // Dynamic colors based on type
    final Color titleColor = isUnderslept ? const Color(0xFFFF6B6B) : const Color(0xFFFFB300);
    final List<Color> gradientColors = isUnderslept
        ? [const Color(0xFF3D1E35), const Color(0xFF1E1535)]
        : [const Color(0xFF3D321E), const Color(0xFF1E1535)];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: titleColor.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            plan.title,
            style: TextStyle(
              color: titleColor,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            plan.subtitle,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
