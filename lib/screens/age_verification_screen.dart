import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/colors.dart';
import '../core/responsive_helper.dart';
import 'matches_screen.dart';

class AgeVerificationScreen extends StatefulWidget {
  const AgeVerificationScreen({super.key});

  @override
  State<AgeVerificationScreen> createState() => _AgeVerificationScreenState();
}

class _AgeVerificationScreenState extends State<AgeVerificationScreen> {
  String? _selectedAgeRange;
  bool _isLoading = false;

  Future<void> _completeRegistration() async {
    if (_selectedAgeRange == null) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");

      // Save age range to Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'ageRange': _selectedAgeRange,
        'registrationCompleted': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MatchesScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error saving age: $e")),
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
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background Elements
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.background,
                    AppColors.brandDark,
                    AppColors.background,
                  ],
                ),
              ),
            ),
          ),
          // Subtle Glows
          Positioned(
            top: -100.h,
            right: -50.w,
            child: Container(
              width: 250.w,
              height: 250.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accentCyan.withOpacity(0.05),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentCyan.withOpacity(0.05),
                    blurRadius: 100,
                    spreadRadius: 50,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: -100.h,
            left: -50.w,
            child: Container(
              width: 300.w,
              height: 300.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accentCyan.withOpacity(0.05),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentCyan.withOpacity(0.05),
                    blurRadius: 100,
                    spreadRadius: 50,
                  ),
                ],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 24.h),
                        _buildHeader(),
                        SizedBox(height: 48.h),
                        _buildTitleSection(),
                        SizedBox(height: 48.h),
                        _buildAgeCards(),
                        SizedBox(height: 48.h),
                        _buildPrivacySection(),
                        SizedBox(height: 32.h),
                        _buildFeaturesPreview(),
                        SizedBox(height: 40.h),
                      ],
                    ),
                  ),
                ),
                _buildCtaSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: const Icon(Icons.arrow_back, color: Colors.white54, size: 20),
          ),
        ),
        Row(
          children: List.generate(4, (index) {
            return Container(
              width: (index == 0) ? 12.w : 8.w,
              height: 8.w,
              margin: EdgeInsets.only(left: 8.w),
              decoration: BoxDecoration(
                color: index == 0 ? AppColors.accentCyan : Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4.w),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "What's your age\nrange?",
          style: TextStyle(
            color: Colors.white,
            fontSize: 32.sp,
            fontWeight: FontWeight.bold,
            height: 1.1,
          ),
        ),
        SizedBox(height: 12.h),
        Text(
          'Help us personalize your experience',
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 16.sp,
            fontWeight: FontWeight.w300,
          ),
        ),
      ],
    );
  }

  Widget _buildAgeCards() {
    return Column(
      children: [
        _buildAgeCard(
          id: 'under-18',
          icon: Icons.child_care_rounded,
          title: 'Under 18',
          subtitle: 'Youth account',
        ),
        SizedBox(height: 16.h),
        _buildAgeCard(
          id: '18-plus',
          icon: Icons.person_outline_rounded,
          title: '18+',
          subtitle: 'Adult account',
        ),
      ],
    );
  }

  Widget _buildAgeCard({
    required String id,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    bool isSelected = _selectedAgeRange == id;

    return GestureDetector(
      onTap: () => setState(() => _selectedAgeRange = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(24.w),
          border: Border.all(
            color: isSelected ? AppColors.accentCyan.withOpacity(0.5) : Colors.white.withOpacity(0.1),
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.accentCyan.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ]
              : [],
        ),
        child: Row(
          children: [
            Container(
              width: 48.w,
              height: 48.w,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.accentCyan.withOpacity(0.2),
                    AppColors.accentCyan.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16.w),
              ),
              child: Icon(icon, color: AppColors.accentCyan, size: 24.sp),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 24.w,
              height: 24.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.accentCyan : Colors.white.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12.w,
                        height: 12.w,
                        decoration: const BoxDecoration(
                          color: AppColors.accentCyan,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacySection() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20.w),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.shield_outlined, color: AppColors.accentCyan, size: 20),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your privacy matters',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'We use age verification to ensure appropriate content and comply with regulations. Your data is encrypted and never shared.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 12,
                    height: 1.5,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "WHAT YOU'LL GET",
          style: TextStyle(
            color: Colors.white.withOpacity(0.3),
            fontSize: 10.sp,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        SizedBox(height: 16.h),
        _buildFeatureItem(Icons.auto_awesome_rounded, 'Personalized recommendations'),
        SizedBox(height: 12.h),
        _buildFeatureItem(Icons.lock_outline_rounded, 'Age-appropriate content filtering'),
        SizedBox(height: 12.h),
        _buildFeatureItem(Icons.bar_chart_rounded, 'Customized progress tracking'),
      ],
    );
  }

  Widget _buildFeatureItem(IconData icon, String label) {
    return Row(
      children: [
        Container(
          width: 32.w,
          height: 32.w,
          decoration: BoxDecoration(
            color: AppColors.accentCyan.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10.w),
          ),
          child: Icon(icon, color: AppColors.accentCyan, size: 16.sp),
        ),
        SizedBox(width: 12.w),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 14.sp,
            fontWeight: FontWeight.w300,
          ),
        ),
      ],
    );
  }

  Widget _buildCtaSection() {
    bool hasSelection = _selectedAgeRange != null;

    return Container(
      padding: EdgeInsets.only(left: 24.w, right: 24.w, bottom: 24.h, top: 12.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: (hasSelection && !_isLoading) ? _completeRegistration : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: double.infinity,
              height: 56.h,
              decoration: BoxDecoration(
                gradient: hasSelection
                    ? const LinearGradient(
                        colors: [AppColors.accentCyan, AppColors.accentCyanDark],
                      )
                    : null,
                color: hasSelection ? null : Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16.w),
                boxShadow: hasSelection
                    ? [
                        BoxShadow(
                          color: AppColors.accentCyan.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        )
                      ]
                    : [],
              ),
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
                    : Text(
                        'Continue',
                        style: TextStyle(
                          color: hasSelection ? Colors.white : Colors.white.withOpacity(0.3),
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ),
          SizedBox(height: 20.h),
          Text.rich(
            TextSpan(
              text: 'By continuing, you agree to our ',
              style: TextStyle(
                color: Colors.white.withOpacity(0.25),
                fontSize: 11,
                fontWeight: FontWeight.w300,
              ),
              children: [
                TextSpan(
                  text: 'Terms of Service',
                  style: TextStyle(color: Colors.white.withOpacity(0.4)),
                ),
                const TextSpan(text: ' and '),
                TextSpan(
                  text: 'Privacy Policy',
                  style: TextStyle(color: Colors.white.withOpacity(0.4)),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
