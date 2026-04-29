import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/colors.dart';
import '../core/constants.dart';
import '../core/responsive_helper.dart';
import 'matches_screen.dart';
import 'age_verification_screen.dart';
import 'login_screen.dart';
import '../widgets/app_dialogs.dart';

class CreateUsernameScreen extends StatefulWidget {
  final Map<String, dynamic>? registrationData;
  const CreateUsernameScreen({super.key, this.registrationData});

  @override
  State<CreateUsernameScreen> createState() => _CreateUsernameScreenState();
}

class _CreateUsernameScreenState extends State<CreateUsernameScreen> {
  final TextEditingController _usernameController = TextEditingController();
  String _username = "YourUsername";
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  String? _usernameError;
  
  // Custom colors from design
  final List<Map<String, dynamic>> _colorOptions = [
    {
      'name': 'blue',
      'color': AppColors.selectionBlueStart,
      'gradient': [AppColors.selectionBlueStart, AppColors.selectionBlueEnd]
    },
    {
      'name': 'green',
      'color': AppColors.selectionGreenStart,
      'gradient': [AppColors.selectionGreenStart, AppColors.selectionGreenEnd]
    },
    {
      'name': 'purple',
      'color': AppColors.selectionPurpleStart,
      'gradient': [AppColors.selectionPurpleStart, AppColors.selectionPurpleEnd]
    },
    {
      'name': 'orange',
      'color': AppColors.selectionOrangeStart,
      'gradient': [AppColors.selectionOrangeStart, AppColors.selectionOrangeEnd]
    },
  ];

  int _selectedColorIndex = 0;

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 512, // Reduced size for faster upload
        maxHeight: 512,
        imageQuality: 75,
      );
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        AppDialogs.showPremiumErrorDialog(context, message: "Error picking image. Please try again.");
      }
    }
  }

  Future<void> _nextStep() async {
    final username = _usernameController.text.trim();
    
    setState(() => _usernameError = null);

    if (username.isEmpty) {
      setState(() => _usernameError = 'Please enter a username');
      return;
    }

    if (username.length < 3) {
      setState(() => _usernameError = 'Username too short');
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? photoUrl;
      if (_imageFile != null) {
        final bytes = await _imageFile!.readAsBytes();
        final base64Str = base64Encode(bytes);
        photoUrl = 'data:image/jpeg;base64,$base64Str';
      }

      if (widget.registrationData != null) {
        // Deferred Email/Password Registration Flow
        widget.registrationData!['username'] = username;
        widget.registrationData!['photoUrl'] = photoUrl;
        widget.registrationData!['themeColor'] = _colorOptions[_selectedColorIndex]['name'];
        
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AgeVerificationScreen(registrationData: widget.registrationData)),
          );
        }
      } else {
        // Google Sign-In Flow (User already exists in Firebase Auth)
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) throw Exception("User not logged in");

        // 1. Check if username is taken
        final query = await FirebaseFirestore.instance
            .collection('users')
            .where('username', isEqualTo: username)
            .get();

        if (query.docs.isNotEmpty && query.docs.first.id != user.uid) {
          setState(() {
            _usernameError = 'Username already taken';
            _isLoading = false;
          });
          return;
        }

        // 2. Save to Firestore (partial update)
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'username': username,
          'photoUrl': photoUrl,
          'themeColor': _colorOptions[_selectedColorIndex]['name'],
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // 3. Update Firebase Auth display name
        await user.updateDisplayName(username);

        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AgeVerificationScreen()),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        AppDialogs.showPremiumErrorDialog(context, message: "Error saving profile. Please check your connection.");
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showImageSourceDialog(Color selectedColor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: AppColors.brandDark,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(32.w),
            topRight: Radius.circular(32.w),
          ),
          border: Border.all(color: selectedColor.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(2.h),
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              'Select Image Source',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 24.h),
            _buildSourceOption(
              icon: Icons.photo_library_outlined,
              label: 'Choose from Gallery',
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
              color: selectedColor,
            ),
            SizedBox(height: 12.h),
            _buildSourceOption(
              icon: Icons.camera_alt_outlined,
              label: 'Take a Picture',
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
              color: selectedColor,
            ),
            SizedBox(height: 12.h),
            _buildSourceOption(
              icon: Icons.close,
              label: 'Cancel',
              onTap: () => Navigator.pop(context),
              color: Colors.white24,
              isCancel: true,
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
    bool isCancel = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.w),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 20.w),
        decoration: BoxDecoration(
          color: isCancel ? Colors.white.withOpacity(0.05) : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16.w),
          border: Border.all(color: isCancel ? Colors.white10 : color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: isCancel ? Colors.white54 : color, size: 24.sp),
            SizedBox(width: 16.w),
            Text(
              label,
              style: TextStyle(
                color: isCancel ? Colors.white54 : Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            if (!isCancel)
              Icon(Icons.arrow_forward_ios, color: color.withOpacity(0.5), size: 14.sp),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveHelper.init(context);
    final selectedColor = _colorOptions[_selectedColorIndex]['color'] as Color;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/signup_background.png', // Using the stadium background as requested
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.background.withOpacity(0.8),
                    AppColors.background.withOpacity(0.9),
                    AppColors.background,
                  ],
                ),
              ),
            ),
          ),
          
          // Subtle Glows
          Positioned(
            top: -100.h,
            left: 50.w,
            right: 50.w,
            child: Container(
              height: 300.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selectedColor.withOpacity(0.08),
                boxShadow: [
                  BoxShadow(color: selectedColor.withOpacity(0.08), blurRadius: 100, spreadRadius: 50),
                ],
              ),
            ),
          ),

          SafeArea(
            child: Stack(
              children: [
                SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Column(
                    children: [
                      SizedBox(height: 40.h),
                      _buildHeader(),
                      SizedBox(height: 40.h),
                      _buildAvatarSection(selectedColor),
                      SizedBox(height: 40.h),
                      _buildInputSection(selectedColor),
                      SizedBox(height: 40.h),
                      _buildColorSelection(),
                      SizedBox(height: 40.h),
                      _buildPreviewSection(selectedColor),
                      SizedBox(height: 40.h),
                      _buildNextButton(selectedColor),
                      SizedBox(height: 40.h),
                    ],
                  ),
                ),
                Positioned(
                  top: 10.h,
                  left: 10.w,
                  child: IconButton(
                    icon: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 24.sp),
                    onPressed: () async {
                      try {
                        final user = FirebaseAuth.instance.currentUser;
                        if (user != null) {
                          await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();
                          await user.delete();
                        }
                      } catch (_) {}
                      await FirebaseAuth.instance.signOut();
                      if (context.mounted) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Text(
          'Create Username',
          style: TextStyle(
            color: Colors.white,
            fontSize: 30.sp,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: 12.h),
        Text(
          'You can change this later in settings',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarSection(Color selectedColor) {
    return Center(
      child: Stack(
        children: [
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: selectedColor.withOpacity(0.3),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 64.w,
              backgroundColor: AppColors.surface,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: selectedColor.withOpacity(0.3), width: 2),
                  gradient: RadialGradient(
                    colors: [
                      selectedColor.withOpacity(0.2),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Center(
                  child: _imageFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(64.w),
                          child: Image.file(
                            _imageFile!,
                            width: 128.w,
                            height: 128.w,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Icon(
                          Icons.face_outlined, // As requested: outlined face icon
                          color: selectedColor.withOpacity(0.5),
                          size: 64.w,
                        ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: () => _showImageSourceDialog(selectedColor),
              child: Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [selectedColor, Color.lerp(selectedColor, Colors.white, 0.3)!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: selectedColor.withOpacity(0.5),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: AppColors.background, width: 2),
                ),
                child: Icon(Icons.camera_alt, color: Colors.white, size: 20.sp),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputSection(Color selectedColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Username',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12.h),
        Container(
          decoration: BoxDecoration(
            color: AppColors.brandDark.withOpacity(0.8),
            borderRadius: BorderRadius.circular(16.w),
            border: Border.all(
              color: _usernameError != null ? Colors.red : Colors.white10,
              width: 2,
            ),
          ),
          child: TextField(
            controller: _usernameController,
            onChanged: (value) {
              setState(() {
                _username = value.isEmpty ? "YourUsername" : value;
                if (_usernameError != null) _usernameError = null;
              });
            },
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Enter your username',
              hintStyle: const TextStyle(color: Colors.white24),
              contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.h),
              border: InputBorder.none,
            ),
          ),
        ),
        if (_usernameError != null)
          Padding(
            padding: EdgeInsets.only(left: 4.w, top: 8.h),
            child: Text(
              _usernameError!,
              style: TextStyle(color: Colors.red, fontSize: 12.sp),
            ),
          ),
        SizedBox(height: 12.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Text(
            '3–20 characters. Letters & numbers only.',
            style: TextStyle(
              color: Colors.white24,
              fontSize: 12.sp,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildColorSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose Your Color',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 20.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_colorOptions.length, (index) {
            final color = _colorOptions[index]['color'] as Color;
            final isSelected = _selectedColorIndex == index;
            
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 10.w),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedColorIndex = index;
                  });
                },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (isSelected)
                      Container(
                        width: 64.w,
                        height: 64.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: color, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(0.6),
                              blurRadius: 25,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    Container(
                      width: 54.w,
                      height: 54.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: _colorOptions[index]['gradient'],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildPreviewSection(Color selectedColor) {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: AppColors.brandDark.withOpacity(0.4),
        borderRadius: BorderRadius.circular(20.w),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Text(
            'PREVIEW',
            style: TextStyle(
              color: Colors.white24,
              fontSize: 10.sp,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Container(
                width: 48.w,
                height: 48.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selectedColor.withOpacity(0.15),
                  border: Border.all(color: selectedColor.withOpacity(0.3)),
                ),
                child: Center(
                  child: _imageFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(48.w),
                          child: Image.file(
                            _imageFile!,
                            width: 48.w,
                            height: 48.w,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Icon(
                          Icons.face_outlined,
                          color: selectedColor,
                          size: 24.sp,
                        ),
                ),
              ),
              SizedBox(width: 16.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _username,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Level 1 Player',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 12.sp,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNextButton(Color selectedColor) {
    return Container(
      width: double.infinity,
      height: 64.h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [selectedColor, Color.lerp(selectedColor, Colors.white, 0.4)!],
        ),
        borderRadius: BorderRadius.circular(32.h),
        boxShadow: [
          BoxShadow(
            color: selectedColor.withOpacity(0.4),
            blurRadius: 30,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : _nextStep,
          borderRadius: BorderRadius.circular(32.h),
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
                    'NEXT',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
