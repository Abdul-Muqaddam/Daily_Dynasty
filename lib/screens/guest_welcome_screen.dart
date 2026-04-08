import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../core/colors.dart';
import '../core/responsive_helper.dart';
import '../services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/app_dialogs.dart';
import 'matches_screen.dart';

class GuestWelcomeScreen extends StatelessWidget {
  const GuestWelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    ResponsiveHelper.init(context);
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/guest_background.png',
              fit: BoxFit.cover,
              alignment: Alignment.center,
              filterQuality: FilterQuality.high,
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.overlayTop,
                    AppColors.overlayBottom,
                  ],
                ),
              ),
            ),
          ),
          
          // Content
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Spacer(),
                  
                  // Logo Text: DAILY (Blue) DYNASTY (White)
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'DAILY\n',
                          style: TextStyle(
                            fontSize: 40.sp,
                            fontWeight: FontWeight.w900,
                            color: AppColors.brandBlueLight,
                            height: 1.0,
                          ),
                        ),
                        TextSpan(
                          text: 'DYNASTY',
                          style: TextStyle(
                            fontSize: 40.sp,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textMain,
                            height: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Spacer(),

                  // Start As Guest Button
                  GestureDetector(
                    onTap: () async {
                      try {
                        final user = await AuthService.signInAnonymously();
                        if (user != null && context.mounted) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => MatchesScreen()),
                          );
                        }
                      } on FirebaseAuthException catch (e) {
                         if (context.mounted) {
                           String message = "Guest login failed. Check your connection.";
                           if (e.code == 'admin-restricted-operation') {
                             message = "Anonymous sign-in is disabled in Firebase Console. Please enable it in Authentication > Sign-in method.";
                           }
                           AppDialogs.showPremiumErrorDialog(context, message: message);
                         }
                      } catch (e) {
                        if (context.mounted) {
                          AppDialogs.showPremiumErrorDialog(
                            context,
                            message: "Failed to start guest session. Please try again later.",
                          );
                        }
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      height: 60.h,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppColors.guestBlue,
                            AppColors.guestGreen,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(30.h),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accentCyan.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'START AS GUEST',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Icon(
                              Icons.sports_football,
                              color: Colors.white,
                              size: 24.sp,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 20.h),
                  
                  // Subtext
                  Text(
                    'Begin your journey without an account',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14.sp,
                    ),
                  ),
                  
                  Spacer(),
                  
                  // Back to Login / Sign Up
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Back to Login / Sign Up',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 14.sp,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 20.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
