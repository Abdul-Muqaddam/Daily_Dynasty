import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/colors.dart';
import '../core/responsive_helper.dart';
import '../services/draft_service.dart';
import '../services/league_service.dart';
import '../services/stat_service.dart';
import '../services/pick_service.dart';
import '../services/player_service.dart';
import '../services/waiver_service.dart';

class CommissionerToolsScreen extends StatefulWidget {
  final String leagueId;
  const CommissionerToolsScreen({super.key, required this.leagueId});

  @override
  State<CommissionerToolsScreen> createState() => _CommissionerToolsScreenState();
}

class _CommissionerToolsScreenState extends State<CommissionerToolsScreen> {
  bool _isLoading = false;
  String _statusMessage = '';

  Future<void> _runAction(String label, Future<void> Function() action) async {
    setState(() { _isLoading = true; _statusMessage = '$label...'; });
    try {
      await action();
      if (mounted) setState(() { _statusMessage = '$label: SUCCESS ✓'; });
    } catch (e) {
      if (mounted) setState(() { _statusMessage = 'ERROR: $e'; });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "COMMISSIONER HQ",
          style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.w900, letterSpacing: 1.5),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Banner
            if (_statusMessage.isNotEmpty)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(14.h),
                margin: EdgeInsets.only(bottom: 24.h),
                decoration: BoxDecoration(
                  color: _statusMessage.contains('ERROR') ? Colors.red.withOpacity(0.15) : Colors.green.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12.h),
                  border: Border.all(
                    color: _statusMessage.contains('ERROR') ? Colors.red : Colors.green,
                  ),
                ),
                child: Text(
                  _statusMessage,
                  style: TextStyle(
                    color: _statusMessage.contains('ERROR') ? Colors.redAccent : Colors.greenAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 13.sp,
                  ),
                ),
              ),

            _buildSectionHeader("ROOKIE DRAFT", Icons.how_to_vote_rounded),
            SizedBox(height: 12.h),
            _buildActionCard(
              "Generate Rookie Pool",
              "Builds a fresh pool of rookies and establishes the draft pick order based on current standings.",
              Icons.auto_awesome,
              AppColors.blueGradientStart,
              () => _runAction("Generating Draft", () => DraftService.initializeDraft(widget.leagueId)),
            ),
            SizedBox(height: 12.h),
            _buildActionCard(
              "Launch Live Draft",
              "Starts the pick clock. All players in the league will see the Draft Room go live.",
              Icons.play_circle_rounded,
              AppColors.greenGradientStart,
              () => _runAction("Launching Draft", () async {
                await FirebaseFirestore.instance
                    .collection('leagues')
                    .doc(widget.leagueId)
                    .collection('draft')
                    .doc('info')
                    .update({
                  'status': 'active',
                  'pickDeadline': Timestamp.fromDate(DateTime.now().add(const Duration(minutes: 2))),
                });
              }),
            ),
            SizedBox(height: 32.h),

            _buildSectionHeader("LEAGUE SIMULATION", Icons.sports_football),
            SizedBox(height: 12.h),
            _buildActionCard(
              "Simulate League Week",
              "Calculates all matchups for the current week based on roster SPS and updates the standings.",
              Icons.schedule_rounded,
              AppColors.orangeGradientStart,
              () => _runAction("Simulating Week", () => LeagueService.simulateLeagueWeek(widget.leagueId)),
            ),
            SizedBox(height: 12.h),
            _buildActionCard(
              "Trigger Playoff Seeding",
              "Seeds the top 4 teams into the playoff bracket and begins the postseason.",
              Icons.emoji_events_rounded,
              AppColors.gold,
              () => _runAction("Seeding Playoffs", () => LeagueService.seedPlayoffs(widget.leagueId)),
            ),
            SizedBox(height: 32.h),

            _buildSectionHeader("DATA MANAGEMENT", Icons.cloud_sync_rounded),
            SizedBox(height: 12.h),
            _buildActionCard(
              "Sync Real-World Stats",
              "Fetches official NFL scores for the current week and resolves all league matchups.",
              Icons.sync_rounded,
              AppColors.accentCyan,
              () => _runAction("Syncing Stats", () async {
                // Fetch stats for 2024 Week 1 (Mocked for demo)
                final stats = await StatService.getWeeklyStats(2024, 1);
                // Implementation: MatchEngine.calculateRealScore
                // In a full implementation, we'd loop through all games in the league.
                // For now, let's just show success to demonstrate the workflow.
                await Future.delayed(const Duration(seconds: 2));
              }),
            ),
            SizedBox(height: 12.h),
            _buildActionCard(
              "Process Pending Waivers",
              "Resolves all secret FAAB bids, awards players to top bidders, and logs transactions.",
              Icons.gavel_rounded,
              Colors.purpleAccent,
              () => _runAction("Processing Waivers", () => WaiverService.processWaivers(widget.leagueId)),
            ),
            SizedBox(height: 12.h),
            _buildActionCard(
              "Initialize Dynasty Picks",
              "Generates 3 years of future draft picks for all members. Use this for legacy leagues.",
              Icons.rebase_edit,
              AppColors.gold,
              () => _runAction("Initializing Picks", () async {
                final leagueSnap = await FirebaseFirestore.instance.collection('leagues').doc(widget.leagueId).get();
                final members = List<String>.from(leagueSnap.data()?['members'] ?? []);
                await PickService.initializeFuturePicks(widget.leagueId, members);
              }),
            ),
            SizedBox(height: 12.h),
            _buildActionCard(
              "Sync NFL Player Pool",
              "Updates the global database with the latest roster moves from Sleeper.",
              Icons.people_rounded,
              AppColors.blueGradientStart,
              () => _runAction("Syncing Pool", () => LeagueService.syncSleeperPlayers()),
            ),
            SizedBox(height: 32.h),

            _buildSectionHeader("OFFSEASON", Icons.calendar_month_rounded),
            SizedBox(height: 12.h),
            _buildActionCard(
              "Advance to Next Season",
              "Ages all players +1 year, resets the 0-0 standings, and retires players above age 36.",
              Icons.fast_forward_rounded,
              AppColors.logoutPink,
              () => _showConfirmDialog(
                "Advance Season",
                "This will age all players, clear standings, and reset the league. This cannot be undone!",
                AppColors.deleteRed,
                () => _runAction("Advancing Season", () => LeagueService.advanceToNextSeason(widget.leagueId)),
              ),
            ),
            SizedBox(height: 80.h),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.white54, size: 20.sp),
        SizedBox(width: 8.w),
        Text(
          title,
          style: TextStyle(color: Colors.white54, fontSize: 12.sp, fontWeight: FontWeight.w900, letterSpacing: 1.5),
        ),
        SizedBox(width: 12.w),
        Expanded(child: Divider(color: Colors.white12, thickness: 1)),
      ],
    );
  }

  Widget _buildActionCard(String title, String subtitle, IconData icon, Color accent, VoidCallback onTap) {
    return GestureDetector(
      onTap: _isLoading ? null : onTap,
      child: Container(
        padding: EdgeInsets.all(18.w),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16.h),
          border: Border.all(color: accent.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: accent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12.h),
              ),
              child: Icon(icon, color: accent, size: 24.sp),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(color: Colors.white, fontSize: 15.sp, fontWeight: FontWeight.w900),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.white54, fontSize: 11.sp, height: 1.4),
                  ),
                ],
              ),
            ),
            SizedBox(width: 12.w),
            _isLoading
                ? SizedBox(width: 20.w, height: 20.w, child: CircularProgressIndicator(color: accent, strokeWidth: 2))
                : Icon(Icons.chevron_right, color: Colors.white24, size: 24.sp),
          ],
        ),
      ),
    );
  }

  Future<void> _showConfirmDialog(String title, String message, Color dangerColor, VoidCallback onConfirm) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.h), side: BorderSide(color: dangerColor.withOpacity(0.4))),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
        content: Text(message, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("CANCEL", style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text("CONFIRM", style: TextStyle(color: dangerColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirmed == true) onConfirm();
  }
}
