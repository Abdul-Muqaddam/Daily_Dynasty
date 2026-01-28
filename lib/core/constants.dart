import 'package:flutter/material.dart';
import 'responsive_helper.dart';

class AppColors {
  static const Color background = Color(0xFF0A0F14);
  static const Color surface = Color(0xFF131B23);
  static const Color accentCyan = Color(0xFF00E5FF);
  static const Color accentTeal = Color(0xFF00BFA5);
  static const Color textMain = Colors.white;
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color cardGlow = Color(0xFF00E5FF);
  static const Color cardBorder = Color(0xFF1E293B);
}

class AppTextStyles {
  static TextStyle get heading => TextStyle(
    fontSize: 28.sp,
    fontWeight: FontWeight.bold,
    color: AppColors.accentCyan,
    letterSpacing: 1.2,
  );

  static TextStyle get subHeading => TextStyle(
    fontSize: 16.sp,
    fontWeight: FontWeight.w600,
    color: AppColors.textMain,
  );

  static TextStyle get body => TextStyle(
    fontSize: 14.sp,
    color: AppColors.textSecondary,
  );

  static TextStyle get stadium => TextStyle(
    fontSize: 12.sp,
    color: AppColors.textSecondary,
  );

  static TextStyle get time => TextStyle(
    fontSize: 24.sp,
    fontWeight: FontWeight.bold,
    color: AppColors.accentCyan,
    fontFamily: 'Courier',
  );
}
