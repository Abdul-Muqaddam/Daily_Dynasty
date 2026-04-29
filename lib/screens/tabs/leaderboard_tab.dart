import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/colors.dart';
import '../../core/responsive_helper.dart';
import '../../widgets/profile_avatar.dart';

enum LeaderboardCategory {
  topPointsCurrentSeason,
  bestSeasonEver,
  allTimePoints,
  allTimeWins,
  allTimeChampionships,
  longestWinStreak,
}

class LeaderboardTab extends StatefulWidget {
  const LeaderboardTab({super.key});

  @override
  State<LeaderboardTab> createState() => _LeaderboardTabState();
}

class _LeaderboardTabState extends State<LeaderboardTab> with SingleTickerProviderStateMixin {
  LeaderboardCategory _selectedCategory = LeaderboardCategory.topPointsCurrentSeason;
  List<Map<String, dynamic>> _entries = [];
  bool _isLoading = false;

  final List<_CategoryInfo> _categories = const [
    _CategoryInfo(LeaderboardCategory.topPointsCurrentSeason, "TOP POINTS", "This Season", Icons.emoji_events),
    _CategoryInfo(LeaderboardCategory.bestSeasonEver, "BEST SEASON", "All Time", Icons.star),
    _CategoryInfo(LeaderboardCategory.allTimePoints, "ALL-TIME PTS", "Career", Icons.analytics),
    _CategoryInfo(LeaderboardCategory.allTimeWins, "ALL-TIME WINS", "Career", Icons.thumb_up),
    _CategoryInfo(LeaderboardCategory.allTimeChampionships, "CHAMPS", "Championships", Icons.military_tech),
    _CategoryInfo(LeaderboardCategory.longestWinStreak, "WIN STREAK", "Longest", Icons.local_fire_department),
  ];

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    setState(() => _isLoading = true);
    try {
      final field = _getFirestoreField(_selectedCategory);
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .orderBy(field, descending: true)
          .limit(50)
          .get();

      final results = snap.docs.map((d) {
        final data = d.data();
        return {
          'uid': d.id,
          'username': data['username'] ?? 'MANAGER',
          'teamName': data['teamName'] ?? 'UNNAMED TEAM',
          'photoUrl': data['photoUrl'],
          'value': data[field] ?? 0,
          'tier': data['tier'] ?? 'Rookie',
        };
      }).toList();

      if (mounted) setState(() { _entries = results; _isLoading = false; });
    } catch (e) {
      // Fallback: show empty state
      if (mounted) setState(() { _entries = []; _isLoading = false; });
    }
  }

  String _getFirestoreField(LeaderboardCategory cat) {
    switch (cat) {
      case LeaderboardCategory.topPointsCurrentSeason:   return 'pointsThisSeason';
      case LeaderboardCategory.bestSeasonEver:           return 'bestSeasonPoints';
      case LeaderboardCategory.allTimePoints:            return 'allTimePoints';
      case LeaderboardCategory.allTimeWins:              return 'allTimeWins';
      case LeaderboardCategory.allTimeChampionships:     return 'championships';
      case LeaderboardCategory.longestWinStreak:         return 'longestWinStreak';
    }
  }

  String _getValueLabel(LeaderboardCategory cat) {
    switch (cat) {
      case LeaderboardCategory.allTimeChampionships:     return ' 🏆';
      case LeaderboardCategory.allTimeWins:
      case LeaderboardCategory.longestWinStreak:         return ' W';
      default:                                           return ' PTS';
    }
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveHelper.init(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(),
          _buildCategorySelector(),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(24.w, 40.h, 24.w, 16.h),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "LEADERBOARD",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28.sp,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                  ),
                ),
                Text(
                  "Global Rankings",
                  style: TextStyle(color: Colors.white38, fontSize: 13.sp),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: AppColors.gold.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.h),
              border: Border.all(color: AppColors.gold.withOpacity(0.3)),
            ),
            child: Icon(Icons.leaderboard, color: AppColors.gold, size: 24.w),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySelector() {
    return SizedBox(
      height: 80.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: _categories.length,
        itemBuilder: (context, i) {
          final cat = _categories[i];
          final isSelected = _selectedCategory == cat.category;
          return GestureDetector(
            onTap: () {
              setState(() => _selectedCategory = cat.category);
              _loadLeaderboard();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(right: 10.w, top: 4.h, bottom: 4.h),
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.accentCyan.withOpacity(0.15) : AppColors.surface,
                borderRadius: BorderRadius.circular(12.h),
                border: Border.all(
                  color: isSelected ? AppColors.accentCyan : Colors.white.withOpacity(0.06),
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(cat.icon, color: isSelected ? AppColors.accentCyan : Colors.white38, size: 18.w),
                  SizedBox(height: 4.h),
                  Text(
                    cat.label,
                    style: TextStyle(
                      color: isSelected ? AppColors.accentCyan : Colors.white38,
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    cat.subtitle,
                    style: TextStyle(color: Colors.white24, fontSize: 7.sp),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.accentCyan));
    }

    if (_entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.leaderboard_outlined, color: Colors.white12, size: 60.w),
            SizedBox(height: 16.h),
            Text(
              "NO DATA YET",
              style: TextStyle(color: Colors.white38, fontSize: 14.sp, fontWeight: FontWeight.w900, letterSpacing: 1.5),
            ),
            SizedBox(height: 6.h),
            Text(
              "Complete a season to appear here",
              style: TextStyle(color: Colors.white24, fontSize: 11.sp),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      itemCount: _entries.length,
      itemBuilder: (context, index) => _buildLeaderboardRow(_entries[index], index + 1),
    );
  }

  Widget _buildLeaderboardRow(Map<String, dynamic> entry, int rank) {
    final isTop3 = rank <= 3;
    final Color rankColor = rank == 1
        ? AppColors.gold
        : rank == 2
            ? const Color(0xFFC0C0C0)
            : rank == 3
                ? const Color(0xFFCD7F32)
                : Colors.white24;

    final value = entry['value'];
    final valueLabel = _getValueLabel(_selectedCategory);

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: isTop3 ? rankColor.withOpacity(0.06) : AppColors.surface,
        borderRadius: BorderRadius.circular(14.h),
        border: Border.all(
          color: isTop3 ? rankColor.withOpacity(0.3) : Colors.white.withOpacity(0.04),
          width: isTop3 ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          // Rank
          SizedBox(
            width: 36.w,
            child: Center(
              child: isTop3
                  ? Icon(
                      rank == 1 ? Icons.looks_one : rank == 2 ? Icons.looks_two : Icons.looks_3,
                      color: rankColor,
                      size: 24.w,
                    )
                  : Text(
                      '#$rank',
                      style: TextStyle(color: Colors.white38, fontSize: 12.sp, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
          SizedBox(width: 12.w),
          // Avatar
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accentCyan.withOpacity(0.1),
              border: Border.all(color: isTop3 ? rankColor.withOpacity(0.4) : Colors.white10),
            ),
            child: ClipOval(
                child: buildProfileImage(
                  photoUrl: entry['photoUrl'] as String?,
                  size: 40.w,
                  fallback: Icon(Icons.person, color: Colors.white38, size: 22.w),
                ),
              ),
          ),
          SizedBox(width: 12.w),
          // Name & Team
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (entry['username'] ?? 'MANAGER').toString().toUpperCase(),
                  style: TextStyle(
                    color: isTop3 ? rankColor : Colors.white,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  (entry['teamName'] ?? '---').toString().toUpperCase(),
                  style: TextStyle(color: Colors.white38, fontSize: 10.sp, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          // Tier Badge
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(6.h),
            ),
            child: Text(
              (entry['tier'] ?? 'Rookie').toString().toUpperCase(),
              style: TextStyle(color: Colors.white38, fontSize: 8.sp, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(width: 12.w),
          // Score
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatValue(value),
                style: TextStyle(
                  color: isTop3 ? rankColor : AppColors.accentCyan,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                valueLabel.trim(),
                style: TextStyle(color: Colors.white24, fontSize: 8.sp, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatValue(dynamic value) {
    if (value is double) return value.toStringAsFixed(1);
    return value.toString();
  }
}

class _CategoryInfo {
  final LeaderboardCategory category;
  final String label;
  final String subtitle;
  final IconData icon;
  const _CategoryInfo(this.category, this.label, this.subtitle, this.icon);
}
