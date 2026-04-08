import 'dart:async';
import 'package:flutter/material.dart';
import '../core/colors.dart';
import '../core/constants.dart';
import '../core/responsive_helper.dart';
import '../services/otp_service.dart';
import '../widgets/app_dialogs.dart';
import 'create_username_screen.dart';
import 'create_new_password_screen.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;
  final bool isForgotPassword;
  const OtpVerificationScreen({
    super.key,
    required this.email,
    this.isForgotPassword = false,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  
  int _timerSeconds = 45;
  Timer? _timer;
  bool _canResend = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    setState(() {
      _timerSeconds = 45;
      _canResend = false;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timerSeconds > 0) {
        setState(() {
          _timerSeconds--;
        });
      } else {
        setState(() {
          _canResend = true;
        });
        _timer?.cancel();
      }
    });
  }

  Future<void> _handleResend() async {
    if (!_canResend) return;
    setState(() => _isLoading = true);
    try {
      await OtpService.generateAndSaveOtp(widget.email);
      _startTimer();
      if (mounted) {
        AppDialogs.showSuccessDialog(context,
          title: 'Code Resent!',
          message: 'A new verification code has been sent to ${widget.email}.',
        );
      }
    } catch (e) {
      if (mounted) {
        AppDialogs.showPremiumErrorDialog(context,
          message: 'Error resending code. Check your connection.',
          isNetworkError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleVerify() async {
    final enteredCode = _controllers.map((c) => c.text).join();
    if (enteredCode.length < 6) {
      AppDialogs.showInfoDialog(context,
        title: 'Incomplete Code',
        message: 'Please enter all 6 digits of your verification code.',
        icon: Icons.dialpad_rounded,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final isValid = await OtpService.verifyOtp(widget.email, enteredCode);
      
      if (isValid) {
        if (mounted) {
          if (widget.isForgotPassword) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const CreateNewPasswordScreen()),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const CreateUsernameScreen()),
            );
          }
        }
      } else {
        if (mounted) {
          AppDialogs.showPremiumErrorDialog(context,
            message: 'Invalid or expired code. Please check your email and try again.',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        AppDialogs.showPremiumErrorDialog(context,
          message: 'Verification failed. Please try again.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _handleSkip() {
    // Only allow skip for signup flow, not for forgot password
    if (!widget.isForgotPassword && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const CreateUsernameScreen()),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String _formatTime(int seconds) {
    int mins = seconds ~/ 60;
    int secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveHelper.init(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/signup_background.png',
              fit: BoxFit.cover,
              alignment: Alignment.center,
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

          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
              child: Column(
                children: [
                  _buildHeader(),
                  SizedBox(height: 30.h),
                  _buildTitleSection(),
                  SizedBox(height: 30.h),
                  _buildOtpInputCard(),
                  SizedBox(height: 24.h),
                  _buildVerifyButton(),
                  if (!widget.isForgotPassword) _buildSkipSection(),
                  SizedBox(height: 24.h),
                  _buildSecurityBadge(),
                  SizedBox(height: 24.h),
                  _buildHelpSection(),
                  SizedBox(height: 24.h),
                  _buildTipsSection(),
                  SizedBox(height: 24.h),
                  _buildAlternativeMethods(),
                  SizedBox(height: 24.h),
                  _buildStatsSection(),
                  SizedBox(height: 24.h),
                  _buildChangeEmailSection(),
                  SizedBox(height: 40.h),
                  _buildFooter(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 64.w,
          height: 64.w,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.accentCyan, AppColors.createGradientPurple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16.w),
            boxShadow: [
              BoxShadow(
                color: AppColors.accentCyan.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(Icons.workspace_premium, color: Colors.white, size: 32.sp),
        ),
        SizedBox(height: 20.h),
        Container(
          width: 48.w,
          height: 4.h,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.transparent, AppColors.accentCyan, Colors.transparent],
            ),
            borderRadius: BorderRadius.circular(2.h),
          ),
        ),
      ],
    );
  }

  Widget _buildTitleSection() {
    return Column(
      children: [
        Text(
          'Verify Your Email',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          widget.isForgotPassword
              ? 'We sent a 6-digit code to your email'
              : 'We attempted to send a 6-digit code to your email.\nYou may skip this step if you did not receive it.',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14.sp,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 4.h),
        Text(
          widget.email,
          style: TextStyle(
            color: AppColors.accentCyan,
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildOtpInputCard() {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: AppColors.leagueCardBg.withOpacity(0.8),
        borderRadius: BorderRadius.circular(24.w),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Text(
            'ENTER VERIFICATION CODE',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 10.sp,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: 20.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(6, (index) => _buildOtpField(index)),
          ),
          SizedBox(height: 24.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.access_time, color: AppColors.accentCyan, size: 16.sp),
              SizedBox(width: 8.w),
              if (!_canResend)
                Text(
                  'Resend code in ',
                  style: TextStyle(color: Colors.white60, fontSize: 13.sp),
                ),
              Text(
                _canResend ? 'Code Expired' : _formatTime(_timerSeconds),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOtpField(int index) {
    return Container(
      width: 45.w,
      height: 56.h,
      decoration: BoxDecoration(
        color: AppColors.brandDark,
        borderRadius: BorderRadius.circular(12.w),
        border: Border.all(
          color: _focusNodes[index].hasFocus ? AppColors.accentCyan : Colors.white10,
          width: 2,
        ),
      ),
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: TextStyle(
          color: Colors.white,
          fontSize: 20.sp,
          fontWeight: FontWeight.bold,
        ),
        decoration: const InputDecoration(
          counterText: "",
          border: InputBorder.none,
        ),
        onChanged: (value) {
          if (value.isNotEmpty && index < 5) {
            _focusNodes[index + 1].requestFocus();
          } else if (value.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
          }
          if (_controllers.every((c) => c.text.isNotEmpty)) {
            _handleVerify();
          }
        },
      ),
    );
  }

  Widget _buildVerifyButton() {
    return Container(
      width: double.infinity,
      height: 56.h,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.accentCyan, AppColors.createGradientPurple],
        ),
        borderRadius: BorderRadius.circular(16.w),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentCyan.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : _handleVerify,
          borderRadius: BorderRadius.circular(16.w),
          child: Center(
            child: _isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Verify',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Icon(Icons.arrow_forward, color: Colors.white, size: 20.sp),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildSkipSection() {
    return Padding(
      padding: EdgeInsets.only(top: 16.h),
      child: GestureDetector(
        onTap: _handleSkip,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Didn't receive a code? ",
              style: TextStyle(color: Colors.white54, fontSize: 14.sp),
            ),
            Text(
              'Skip for now →',
              style: TextStyle(
                color: AppColors.accentCyan,
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
                decorationColor: AppColors.accentCyan,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityBadge() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.leagueCardBg.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16.w),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.shield, color: Colors.green, size: 20.sp),
          ),
          SizedBox(width: 12.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Secure Verification',
                style: TextStyle(color: Colors.white, fontSize: 13.sp, fontWeight: FontWeight.bold),
              ),
              Text(
                'Your data is encrypted and protected',
                style: TextStyle(color: Colors.white54, fontSize: 11.sp),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHelpSection() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.leagueCardBg,
        borderRadius: BorderRadius.circular(20.w),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.w),
                ),
                child: Icon(Icons.info_outline, color: Colors.purple[300], size: 18.sp),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Didn't receive the code?",
                      style: TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      "Check your spam folder or make sure you entered the correct email address.",
                      style: TextStyle(color: Colors.white54, fontSize: 12.sp, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          OutlinedButton(
            onPressed: (_canResend && !_isLoading) ? _handleResend : null,
            style: OutlinedButton.styleFrom(
              minimumSize: Size(double.infinity, 44.h),
              side: const BorderSide(color: Colors.white10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.w)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.refresh, size: 16.sp, color: _canResend ? AppColors.accentCyan : Colors.white24),
                SizedBox(width: 8.w),
                Text(
                  'Resend Code',
                  style: TextStyle(
                    color: _canResend ? AppColors.accentCyan : Colors.white24,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'QUICK TIPS',
          style: TextStyle(
            color: Colors.white38,
            fontSize: 10.sp,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        SizedBox(height: 16.h),
        _buildTipItem('Code is valid for 10 minutes'),
        SizedBox(height: 12.h),
        _buildTipItem('Make sure to check your email inbox'),
        SizedBox(height: 12.h),
        _buildTipItem("Don't share your verification code with anyone"),
      ],
    );
  }

  Widget _buildTipItem(String tip) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: AppColors.accentCyan.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6.w),
          ),
          child: Icon(Icons.check, color: AppColors.accentCyan, size: 12.sp),
        ),
        SizedBox(width: 12.w),
        Text(
          tip,
          style: TextStyle(color: Colors.white54, fontSize: 12.sp),
        ),
      ],
    );
  }

  Widget _buildAlternativeMethods() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.leagueCardBg, AppColors.brandDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.w),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.send, color: Colors.purple[300], size: 18.sp),
              SizedBox(width: 12.w),
              Text(
                'Alternative Verification',
                style: TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            'Having trouble with email? Try these other options to verify your account.',
            style: TextStyle(color: Colors.white54, fontSize: 12.sp, height: 1.4),
          ),
          SizedBox(height: 16.h),
          _buildAltButton(Icons.phone_android, 'Send SMS Instead', Colors.green),
          SizedBox(height: 8.h),
          _buildAltButton(Icons.headset_mic, 'Contact Support', AppColors.accentCyan),
        ],
      ),
    );
  }

  Widget _buildAltButton(IconData icon, String label, Color iconColor) {
    return Container(
      width: double.infinity,
      height: 44.h,
      decoration: BoxDecoration(
        color: AppColors.brandDark,
        borderRadius: BorderRadius.circular(12.w),
        border: Border.all(color: Colors.white10),
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 18.sp),
            SizedBox(width: 8.w),
            Text(label, style: TextStyle(color: Colors.white, fontSize: 13.sp, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return Row(
      children: [
        _buildStatItem(Icons.bolt, 'Fast', '< 30s', Colors.orange),
        SizedBox(width: 12.w),
        _buildStatItem(Icons.lock, 'Secure', '256-bit', Colors.green),
        SizedBox(width: 12.w),
        _buildStatItem(Icons.people, 'Users', '2M+', Colors.purple),
      ],
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value, Color iconColor) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16.h),
        decoration: BoxDecoration(
          color: AppColors.leagueCardBg,
          borderRadius: BorderRadius.circular(16.w),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(6.w),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.w),
              ),
              child: Icon(icon, color: iconColor, size: 16.sp),
            ),
            SizedBox(height: 8.h),
            Text(label, style: TextStyle(color: Colors.white38, fontSize: 11.sp)),
            SizedBox(height: 4.h),
            Text(value, style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildChangeEmailSection() {
    return Container(
      width: double.infinity,
      height: 48.h,
      decoration: BoxDecoration(
        color: AppColors.leagueCardBg,
        borderRadius: BorderRadius.circular(12.w),
        border: Border.all(color: Colors.white10),
      ),
      child: Center(
        child: RichText(
          text: TextSpan(
            text: 'Wrong email? ',
            style: TextStyle(color: Colors.white54, fontSize: 13.sp),
            children: [
              TextSpan(
                text: 'Change email',
                style: TextStyle(color: AppColors.accentCyan, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Text(
          'Protected by Daily Dynasty Security',
          style: TextStyle(color: Colors.white24, fontSize: 11.sp),
        ),
        SizedBox(height: 12.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Privacy Policy', style: TextStyle(color: Colors.white38, fontSize: 11.sp)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              child: Text('•', style: TextStyle(color: Colors.white12, fontSize: 11.sp)),
            ),
            Text('Terms of Service', style: TextStyle(color: Colors.white38, fontSize: 11.sp)),
          ],
        ),
        SizedBox(height: 20.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.apple, color: Colors.white24, size: 24.sp),
            SizedBox(width: 20.w),
            Icon(Icons.android, color: Colors.white24, size: 24.sp),
            SizedBox(width: 20.w),
            Icon(Icons.shield_outlined, color: Colors.white24, size: 24.sp),
          ],
        ),
      ],
    );
  }
}
