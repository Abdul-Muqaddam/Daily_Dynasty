import 'package:flutter/material.dart';
import '../core/colors.dart';
import '../core/responsive_helper.dart';

class PlayerProfileScreen extends StatelessWidget {
  final String name;
  final String pos;
  final String team;
  final String sps;
  final String exp;

  const PlayerProfileScreen({
    super.key,
    required this.name,
    required this.pos,
    this.team = "GRIDIRON KINGS",
    required this.sps,
    required this.exp,
  });

  @override
  Widget build(BuildContext context) {
    ResponsiveHelper.init(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background Gradient decoration
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300.w,
              height: 300.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accentCyan.withOpacity(0.05),
              ),
            ),
          ),
          
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  SizedBox(height: 30.h),
                  _buildPlayerInfo(),
                  SizedBox(height: 30.h),
                  _buildBasicMetrics(),
                  SizedBox(height: 30.h),
                  _buildStatsSection(),
                  SizedBox(height: 30.h),
                  _buildSeasonTotals(),
                  SizedBox(height: 30.h),
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
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20.w),
          ),
        ),
        Text(
          "PLAYER PROFILE",
          style: TextStyle(
            color: Colors.white,
            fontSize: 16.sp,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
          ),
        ),
        SizedBox(width: 40.w), // Balance for back button
      ],
    );
  }

  Widget _buildPlayerInfo() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Player Image Placeholder
        Container(
          width: 100.w,
          height: 120.h,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20.h),
            border: Border.all(color: Colors.white10),
          ),
          child: Icon(Icons.person, size: 80.w, color: Colors.white24),
        ),
        SizedBox(width: 20.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name.toUpperCase(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
              Text(
                team.toUpperCase(),
                style: TextStyle(
                  color: AppColors.accentCyan,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              SizedBox(height: 15.h),
              Row(
                children: [
                  _buildActionButton(
                    label: "TRADE",
                    color: const Color(0xFF1E88E5), // Blue
                    onPressed: () {},
                  ),
                  SizedBox(width: 10.w),
                  _buildActionButton(
                    label: "DROP",
                    color: const Color(0xFFE53935), // Red
                    onPressed: () {},
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({required String label, required Color color, required VoidCallback onPressed}) {
    return Expanded(
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 10.h),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12.h),
            border: Border.all(color: color.withOpacity(0.5)),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12.sp,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBasicMetrics() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20.h),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "BASIC METRICS",
            style: TextStyle(
              color: Colors.white38,
              fontSize: 12.sp,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: 20.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMetricItem("POS", pos),
              _buildMetricItem("AGE", "24"), // Mock data
              _buildMetricItem("HEIGHT", "6'1\""), // Mock data
              _buildMetricItem("WEIGHT", "215 lbs"), // Mock data
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white24,
            fontSize: 10.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14.sp,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "PERFORMANCE DATA",
          style: TextStyle(
            color: Colors.white38,
            fontSize: 12.sp,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
        SizedBox(height: 15.h),
        Row(
          children: [
            _buildStatBox("SPS GRADE", sps, AppColors.accentCyan),
            _buildStatBox("EXPERIENCE", exp, Colors.orange),
            _buildStatBox("LEAGUE RANK", "#12", Colors.purpleAccent),
          ],
        ),
      ],
    );
  }

  Widget _buildStatBox(String label, String value, Color color) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 4.w),
        padding: EdgeInsets.symmetric(vertical: 16.h),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16.h),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: color.withOpacity(0.7),
                fontSize: 9.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18.sp,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeasonTotals() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20.h),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "SEASON TOTALS",
            style: TextStyle(
              color: Colors.white38,
              fontSize: 12.sp,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: 20.h),
          _buildTotalRow("GAMES PLAYED", "10"),
          _buildTotalRow("TOTAL POINTS", "184.5"),
          _buildTotalRow("AVG POINTS/GM", "18.45"),
          _buildTotalRow("TDs (ALL)", "12"),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14.sp,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
