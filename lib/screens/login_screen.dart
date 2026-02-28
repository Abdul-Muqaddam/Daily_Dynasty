import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants.dart';
import '../core/colors.dart';
import '../core/responsive_helper.dart';
import 'matches_screen.dart';
import 'signup_screen.dart';
import 'guest_welcome_screen.dart';
import 'forgot_password_screen.dart';
import '../services/auth_service.dart';
import 'create_username_screen.dart';
import '../widgets/app_dialogs.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _rememberMe = false;
  
  String? _emailError;
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    _loadRememberedEmail();
  }

  Future<void> _loadRememberedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('remembered_email');
    final isRemembered = prefs.getBool('remember_me') ?? false;
    
    if (savedEmail != null && savedEmail.isNotEmpty) {
      if (mounted) {
        setState(() {
          _emailController.text = savedEmail;
        });
      }
    }
    
    if (mounted) {
      setState(() {
        _rememberMe = isRemembered;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _emailError = null;
      _passwordError = null;
    });

    bool hasError = false;
    if (_emailController.text.trim().isEmpty) {
      setState(() => _emailError = 'Email is required');
      hasError = true;
    }
    if (_passwordController.text.trim().isEmpty) {
      setState(() => _passwordError = 'Password is required');
      hasError = true;
    }

    if (hasError) return;

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('remember_me', _rememberMe);
      
      if (_rememberMe) {
        await prefs.setString('remembered_email', _emailController.text.trim());
      } else {
        await prefs.remove('remembered_email');
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MatchesScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        final errorStr = e.message?.toLowerCase() ?? '';
        final isNetwork = errorStr.contains('network') || 
                          errorStr.contains('connection') || 
                          errorStr.contains('timeout') || 
                          errorStr.contains('host') ||
                          errorStr.contains('unreachable');
        
        if (isNetwork) {
          AppDialogs.showPremiumErrorDialog(context, message: "UNSTABLE CONNECTION DETECTED. PLEASE CHECK YOUR INTERNET AND TRY AGAIN.", isNetworkError: true);
        } else if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
          setState(() => _emailError = 'Invalid email or password');
        } else if (e.code == 'invalid-email') {
          setState(() => _emailError = 'The email address is not valid');
        } else {
          AppDialogs.showPremiumErrorDialog(context, message: e.message ?? 'Login failed');
        }
      }
    } catch (e) {
      if (mounted) {
        final errorStr = e.toString().toLowerCase();
        final isNetwork = errorStr.contains('network') || 
                          errorStr.contains('connection') || 
                          errorStr.contains('timeout');
        
        AppDialogs.showPremiumErrorDialog(
          context, 
          message: isNetwork 
            ? "UNSTABLE CONNECTION DETECTED. PLEASE CHECK YOUR INTERNET AND TRY AGAIN."
            : e.toString().replaceAll('Exception: ', ''),
          isNetworkError: isNetwork,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final user = await AuthService.signInWithGoogle();
      if (user != null && mounted) {
        // Automatically set remember me to true for Google Sign Ins
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('remember_me', true);
        
        // Check if registration is completed (we'll need to fetch this from Firestore)
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        final registrationCompleted = userDoc.data()?['registrationCompleted'] ?? false;

        if (registrationCompleted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MatchesScreen()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const CreateUsernameScreen()),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        final errorStr = e.toString().toLowerCase();
        final isNetwork = errorStr.contains('network') || 
                          errorStr.contains('connection') || 
                          errorStr.contains('timeout');
        
        AppDialogs.showPremiumErrorDialog(
          context,
          message: isNetwork 
            ? "UNSTABLE CONNECTION DETECTED. PLEASE CHECK YOUR INTERNET AND TRY AGAIN."
            : 'Google Sign-In failed: $e',
          isNetworkError: isNetwork,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
                physics: const ClampingScrollPhysics(), // Changed from NeverScrollable to allow small adjustments
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
                            'DAILY\nDYNASTY',
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
                            'Welcome Back!',
                            style: TextStyle(
                              fontSize: 22.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 24.h),
                          _buildTextField(
                            hint: 'Email Address',
                            icon: Icons.email_outlined,
                            controller: _emailController,
                            errorText: _emailError,
                          ),
                          SizedBox(height: 16.h),
                          _buildTextField(
                            hint: 'Password',
                            icon: Icons.lock_outline,
                            isPassword: true,
                            isObscure: !_isPasswordVisible,
                            controller: _passwordController,
                            errorText: _passwordError,
                            onToggleVisibility: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                          SizedBox(height: 8.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _rememberMe = !_rememberMe;
                                  });
                                },
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: Checkbox(
                                        value: _rememberMe,
                                        onChanged: (value) {
                                          setState(() {
                                            _rememberMe = value ?? false;
                                          });
                                        },
                                        activeColor: AppColors.gradientBlue,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 8.w),
                                    Text(
                                      'Remember Me',
                                      style: TextStyle(
                                        color: Colors.black54,
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                                  );
                                },
                                child: Text(
                                  'Forgot Password?',
                                  style: TextStyle(
                                    color: AppColors.gradientBlue,
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16.h),
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
                                onTap: _isLoading ? null : _login,
                                borderRadius: BorderRadius.circular(25.h),
                                child: Center(
                                  child: _isLoading 
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'LOGIN',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16.sp,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1.0,
                                            ),
                                          ),
                                          SizedBox(width: 8.w),
                                          Icon(
                                            Icons.sports_football,
                                            color: Colors.white,
                                            size: 18.sp,
                                          ),
                                        ],
                                      ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 24.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildSocialButton(
                                child: Text(
                                  'G',
                                  style: TextStyle(
                                    fontSize: 24.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                                onTap: _isLoading ? null : () => _handleGoogleSignIn(),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 24.h),
                  
                  // Don't have account
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SignUpScreen()),
                      );
                    },
                    child: RichText(
                      text: TextSpan(
                        text: "Don't have any account? ",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14.sp,
                        ),
                        children: [
                          TextSpan(
                            text: 'Click here',
                            style: TextStyle(
                              color: AppColors.accentCyan,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 16.h),
                  
                  // Continue without account
                  GestureDetector(
                    onTap: () {
                       Navigator.push(
                         context,
                         MaterialPageRoute(builder: (_) => const GuestWelcomeScreen()),
                       );
                    },
                    child: Text(
                      'or continue without account',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 14.sp,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    bool isPassword = false,
    bool isObscure = false,
    String? errorText,
    VoidCallback? onToggleVisibility,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12.h),
            border: Border.all(
              color: errorText != null ? Colors.red : Colors.grey[300]!,
            ),
          ),
          child: TextField(
            controller: controller,
            obscureText: isObscure,
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
            padding: EdgeInsets.only(left: 12.w, top: 4.h),
            child: Text(
              errorText,
              style: TextStyle(color: Colors.red, fontSize: 12.sp),
            ),
          ),
      ],
    );
  }

  Widget _buildSocialButton({required Widget child, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 50.h,
        height: 50.h,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(child: child),
      ),
    );
  }
}
