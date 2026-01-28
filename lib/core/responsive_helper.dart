import 'package:flutter/material.dart';

class ResponsiveHelper {
  static double screenWidth = 375;
  static double screenHeight = 812;
  static double _safeAreaHorizontal = 0;
  static double _safeAreaVertical = 0;
  static bool _isInitialized = false;

  static void init(BuildContext context) {
    final mediaQueryData = MediaQuery.of(context);
    
    // Only update if we have a valid width (avoid zero on first frame)
    if (mediaQueryData.size.width > 0) {
      screenWidth = mediaQueryData.size.width;
      screenHeight = mediaQueryData.size.height;
      _safeAreaHorizontal = mediaQueryData.padding.left + mediaQueryData.padding.right;
      _safeAreaVertical = mediaQueryData.padding.top + mediaQueryData.padding.bottom;
      _isInitialized = true;
    }
  }

  // Base dimensions based on iPhone 11 Pro (375x812)
  static double get h => screenHeight / 812;
  static double get w => screenWidth / 375;

  // Use a safety multiplier to ensure text is never zero size
  static double setSp(double size) => size * (w > 0.1 ? w : 1.0);
  static double setHeight(double size) => size * (h > 0.1 ? h : 1.0);
  static double setWidth(double size) => size * (w > 0.1 ? w : 1.0);

  static double get paddingSide => setWidth(20);
  static double get paddingTop => setHeight(20);
}

extension ResponsiveDouble on num {
  double get sp => ResponsiveHelper.setSp(toDouble());
  double get h => ResponsiveHelper.setHeight(toDouble());
  double get w => ResponsiveHelper.setWidth(toDouble());
}
