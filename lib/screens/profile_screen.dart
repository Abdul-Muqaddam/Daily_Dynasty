import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/colors.dart';
import '../core/constants.dart';
import '../core/responsive_helper.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'edit_profile_screen.dart';
import 'daily_check_in_screen.dart';
import 'activity_feed_screen.dart';
import '../services/check_in_service.dart';
import '../services/notification_service.dart';
import '../widgets/notification_badge.dart';
import '../widgets/app_dialogs.dart';
import '../widgets/countdown_timer.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final ImagePicker _picker = ImagePicker();
  Map<String, dynamic>? userData;
  bool _isLoading = true;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    if (currentUser == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .get();
      
      if (mounted) {
        setState(() {
          userData = doc.data();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppDialogs.showPremiumErrorDialog(context,
          message: 'Error fetching profile. Please check your connection.',
          isNetworkError: true,
        );
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );
      
      if (pickedFile != null) {
        await _uploadProfilePicture(File(pickedFile.path));
      }
    } catch (e) {
      if (mounted) {
        AppDialogs.showPremiumErrorDialog(context,
          message: 'Could not pick image. Please try again.',
        );
      }
    }
  }

  Future<void> _uploadProfilePicture(File imageFile) async {
    if (currentUser == null) return;
    
    setState(() => _isUploading = true);
    
    try {
      // Use instanceFor to be explicit about the bucket name if the default one fails
      final storage = FirebaseStorage.instanceFor(
        bucket: 'daily-dynasty.firebasestorage.app',
      );
      
      final ref = storage
          .ref()
          .child('profile_pictures')
          .child('${currentUser!.uid}.jpg');
      
      await ref.putFile(imageFile);
      final photoUrl = await ref.getDownloadURL();
      
      // Update Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .update({'photoUrl': photoUrl});
          
      // Update Firebase Auth Profile
      await currentUser!.updatePhotoURL(photoUrl);
      
      await _fetchUserData();
      
      if (mounted) {
        AppDialogs.showSuccessDialog(context,
          title: 'Photo Updated!',
          message: 'Your profile picture has been updated successfully.',
        );
      }
    } catch (e) {
      if (mounted) {
        AppDialogs.showPremiumErrorDialog(context,
          message: 'Error uploading image. Check your connection and try again.',
          isNetworkError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _handleLogout() async {
    await AuthService.signOut();
    if (mounted) {
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _handleDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.h),
          side: BorderSide(color: AppColors.deleteRed.withOpacity(0.3)),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.deleteRed, size: 28.w),
            SizedBox(width: 12.w),
            Text(
              "DELETE ACCOUNT",
              style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.w900),
            ),
          ],
        ),
        content: Text(
          "This will permanently delete your account, all league data, and your coin balance.\n\nThis action cannot be undone.",
          style: TextStyle(color: Colors.white54, fontSize: 13.sp, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("CANCEL", style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)),
          ),
          GestureDetector(
            onTap: () => Navigator.pop(context, true),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.deleteGrey, AppColors.deleteRed]),
                borderRadius: BorderRadius.circular(12.h),
              ),
              child: Text(
                "DELETE",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13.sp),
              ),
            ),
          ),
          SizedBox(width: 4.w),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Delete Firestore user document
      await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();

      // Delete Firebase Auth account
      await user.delete();

      if (mounted) {
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        AppDialogs.showPremiumErrorDialog(context,
          message: 'Error deleting account. You may need to re-login first.',
        );
      }
    }
  }

  Color _getThemeColor() {
    final colorName = userData?['themeColor'] as String? ?? 'blue';
    switch (colorName) {
      case 'green': return AppColors.selectionGreenStart;
      case 'purple': return AppColors.selectionPurpleStart;
      case 'orange': return AppColors.selectionOrangeStart;
      default: return AppColors.selectionBlueStart;
    }
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveHelper.init(context);
    final themeColor = _getThemeColor();

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.accentCyan)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background Stadium Image
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 400.h,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/login_background.png',
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                  ),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.4),
                          AppColors.background.withOpacity(0.9),
                          AppColors.background,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Column(
                children: [
                   _buildHeader(context),
                   SizedBox(height: 30.h),
                   _buildProfileSection(themeColor),
                   SizedBox(height: 30.h),
                   _buildStatsRow(),
                   SizedBox(height: 40.h),
                   _buildDailyCheckIn(themeColor),
                   SizedBox(height: 60.h),
                   _buildActionButtons(),
                   SizedBox(height: 40.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        // Only show back button if we can pop
        if (Navigator.canPop(context))
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back_ios, color: Colors.white, size: 20.sp),
          ),
        const Spacer(),
        Text(
          "DAILY DYNASTY",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20.sp,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        const Spacer(),
        // Notification bell with live unread count badge
        if (currentUser != null)
          StreamBuilder<int>(
            stream: NotificationService.unreadCountStream(currentUser!.uid),
            builder: (context, snapshot) {
              final count = snapshot.data ?? 0;
              return GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ActivityFeedScreen())),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(8.w),
                      child: Icon(Icons.notifications_outlined, color: Colors.white70, size: 24.sp),
                    ),
                    if (count > 0)
                      Positioned(
                        top: 2.h,
                        right: 2.w,
                        child: Container(
                          padding: EdgeInsets.all(3.w),
                          decoration: const BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            count > 9 ? '9+' : '$count',
                            style: TextStyle(color: Colors.white, fontSize: 8.sp, fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          )
        else
          SizedBox(width: 40.w),
      ],
    );
  }

  Widget _buildProfileSection(Color themeColor) {
    final photoUrl = userData?['photoUrl'] as String?;
    final username = userData?['username'] as String? ?? 'Username';

    return Column(
      children: [
        Stack(
          children: [
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: themeColor, width: 3.w),
                boxShadow: [
                  BoxShadow(
                    color: themeColor.withOpacity(0.2),
                    blurRadius: 15,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 80.w,
                    backgroundColor: AppColors.surface,
                    backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                    child: photoUrl == null 
                      ? Icon(Icons.person, size: 80.w, color: Colors.white24)
                      : null,
                  ),
                  if (_isUploading)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: CircularProgressIndicator(color: themeColor),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Pencil Icon
            Positioned(
              bottom: 5.h,
              right: 5.w,
              child: GestureDetector(
                onTap: _isUploading ? null : _pickImage,
                child: Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: themeColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.edit,
                    color: Colors.black,
                    size: 20.w,
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 20.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              username.toUpperCase(),
              style: TextStyle(
                color: Colors.white,
                fontSize: 24.sp,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
            ),
            if (userData?['ageRange'] != null) ...[
              SizedBox(width: 10.w),
              _buildAgeBadge(userData?['ageRange'] == '18-plus'),
            ],
          ],
        ),
        SizedBox(height: 4.h),
        if ((userData?['fullName'] as String? ?? '').isNotEmpty)
          Text(
            userData?['fullName'] as String? ?? '',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        SizedBox(height: 4.h),
        Text(
          userData?['email'] as String? ?? '',
          style: TextStyle(
            color: Colors.white38,
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 16.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          decoration: BoxDecoration(
            border: Border.all(color: themeColor.withOpacity(0.5)),
            borderRadius: BorderRadius.circular(20.h),
            boxShadow: [
              BoxShadow(
                color: themeColor.withOpacity(0.2),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.stars, color: themeColor, size: 20.w),
              SizedBox(width: 8.w),
              Text(
                "ROOKIE TIER",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildStatCard("SEASONS\nPLAYED:", "1"),
          _buildStatCard("CHAMPION-\nSHIPS:", "0"),
          _buildStatCard("W/L\nRECORD:", "0-0"),
          _buildStatCard("LONGEST\nWIN\nSTREAK:", "0"),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Container(
      width: 85.w,
      height: 105.h,
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.h),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black,
              fontSize: 9.sp,
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: Colors.black,
              fontSize: 20.sp,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyCheckIn(Color themeColor) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const DailyCheckInScreen()),
      ),
      child: Column(
        children: [
        Text(
          "DAILY CHECK-IN",
          style: TextStyle(
            color: Colors.white,
            fontSize: 14.sp,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
          ),
        ),
        SizedBox(height: 20.h),
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 140.w,
              height: 140.w,
              child: CircularProgressIndicator(
                value: 1 / 7,
                strokeWidth: 12.w,
                backgroundColor: Colors.white10,
                valueColor: AlwaysStoppedAnimation<Color>(themeColor),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: Icon(Icons.check, color: Colors.black, size: 24.w),
                ),
                SizedBox(height: 8.h),
                StreamBuilder<bool>(
                  stream: CheckInService.checkInStatusStream(),
                  builder: (context, snap) {
                    if (snap.data == false) {
                      return CheckInCountdown(
                        prefix: "Next in ",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }
                    return Text(
                      "Day 1 of 7",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }
                ),
              ],
            ),
            StreamBuilder<bool>(
              stream: CheckInService.checkInStatusStream(),
              builder: (context, snapshot) {
                if (snapshot.data == true) {
                  return Positioned(
                    top: 10.h,
                    right: 10.w,
                    child: const PulsingNotificationDot(),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        _buildGradientButton(
          "EDIT PROFILE",
          [AppColors.editProfileLightBlue, AppColors.createGradientPurple],
          onPressed: () async {
            if (userData == null) return;
            final changed = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (_) => EditProfileScreen(userData: userData!),
              ),
            );
            if (changed == true) _fetchUserData();
          },
        ),
        SizedBox(height: 16.h),
        _buildGradientButton(
          "LOGOUT",
          [AppColors.logoutOrange, AppColors.logoutPink],
          onPressed: _handleLogout,
        ),
        SizedBox(height: 16.h),
        _buildGradientButton(
          "DELETE ACCOUNT",
          [AppColors.deleteGrey, AppColors.deleteRed],
          onPressed: _handleDeleteAccount,
        ),
      ],
    );
  }

  Widget _buildGradientButton(String label, List<Color> colors, {VoidCallback? onPressed}) {
    return Container(
      width: double.infinity,
      height: 60.h,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(30.h),
        boxShadow: [
          BoxShadow(
            color: colors[0].withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(30.h),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAgeBadge(bool isAdult) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isAdult 
            ? [AppColors.accentCyan, AppColors.createGradientPurple] 
            : [AppColors.selectionGreenStart, AppColors.selectionGreenEnd],
        ),
        borderRadius: BorderRadius.circular(8.h),
        boxShadow: [
          BoxShadow(
            color: (isAdult ? AppColors.accentCyan : AppColors.selectionGreenStart).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        isAdult ? "PRO" : "YOUTH",
        style: TextStyle(
          color: isAdult ? Colors.white : Colors.black,
          fontSize: 10.sp,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
