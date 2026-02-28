import 'package:flutter/material.dart';
import '../core/colors.dart';
import '../core/responsive_helper.dart';

class AppDialogs {
  static void showPremiumErrorDialog(BuildContext context, {required String message, bool isNetworkError = false}) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) {
        return const SizedBox.shrink();
      },
      transitionBuilder: (context, anim1, anim2, child) {
        final curve = CurvedAnimation(parent: anim1, curve: Curves.easeOutBack);
        return ScaleTransition(
          scale: curve,
          child: FadeTransition(
            opacity: anim1,
            child: AlertDialog(
              backgroundColor: Colors.transparent,
              contentPadding: EdgeInsets.zero,
              content: Container(
                width: 300.w,
                padding: EdgeInsets.all(24.w),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24.w),
                  border: Border.all(color: AppColors.accentCyan.withOpacity(0.3), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentCyan.withOpacity(0.1),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isNetworkError ? Icons.wifi_off_rounded : Icons.error_outline_rounded,
                        color: Colors.redAccent,
                        size: 40.w,
                      ),
                    ),
                    SizedBox(height: 20.h),
                    Text(
                      isNetworkError ? "CONNECTION ERROR" : "ACTION FAILED",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 14.sp,
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: 24.h),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.accentCyan, AppColors.createGradientPurple],
                          ),
                          borderRadius: BorderRadius.circular(16.w),
                        ),
                        child: Center(
                          child: Text(
                            "DISMISS",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
