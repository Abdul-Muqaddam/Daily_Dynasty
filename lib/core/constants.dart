import 'package:flutter/material.dart';
import 'colors.dart';
import 'responsive_helper.dart';

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
