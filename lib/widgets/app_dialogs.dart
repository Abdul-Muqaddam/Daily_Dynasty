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
  static void showInsufficientCoinsDialog(BuildContext context, {required String message, required VoidCallback onGetCoins}) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) => const SizedBox.shrink(),
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
                width: 320.w,
                padding: EdgeInsets.all(28.w),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(28.w),
                  border: Border.all(color: AppColors.gold.withOpacity(0.3), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gold.withOpacity(0.1),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.all(20.w),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.monetization_on,
                        color: AppColors.gold,
                        size: 48.w,
                      ),
                    ),
                    SizedBox(height: 24.h),
                    Text(
                      "INSUFFICIENT COINS",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20.sp,
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
                    SizedBox(height: 32.h),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        onGetCoins();
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.orangeGradientStart, AppColors.orangeGradientEnd],
                          ),
                          borderRadius: BorderRadius.circular(20.w),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.orangeGradientStart.withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            "GET COINS",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        "CANCEL",
                        style: TextStyle(
                          color: Colors.white24,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
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

  static void showSuccessDialog(BuildContext context, {required String title, required String message, String buttonLabel = "GOT IT", VoidCallback? onDismiss}) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) => const SizedBox.shrink(),
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
                width: 320.w,
                padding: EdgeInsets.all(28.w),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(28.w),
                  border: Border.all(color: Colors.greenAccent.withOpacity(0.3), width: 1.5),
                  boxShadow: [BoxShadow(color: Colors.greenAccent.withOpacity(0.1), blurRadius: 30, spreadRadius: 10)],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.all(18.w),
                      decoration: BoxDecoration(color: Colors.greenAccent.withOpacity(0.1), shape: BoxShape.circle),
                      child: Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 44.w),
                    ),
                    SizedBox(height: 20.h),
                    Text(title.toUpperCase(), textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                    SizedBox(height: 10.h),
                    Text(message, textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white54, fontSize: 13.sp, height: 1.5)),
                    SizedBox(height: 28.h),
                    GestureDetector(
                      onTap: () { Navigator.pop(context); onDismiss?.call(); },
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF00C853), Color(0xFF69F0AE)]),
                          borderRadius: BorderRadius.circular(18.w),
                          boxShadow: [BoxShadow(color: Colors.greenAccent.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))],
                        ),
                        child: Center(child: Text(buttonLabel,
                          style: TextStyle(color: Colors.black87, fontSize: 14.sp, fontWeight: FontWeight.w900, letterSpacing: 1.2))),
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

  static void showInfoDialog(BuildContext context, {
    required String title,
    required String message,
    IconData icon = Icons.info_outline_rounded,
    Color accentColor = AppColors.accentCyan,
    String buttonLabel = "GOT IT",
    VoidCallback? onDismiss,
  }) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) => const SizedBox.shrink(),
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
                width: 320.w,
                padding: EdgeInsets.all(28.w),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(28.w),
                  border: Border.all(color: accentColor.withOpacity(0.3), width: 1.5),
                  boxShadow: [BoxShadow(color: accentColor.withOpacity(0.1), blurRadius: 30, spreadRadius: 10)],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.all(18.w),
                      decoration: BoxDecoration(color: accentColor.withOpacity(0.1), shape: BoxShape.circle),
                      child: Icon(icon, color: accentColor, size: 44.w),
                    ),
                    SizedBox(height: 20.h),
                    Text(title.toUpperCase(), textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                    SizedBox(height: 10.h),
                    Text(message, textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white54, fontSize: 13.sp, height: 1.5)),
                    SizedBox(height: 28.h),
                    GestureDetector(
                      onTap: () { Navigator.pop(context); onDismiss?.call(); },
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [accentColor, accentColor.withOpacity(0.7)]),
                          borderRadius: BorderRadius.circular(18.w),
                          boxShadow: [BoxShadow(color: accentColor.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))],
                        ),
                        child: Center(child: Text(buttonLabel,
                          style: TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.w900, letterSpacing: 1.2))),
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
