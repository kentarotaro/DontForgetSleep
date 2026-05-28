import 'package:flutter/material.dart';
import 'package:dont_forget_sleep/theme/typography.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool isPassword;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.label,
    this.isPassword = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: AppTextStyles.input,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTextStyles.labelSecondary,
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white38),
        ),
      ),
    );
  }
}