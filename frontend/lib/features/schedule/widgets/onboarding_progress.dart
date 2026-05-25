// import 'package:flutter/material.dart';
// import 'package:dont_forget_sleep/theme/app_colors.dart';
// import 'package:dont_forget_sleep/theme/typography.dart';
// import 'package:dont_forget_sleep/theme/app_spacing.dart';

// class OnboardingProgress extends StatelessWidget {
//   final int currentStep;
//   final int totalSteps;

//   const OnboardingProgress({
//     super.key,
//     required this.currentStep,
//     required this.totalSteps,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           children: List.generate(totalSteps, (index) {
//             final isActive = index <= currentStep;
//             return Expanded(
//               child: Container(
//                 height: 3,
//                 margin: EdgeInsets.only(
//                   right: index == totalSteps - 1 ? 0 : AppSpacing.sm,
//                 ),
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(1.5),
//                   color: isActive ? AppColors.purple800 : AppColors.border,
//                   boxShadow: isActive
//                       ? [
//                           BoxShadow(
//                             color: AppColors.primaryGlow,
//                             blurRadius: 8,
//                             spreadRadius: 1,
//                           )
//                         ]
//                       : [],
//                 ),
//               ),
//             );
//           }),
//         ),
//         const SizedBox(height: AppSpacing.md),
//         Text(
//           'STEP ${currentStep + 1} OF $totalSteps',
//           style: AppTextStyles.stepLabelActive.copyWith(
//             color: AppColors.purple400,
//           ),
//         ),
//       ],
//     );
//   }
// }
