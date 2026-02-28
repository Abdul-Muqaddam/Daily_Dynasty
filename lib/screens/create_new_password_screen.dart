import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../core/colors.dart';
import '../core/responsive_helper.dart';
import 'login_screen.dart';

class CreateNewPasswordScreen extends StatefulWidget {
  const CreateNewPasswordScreen({super.key});

  @override
  State<CreateNewPasswordScreen> createState() => _CreateNewPasswordScreenState();
}

class _CreateNewPasswordScreenState extends State<CreateNewPasswordScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  String? _passwordError;
  String? _confirmPasswordError;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
                          color: AppColors.textMain,
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
                              'CREATE NEW\nPASSWORD',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 26.sp,
                                fontWeight: FontWeight.w900,
                                color: AppColors.brandDark,
                                letterSpacing: 1.5,
                                height: 1.0,
                              ),
                            ),
                            SizedBox(height: 16.h),
                            _buildInstructions(),
                            SizedBox(height: 24.h),
                            _buildTextField(
                              controller: _passwordController,
                              hint: 'New Password',
                              icon: Icons.lock_outline,
                              isPassword: true,
                              isObscure: !_isPasswordVisible,
                              errorText: _passwordError,
                              onToggleVisibility: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                              onChanged: (_) {
                                if (_passwordError != null) {
                                  setState(() => _passwordError = null);
                                }
                              },
                            ),
                            SizedBox(height: 16.h),
                            _buildTextField(
                              controller: _confirmPasswordController,
                              hint: 'Confirm Password',
                              icon: Icons.lock_outline,
                              isPassword: true,
                              isObscure: !_isConfirmPasswordVisible,
                              errorText: _confirmPasswordError,
                              onToggleVisibility: () {
                                setState(() {
                                  _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                                });
                              },
                              onChanged: (_) {
                                if (_confirmPasswordError != null) {
                                  setState(() => _confirmPasswordError = null);
                                }
                              },
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
                                    // Handle password reset logic
                                    _handleReset();
                                  },
                                  borderRadius: BorderRadius.circular(25.h),
                                  child: Center(
                                    child: Text(
                                      'RESET PASSWORD',
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

  Widget _buildInstructions() {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.instructionBg,
        borderRadius: BorderRadius.circular(12.w),
        border: Border.all(color: AppColors.fieldBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your password must contain:',
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 8.h),
          _buildInstructionItem('At least 8 characters'),
          _buildInstructionItem('One uppercase letter'),
          _buildInstructionItem('One numerical digit'),
          _buildInstructionItem('One special character'),
        ],
      ),
    );
  }

  Widget _buildInstructionItem(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4.h),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, size: 14.sp, color: AppColors.gradientGreen),
          SizedBox(width: 8.w),
          Text(
            text,
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.black54,
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
    bool isPassword = false,
    bool isObscure = false,
    String? errorText,
    VoidCallback? onToggleVisibility,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.fieldBackground,
            borderRadius: BorderRadius.circular(12.h),
            border: Border.all(
              color: errorText != null ? AppColors.error : AppColors.fieldBorder,
            ),
          ),
          child: TextField(
            controller: controller,
            obscureText: isObscure,
            onChanged: onChanged,
            style: const TextStyle(color: Colors.black87),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.grey),
              prefixIcon: Icon(icon, color: Colors.grey),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        isObscure ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: onToggleVisibility,
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 16.h),
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: EdgeInsets.only(top: 4.h, left: 8.w),
            child: Text(
              errorText,
              style: TextStyle(
                color: AppColors.error,
                fontSize: 12.sp,
              ),
            ),
          ),
      ],
    );
  }

  void _handleReset() {
    setState(() {
      _passwordError = null;
      _confirmPasswordError = null;
    });

    bool hasError = false;

    if (_passwordController.text.isEmpty) {
      setState(() => _passwordError = 'Password is required');
      hasError = true;
    } else if (_passwordController.text.length < 8) {
      setState(() => _passwordError = 'Minimum 8 characters');
      hasError = true;
    }

    if (_confirmPasswordController.text.isEmpty) {
      setState(() => _confirmPasswordError = 'Confirm Password is required');
      hasError = true;
    } else if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _confirmPasswordError = 'Passwords do not match');
      hasError = true;
    }

    if (hasError) return;

    // Success
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Container(
          padding: EdgeInsets.all(24.w),
          decoration: BoxDecoration(
            color: AppColors.leagueCardBg, // Dark background
            borderRadius: BorderRadius.circular(24.w),
            border: Border.all(color: AppColors.textMain.withOpacity(0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: AppColors.gradientGreen.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  color: AppColors.gradientGreen,
                  size: 48.sp,
                ),
              ),
              SizedBox(height: 24.h),
              Text(
                'Success!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                'Your password has been successfully reset.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16.sp,
                  height: 1.5,
                ),
              ),
              SizedBox(height: 32.h),
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
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                      );
                    },
                    borderRadius: BorderRadius.circular(25.h),
                    child: Center(
                      child: Text(
                        'LOGIN NOW',
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
    );
  }
}
