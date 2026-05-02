import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/colors.dart';
import '../core/responsive_helper.dart';
import '../services/league_service.dart';
import '../services/pick_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

class TeamDetailsScreen extends StatelessWidget {
  final String leagueId;
  final String userId;
  final String? teamName;
  final String? username;
  final String? photoUrl;

  const TeamDetailsScreen({
    super.key,
    required this.leagueId,
    required this.userId,
    this.teamName,
    this.username,
    this.photoUrl,
  });

  @override
  Widget build(BuildContext context) {
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
          (teamName ?? 'TEAM DETAILS').toUpperCase(),
          style: TextStyle(
            color: Colors.white,
            fontSize: 16.sp,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: LeagueService.getRosterStream(leagueId, userId),
        builder: (context, rosterSnap) {
          if (rosterSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.accentCyan));
          }

          final players = rosterSnap.data ?? [];
          
          // 10 standard starter slots
          final List<String> rosterSlots = [
            'QB', 'RB', 'RB', 'WR', 'WR', 'WR', 'TE', 'WRT', 'SFLEX', 'K'
          ];
          const int benchSlots = 5;

          // Map players to starter slots
          final List<Map<String, dynamic>?> starterRows = List.filled(rosterSlots.length, null);
          // Include everyone EXCEPT IR and TAXI in the pool for starters
          final List<Map<String, dynamic>> unassignedStarters = List.from(players.where((p) {
             final pos = p['pos']?.toString().toUpperCase() ?? 'BN';
             return !pos.startsWith('TAXI') && !pos.startsWith('IR');
          }));

          for (int i = 0; i < rosterSlots.length; i++) {
            final slot = rosterSlots[i];
            for (int j = 0; j < unassignedStarters.length; j++) {
              final p = unassignedStarters[j];
              final pPos = (p['primaryPos'] ?? p['pos'])?.toString().toUpperCase() ?? '';
              
              final isQB = pPos.startsWith('QB');
              final isRB = pPos.startsWith('RB');
              final isWR = pPos.startsWith('WR');
              final isTE = pPos.startsWith('TE');
              final isK = pPos.startsWith('K');
              
              final isFlexEligible = isWR || isRB || isTE;
              final isSuperFlexEligible = isFlexEligible || isQB;

              bool matches = false;
              if (slot == 'QB' && isQB) matches = true;
              else if (slot == 'RB' && isRB) matches = true;
              else if (slot == 'WR' && isWR) matches = true;
              else if (slot == 'TE' && isTE) matches = true;
              else if (slot == 'K' && isK) matches = true;
              else if ((slot == 'WRT' || slot == 'FLEX') && isFlexEligible) matches = true;
              else if (slot == 'SFLEX' && isSuperFlexEligible) matches = true;

              if (matches) {
                starterRows[i] = p;
                unassignedStarters.removeAt(j);
                break;
              }
            }
          }

          final List<Map<String, dynamic>> benchPlayers = players.where((p) {
            final pos = p['pos']?.toString().toUpperCase() ?? 'BN';
            return pos.startsWith('BN');
          }).toList();
          benchPlayers.addAll(unassignedStarters);

          return ListView(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            children: [
              _buildTeamHeader(context),
              _buildSectionHeader("Starters"),
              ...List.generate(rosterSlots.length, (i) {
                final slot = rosterSlots[i];
                final player = starterRows[i];
                return _buildPlayerRow(
                  player ?? {'pos': slot},
                  isPlaceholder: player == null,
                );
              }),
              _buildSectionHeader("BENCH"),
              ...List.generate(benchSlots, (i) {
                final player = i < benchPlayers.length ? benchPlayers[i] : null;
                return _buildPlayerRow(
                  player ?? {'pos': 'BN'},
                  slot: 'BN',
                  isPlaceholder: player == null,
                );
              }),
              SizedBox(height: 48.h),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTeamHeader(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 24.h, bottom: 16.h),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.h),
        border: Border.all(color: AppColors.accentCyan.withOpacity(0.1)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surface,
            AppColors.accentCyan.withAlpha(10),
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: AppColors.accentCyan.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.shield, color: AppColors.accentCyan, size: 24.w),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (teamName ?? 'TEAM').toUpperCase(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  "@${username ?? 'Manager'}",
                  style: TextStyle(color: Colors.white38, fontSize: 10.sp, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16.h),
      child: Row(
        children: [
          Container(width: 4.w, height: 16.h, decoration: BoxDecoration(color: AppColors.accentCyan, borderRadius: BorderRadius.circular(2.w))),
          SizedBox(width: 12.w),
          Text(title, style: TextStyle(color: Colors.white70, fontSize: 12.sp, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
        ],
      ),
    );
  }

  Widget _buildPlayerRow(Map<String, dynamic> player, {String? slot, bool isPlaceholder = false}) {
    final displaySlot = slot ?? player['pos']?.toString() ?? 'BN';
    final posColor = _getPositionColor(displaySlot);

    if (isPlaceholder) {
      return Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12.h),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Container(
              width: 38.w,
              padding: EdgeInsets.symmetric(vertical: 4.h),
              decoration: BoxDecoration(
                color: posColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6.h),
                border: Border.all(color: posColor.withOpacity(0.3)),
              ),
              child: Center(
                child: Text(
                  displaySlot,
                  style: TextStyle(color: posColor, fontSize: 10.sp, fontWeight: FontWeight.w900),
                ),
              ),
            ),
            SizedBox(width: 16.w),
            Text(
              "Empty",
              style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    final dynamic gradeValue = player['grade'];
    final double grade = gradeValue is num ? gradeValue.toDouble() : double.tryParse(gradeValue?.toString() ?? '0') ?? 0.0;
    final team = player['team'] as String? ?? 'FA';
    final bye = player['bye_week']?.toString() ?? '-';
    final imageUrl = player['imageUrl'] as String?;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.h),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            width: 38.w,
            padding: EdgeInsets.symmetric(vertical: 4.h),
            decoration: BoxDecoration(
              color: displaySlot == 'BN' ? Colors.white10 : posColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6.h),
              border: displaySlot == 'BN' ? null : Border.all(color: posColor.withOpacity(0.3)),
            ),
            child: Center(
              child: Text(
                displaySlot,
                style: TextStyle(
                  color: displaySlot == 'BN' ? Colors.white24 : posColor,
                  fontSize: 10.sp, 
                  fontWeight: FontWeight.w900
                ),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          CircleAvatar(
            radius: 18.w,
            backgroundColor: AppColors.createGradientPurple.withOpacity(0.1),
            backgroundImage: imageUrl != null && imageUrl.isNotEmpty ? CachedNetworkImageProvider(imageUrl) : null,
            child: imageUrl == null || imageUrl.isEmpty
                ? Icon(Icons.person, color: Colors.white24, size: 20.w)
                : null,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (player['name'] as String? ?? 'Unknown Player').toUpperCase(),
                  style: TextStyle(color: Colors.white, fontSize: 13.sp, fontWeight: FontWeight.w900, overflow: TextOverflow.ellipsis),
                ),
                SizedBox(height: 4.h),
                Text(
                  '$team • BYE $bye',
                  style: TextStyle(color: Colors.white38, fontSize: 10.sp, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8.h),
            ),
            child: Text(
              grade.toStringAsFixed(1),
              style: TextStyle(color: AppColors.accentTeal, fontSize: 12.sp, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }

  Color _getPositionColor(String position) {
    switch (position.toUpperCase()) {
      case 'QB': return const Color(0xFFFF4B4B); 
      case 'RB': case 'RB1': case 'RB2': return const Color(0xFF00E676);
      case 'WR': case 'WR1': case 'WR2': case 'WR3': return const Color(0xFF2196F3);
      case 'TE': return const Color(0xFFFF9800);
      case 'K': return const Color(0xFF9C27B0);
      case 'WRT': case 'FLEX': return const Color(0xFF00BCD4);
      case 'SFLEX': return const Color(0xFFCDDC39);
      default: return Colors.white24;
    }
  }
}
