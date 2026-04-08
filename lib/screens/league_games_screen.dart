import 'package:flutter/material.dart';
import '../core/colors.dart';
import '../core/responsive_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/user_service.dart';

class LeagueGamesScreen extends StatefulWidget {
  final String leagueId;
  const LeagueGamesScreen({super.key, required this.leagueId});

  @override
  State<LeagueGamesScreen> createState() => _LeagueGamesScreenState();
}

class _LeagueGamesScreenState extends State<LeagueGamesScreen> {
  final Map<String, String> _managerNames = {};

  void _fetchManagerNames(List<String> uids) async {
    bool hasNew = uids.any((uid) => !_managerNames.containsKey(uid));
    if (!hasNew) return;

    await UserService.preloadUsernames(uids);
    if (mounted) {
      setState(() {
        for (var uid in uids) {
          _managerNames[uid] = UserService.getCachedUsername(uid) ?? "MANAGER ${uid.substring(0, 4)}";
        }
      });
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
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('leagues')
            .doc(widget.leagueId)
            .collection('matches')
            .orderBy('week', descending: true)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.accentCyan));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.sports_football_outlined, color: Colors.white10, size: 64.w),
                  SizedBox(height: 16.h),
                  Text("NO GAMES PLAYED", style: TextStyle(color: Colors.white38, fontSize: 16.sp, fontWeight: FontWeight.bold)),
                ],
              ),
            );
          }

          final matches = snapshot.data!.docs;
          
          // Trigger name fetch for all teams in matches
          final allUids = <String>{};
          for (var doc in matches) {
            final m = doc.data() as Map<String, dynamic>;
            allUids.add(m['team1'].toString());
            allUids.add(m['team2'].toString());
          }
          
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _fetchManagerNames(allUids.toList());
          });

          return ListView.separated(
            padding: EdgeInsets.all(20.w),
            itemCount: matches.length,
            separatorBuilder: (_, __) => SizedBox(height: 16.h),
            itemBuilder: (context, index) {
              final match = matches[index].data() as Map<String, dynamic>;
              final t1 = match['team1'].toString();
              final t2 = match['team2'].toString();
              
              return _buildLeagueMatchCard(
                team1: _managerNames[t1] ?? "MANAGER ${t1.substring(0, 4)}",
                team2: _managerNames[t2] ?? "MANAGER ${t2.substring(0, 4)}",
                score1: (match['score1'] as num? ?? 0.0).toStringAsFixed(1),
                score2: (match['score2'] as num? ?? 0.0).toStringAsFixed(1),
                status: "WEEK ${match['week']}",
                isLive: false, // We don't have true live games yet
              );
            },
          );
        },
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
                  color: isLive ? AppColors.accentCyan.withOpacity(0.1) : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8.h),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: isLive ? AppColors.accentCyan : Colors.white38,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (isLive)
                Container(
                  width: 8.w,
                  height: 8.w,
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                ),
            ],
          ),
          SizedBox(height: 20.h),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(team1, style: TextStyle(color: Colors.white, fontSize: 15.sp, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                    SizedBox(height: 4.h),
                    Text(score1, style: TextStyle(color: AppColors.accentCyan, fontSize: 24.sp, fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Text("VS", style: TextStyle(color: Colors.white10, fontSize: 18.sp, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(team2, style: TextStyle(color: Colors.white, fontSize: 15.sp, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                    SizedBox(height: 4.h),
                    Text(score2, style: TextStyle(color: AppColors.accentCyan, fontSize: 24.sp, fontWeight: FontWeight.w900)),
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
