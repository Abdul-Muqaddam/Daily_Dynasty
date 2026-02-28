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
  // We use the shortest side to determine the scale factor to ensure elements 
  // don't become too small or distorted in landscape mode.
  static double get scaleFactor {
    if (screenWidth == 0 || screenHeight == 0) return 1.0;
    double shortestSide = screenWidth < screenHeight ? screenWidth : screenHeight;
    return shortestSide / 375.0;
  }

  // Use the scale factor for all dimensions to preserve aspect ratios
  static double setSp(double size) => size * scaleFactor;
  static double setHeight(double size) => size * scaleFactor;
  static double setWidth(double size) => size * scaleFactor;

  static double get paddingSide => setWidth(20);
  static double get paddingTop => setHeight(20);
}

extension ResponsiveDouble on num {
  double get sp => ResponsiveHelper.setSp(toDouble());
  double get h => ResponsiveHelper.setHeight(toDouble());
  double get w => ResponsiveHelper.setWidth(toDouble());
}
