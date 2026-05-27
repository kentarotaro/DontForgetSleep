import 'package:flutter/material.dart';
import 'package:dont_forget_sleep/theme/app_colors.dart';
class SecondaryButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final Color? disabledColor;
  final Color? disabledTextColor;
  final bool isBusy;

  const SecondaryButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.disabledColor,
    this.disabledTextColor,
    this.isBusy = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 64,
      child: ElevatedButton(
        onPressed: isBusy ? null : onPressed,
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.resolveWith<Color?>((states) {
            if (states.contains(MaterialState.disabled)) return disabledColor ?? const Color(0xff452E7B);
            return AppColors.purple800;
          }),
          foregroundColor: MaterialStateProperty.resolveWith<Color?>((states) {
            if (states.contains(MaterialState.disabled)) return disabledTextColor ?? Colors.white;
            return Colors.white;
          }),
          shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
          elevation: MaterialStateProperty.all(0),
          // Keep minimumSize to match previous SizedBox height behavior
          minimumSize: MaterialStateProperty.all(const Size.fromHeight(64)),
        ),
        child: isBusy
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                text,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}