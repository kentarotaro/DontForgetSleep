import 'package:flutter/material.dart';
import 'package:dont_forget_sleep/theme/app_colors.dart';
import 'package:dont_forget_sleep/widgets/settings/settings_section_card.dart';
import 'package:dont_forget_sleep/widgets/settings/settings_section_header.dart';

class SettingsSleepPreferencesSection extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelectedIndexChanged;
  final String wakeTimeText;
  final String bedTimeText;
  final VoidCallback? onWakeTimeTap;
  final VoidCallback? onBedTimeTap;

  const SettingsSleepPreferencesSection({
    super.key,
    required this.selectedIndex,
    required this.onSelectedIndexChanged,
    required this.wakeTimeText,
    required this.bedTimeText,
    this.onWakeTimeTap,
    this.onBedTimeTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionHeader(title: 'SLEEP PREFERENCES'),
        SettingsSectionCard(
          border: Border.all(color: AppColors.purple900, width: 1),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Minimum sleep floor',
                style: TextStyle(color: Colors.white, fontSize: 11),
              ),
              const SizedBox(height: 16),
              Row(
                children: List.generate(3, (index) {
                  final labels = ['6h', '7h', '8h'];
                  final selected = selectedIndex == index;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: index == 2 ? 0 : 12),
                      child: GestureDetector(
                        onTap: () => onSelectedIndexChanged(index),
                        child: Container(
                           height: 55,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: selected ? Colors.transparent : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: selected ? AppColors.purple500 : AppColors.purple900,
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            labels[index],
                            style: TextStyle(
                              color: selected ? AppColors.purple500 : AppColors.purple400,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SettingsSectionCard(
          border: Border.all(color: AppColors.purple900, width: 1),
          child: Column(
            children: [
              _TimeValueRow(
                label: 'Wake time',
                value: wakeTimeText,
                showDivider: true,
                onTap: onWakeTimeTap,
              ),
              _TimeValueRow(
                label: 'Bedtime',
                value: bedTimeText,
                onTap: onBedTimeTap,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _TimeValueRow({
    required String label,
    required String value,
    bool showDivider = false,
    VoidCallback? onTap,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.purple400,
                    fontSize: 12,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.chevron_right,
                      color: AppColors.purple400,
                      size: 16,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (showDivider) Divider(color: AppColors.purple900, height: 10, thickness: 1),
      ],
    );
  }
}