import 'package:flutter/material.dart';
import '../models/rescue_plan_model.dart';

class RescueToggleTab extends StatelessWidget {
  final RescueType type;

  const RescueToggleTab({Key? key, required this.type}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String emoji;
    String text;

    if (type == RescueType.underslept) {
      emoji = '😴';
      text = 'Underslept';
    } else if (type == RescueType.overslept) {
      emoji = '😵';
      text = 'Overslept';
    } else {
      emoji = '✨';
      text = 'Normal';
    }

    // A fake toggle background
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1535),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Stack(
        children: [
          // Simulated active tab position
          AnimatedAlign(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: type == RescueType.underslept
                ? Alignment.centerLeft
                : type == RescueType.overslept
                    ? Alignment.centerRight
                    : Alignment.center,
            child: Container(
              width: MediaQuery.of(context).size.width / 2.5,
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFF9151F5), // Neon purple
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Text(
                      text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
