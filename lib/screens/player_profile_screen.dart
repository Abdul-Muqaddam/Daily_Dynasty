import 'package:flutter/material.dart';
import '../services/coin_market_service.dart';
import '../services/user_service.dart';
import '../core/colors.dart';
import '../core/responsive_helper.dart';
import '../widgets/attention_mark.dart';
import 'training_screen.dart';
import '../services/scouting_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/app_dialogs.dart';
import 'store_screen.dart';
import '../services/league_service.dart';
import 'trade_block_screen.dart';
import '../services/stat_service.dart';

class PlayerProfileScreen extends StatefulWidget {
  final String name;
  final String pos;
  final String team;
  final String sps;
  final String exp;
  final Map<String, dynamic>? player;
  final String? leagueId;
  final String? userId; // Owner of the roster
  final int? playerIndex; // Position in the players list

  const PlayerProfileScreen({
    super.key,
    required this.name,
    required this.pos,
    this.team = "GRIDIRON KINGS",
    required this.sps,
    required this.exp,
    this.player,
    this.leagueId,
    this.userId,
    this.playerIndex,
  });

  @override
  State<PlayerProfileScreen> createState() => _PlayerProfileScreenState();
}

class _PlayerProfileScreenState extends State<PlayerProfileScreen> {
  Map<String, dynamic>? _scoutingReport;
  bool _isScoutingLoading = false;

  @override
  void initState() {
    super.initState();
    _loadScoutingReport();
  }

  Future<void> _loadScoutingReport() async {
    if (widget.leagueId == null || widget.userId == null || widget.player == null) return;
    
    final report = await ScoutingService.getScoutingReport(
      leagueId: widget.leagueId!,
      userId: widget.userId!,
      playerId: widget.player?['id']?.toString() ?? "unknown",
    );
    
    if (mounted) {
      setState(() {
        _scoutingReport = report;
      });
    }
  }

  void _showInfoDialog(String title, String message, {IconData icon = Icons.check_circle_outline}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.h)),
        icon: Icon(icon, color: AppColors.accentCyan, size: 40.w),
        title: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.w900, letterSpacing: 1.2),
        ),
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white60, fontSize: 13.sp, height: 1.5),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                backgroundColor: AppColors.accentCyan.withOpacity(0.15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.h)),
              ),
              child: Text("GOT IT", style: TextStyle(color: AppColors.accentCyan, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String title, String message, {String? hint}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.h)),
        icon: Icon(Icons.wifi_off_rounded, color: Colors.orangeAccent, size: 40.w),
        title: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.w900, letterSpacing: 1.2),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white60, fontSize: 13.sp, height: 1.5),
            ),
            if (hint != null) ...[
              SizedBox(height: 12.h),
              Container(
                padding: EdgeInsets.all(10.h),
                decoration: BoxDecoration(
                  color: Colors.orangeAccent.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10.h),
                  border: Border.all(color: Colors.orangeAccent.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: Colors.orangeAccent, size: 16.w),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(hint, style: TextStyle(color: Colors.orangeAccent, fontSize: 11.sp, height: 1.4)),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                backgroundColor: Colors.orangeAccent.withOpacity(0.15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.h)),
              ),
              child: Text("UNDERSTOOD", style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showConfirmDialog(String title, String message) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.h)),
        icon: Icon(Icons.warning_amber_rounded, color: const Color(0xFFE53935), size: 40.w),
        title: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.w900, letterSpacing: 1.2),
        ),
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white60, fontSize: 13.sp, height: 1.5),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    backgroundColor: Colors.white.withOpacity(0.05),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.h)),
                  ),
                  child: Text("CANCEL", style: TextStyle(color: Colors.white54, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    backgroundColor: const Color(0xFFE53935).withOpacity(0.15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.h)),
                  ),
                  child: Text("CONFIRM", style: TextStyle(color: const Color(0xFFE53935), fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveHelper.init(context);
    final trainingEndTime = widget.player?['trainingEndTime'] as Timestamp?;
    final isTrainingCompleted = trainingEndTime != null && DateTime.now().isAfter(trainingEndTime.toDate());

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background Image with gradient overlay
          Positioned.fill(
            child: Image.asset(
              'assets/images/login_background.png',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    AppColors.background.withOpacity(0.95),
                    AppColors.background,
                  ],
                  stops: const [0.0, 0.35, 0.6],
                ),
              ),
            ),
          ),
          
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   _buildHeader(),
                  SizedBox(height: 30.h),
                  _buildPlayerInfo(isTrainingCompleted),
                  if (_scoutingReport != null) ...[
                    SizedBox(height: 20.h),
                    _buildScoutingConfidenceBar(),
                  ],
                  SizedBox(height: 30.h),
                  _buildBasicMetrics(),
                  SizedBox(height: 30.h),
                  _buildStatsSection(),
                  SizedBox(height: 30.h),
                  _buildSeasonTotals(),
                  SizedBox(height: 30.h),
                  _buildRealWorldNews(),
                  SizedBox(height: 50.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final status = widget.player?['injury_status']?.toString().toUpperCase() ?? 
                   (widget.player?['status'] == 'Active' ? 'HEALTHY' : 'INACTIVE');
    
    Color statusColor = Colors.greenAccent;
    if (status == 'OUT' || status == 'IR') statusColor = Colors.redAccent;
    else if (status == 'QUESTIONABLE' || status == 'QUES') statusColor = Colors.orangeAccent;
    else if (status == 'DOUBTFUL') statusColor = Colors.deepOrangeAccent;

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
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12.h),
            border: Border.all(color: statusColor.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 6.w, height: 6.w, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
              SizedBox(width: 6.w),
              Text(
                status,
                style: TextStyle(color: statusColor, fontSize: 10.sp, fontWeight: FontWeight.w900, letterSpacing: 1.0),
              ),
            ],
          ),
        ),
        SizedBox(width: 40.w),
      ],
    );
  }

  Widget _buildPlayerInfo(bool showTrainingAttention) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Player Image with CachedNetworkImage
        Container(
          width: 100.w,
          height: 120.h,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20.h),
            border: Border.all(color: Colors.white10),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20.h),
            child: widget.player?['player_id'] != null
                ? Image.network(
                    "https://sleepercdn.com/content/nfl/players/thumb/${widget.player!['player_id']}.jpg",
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => 
                        Icon(Icons.person, size: 80.w, color: Colors.white24),
                  )
                : Icon(Icons.person, size: 80.w, color: Colors.white24),
          ),
        ),
        SizedBox(width: 20.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                (widget.name ?? "UNKNOWN").toUpperCase(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
              Text(
                (widget.team ?? "---").toUpperCase(),
                style: TextStyle(
                  color: AppColors.accentCyan,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              if (widget.player?['primaryPos'] != null && widget.player?['primaryPos'] != widget.pos)
                Padding(
                  padding: EdgeInsets.only(top: 4.h),
                  child: Text(
                    "SLOT: ${widget.pos.toUpperCase()}",
                    style: TextStyle(color: Colors.white38, fontSize: 10.sp, fontWeight: FontWeight.bold),
                  ),
                ),
              SizedBox(height: 15.h),
               Row(
                 children: [
                   _buildActionButton(
                     label: "TRAIN",
                     color: AppColors.accentCyan,
                     showAttention: showTrainingAttention,
                    onPressed: () {
                      debugPrint("PROFILE START TRAINING: leagueId=${widget.leagueId}, userId=${widget.userId}");
                      bool canTrain = widget.player != null && 
                                     widget.leagueId != null && 
                                     widget.leagueId!.isNotEmpty &&
                                     widget.userId != null &&
                                     widget.userId!.isNotEmpty;

                      if (canTrain) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TrainingScreen(
                              player: widget.player!,
                              leagueId: widget.leagueId!,
                              userId: widget.userId!, 
                              playerIndex: widget.playerIndex ?? 0, 
                            ),
                          ),
                        );
                      } else {
                        _showErrorDialog(
                          "TRAINING UNAVAILABLE",
                          "We couldn\'t link this player to a league session. This usually happens if you navigated here outside of a league context.",
                          hint: "Try accessing the player from your Roster in an active league.",
                        );
                      }
                    },
                  ),
                  SizedBox(width: 10.w),
                  _buildActionButton(
                    label: "SCOUT",
                    color: Colors.orange,
                    onPressed: _isScoutingLoading ? () {} : () async {
                      if (widget.leagueId != null && widget.userId != null && widget.player != null) {
                        setState(() => _isScoutingLoading = true);
                        try {
                           await ScoutingService.scoutPlayer(
                            leagueId: widget.leagueId!,
                            userId: widget.userId!,
                            playerId: widget.player?['id']?.toString() ?? "unknown",
                           );
                           await _loadScoutingReport();
                           if (mounted) {
                             _showInfoDialog(
                               "SCOUTING COMPLETE!",
                               "Intel gathered. Your confidence in this player\'s true potential has increased.\n\nKeep scouting to narrow the SPS estimate further.",
                               icon: Icons.radar,
                             );
                           }
                        } catch (e) {
                          if (e.toString().contains("Insufficient coins")) {
                            AppDialogs.showInsufficientCoinsDialog(
                              context,
                              message: "You need more coins to scout this player.",
                              onGetCoins: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StoreScreen())),
                            );
                          } else {
                            _showErrorDialog(
                              "CONNECTION ERROR",
                              "Unable to reach the server right now. This is likely a temporary network issue.",
                              hint: "Check your internet connection and try again. If the issue persists, the server may be temporarily unavailable.",
                            );
                          }
                        } finally {
                          if (mounted) setState(() => _isScoutingLoading = false);
                        }
                      }
                    },
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              Row(
                children: [
                  _buildActionButton(
                    label: "TRADE",
                    color: const Color(0xFF1E88E5), // Blue
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const TradeBlockScreen()));
                    },
                  ),
                  SizedBox(width: 10.w),
                  _buildActionButton(
                    label: "SELL",
                    color: AppColors.gold,
                    onPressed: () async {
                      if (widget.leagueId != null && widget.userId != null && widget.player != null) {
                        _showSellDialog();
                      }
                    },
                  ),
                  SizedBox(width: 10.w),
                  _buildActionButton(
                    label: "DROP",
                    color: const Color(0xFFE53935), // Red
                    onPressed: () async {
                      if (widget.leagueId != null && widget.userId != null && widget.player != null) {
                        bool? confirm = await _showConfirmDialog(
                          "DROP PLAYER", 
                          "Are you sure you want to drop ${widget.name}? This will remove them from your roster permanently."
                        );
                        if (confirm == true) {
                          try {
                            await LeagueService.dropPlayer(widget.leagueId!, widget.userId!, widget.player!['id'].toString());
                            if (mounted) {
                              Navigator.pop(context, true); // true = refresh roster
                            }
                          } catch (e) {
                            if (mounted) _showErrorDialog("DROP FAILED", e.toString().replaceAll('Exception: ', ''));
                          }
                        }
                      } else {
                        _showErrorDialog("UNAVAILABLE", "Cannot drop players outside of an active league.");
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({required String label, required Color color, required VoidCallback onPressed, bool showAttention = false}) {
    return Expanded(
      child: GestureDetector(
        onTap: onPressed,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
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
            if (showAttention)
              const Positioned(
                top: -8,
                right: -8,
                child: AttentionMark(size: 14),
              ),
          ],
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
              _buildMetricItem("POS", widget.player?['primaryPos'] ?? widget.pos),
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
    String displayValue = value;
    if (label == "SPS" && _scoutingReport != null) {
      final trueSps = double.tryParse(value) ?? 0.0;
      final confidence = (_scoutingReport?['confidence'] as num? ?? 0.2).toDouble();
      final estimated = ScoutingService.calculateEstimatedSps(trueSps, confidence, widget.player?['id']?.toString() ?? "unknown");
      
      if (confidence < 1.0) {
        displayValue = "~$estimated";
      }
    }

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
          displayValue,
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
    final confidence = (_scoutingReport?['confidence'] ?? 1.0).toDouble();
    final trueSpsNum = double.tryParse(widget.sps) ?? 0.0;
    final displaySps = ScoutingService.calculateEstimatedSps(trueSpsNum, confidence, widget.player?['id']?.toString() ?? "unknown");

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
            _buildStatBox(
              "SPS GRADE", 
              displaySps.toStringAsFixed(1), 
              AppColors.accentCyan,
              subValue: confidence < 1.0 
                ? "${(confidence * 100).toInt()}% CONF"
                : ((double.tryParse(widget.player?['tempBoost']?.toString() ?? '0.0') ?? 0.0) > 0 
                    ? "+${(double.tryParse(widget.player?['tempBoost']?.toString() ?? '0.0') ?? 0.0).toStringAsFixed(1)} BOOST" 
                    : null)
            ),
            _buildStatBox("EXPERIENCE", widget.exp, Colors.orange),
            _buildStatBox("LEAGUE RANK", "#12", Colors.purpleAccent),
          ],
        ),
      ],
    );
  }

  Widget _buildStatBox(String label, String value, Color color, {String? subValue}) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.only(right: 8.w),
        padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 8.w),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20.h),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(label, style: TextStyle(color: Colors.white24, fontSize: 8.sp, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
            SizedBox(height: 6.h),
            Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18.sp,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (subValue != null) ...[
              SizedBox(height: 4.h),
              Text(
                subValue,
                style: TextStyle(
                  color: color,
                  fontSize: 8.sp,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ],
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

  Widget _buildScoutingConfidenceBar() {
    final confidence = (_scoutingReport?['confidence'] as num? ?? 0.2).toDouble();
    final isFull = confidence >= 1.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "SCOUTING CONFIDENCE",
              style: TextStyle(color: Colors.white38, fontSize: 10.sp, fontWeight: FontWeight.bold, letterSpacing: 1.0),
            ),
            Text(
              "${(confidence * 100).toInt()}%",
              style: TextStyle(color: isFull ? AppColors.accentCyan : Colors.orange, fontSize: 10.sp, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(4.h),
          child: LinearProgressIndicator(
            value: confidence,
            minHeight: 6.h,
            backgroundColor: Colors.white.withOpacity(0.05),
            valueColor: AlwaysStoppedAnimation<Color>(isFull ? AppColors.accentCyan : Colors.orange),
          ),
        ),
        if (!isFull)
          Padding(
            padding: EdgeInsets.only(top: 8.h),
            child: Text(
              "SCOUT AGAIN TO REVEAL TRUE SKILL",
              style: TextStyle(color: Colors.white10, fontSize: 8.sp, fontWeight: FontWeight.bold),
            ),
          ),
      ],
    );
  }

  void _showSellDialog() {
    final TextEditingController _priceController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            "SELL ${widget.name}?",
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Enter the asking price in coins. If another manager buys this player, the coins will be added to your balance.",
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "e.g. 1500",
                  hintStyle: const TextStyle(color: Colors.white38),
                  prefixIcon: const Icon(Icons.monetization_on, color: AppColors.gold),
                  filled: true,
                  fillColor: Colors.white10,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("CANCEL", style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                final str = _priceController.text.trim();
                if (str.isEmpty) return;
                final price = int.tryParse(str);
                if (price == null || price <= 0) return;
                
                Navigator.pop(ctx);
                _executeSell(price);
              },
              child: const Text("LIST PLAYER", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      }
    );
  }

  Future<void> _executeSell(int askingPrice) async {
    try {
      _showInfoDialog("LISTING...", "Placing player on the coin market...", icon: Icons.store);
      
      final profile = await UserService.getCurrentUserProfile();
      final teamName = profile?['teamName'] ?? 'Unknown Team';
      
      await CoinMarketService.listPlayerForCoins(
        leagueId: widget.leagueId!,
        userId: widget.userId!,
        player: widget.player!,
        askingPrice: askingPrice,
        teamName: teamName,
      );
      
      if (mounted) {
        Navigator.pop(context); // pop dialog
        Navigator.pop(context, true); // pop screen
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showErrorDialog("LISTING FAILED", e.toString());
      }
    }
  }

  Widget _buildRealWorldNews() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "REAL-WORLD UPDATES",
          style: TextStyle(
            color: Colors.white38,
            fontSize: 12.sp,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
        SizedBox(height: 15.h),
        Container(
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(20.h),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            children: [
              _buildNewsItem("Dynasty Value: Trending Up", "3h ago", Icons.trending_up, Colors.greenAccent),
              Divider(color: Colors.white10, height: 24.h),
              _buildNewsItem("Full participant in Wednesday practice", "1d ago", Icons.check_circle_outline, AppColors.accentCyan),
              Divider(color: Colors.white10, height: 24.h),
              _buildNewsItem("Scheduled for further evaluation on left ankle", "2d ago", Icons.medical_services_outlined, Colors.orangeAccent),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNewsItem(String title, String time, IconData icon, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(6.w),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8.h)),
          child: Icon(icon, color: color, size: 14.w),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: Colors.white, fontSize: 13.sp, fontWeight: FontWeight.bold)),
              SizedBox(height: 4.h),
              Text(time, style: TextStyle(color: Colors.white24, fontSize: 10.sp, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }
}
