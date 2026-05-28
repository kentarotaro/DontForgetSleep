import 'package:flutter/material.dart';
import 'package:dont_forget_sleep/theme/app_colors.dart';
import 'package:dont_forget_sleep/theme/typography.dart';

class LabeledTextField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final String? hintText;
  final TextInputType? keyboardType;
  final bool isPassword;
  final String? helperText;
  final int minPasswordLength;

  const LabeledTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hintText,
    this.keyboardType,
    this.isPassword = false,
    this.helperText,
    this.minPasswordLength = 8,
  });

  @override
  State<LabeledTextField> createState() => _LabeledTextFieldState();
}

class _LabeledTextFieldState extends State<LabeledTextField> {
  late bool _obscure;
  late final VoidCallback _controllerListener;

  @override
  void initState() {
    super.initState();
    _obscure = widget.isPassword;
    _controllerListener = () {
      if (mounted) {
        setState(() {});
      }
    };
    widget.controller.addListener(_controllerListener);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_controllerListener);
    super.dispose();
  }

  InputDecoration _fieldDecoration({Widget? suffixIcon}) {
    return InputDecoration(
      hintText: widget.hintText,
      hintStyle: AppTextStyles.hint,
      filled: true,
      fillColor: Colors.transparent,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.white, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.purple800, width: 1.5),
      ),
      suffixIcon: suffixIcon,
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: AppTextStyles.label),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool shouldShowPasswordHelper = widget.isPassword &&
        widget.controller.text.isNotEmpty &&
        widget.controller.text.length < widget.minPasswordLength;
    final String? helperText = widget.isPassword
        ? (shouldShowPasswordHelper
            ? widget.helperText ?? 'must contain ${widget.minPasswordLength} char.'
            : null)
        : widget.helperText;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(widget.label),
        TextField(
          controller: widget.controller,
          keyboardType: widget.keyboardType,
          obscureText: _obscure,
          style: AppTextStyles.input,
          decoration: _fieldDecoration(
            suffixIcon: widget.isPassword
                ? IconButton(
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(
                      _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: AppTextStyles.helperSmall.color,
                      size: 20,
                    ),
                  )
                : null,
          ),
        ),
        if (helperText != null) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(helperText, style: AppTextStyles.helperSmall),
          ),
        ],
      ],
    );
  }
}
