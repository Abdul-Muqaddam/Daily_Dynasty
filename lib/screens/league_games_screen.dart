import 'package:flutter/material.dart';
import '../core/colors.dart';
import '../core/responsive_helper.dart';

class LeagueGamesScreen extends StatelessWidget {
  const LeagueGamesScreen({super.key});

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
          "LEAGUE GAMES",
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
          _buildLeagueMatchCard(
            team1: "GRIDIRON KINGS",
            team2: "CYBER TITANS",
            score1: "85.2",
            score2: "102.4",
            status: "LIVE",
            isLive: true,
          ),
          SizedBox(height: 16.h),
          _buildLeagueMatchCard(
            team1: "NEON KNIGHTS",
            team2: "DYNASTY WARRIORS",
            score1: "76.5",
            score2: "74.8",
            status: "FINAL",
          ),
          SizedBox(height: 16.h),
          _buildLeagueMatchCard(
            team1: "SHADOW RAIDERS",
            team2: "BLITZ BOMBERS",
            score1: "0.0",
            score2: "0.0",
            status: "SUN 1:00 PM",
          ),
        ],
      ),
    );
  }

  Widget _buildLeagueMatchCard({
    required String team1,
    required String team2,
    required String score1,
    required String score2,
    required String status,
    bool isLive = false,
  }) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20.h),
        border: Border.all(color: isLive ? AppColors.accentCyan.withOpacity(0.3) : Colors.white10),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: isLive ? Colors.red.withOpacity(0.1) : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10.h),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: isLive ? Colors.redAccent : Colors.white38,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (isLive)
                Icon(Icons.sensors, color: Colors.redAccent, size: 16.w),
            ],
          ),
          SizedBox(height: 20.h),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    CircleAvatar(radius: 24.w, backgroundColor: Colors.white10, child: Icon(Icons.shield, color: AppColors.accentCyan, size: 24.w)),
                    SizedBox(height: 12.h),
                    Text(team1, textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 12.sp, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Column(
                children: [
                  Row(
                    children: [
                      Text(score1, style: TextStyle(color: Colors.white, fontSize: 20.sp, fontWeight: FontWeight.w900)),
                      SizedBox(width: 12.w),
                      Text("VS", style: TextStyle(color: Colors.white24, fontSize: 14.sp, fontWeight: FontWeight.w900)),
                      SizedBox(width: 12.w),
                      Text(score2, style: TextStyle(color: Colors.white, fontSize: 20.sp, fontWeight: FontWeight.w900)),
                    ],
                  ),
                ],
              ),
              Expanded(
                child: Column(
                  children: [
                    CircleAvatar(radius: 24.w, backgroundColor: Colors.white10, child: Icon(Icons.shield, color: Colors.orangeAccent, size: 24.w)),
                    SizedBox(height: 12.h),
                    Text(team2, textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 12.sp, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
