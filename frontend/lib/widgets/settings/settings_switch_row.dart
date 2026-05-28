import 'package:flutter/material.dart';
import 'package:dont_forget_sleep/theme/app_colors.dart';

class SettingsSwitchRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool showDivider;

  const SettingsSwitchRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(color: AppColors.purple400, fontSize: 14)),
              
  
              GestureDetector(
                onTap: () => onChanged(!value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 52, 
                  height: 30, 
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: value ? AppColors.purple500 : AppColors.purple1000, 
                    border: value ? null : Border.all(color: Colors.white10),
                  ),
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 200),
                    alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      child: Icon(
                        value ? Icons.check : Icons.close,
                        size: 14,
                        weight: 700,
                        color: AppColors.purple1000,
                      ),
                    ),
                  ),
                ),
              ),
              // CUSTOM SWITCH END
            ],
          ),
        ),
        if (showDivider)
          const Divider(color: AppColors.purple900, height: 4, thickness: 1),
      ],
    );
  }
}
