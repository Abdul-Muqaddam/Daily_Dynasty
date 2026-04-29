import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/colors.dart';
import '../../core/responsive_helper.dart';
import '../../services/league_service.dart';
import '../../widgets/app_dialogs.dart';
import '../training_screen.dart';
import '../../services/user_service.dart';
import '../../widgets/join_league_bottom_sheet.dart';
import '../player_profile_screen.dart';
import '../scout_players_screen.dart';
import '../../widgets/attention_mark.dart';
import '../../services/scouting_service.dart';
import '../../services/pick_service.dart';
import '../../widgets/app_dialogs.dart';

class RosterTab extends StatefulWidget {
  const RosterTab({super.key});

  @override
  State<RosterTab> createState() => _RosterTabState();
}

class _RosterTabState extends State<RosterTab> {
  List<Map<String, dynamic>> _myLeagues = [];
  Map<String, dynamic>? _selectedLeague;
  List<Map<String, dynamic>> _roster = [];
  bool _isLoading = true;
  bool _isRosterLoading = false;
  int? _selectedIndex;
  bool _isSwapping = false;
  Map<String, Map<String, dynamic>> _scoutingReports = {};
  List<Map<String, dynamic>> _myPicks = [];
  String _username = "MY TEAM";

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final leagues = await LeagueService.getUserLeagues().timeout(const Duration(seconds: 10));
      if (mounted) {
        setState(() {
          _myLeagues = leagues;
          if (leagues.isNotEmpty) {
            _selectedLeague = leagues.first;
          }
          _isLoading = false;
        });
        if (_selectedLeague != null) {
          _loadRoster();
          _loadPicks();
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadPicks() async {
    if (_selectedLeague == null) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // We can use a stream for better reactiveness later, but for now, simple fetch
    final picks = await PickService.getUserPicks(_selectedLeague!['id'], user.uid);
    if (mounted) {
      setState(() => _myPicks = picks);
    }
  }

  Future<void> _loadRoster() async {
    if (_selectedLeague == null) return;
    setState(() => _isRosterLoading = true);
    try {
      final profile = await UserService.getCurrentUserProfile().timeout(const Duration(seconds: 10));
      if (profile != null) {
        final roster = await LeagueService.getUserRoster(_selectedLeague!['id'], profile['uid']).timeout(const Duration(seconds: 10));
        
        // Fetch Scouting Reports for the whole roster
        final Map<String, Map<String, dynamic>> reports = {};
        for (var p in roster) {
          final pid = p['id']?.toString() ?? "unknown";
          reports[pid] = await ScoutingService.getScoutingReport(
            leagueId: _selectedLeague!['id'],
            userId: profile['uid'],
            playerId: pid,
          );
        }

        if (mounted) {
          setState(() {
            _roster = roster;
            _scoutingReports = reports;
            _username = (profile?['username']?.toString() ?? profile?['teamName']?.toString() ?? "MY TEAM").toUpperCase();
            _isRosterLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isRosterLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isRosterLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(),
          if (_myLeagues.length > 1) _buildLeagueSelector(),
          Expanded(
            child: _buildRosterContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 10.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_username, style: TextStyle(color: Colors.white38, fontSize: 12.sp, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          SizedBox(height: 4.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("ROSTER", style: TextStyle(color: Colors.white, fontSize: 24.sp, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
              if (_selectedLeague != null)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppColors.accentCyan.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.h),
                    border: Border.all(color: AppColors.accentCyan.withOpacity(0.3)),
                  ),
                  child: Text(
                    _selectedLeague!['name']?.toString().toUpperCase() ?? "",
                    style: TextStyle(color: AppColors.accentCyan, fontSize: 10.sp, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLeagueSelector() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.h),
        border: Border.all(color: Colors.white10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Map<String, dynamic>>(
          value: _selectedLeague,
          dropdownColor: AppColors.surface,
          isExpanded: true,
          icon: Icon(Icons.swap_vert, color: AppColors.accentCyan),
          items: _myLeagues.map((league) {
            return DropdownMenuItem(
              value: league,
              child: Text(
                league['name']?.toString().toUpperCase() ?? "UNKNOWN",
                style: TextStyle(color: Colors.white, fontSize: 13.sp, fontWeight: FontWeight.bold),
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() => _selectedLeague = val);
              _loadRoster();
            }
          },
        ),
      ),
    );
  }

  Widget _buildRosterContent() {
    if (_isLoading || _isRosterLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.accentCyan));
    }

    if (_myLeagues.isEmpty) {
      return _buildEmptyState(
        title: "NO LEAGUES FOUND",
        subtitle: "Join a league to start building your roster!",
        buttonText: "JOIN A LEAGUE",
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => const JoinLeagueBottomSheet(),
          ).then((val) {
            if (val == true) _loadInitialData();
          });
        },
      );
    }

    if (_roster.isEmpty) {
      return _buildEmptyState(
        title: "EMPTY ROSTER",
        subtitle: "You don't have any players in this league yet.",
        buttonText: "SCOUT PLAYERS",
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ScoutPlayersScreen(
          leagueId: _selectedLeague?['id'] ?? "",
          userId: FirebaseAuth.instance.currentUser?.uid ?? "",
        ))),
      );
    }

    // 1. Define the League Roster Structure
    final starterSlots = ['QB', 'RB1', 'RB2', 'WR1', 'WR2', 'WR3', 'TE', 'FLEX', 'SFLEX'];
    final benchSlotCount = 18;
    final irSlotCount = 4;
    final taxiSlotCount = 2;

    // 2. Helper to find player for a specific slot
    Map<String, dynamic>? getPlayerForSlot(String slot) {
      try {
        return _roster.firstWhere((p) => (p['pos'] ?? '').toString().toUpperCase() == slot.toUpperCase());
      } catch (_) {
        return null;
      }
    }

    // 3. Handle Bench/IR/Taxi which are multiple but identical labels
    final benchPlayers = _roster.where((p) => (p['pos'] ?? '').toString().toUpperCase() == 'BN').toList();
    final irPlayers = _roster.where((p) => (p['pos'] ?? '').toString().toUpperCase() == 'IR').toList();
    final taxiPlayers = _roster.where((p) => (p['pos'] ?? '').toString().toUpperCase() == 'TAXI').toList();

    return Stack(
      children: [
        ListView(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
          children: [
            _buildRosterColumnHeader(),
            SizedBox(height: 8.h),
            
            // --- STARTERS ---
            _buildSectionHeader("STARTERS"),
            SizedBox(height: 8.h),
            ...starterSlots.map((slot) {
              final player = getPlayerForSlot(slot);
              return player != null 
                ? _buildPlayerRow(player, _roster.indexOf(player))
                : _buildEmptySlotRow(slot, Colors.white10);
            }),
            SizedBox(height: 16.h),

            // --- BENCH ---
            _buildSectionHeader("BENCH (${benchPlayers.length}/$benchSlotCount)"),
            SizedBox(height: 8.h),
            ...List.generate(benchSlotCount, (i) {
              if (i < benchPlayers.length) {
                final p = benchPlayers[i];
                return _buildPlayerRow(p, _roster.indexOf(p));
              }
              return _buildEmptySlotRow("BN", Colors.white.withOpacity(0.02));
            }),
            SizedBox(height: 16.h),

            // --- IR ---
            _buildSectionHeader("INJURED RESERVE (${irPlayers.length}/$irSlotCount)"),
            SizedBox(height: 8.h),
            ...List.generate(irSlotCount, (i) {
              if (i < irPlayers.length) {
                final p = irPlayers[i];
                return _buildPlayerRow(p, _roster.indexOf(p));
              }
              return _buildEmptySlotRow("IR", Colors.red.withOpacity(0.05));
            }),
            SizedBox(height: 16.h),

            // --- TAXI ---
            _buildSectionHeader("TAXI SQUAD (${taxiPlayers.length}/$taxiSlotCount)"),
            SizedBox(height: 8.h),
            ...List.generate(taxiSlotCount, (i) {
              if (i < taxiPlayers.length) {
                final p = taxiPlayers[i];
                return _buildPlayerRow(p, _roster.indexOf(p));
              }
              return _buildEmptySlotRow("TAXI", Colors.amber.withOpacity(0.05));
            }),

            if (_myPicks.isNotEmpty) ...[
              SizedBox(height: 24.h),
              _buildSectionHeader("DRAFT PICKS"),
              SizedBox(height: 12.h),
              _buildPicksGrid(),
            ],
            SizedBox(height: 80.h),
          ],
        ),
        if (_isSwapping)
          Container(
            color: Colors.black45,
            child: const Center(child: CircularProgressIndicator(color: AppColors.accentCyan)),
          ),
      ],
    );
  }

  Widget _buildRosterColumnHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
      child: Row(
        children: [
          SizedBox(width: 44.w), // POS column
          SizedBox(width: 8.w),
          Expanded(
            flex: 3,
            child: Text("PLAYER", style: TextStyle(color: Colors.white24, fontSize: 9.sp, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
          ),
          SizedBox(
            width: 38.w,
            child: Text("SPS", textAlign: TextAlign.center, style: TextStyle(color: Colors.white24, fontSize: 9.sp, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
          ),
          SizedBox(
            width: 44.w,
            child: Text("MATCHUP", textAlign: TextAlign.center, style: TextStyle(color: Colors.white24, fontSize: 9.sp, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
          ),
          SizedBox(
            width: 30.w,
            child: Text("EXP", textAlign: TextAlign.center, style: TextStyle(color: Colors.white24, fontSize: 9.sp, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
          ),
          SizedBox(
            width: 42.w,
            child: Text("TRAIN", textAlign: TextAlign.center, style: TextStyle(color: Colors.white24, fontSize: 9.sp, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerRow(Map<String, dynamic> player, int index) {
    final pos = player['pos'] ?? "BN";
    final name = player['name'] ?? "UNKNOWN";
    final sps = player['sps']?.toString() ?? "---";
    final exp = player['exp']?.toString() ?? "R";

    final trainingEndTime = player['trainingEndTime'] as Timestamp?;
    final isTraining = trainingEndTime != null && trainingEndTime.toDate().isAfter(DateTime.now());
    final isTrainingCompleted = trainingEndTime != null && DateTime.now().isAfter(trainingEndTime.toDate());

    // Scouting Logic
    final pid = player['id']?.toString() ?? "unknown";
    final report = _scoutingReports[pid];
    final scoutingConfidence = (report?['confidence'] as num? ?? 1.0).toDouble();
    final trueSpsNum = double.tryParse(player['sps']?.toString() ?? "0.0") ?? 0.0;
    final displaySpsValue = ScoutingService.calculateEstimatedSps(trueSpsNum, scoutingConfidence, pid);
    final displaySpsString = scoutingConfidence < 1.0 ? "~${displaySpsValue.toStringAsFixed(1)}" : sps;

    final isSelected = _selectedIndex == index;

    Color posColor = AppColors.accentCyan;
    if (pos == 'QB') posColor = Colors.redAccent;
    else if (pos == 'RB' || pos == 'RB1' || pos == 'RB2') posColor = Colors.greenAccent;
    else if (pos == 'WR' || pos == 'WR1' || pos == 'WR2' || pos == 'WR3') posColor = Colors.blueAccent;
    else if (pos == 'TE') posColor = Colors.orangeAccent;
    else if (pos == 'FLEX') posColor = Colors.purpleAccent;
    else if (pos == 'SFLEX') posColor = Colors.pinkAccent;
    else if (pos == 'IR') posColor = Colors.red;
    else if (pos == 'TAXI') posColor = Colors.grey;

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PlayerProfileScreen(
              name: name, 
              pos: pos, 
              sps: sps, 
              exp: exp, 
              player: player, 
              leagueId: _selectedLeague!['id'], 
              userId: FirebaseAuth.instance.currentUser?.uid, 
              playerIndex: index
            ),
          ),
        );
        if (result == true) {
          _loadRoster();
        }
      },
      onLongPress: () => _handlePlayerTap(index),
      child: Container(
        margin: EdgeInsets.only(bottom: 8.h),
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppColors.accentCyan.withOpacity(0.12) 
              : (isTraining ? AppColors.accentCyan.withOpacity(0.04) : AppColors.surface),
          borderRadius: BorderRadius.circular(12.h),
          border: Border.all(
            color: isSelected 
                ? AppColors.accentCyan 
                : (isTrainingCompleted ? Colors.greenAccent.withOpacity(0.4) : (isTraining ? AppColors.accentCyan.withOpacity(0.2) : Colors.white.withOpacity(0.04))),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Player Image + POS overlay
            Container(
              width: 44.w,
              height: 36.h,
              decoration: BoxDecoration(
                color: posColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8.h),
                border: Border.all(color: posColor.withOpacity(0.2)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.h),
                child: Stack(
                  alignment: Alignment.center,
                  children: [

                    if (player['player_id'] != null)
                      CachedNetworkImage(
                        imageUrl: "https://sleepercdn.com/content/nfl/players/thumb/${player['player_id']}.jpg",
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const SizedBox(),
                        errorWidget: (context, url, error) => const SizedBox(),
                      ),
                    Container(
                      color: (player['player_id'] != null) ? Colors.black38 : Colors.transparent,
                      child: Center(
                        child: isTraining
                            ? Icon(Icons.timer_outlined, color: AppColors.accentCyan, size: 18.w)
                            : Text(
                                pos,
                                style: TextStyle(
                                  color: (player['player_id'] != null) ? Colors.white : posColor,
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w900,
                                  shadows: [
                                    if (player['player_id'] != null)
                                      const Shadow(color: Colors.black, blurRadius: 4),
                                  ],
                                ),
                                textAlign: TextAlign.center,
                              ),
                      ),
                    ),
                    // Injury Status Badge
                    if (player['injury_status'] != null && 
                        player['injury_status'].toString().isNotEmpty)
                      Positioned(
                        top: 2,
                        right: 2,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 4.w),
                          decoration: BoxDecoration(
                            color: player['injury_status'] == 'Out' || player['injury_status'] == 'IR' 
                                ? Colors.red 
                                : Colors.orange,
                            borderRadius: BorderRadius.circular(4.h),
                          ),
                          child: Text(
                            player['injury_status'].toString().substring(0, 1).toUpperCase(),
                            style: TextStyle(color: Colors.white, fontSize: 6.sp, fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            SizedBox(width: 8.w),
            // Player Name column
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: isSelected ? AppColors.accentCyan : Colors.white, fontSize: 13.sp, fontWeight: FontWeight.bold),
                  ),
                  if (player['primaryPos'] != null && player['primaryPos'] != pos)
                    Text(player['primaryPos'], style: TextStyle(color: Colors.white24, fontSize: 8.sp, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            // SPS column
            SizedBox(
              width: 38.w,
              child: Column(
                children: [
                  Text(
                    displaySpsString,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: scoutingConfidence < 1.0 ? Colors.orange : Colors.white,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (player['tempBoost'] != null && player['tempBoost'] != 0)
                    Text("+${player['tempBoost']}", style: TextStyle(color: Colors.greenAccent, fontSize: 7.sp, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            // Matchup column
            SizedBox(
              width: 44.w,
              child: Center(
                child: Text(
                  "vs ---",
                  style: TextStyle(color: Colors.white24, fontSize: 9.sp, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            // EXP column
            SizedBox(
              width: 30.w,
              child: Center(
                child: Text(
                  exp,
                  style: TextStyle(color: Colors.white54, fontSize: 11.sp, fontWeight: FontWeight.w900),
                ),
              ),
            ),
            // Train column
            SizedBox(
              width: 42.w,
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        if (isTraining || isTrainingCompleted) {
                          final profile = await UserService.getCurrentUserProfile();
                          if (mounted && profile != null) {
                            final updated = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TrainingScreen(
                                  player: player,
                                  leagueId: _selectedLeague!['id'],
                                  userId: profile['uid'],
                                  playerIndex: index,
                                ),
                              ),
                            );
                            if (updated == true) _loadRoster();
                          }
                        } else {
                          final profile = await UserService.getCurrentUserProfile();
                          if (mounted && profile != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TrainingScreen(
                                  player: player,
                                  leagueId: _selectedLeague!['id'],
                                  userId: profile['uid'],
                                  playerIndex: index,
                                ),
                              ),
                            );
                          }
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 5.h),
                        decoration: BoxDecoration(
                          color: isTrainingCompleted
                              ? Colors.greenAccent.withOpacity(0.15)
                              : (isTraining ? AppColors.accentCyan.withOpacity(0.08) : AppColors.accentCyan.withOpacity(0.1)),
                          borderRadius: BorderRadius.circular(8.h),
                          border: Border.all(
                            color: isTrainingCompleted
                                ? Colors.greenAccent.withOpacity(0.5)
                                : (isTraining ? AppColors.accentCyan.withOpacity(0.3) : AppColors.accentCyan.withOpacity(0.3)),
                          ),
                        ),
                        child: Icon(
                          isTrainingCompleted ? Icons.check_circle : (isTraining ? Icons.timer : Icons.fitness_center),
                          color: isTrainingCompleted ? Colors.greenAccent : AppColors.accentCyan,
                          size: 16.w,
                        ),
                      ),
                    ),
                    if (isTrainingCompleted)
                      Positioned(
                        top: -4,
                        right: -4,
                        child: AttentionMark(size: 10),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(width: 4.w, height: 16.h, decoration: BoxDecoration(color: AppColors.accentCyan, borderRadius: BorderRadius.circular(2.w))),
        SizedBox(width: 8.w),
        Text(title, style: TextStyle(color: Colors.white70, fontSize: 12.sp, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
      ],
    );
  }

  Widget _buildPlayerCard(Map<String, dynamic> player, int index) {
    final pos = player['pos'] ?? "BN";
    final name = player['name'] ?? "UNKNOWN";
    final sps = player['sps']?.toString() ?? "---";
    final exp = player['exp']?.toString() ?? "R";
    
    final trainingEndTime = player['trainingEndTime'] as Timestamp?;
    final isTraining = trainingEndTime != null && trainingEndTime.toDate().isAfter(DateTime.now());
    final isTrainingCompleted = trainingEndTime != null && DateTime.now().isAfter(trainingEndTime.toDate());
    
    // Scouting Logic
    final pid = player['id']?.toString() ?? "unknown";
    final report = _scoutingReports[pid];
    final scoutingConfidence = (report?['confidence'] as num? ?? 1.0).toDouble();
    final trueSpsNum = double.tryParse(player['sps']?.toString() ?? "0.0") ?? 0.0;
    final displaySpsValue = ScoutingService.calculateEstimatedSps(trueSpsNum, scoutingConfidence, pid);
    final displaySpsString = scoutingConfidence < 1.0 ? "~${displaySpsValue.toStringAsFixed(1)}" : sps;

    final isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PlayerProfileScreen(
              name: name, 
              pos: pos, 
              sps: sps, 
              exp: exp, 
              player: player, 
              leagueId: _selectedLeague!['id'], 
              userId: FirebaseAuth.instance.currentUser?.uid, 
              playerIndex: index
            ),
          ),
        );
        if (result == true) {
          _loadRoster();
        }
      },
      onLongPress: () => _handlePlayerTap(index),
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppColors.accentCyan.withOpacity(0.15) 
              : (isTraining ? AppColors.accentCyan.withOpacity(0.05) : AppColors.surface),
          borderRadius: BorderRadius.circular(16.h),
          border: Border.all(
            color: isSelected 
                ? AppColors.accentCyan 
                : (isTraining ? AppColors.accentCyan.withOpacity(0.3) : Colors.white.withOpacity(0.05)),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(color: AppColors.accentCyan.withOpacity(0.2), blurRadius: 10, spreadRadius: 2),
            BoxShadow(color: Colors.black26, blurRadius: 8, offset: const Offset(0, 4)),
          ],
        ),
        child: Stack(
          children: [
            Row(
              children: [
                Container(
                  width: 50.w,
                  height: 50.w,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12.h),
                    border: Border.all(color: isSelected ? AppColors.accentCyan : AppColors.accentCyan.withOpacity(0.2)),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isTraining) 
                          Icon(Icons.timer_outlined, color: AppColors.accentCyan, size: 24.w)
                        else
                          Text(pos, style: TextStyle(color: AppColors.accentCyan, fontSize: 13.sp, fontWeight: FontWeight.w900)),
                        if (player['primaryPos'] != null && player['primaryPos'] != pos)
                          Text(player['primaryPos'], style: TextStyle(color: Colors.white38, fontSize: 8.sp, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: TextStyle(color: isSelected ? AppColors.accentCyan : Colors.white, fontSize: 15.sp, fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      _buildStatLabel("SPS", displaySpsString),
                      if (scoutingConfidence < 1.0)
                        Padding(
                          padding: EdgeInsets.only(left: 4.w),
                          child: Text("${(scoutingConfidence * 100).toInt()}% CONF", style: TextStyle(color: Colors.orange, fontSize: 8.sp, fontWeight: FontWeight.bold)),
                        ),
                      if (player['tempBoost'] != null && player['tempBoost'] != 0)
                        Text(" (+${player['tempBoost']})", style: TextStyle(color: Colors.greenAccent, fontSize: 10.sp, fontWeight: FontWeight.bold)),
                      SizedBox(width: 12.w),
                      _buildStatLabel("EXP", exp),
                    ],
                  ),
                ],
            ),
          ),
            Column(
              children: [
                if (!isTraining && !isTrainingCompleted)
                  GestureDetector(
                    onTap: () async {
                      final profile = await UserService.getCurrentUserProfile();
                      if (mounted && profile != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TrainingScreen(
                              player: player,
                              leagueId: _selectedLeague!['id'],
                              userId: profile['uid'],
                              playerIndex: index,
                            ),
                          ),
                        );
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: AppColors.accentCyan.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4.h),
                        border: Border.all(color: AppColors.accentCyan.withOpacity(0.3)),
                      ),
                      child: Text("TRAIN", style: TextStyle(color: AppColors.accentCyan, fontSize: 8.sp, fontWeight: FontWeight.bold)),
                    ),
                  ),
                IconButton(
                  icon: Icon(
                    isTraining ? Icons.fitness_center : (isTrainingCompleted ? Icons.check_circle : Icons.analytics_outlined), 
                    color: isTraining ? AppColors.accentCyan : (isTrainingCompleted ? Colors.greenAccent : Colors.white38), 
                    size: 24.w
                  ),
                  onPressed: () async {
                    if (isTraining || isTrainingCompleted) {
                      final profile = await UserService.getCurrentUserProfile();
                      if (mounted && profile != null) {
                         final updated = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TrainingScreen(
                              player: player,
                              leagueId: _selectedLeague!['id'],
                              userId: profile['uid'],
                              playerIndex: index,
                            ),
                          ),
                        );
                        if (updated == true) _loadRoster();
                      }
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PlayerProfileScreen(name: name, pos: pos, sps: sps, exp: exp, player: player, leagueId: _selectedLeague!['id'], userId: FirebaseAuth.instance.currentUser?.uid, playerIndex: index),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ],
        ),
        if (isTrainingCompleted)
          const Positioned(
            top: -5,
            left: -5,
            child: AttentionMark(size: 14),
          ),
      ],
    ),
  ),
);
}

  Widget _buildStatLabel(String label, String value) {
    return Row(
      children: [
        Text("$label: ", style: TextStyle(color: Colors.white30, fontSize: 10.sp, fontWeight: FontWeight.bold)),
        Text(value, style: TextStyle(color: Colors.white70, fontSize: 10.sp, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildEmptyState({required String title, required String subtitle, required String buttonText, required VoidCallback onTap}) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(40.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.group_off_outlined, color: Colors.white10, size: 80.w),
            SizedBox(height: 20.h),
            Text(title, style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.bold)),
            SizedBox(height: 8.h),
            Text(subtitle, textAlign: TextAlign.center, style: TextStyle(color: Colors.white38, fontSize: 14.sp)),
            SizedBox(height: 30.h),
            ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentCyan,
                foregroundColor: Colors.black,
                padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 12.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.h)),
              ),
              child: Text(buttonText, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPicksGrid() {
    // Sort picks by year then round
    _myPicks.sort((a, b) {
      if (a['year'] != b['year']) return (a['year'] as int).compareTo(b['year'] as int);
      return (a['round'] as int).compareTo(b['round'] as int);
    });

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10.w,
        mainAxisSpacing: 10.h,
        childAspectRatio: 2.2,
      ),
      itemCount: _myPicks.length,
      itemBuilder: (context, index) {
        final pick = _myPicks[index];
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8.h),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 18.w, height: 18.w,
                decoration: BoxDecoration(color: AppColors.accentCyan.withOpacity(0.2), shape: BoxShape.circle),
                child: Center(child: Text(pick['round'].toString(), style: TextStyle(color: AppColors.accentCyan, fontSize: 10.sp, fontWeight: FontWeight.bold))),
              ),
              SizedBox(width: 8.w),
              Text("${pick['year']} RD ${pick['round']}", style: TextStyle(color: Colors.white70, fontSize: 9.sp, fontWeight: FontWeight.bold)),
            ],
          ),
        );
      },
    );
  }

  void _handlePlayerTap(int index) async {
    if (_isSwapping) return;

    if (_selectedIndex == null) {
      setState(() => _selectedIndex = index);
    } else if (_selectedIndex == index) {
      setState(() => _selectedIndex = null);
    } else {
      // Perform Swap
      final idx1 = _selectedIndex!;
      final idx2 = index;
      setState(() {
        _isSwapping = true;
        _selectedIndex = null;
      });

      try {
        final profile = await UserService.getCurrentUserProfile();
        if (profile != null) {
          await LeagueService.swapPlayers(_selectedLeague!['id'], profile['uid'], idx1, idx2);
          await _loadRoster();
          if (mounted) {
            AppDialogs.showSuccessDialog(context, title: "LINEUP UPDATED", message: "Your roster swap was successful.");
          }
        }
      } catch (e) {
        if (mounted) {
          AppDialogs.showPremiumErrorDialog(context, message: 'Swap failed. Please try again.');
        }
      } finally {
        if (mounted) setState(() => _isSwapping = false);
      }
    }
  }

  Widget _buildEmptySlotRow(String slot, Color bgColor) {
    final isSelectionActive = _selectedIndex != null;
    
    return GestureDetector(
      onTap: () => isSelectionActive ? _handleMoveToEmptySlot(_selectedIndex!, slot) : null,
      child: Container(
        margin: EdgeInsets.only(bottom: 8.h),
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12.h),
          border: Border.all(
            color: isSelectionActive ? AppColors.accentCyan.withOpacity(0.5) : Colors.white.withOpacity(0.04),
            style: isSelectionActive ? BorderStyle.solid : BorderStyle.none,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44.w, height: 32.h,
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(8.h)),
              child: Center(
                child: Text(slot, style: TextStyle(color: Colors.white24, fontSize: 10.sp, fontWeight: FontWeight.w900)),
              ),
            ),
            SizedBox(width: 12.w),
            Text(
              isSelectionActive ? "MOVE TO $slot" : "EMPTY SLOT",
              style: TextStyle(
                color: isSelectionActive ? AppColors.accentCyan.withOpacity(0.7) : Colors.white10,
                fontSize: 11.sp,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const Spacer(),
            if (isSelectionActive)
              Icon(Icons.login, color: AppColors.accentCyan.withOpacity(0.4), size: 16.w),
          ],
        ),
      ),
    );
  }

  void _handleMoveToEmptySlot(int playerIndex, String targetSlot) async {
    if (_isSwapping) return;

    setState(() {
      _isSwapping = true;
      _selectedIndex = null;
    });

    try {
      final profile = await UserService.getCurrentUserProfile();
      if (profile != null) {
        await LeagueService.movePlayerToSlot(_selectedLeague!['id'], profile['uid'], playerIndex, targetSlot);
        await _loadRoster();
        if (mounted) {
          AppDialogs.showSuccessDialog(context, title: "PLAYER MOVED", message: "Successfully moved into the $targetSlot slot.");
        }
      }
    } catch (e) {
      if (mounted) {
        AppDialogs.showPremiumErrorDialog(context, message: e.toString().contains('Exception:') ? e.toString().split('Exception: ')[1] : e.toString());
      }
    } finally {
      if (mounted) setState(() => _isSwapping = false);
    }
  }
}
