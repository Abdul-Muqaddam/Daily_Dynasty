import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/colors.dart';
import '../core/responsive_helper.dart';
import '../services/player_service.dart';
import '../services/scouting_service.dart';
import '../services/coin_service.dart';
import '../services/waiver_service.dart';
import '../services/league_service.dart';
import '../widgets/app_dialogs.dart';
import 'store_screen.dart';

class ScoutPlayersScreen extends StatefulWidget {
  final String leagueId;
  final String userId;

  const ScoutPlayersScreen({
    super.key,
    required this.leagueId,
    required this.userId,
  });

  @override
  State<ScoutPlayersScreen> createState() => _ScoutPlayersScreenState();
}

class _ScoutPlayersScreenState extends State<ScoutPlayersScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _allPlayers = [];
  List<Map<String, dynamic>> _filteredPlayers = [];
  Map<String, Map<String, dynamic>> _scoutingReports = {};
  int _faabBalance = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlayers();
  }

  Future<void> _loadPlayers() async {
    setState(() => _isLoading = true);
    try {
      final players = await PlayerService.getAllPlayers();
      if (mounted) {
        setState(() {
          _allPlayers = players;
          _filteredPlayers = players;
          _isLoading = false;
        });
        _loadFaab();
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadFaab() async {
    try {
      final roster = await LeagueService.getUserRoster(widget.leagueId, widget.userId);
      // Roster storage logic might vary, but we often store metadata in the doc or a separate field.
      // Based on my previous edit to LeagueService, we added 'faabBalance' to the roster document.
      final doc = await FirebaseFirestore.instance
          .collection('leagues')
          .doc(widget.leagueId)
          .collection('rosters')
          .doc(widget.userId)
          .get();
      
      if (mounted) {
        setState(() {
          _faabBalance = doc.data()?['faabBalance'] ?? 0;
        });
      }
    } catch (e) {
      debugPrint("Error loading FAAB: $e");
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _filteredPlayers = _allPlayers
          .where((p) => (p['name'] as String).toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
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
          "SCOUT PLAYERS",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildFaabHeader(),
          _buildSearchBar(),
          _buildTableHeader(),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: AppColors.accentCyan))
              : ListView.builder(
                  itemCount: _filteredPlayers.length,
                  itemBuilder: (context, index) => _buildPlayerRow(_filteredPlayers[index]),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.all(20.w),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16.h),
          border: Border.all(color: Colors.white10),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "Search players...",
            hintStyle: TextStyle(color: Colors.white38, fontSize: 14.sp),
            prefixIcon: Icon(Icons.search, color: AppColors.accentCyan, size: 20.w),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 14.h),
          ),
        ),
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          Expanded(flex: 8, child: Text("PLAYER", style: _headerStyle)),
          Expanded(flex: 3, child: Center(child: Text("POSITION", style: _headerStyle))),
          Expanded(flex: 2, child: Center(child: Text("ADP", style: _headerStyle))),
          Expanded(flex: 4, child: Center(child: FittedBox(fit: BoxFit.scaleDown, child: Text("PROJ. SPS (CONF)", style: _headerStyle)))),
          Expanded(flex: 3, child: Center(child: Text("ACTION", style: _headerStyle))),
        ],
      ),
    );
  }

  Widget _buildPlayerRow(Map<String, dynamic> player) {
    return FutureBuilder<Map<String, dynamic>>(
      future: ScoutingService.getScoutingReport(
        leagueId: widget.leagueId,
        userId: widget.userId,
        playerId: player['id']?.toString() ?? "unknown_player",
      ),
      builder: (context, snapshot) {
        final report = snapshot.data ?? {'confidence': 0.2};
        final confidence = (report['confidence'] as num).toDouble();
        final trueSps = double.tryParse(player['sps']?.toString() ?? '0.0') ?? 0.0;
        final estimatedSps = ScoutingService.calculateEstimatedSps(trueSps, confidence, player['id']?.toString() ?? "unknown_player");
        final grade = _getGradeFromSps(estimatedSps);
        // ADP: use rank from hashcode as a stable mock
        final adp = ((player['id'].hashCode.abs() % 200) + 1).toString();

        return Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
          ),
          child: Row(
            children: [
              // PLAYER name with Image
              Expanded(
                flex: 8,
                child: Row(
                  children: [
                    Container(
                      width: 32.w,
                      height: 32.w,
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white10),
                      ),
                      child: ClipOval(
                        child: player['player_id'] != null
                            ? Image.network(
                                "https://sleepercdn.com/content/nfl/players/thumb/${player['player_id']}.jpg",
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => 
                                    const Icon(Icons.person, color: Colors.white24, size: 20),
                              )
                            : const Icon(Icons.person, color: Colors.white24, size: 20),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        player['name']?.toString() ?? "UNKNOWN",
                        style: TextStyle(color: Colors.white, fontSize: 13.sp, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              // POSITION
              Expanded(
                flex: 3,
                child: Center(
                  child: Text(
                    player['primaryPos']?.toString() ?? player['pos']?.toString() ?? "---",
                    style: TextStyle(color: Colors.white70, fontSize: 11.sp, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              // ADP
              Expanded(
                flex: 2,
                child: Center(
                  child: Text(
                    adp,
                    style: TextStyle(color: AppColors.accentCyan, fontSize: 11.sp, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              // PROJ. SPS (CONFIDENCE)
              Expanded(
                flex: 4,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        grade,
                        style: TextStyle(
                          color: _getGradeColor(grade),
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        "${(confidence * 100).toInt()}% CONF",
                        style: TextStyle(color: Colors.white24, fontSize: 8.sp, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              // ACTION
              Expanded(
                flex: 3,
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () => _showScoutOptions(player, confidence),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 6.h),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(8.h),
                            border: Border.all(color: AppColors.accentCyan.withOpacity(0.3)),
                          ),
                          child: Icon(Icons.analytics_outlined, color: AppColors.accentCyan, size: 14.w),
                        ),
                      ),
                      SizedBox(width: 6.w),
                      GestureDetector(
                        onTap: () => _showBidDialog(player),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [AppColors.accentCyan, AppColors.createGradientPurple]),
                            borderRadius: BorderRadius.circular(8.h),
                          ),
                          child: Text(
                            "BID",
                            style: TextStyle(color: Colors.black, fontSize: 10.sp, fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFaabHeader() {
    return Container(
      margin: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 0),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.h),
        border: Border.all(color: AppColors.accentCyan.withOpacity(0.2)),
        gradient: LinearGradient(
          colors: [AppColors.accentCyan.withOpacity(0.05), Colors.transparent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("AVAILABLE BUDGET", style: TextStyle(color: Colors.white38, fontSize: 10.sp, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
              SizedBox(height: 4.h),
              Text("\$$_faabBalance FAAB", style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.w900)),
            ],
          ),
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(color: AppColors.accentCyan.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(Icons.account_balance_wallet, color: AppColors.accentCyan, size: 20.w),
          ),
        ],
      ),
    );
  }

  void _showBidDialog(Map<String, dynamic> player) {
    final TextEditingController amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.h), side: const BorderSide(color: Colors.white10)),
        title: Text("PLACE WAIVER BID", style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.w900)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Bid on ${player['name']}", style: TextStyle(color: AppColors.accentCyan, fontSize: 14.sp, fontWeight: FontWeight.bold)),
            SizedBox(height: 20.h),
            Text("AMOUNT (MAX \$$_faabBalance)", style: TextStyle(color: Colors.white38, fontSize: 10.sp, fontWeight: FontWeight.bold)),
            SizedBox(height: 8.h),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                prefixText: "\$ ",
                prefixStyle: const TextStyle(color: AppColors.accentCyan, fontWeight: FontWeight.bold),
                filled: true,
                fillColor: Colors.black26,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.h), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL", style: TextStyle(color: Colors.white38))),
          ElevatedButton(
            onPressed: () async {
              final amount = int.tryParse(amountController.text) ?? 0;
              if (amount < 0 || amount > _faabBalance) {
                AppDialogs.showPremiumErrorDialog(context, message: "Invalid bid amount.");
                return;
              }
              Navigator.pop(context);
              try {
                await WaiverService.submitBid(
                  leagueId: widget.leagueId,
                  userId: widget.userId,
                  player: player,
                  bidAmount: amount,
                );
                if (mounted) {
                  AppDialogs.showSuccessDialog(context, title: "BID PLACED", message: "Your secret bid of \$$amount has been submitted!");
                }
              } catch (e) {
                if (mounted) AppDialogs.showPremiumErrorDialog(context, message: e.toString());
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentCyan, foregroundColor: Colors.black),
            child: const Text("SUBMIT BID"),
          ),
        ],
      ),
    );
  }

  void _showScoutOptions(Map<String, dynamic> player, double currentConfidence) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30.h)),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "SCOUT: ${player['name'] ?? 'UNKNOWN'}",
              style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.w900, letterSpacing: 1.2),
            ),
            SizedBox(height: 8.h),
            Text(
              "Projected Confidence: ${(currentConfidence * 100).toInt()}%",
              style: TextStyle(color: AppColors.accentCyan, fontSize: 12.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20.h),
            if (currentConfidence < 1.0)
              ListTile(
                leading: Icon(Icons.bolt, color: Colors.orange),
                title: Text("QUICK SCOUT (+20% Confidence)", style: TextStyle(color: Colors.white, fontSize: 14.sp)),
                subtitle: Text("Cost: 50 Coins", style: TextStyle(color: Colors.white38, fontSize: 12.sp)),
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    await ScoutingService.scoutPlayer(
                      leagueId: widget.leagueId,
                      userId: widget.userId,
                      playerId: player['id'],
                    );
                    setState(() {}); // Refresh list to show new confidence
                  } catch (e) {
                    if (e.toString().contains("Insufficient coins")) {
                      AppDialogs.showInsufficientCoinsDialog(
                        context,
                        message: "You need more coins to perform a Quick Scout.",
                        onGetCoins: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StoreScreen())),
                      );
                    } else {
                      AppDialogs.showPremiumErrorDialog(context, message: "Scouting failed. Please check your connection.");
                    }
                  }
                },
              )
            else
              Padding(
                padding: EdgeInsets.symmetric(vertical: 20.h),
                child: Center(child: Text("FULLY SCOUTED", style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold))),
              ),
            SizedBox(height: 20.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white10,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.h)),
                ),
                child: Text("CLOSE", style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w900)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getGradeFromSps(double sps) {
    if (sps >= 95) return 'A+';
    if (sps >= 90) return 'A';
    if (sps >= 85) return 'A-';
    if (sps >= 80) return 'B+';
    if (sps >= 75) return 'B';
    if (sps >= 70) return 'B-';
    if (sps >= 60) return 'C+';
    if (sps >= 50) return 'C';
    if (sps >= 40) return 'C-';
    return 'D';
  }

  Color _getGradeColor(String grade) {
    if (grade.startsWith('A')) return Colors.greenAccent;
    if (grade.startsWith('B')) return AppColors.accentCyan;
    if (grade.startsWith('C')) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  TextStyle get _headerStyle => TextStyle(
    color: Colors.white38,
    fontSize: 10.sp,
    fontWeight: FontWeight.bold,
    letterSpacing: 1.0,
  );
}