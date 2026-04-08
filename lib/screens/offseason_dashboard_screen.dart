import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/colors.dart';
import '../core/responsive_helper.dart';
import '../services/user_service.dart';

class OffseasonDashboardScreen extends StatefulWidget {
  final String leagueId;
  final String leagueName;
  final int seasonNumber;

  const OffseasonDashboardScreen({
    super.key,
    required this.leagueId,
    required this.leagueName,
    required this.seasonNumber,
  });

  @override
  State<OffseasonDashboardScreen> createState() => _OffseasonDashboardScreenState();
}

class _OffseasonDashboardScreenState extends State<OffseasonDashboardScreen> {
  final Map<String, String> _ownerNames = {};

  Future<String> _getOwnerName(String uid) async {
    if (_ownerNames.containsKey(uid)) return _ownerNames[uid]!;
    final name = await UserService.getUsername(uid);
    if (mounted) setState(() => _ownerNames[uid] = name);
    return name;
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveHelper.init(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "OFFSEASON HUB",
          style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.w900, letterSpacing: 1.5),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: EdgeInsets.all(20.w),
        children: [
          _buildSeasonHeader(),
          SizedBox(height: 24.h),
          _buildRetirementReport(),
          SizedBox(height: 24.h),
          _buildUpcomingDraftCard(),
          SizedBox(height: 50.h),
        ],
      ),
    );
  }

  Widget _buildSeasonHeader() {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24.h),
        border: Border.all(color: AppColors.accentCyan.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.history_edu, color: AppColors.accentCyan, size: 24.sp),
              SizedBox(width: 8.w),
              Text(
                "SEASON ${widget.seasonNumber} SUMMARY",
                style: TextStyle(color: AppColors.accentCyan, fontSize: 14.sp, fontWeight: FontWeight.w900, letterSpacing: 1.0),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Text(
            widget.leagueName,
            style: TextStyle(color: Colors.white, fontSize: 24.sp, fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 8.h),
          Text(
            "League state has been reset for the new year.\nStandings are 0-0. Players have aged +1.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white38, fontSize: 12.sp, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildRetirementReport() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.person_off, color: Colors.white54, size: 18.sp),
            SizedBox(width: 8.w),
            Text(
              "RETIREMENT REPORT",
              style: TextStyle(color: Colors.white70, fontSize: 14.sp, fontWeight: FontWeight.w900, letterSpacing: 0.5),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('leagues')
              .doc(widget.leagueId)
              .collection('transactions')
              .where('type', isEqualTo: 'retirement')
              .limit(20)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.all(20.w),
                  child: Text("Error loading report", style: TextStyle(color: Colors.redAccent.withOpacity(0.5), fontSize: 12.sp)),
                ),
              );
            }
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final docs = snapshot.data!.docs;

            if (docs.isEmpty) {
              return Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16.h)),
                child: Center(
                  child: Text(
                    "No players retired this season.",
                    style: TextStyle(color: Colors.white24, fontSize: 12.sp),
                  ),
                ),
              );
            }

            return Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16.h),
                border: Border.all(color: Colors.white10),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: docs.length,
                separatorBuilder: (context, _) => Divider(color: Colors.white.withOpacity(0.05), height: 1),
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final name = data['playerName'] ?? 'Unknown';
                  final pos = data['pos'] ?? '??';
                  final ownerId = data['ownerId'] as String?;

                  return ListTile(
                    dense: true,
                    leading: Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(4)),
                      child: Text(pos, style: TextStyle(color: Colors.white54, fontSize: 10.sp, fontWeight: FontWeight.bold)),
                    ),
                    title: Text(name, style: TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.bold)),
                    subtitle: ownerId != null 
                      ? FutureBuilder<String>(
                          future: _getOwnerName(ownerId),
                          builder: (context, snap) => Text("Last Team: ${snap.data ?? '...'}", style: TextStyle(color: Colors.white38, fontSize: 11.sp)),
                        )
                      : null,
                    trailing: Text("RETIRED", style: TextStyle(color: Colors.redAccent.withOpacity(0.8), fontSize: 10.sp, fontWeight: FontWeight.w900)),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildUpcomingDraftCard() {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.gold.withOpacity(0.2), AppColors.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24.h),
        border: Border.all(color: AppColors.gold.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(Icons.how_to_vote_rounded, color: AppColors.gold, size: 40.sp),
          SizedBox(height: 12.h),
          Text(
            "PREPARING FOR DRAFT",
            style: TextStyle(color: AppColors.gold, fontSize: 16.sp, fontWeight: FontWeight.w900, letterSpacing: 1.0),
          ),
          SizedBox(height: 8.h),
          Text(
            "The Rookie Draft pool is being finalized.\nThe Commissioner will launch the Draft Room soon.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, fontSize: 12.sp, height: 1.5),
          ),
          SizedBox(height: 20.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: AppColors.gold,
              borderRadius: BorderRadius.circular(12.h),
            ),
            child: Text(
              "VIEW DRAFT ORDER",
              style: TextStyle(color: Colors.black, fontSize: 12.sp, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}
