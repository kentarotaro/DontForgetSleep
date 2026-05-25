import 'package:flutter/material.dart';
import '../models/rescue_plan_model.dart';

class ChecklistTile extends StatelessWidget {
  final ChecklistItem item;
  final VoidCallback onToggle;

  const ChecklistTile({
    Key? key,
    required this.item,
    required this.onToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: item.isCompleted 
              ? const Color(0xFF161E2E) // Dark muted cyan background 
              : const Color(0xFF1E1535), // Dark muted purple background
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: item.isCompleted 
                ? const Color(0xFF00E676).withOpacity(0.5) 
                : Colors.white.withOpacity(0.05),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: item.isCompleted ? const Color(0xFF00E676) : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: item.isCompleted ? const Color(0xFF00E676) : Colors.white38,
                  width: 2,
                ),
              ),
              child: item.isCompleted
                  ? const Icon(Icons.check, color: Colors.black, size: 16)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: TextStyle(
                  color: item.isCompleted ? Colors.white38 : Colors.white70,
                  fontSize: 14,
                  decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                  decorationColor: Colors.white38,
                ),
                child: Text(item.text),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
