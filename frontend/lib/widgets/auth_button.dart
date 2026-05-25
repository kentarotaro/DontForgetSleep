import 'package:flutter/material.dart';
import 'package:dont_forget_sleep/theme/typography.dart';


class AuthButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? textColor;
  final BorderSide? side;
  final Widget? icon;
  final bool isOutlined; // Parameter baru untuk penentu jenis tombol
  final bool error; // Parameter untuk menandakan error

  const AuthButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.backgroundColor,
    this.textColor,
    this.side,
    this.icon,
    this.isOutlined = false, // Default-nya filled (Elevated)
    this.error = false, // Default-nya tidak error
  });

  @override
  Widget build(BuildContext context) {
    final commonStyle = ElevatedButton.styleFrom(
      backgroundColor: backgroundColor ?? (isOutlined ? Colors.transparent : Colors.white),
      foregroundColor: textColor ?? (isOutlined ? Colors.white : Colors.black),
      elevation: isOutlined ? 0 : 2, // Hilangkan bayangan kalau outlined
      side: side ?? (isOutlined ? const BorderSide(color: Colors.white) : null),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      padding: const EdgeInsets.symmetric(vertical: 12),
    );

    return SizedBox(
      width: double.infinity,
      height: 48, // Standar tinggi tombol yang nyaman dipencet
      child: icon != null
          ? ElevatedButton.icon( // Tetap pakai ElevatedButton tapi bisa dikasih style outlined
              onPressed: onPressed,
              icon: icon!,
              label: Text(text, style: AppTextStyles.medium),
              style: commonStyle,
            )
          : ElevatedButton(
              onPressed: onPressed,
              style: commonStyle,
              child: Text(text, style: AppTextStyles.medium),
            ),
    );
  }
}