import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/colors.dart';
import '../core/responsive_helper.dart';
import '../services/training_service.dart';
import '../services/coin_service.dart';
import '../widgets/app_dialogs.dart';
import 'matches_screen.dart';

class TrainingScreen extends StatefulWidget {
  final Map<String, dynamic> player;
  final String leagueId;
  final String userId;
  final int playerIndex;

  const TrainingScreen({
    super.key,
    required this.player,
    required this.leagueId,
    required this.userId,
    required this.playerIndex,
  });

  @override
  State<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends State<TrainingScreen> {
  bool _isLoading = false;
  Timer? _timer;
  Duration _remainingTime = Duration.zero;
  Map<String, dynamic>? _livePlayer;

  @override
  void initState() {
    super.initState();
    _updateRemainingTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateRemainingTime());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateRemainingTime() {
    final player = _livePlayer ?? widget.player;
    if (player['trainingEndTime'] != null) {
      final endTime = (player['trainingEndTime'] as Timestamp).toDate();
      final now = DateTime.now();
      if (mounted) {
        setState(() {
          _remainingTime = endTime.isAfter(now) ? endTime.difference(now) : Duration.zero;
        });
      }
    }
  }

  Future<void> _handleStartTraining(TrainingBadgeType type) async {
    setState(() => _isLoading = true);
    try {
      await TrainingService.startTraining(
        leagueId: widget.leagueId,
        userId: widget.userId,
        playerIndex: widget.playerIndex.toString(),
        badgeType: type,
      );
      
      if (mounted) {
        setState(() => _isLoading = false);
        // Show Success Dialog
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(28.h),
                border: Border.all(color: AppColors.accentCyan.withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(color: AppColors.accentCyan.withOpacity(0.1), blurRadius: 20, spreadRadius: 5),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: AppColors.accentCyan.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.bolt, color: AppColors.accentCyan, size: 40.w),
                  ),
                  SizedBox(height: 20.h),
                  Text(
                    "TRAINING STARTED!",
                    style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.w900, letterSpacing: 1.2),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    "Session is active. You can track live progress on the team dashboard.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white60, fontSize: 12.sp),
                  ),
                  SizedBox(height: 24.h),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentCyan,
                        foregroundColor: Colors.black,
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.h)),
                      ),
                      child: Text("GOT IT!", style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w900)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        if (mounted) Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        AppDialogs.showPremiumErrorDialog(context, message: e.toString().replaceAll('Exception: ', ''));
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleSkip() async {
    setState(() => _isLoading = true);
    try {
      await TrainingService.skipTraining(
        leagueId: widget.leagueId,
        userId: widget.userId,
        playerIndex: widget.playerIndex.toString(),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        AppDialogs.showPremiumErrorDialog(context, message: e.toString().replaceAll('Exception: ', ''));
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleClaim() async {
    setState(() => _isLoading = true);
    try {
      await TrainingService.claimTrainingReward(
        leagueId: widget.leagueId,
        userId: widget.userId,
        playerIndex: widget.playerIndex.toString(),
      );
      if (mounted) {
        Navigator.pop(context, true);
        MatchesScreen.globalKey.currentState?.setTab(0);
      }
    } catch (e) {
      if (mounted) {
        AppDialogs.showPremiumErrorDialog(context, message: e.toString().replaceAll('Exception: ', ''));
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveHelper.init(context);

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('leagues')
          .doc(widget.leagueId)
          .collection('rosters')
          .doc(widget.userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.exists) {
          final roster = List<dynamic>.from(snapshot.data!.get('players') ?? []);
          if (widget.playerIndex < roster.length) {
            _livePlayer = Map<String, dynamic>.from(roster[widget.playerIndex]);
          }
        }

        final player = _livePlayer ?? widget.player;
        final isTraining = player['trainingEndTime'] != null;
        final isComplete = isTraining && _remainingTime == Duration.zero;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text("TRAIN PLAYER", style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: _isLoading 
            ? const Center(child: CircularProgressIndicator(color: AppColors.accentCyan))
            : SingleChildScrollView(
                padding: EdgeInsets.all(24.w),
                child: Column(
                  children: [
                    _buildPlayerCard(player),
                    SizedBox(height: 30.h),
                    if (isTraining) _buildActiveTraining(player, isComplete)
                    else _buildBadgeSelection(),
                  ],
                ),
              ),
        );
      }
    );
  }

  Widget _buildPlayerCard(Map<String, dynamic> player) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24.h),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30.w,
            backgroundColor: AppColors.background,
            child: Icon(Icons.person, color: AppColors.accentCyan, size: 30.w),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(player['name']?.toUpperCase() ?? "UNKNOWN", style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.w900)),
                Text(player['pos'] ?? "BN", style: TextStyle(color: AppColors.accentCyan, fontSize: 13.sp, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Column(
            children: [
              Text("CURRENT SPS", style: TextStyle(color: Colors.white38, fontSize: 10.sp, fontWeight: FontWeight.bold)),
              Text(player['sps']?.toString() ?? "---", style: TextStyle(color: Colors.white, fontSize: 24.sp, fontWeight: FontWeight.w900)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveTraining(Map<String, dynamic> player, bool isComplete) {
    final badgeTypeStr = player['trainingBadgeType'];
    final badgeType = TrainingBadgeType.values.firstWhere((e) => e.toString() == badgeTypeStr, orElse: () => TrainingBadgeType.bronze);
    final config = TrainingService.badgeConfigs[badgeType]!;

    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(24.w),
          decoration: BoxDecoration(
            color: AppColors.accentCyan.withOpacity(0.05),
            borderRadius: BorderRadius.circular(24.h),
            border: Border.all(color: AppColors.accentCyan.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Icon(Icons.timer_outlined, color: AppColors.accentCyan, size: 40.w),
              SizedBox(height: 16.h),
              Text(
                isComplete ? "TRAINING COMPLETE!" : "TRAINING IN PROGRESS...",
                style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8.h),
              Text(
                isComplete ? "00:00:00" : _formatDuration(_remainingTime),
                style: TextStyle(color: AppColors.accentCyan, fontSize: 32.sp, fontWeight: FontWeight.w900, fontFamily: 'Courier'),
              ),
              SizedBox(height: 8.h),
              Text(
                "${config['name']} (+${config['boost']} SPS)",
                style: TextStyle(color: Colors.white38, fontSize: 12.sp, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        SizedBox(height: 30.h),
        if (isComplete)
          _buildActionButton("CLAIM REWARD", AppColors.accentCyan, _handleClaim)
        else
          _buildActionButton("SKIP FOR ${config['skipCost']} COINS", AppColors.gold, _handleSkip),
      ],
    );
  }

  Widget _buildBadgeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("SELECT TRAINING BADGE", style: TextStyle(color: Colors.white38, fontSize: 12.sp, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        SizedBox(height: 20.h),
        _buildBadgeCard(TrainingBadgeType.bronze),
        _buildBadgeCard(TrainingBadgeType.silver),
        _buildBadgeCard(TrainingBadgeType.gold),
      ],
    );
  }

  Widget _buildBadgeCard(TrainingBadgeType type) {
    final config = TrainingService.badgeConfigs[type]!;
    final color = type == TrainingBadgeType.bronze ? Colors.orange : (type == TrainingBadgeType.silver ? Colors.grey : AppColors.gold);

    return GestureDetector(
      onTap: () => _handleStartTraining(type),
      child: Container(
        margin: EdgeInsets.only(bottom: 16.h),
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20.h),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.verified, color: color, size: 30.w),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(config['name'], style: TextStyle(color: Colors.white, fontSize: 15.sp, fontWeight: FontWeight.bold)),
                  Text("BOOST: +${config['boost']} SPS", style: TextStyle(color: color, fontSize: 12.sp, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text("TIME: ${_formatDuration(config['duration'])}", style: TextStyle(color: Colors.white38, fontSize: 10.sp)),
                Text("SKIP: ${config['skipCost']} COINS", style: TextStyle(color: AppColors.gold, fontSize: 10.sp, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 18.h),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16.h),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: Center(
          child: Text(label, style: TextStyle(color: color == AppColors.gold || color == AppColors.accentCyan ? Colors.black : Colors.white, fontSize: 14.sp, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    String h = d.inHours.toString().padLeft(2, '0');
    String m = (d.inMinutes % 60).toString().padLeft(2, '0');
    String s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return "$h:$m:$s";
  }
}
