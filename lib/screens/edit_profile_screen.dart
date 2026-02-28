import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/colors.dart';
import '../core/responsive_helper.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const EditProfileScreen({super.key, required this.userData});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _usernameController;
  late TextEditingController _fullNameController;
  late TextEditingController _bioController;

  String _selectedColor = 'blue';
  bool _isSaving = false;

  final List<Map<String, dynamic>> _colorOptions = [
    {'label': 'NEON', 'value': 'blue', 'color': AppColors.selectionBlueStart},
    {'label': 'PULSE', 'value': 'green', 'color': AppColors.selectionGreenStart},
    {'label': 'ROYAL', 'value': 'purple', 'color': AppColors.selectionPurpleStart},
    {'label': 'BLAZE', 'value': 'orange', 'color': AppColors.selectionOrangeStart},
  ];

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(
        text: widget.userData['username'] as String? ?? '');
    _fullNameController = TextEditingController(
        text: widget.userData['fullName'] as String? ?? '');
    _bioController = TextEditingController(
        text: widget.userData['bio'] as String? ?? '');
    _selectedColor = widget.userData['themeColor'] as String? ?? 'blue';
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _fullNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username cannot be empty')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'username': username,
        'fullName': _fullNameController.text.trim(),
        'bio': _bioController.text.trim(),
        'themeColor': _selectedColor,
      });

      if (mounted) {
        Navigator.pop(context, true); // Return true = data changed
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Color get _themeColor {
    switch (_selectedColor) {
      case 'green':
        return AppColors.selectionGreenStart;
      case 'purple':
        return AppColors.selectionPurpleStart;
      case 'orange':
        return AppColors.selectionOrangeStart;
      default:
        return AppColors.selectionBlueStart;
    }
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveHelper.init(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "EDIT PROFILE",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 16.w),
            child: GestureDetector(
              onTap: _isSaving ? null : _saveProfile,
              child: _isSaving
                  ? SizedBox(
                      width: 20.w,
                      height: 20.w,
                      child: const CircularProgressIndicator(
                          color: AppColors.accentCyan, strokeWidth: 2),
                    )
                  : Text(
                      "SAVE",
                      style: TextStyle(
                        color: AppColors.accentCyan,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAvatarSection(),
            SizedBox(height: 36.h),
            _buildSectionLabel("DISPLAY NAME"),
            SizedBox(height: 10.h),
            _buildTextField(
              controller: _usernameController,
              hint: "Enter username",
              icon: Icons.person_outline,
            ),
            SizedBox(height: 20.h),
            _buildSectionLabel("FULL NAME"),
            SizedBox(height: 10.h),
            _buildTextField(
              controller: _fullNameController,
              hint: "Enter full name",
              icon: Icons.badge_outlined,
            ),
            SizedBox(height: 20.h),
            _buildSectionLabel("BIO"),
            SizedBox(height: 10.h),
            _buildTextField(
              controller: _bioController,
              hint: "Tell the league about yourself...",
              icon: Icons.edit_note,
              maxLines: 3,
            ),
            SizedBox(height: 32.h),
            _buildSectionLabel("TEAM THEME"),
            SizedBox(height: 14.h),
            _buildColorSelector(),
            SizedBox(height: 40.h),
            _buildSaveButton(),
            SizedBox(height: 32.h),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarSection() {
    final photoUrl = widget.userData['photoUrl'] as String?;
    return Center(
      child: Stack(
        children: [
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _themeColor, width: 3.w),
              boxShadow: [
                BoxShadow(
                  color: _themeColor.withOpacity(0.25),
                  blurRadius: 20,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 60.w,
              backgroundColor: AppColors.surface,
              backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
              child: photoUrl == null
                  ? Icon(Icons.person, size: 60.w, color: Colors.white24)
                  : null,
            ),
          ),
          Positioned(
            bottom: 4.h,
            right: 4.w,
            child: Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: _themeColor,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.photo_camera, color: Colors.black, size: 18.w),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        color: Colors.white38,
        fontSize: 10.sp,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14.h),
        border: Border.all(color: Colors.white10),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: TextStyle(color: Colors.white, fontSize: 14.sp),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white24, fontSize: 13.sp),
          prefixIcon: Icon(icon, color: AppColors.accentCyan, size: 20.w),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16.w,
            vertical: 14.h,
          ),
        ),
      ),
    );
  }

  Widget _buildColorSelector() {
    return Row(
      children: _colorOptions.map((opt) {
        final isSelected = _selectedColor == opt['value'];
        final color = opt['color'] as Color;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedColor = opt['value'] as String),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.symmetric(horizontal: 4.w),
              padding: EdgeInsets.symmetric(vertical: 16.h),
              decoration: BoxDecoration(
                color: isSelected ? color.withOpacity(0.18) : AppColors.surface,
                borderRadius: BorderRadius.circular(14.h),
                border: Border.all(
                  color: isSelected ? color : Colors.white10,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 24.w,
                    height: 24.w,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    opt['label'] as String,
                    style: TextStyle(
                      color: isSelected ? color : Colors.white38,
                      fontSize: 9.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSaveButton() {
    return GestureDetector(
      onTap: _isSaving ? null : _saveProfile,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 18.h),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_themeColor, AppColors.createGradientPurple],
          ),
          borderRadius: BorderRadius.circular(16.h),
          boxShadow: [
            BoxShadow(
              color: _themeColor.withOpacity(0.35),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: _isSaving
              ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
              : Text(
                  "SAVE CHANGES",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
        ),
      ),
    );
  }
}
