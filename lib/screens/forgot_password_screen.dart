import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../core/colors.dart';
import '../core/responsive_helper.dart';
import 'otp_verification_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  String? _emailError;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveHelper.init(context);
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/login_background.png',
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
          
          Center(
            child: MediaQuery.removeViewInsets(
              removeBottom: true,
              context: context,
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24.w),
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(24.w),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24.w),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accentCyan.withOpacity(0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              'FORGOT\nPASSWORD',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 28.sp,
                                fontWeight: FontWeight.w900,
                                color: AppColors.brandDark,
                                letterSpacing: 1.5,
                                height: 1.0,
                              ),
                            ),
                            SizedBox(height: 16.h),
                            Text(
                              'Enter the email of your account',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w500,
                                color: Colors.black54,
                              ),
                            ),
                            SizedBox(height: 24.h),
                            _buildTextField(
                              controller: _emailController,
                              hint: 'Email Address',
                              icon: Icons.email_outlined,
                              errorText: _emailError,
                            ),
                            SizedBox(height: 24.h),
                            Container(
                              width: double.infinity,
                              height: 50.h,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    AppColors.gradientBlue,
                                    AppColors.gradientGreen,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(25.h),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.gradientBlue.withOpacity(0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      if (_emailController.text.isEmpty) {
                                        _emailError = 'Please enter your email';
                                      } else {
                                        _emailError = null;
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => OtpVerificationScreen(
                                              email: _emailController.text,
                                              isForgotPassword: true,
                                            ),
                                          ),
                                        );
                                      }
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(25.h),
                                  child: Center(
                                    child: Text(
                                      'FORGOT PASSWORD',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    SizedBox(height: 24.h),
                    
                    // Back to Login
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: RichText(
                        text: TextSpan(
                          text: "Remember your password? ",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14.sp,
                          ),
                          children: [
                            TextSpan(
                              text: 'Login',
                              style: TextStyle(
                                color: AppColors.accentCyan,
                                fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          
          // Back Button
          Positioned(
            top: 40.h,
            left: 16.w,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12.h),
            border: Border.all(color: errorText != null ? Colors.red : Colors.grey[300]!),
          ),
          child: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.black87),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.grey),
              prefixIcon: Icon(icon, color: errorText != null ? Colors.red : Colors.grey),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 16.h),
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: EdgeInsets.only(top: 8.h, left: 12.w),
            child: Text(
              errorText,
              style: TextStyle(
                color: Colors.red,
                fontSize: 12.sp,
              ),
            ),
          ),
      ],
    );
  }
}
