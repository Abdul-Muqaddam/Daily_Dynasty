import 'package:flutter/material.dart';
import '../core/colors.dart';
import '../core/responsive_helper.dart';

class GameRecapScreen extends StatelessWidget {
  const GameRecapScreen({super.key});

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
          "GAME RECAP",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: EdgeInsets.all(20.w),
        children: [
          _buildRecapCard(
            matchup: "LIVERPOOL vs CHELSEA",
            score: "2 - 1",
            date: "OCT 22, 2025",
            mvp: "Mo Salah",
            highlights: "Salah scored a stunning volley in the 85th minute to seal the win.",
          ),
          SizedBox(height: 20.h),
          _buildRecapCard(
            matchup: "MAN. UTD vs MAN. CITY",
            score: "1 - 3",
            date: "OCT 21, 2025",
            mvp: "Erling Haaland",
            highlights: "Haaland's hat-trick dominated the derby as City cruised to victory.",
          ),
          SizedBox(height: 20.h),
          _buildRecapCard(
            matchup: "MARSEILLE vs PSG",
            score: "0 - 2",
            date: "OCT 20, 2025",
            mvp: "Kylian Mbappé",
            highlights: "Mbappé's speed was too much for Marseille's defense in Le Classique.",
          ),
        ],
      ),
    );
  }

  Widget _buildRecapCard({
    required String matchup,
    required String score,
    required String date,
    required String mvp,
    required String highlights,
  }) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20.h),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(date, style: TextStyle(color: Colors.white38, fontSize: 10.sp, fontWeight: FontWeight.bold)),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppColors.accentCyan.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.h),
                ),
                child: Text("FINAL", style: TextStyle(color: AppColors.accentCyan, fontSize: 9.sp, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            matchup,
            style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 4.h),
          Text(
            score,
            style: TextStyle(color: AppColors.accentCyan, fontSize: 24.sp, fontWeight: FontWeight.w900, letterSpacing: 2.0),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Icon(Icons.star, color: AppColors.gold, size: 16.w),
              SizedBox(width: 8.w),
              Text("MVP: ", style: TextStyle(color: Colors.white38, fontSize: 12.sp, fontWeight: FontWeight.bold)),
              Text(mvp, style: TextStyle(color: Colors.white70, fontSize: 12.sp, fontWeight: FontWeight.bold)),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            highlights,
            style: TextStyle(color: Colors.white54, fontSize: 13.sp, height: 1.4),
          ),
        ],
      ),
    );
  }
}
