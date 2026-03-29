import 'package:flutter/material.dart';
import 'package:onetap365app/core/constants/app_colors.dart';

/// Reusable text field that matches the Sign In style used across the app.
///
/// Usage:
/// AppTextField(
///   controller: controller,
///   hint: 'Enter email',
///   obscure: false,
///   suffixIcon: Icons.visibility,
///   onSuffixTap: () => ...,
/// )
class AppTextField extends StatelessWidget {
  final TextEditingController? controller;
  final bool obscure;
  final TextInputType keyboardType;
  final String hint;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixTap;
  final int maxLines;

  const AppTextField({
    super.key,
    this.controller,
    this.obscure = false,
    this.keyboardType = TextInputType.text,
    required this.hint,
    this.suffixIcon,
    this.onSuffixTap,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              const TextStyle(color: AppColors.textSecondary, fontSize: 16),
          filled: true,
          fillColor: AppColors.card,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          suffixIcon: suffixIcon != null
              ? IconButton(
                  icon: Icon(suffixIcon, color: AppColors.textSecondary),
                  onPressed: onSuffixTap,
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
