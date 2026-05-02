import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/user_service.dart';
import '../../services/league_service.dart';
import '../tabs/roster_tab.dart';

import '../../core/colors.dart';
import '../../core/constants.dart';
import '../../core/responsive_helper.dart';
import '../profile_screen.dart';
import '../player_profile_screen.dart';
import '../scout_players_screen.dart';
import '../daily_check_in_screen.dart';
import '../game_recap_screen.dart';
import '../draft_room_screen.dart';
import '../league_chat_screen.dart';
import '../offseason_dashboard_screen.dart';
import '../../services/coin_service.dart';
import '../../services/check_in_service.dart';
import '../../widgets/app_dialogs.dart';
import '../../widgets/notification_badge.dart';
import '../league_games_screen.dart';
import '../training_screen.dart';
import '../matches_screen.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> with TickerProviderStateMixin {
  String _teamName = "GRIDIRON KINGS";
  late AnimationController _statsController;
  late AnimationController _logoController;
  int _coins = 0;
  List<Map<String, dynamic>> _myLeagues = [];
  Map<String, dynamic>? _selectedLeague;
  String? _userId;
  String? _ageRange;
  bool _isAnyTrainingCompleted = false;
  bool _isSimulating = false;
  bool _forceOffseason = false;
  bool _isGuest = false;
  Timer? _uiTimer;
  final ScrollController _scrollController = ScrollController();


  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _statsController = AnimationController(vsync: this, duration: const Duration(seconds: 10), value: 0.2)..repeat();
    _logoController = AnimationController(vsync: this, duration: const Duration(seconds: 15), value: 0.5)..repeat();
    _loadInitialData();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
        
        // Simulation Trigger Check (8 PM EST)
        final now = DateTime.now().toUtc();
        final estNow = now.subtract(const Duration(hours: 5));
        if (estNow.hour == 20 && estNow.minute == 0 && estNow.second == 0 && !_isSimulating) {
           _triggerLiveSimulation();
        }
      }
    });
  }
  
  Future<void> _loadInitialData() async {
    try {
      final profile = await UserService.getCurrentUserProfile();
      final leagues = await LeagueService.getUserLeagues();
      if (mounted) {
        setState(() {
          _teamName = (profile?['username']?.toString() ?? profile?['teamName']?.toString() ?? "MY TEAM").toUpperCase();
          _userId = profile?['uid'];
          _ageRange = profile?['ageRange'];
          _isGuest = profile?['isGuest'] ?? false;
          if (leagues.isNotEmpty) {
            _myLeagues = leagues;
            // Prioritize the league the user just looked at (Global State)
            if (LeagueService.activeLeague != null) {
              _selectedLeague = leagues.firstWhere(
                (l) => l['id'] == LeagueService.activeLeagueId, 
                orElse: () => leagues.first
              );
            } else {
              _selectedLeague = leagues.first;
            }
          }
        });
      }
      if (_selectedLeague != null) {
        // No need to manually load roster, StreamBuilder handles it
      }
    } catch (e) {
      // Error handling
    }
  }

  int _getDaysUntilDraft() {
    final now = DateTime.now();
    DateTime next;
    if (now.day <= 15) {
      next = DateTime(now.year, now.month, 15);
    } else {
      int nextMonth = now.month + 1;
      int nextYear = now.year;
      if (nextMonth > 12) {
        nextMonth = 1;
        nextYear++;
      }
      next = DateTime(nextYear, nextMonth, 15);
    }
    return next.difference(now).inDays;
  }

  double _calculateTeamSps(List<Map<String, dynamic>> roster) {
    if (roster.isEmpty) return 0.0;
    
    // Only count starters for the overall team SPS
    final starters = roster.where((p) {
      final pos = p['pos']?.toString() ?? "";
      return ["QB", "RB1", "RB2", "WR1", "WR2", "WR3", "TE", "FLEX", "SFLEX", "RB", "WR"].contains(pos);
    }).toList();

    if (starters.isEmpty) return 0.0;
    
    double total = 0.0;
    for (var p in starters) {
      total += double.tryParse(p['sps']?.toString() ?? "0.0") ?? 0.0;
    }
    return total / starters.length;
  }

  Widget _buildAgeBasedTipCard() {
    final bool isPro = _ageRange == '18-plus';
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20.h),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: (isPro ? AppColors.accentCyan : AppColors.selectionGreenStart).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPro ? Icons.trending_up : Icons.security,
              color: isPro ? AppColors.accentCyan : AppColors.selectionGreenStart,
              size: 24.sp,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPro ? "PRO MARKET INSIGHT" : "ACADEMY SAFETY TIP",
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  isPro 
                    ? "Monitor SPS trends carefully. High-growth players often peak before the mid-season trade window."
                    : "Always verify your trades twice. Remember, virtual sportsmanship makes the best managers!",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimulationOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.85),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             SizedBox(
               width: 120.w,
               height: 120.w,
               child: CircularProgressIndicator(
                 color: AppColors.accentCyan,
                 strokeWidth: 2,
               ),
             ),
             SizedBox(height: 40.h),
             Text(
               "SIMULATING MATCHES...",
               style: TextStyle(
                 color: Colors.white,
                 fontSize: 20.sp,
                 fontWeight: FontWeight.w900,
                 letterSpacing: 3.0,
               ),
             ),
             SizedBox(height: 12.h),
             Text(
               "PLEASE WAIT WHILE WE CALCULATE RESULTS",
               style: TextStyle(
                 color: Colors.white38,
                 fontSize: 10.sp,
                 fontWeight: FontWeight.bold,
                 letterSpacing: 1.0,
               ),
             ),
          ],
        ),
      ),
    );
  }

  Map<String, String> _getStandingsInfo() {
    if (_selectedLeague == null || _selectedLeague!['standings'] == null) {
      return {'record': '0-0', 'rank': '---', 'gamesOut': '0'};
    }
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return {'record': '0-0', 'rank': '---', 'gamesOut': '0'};
    }
    final rawStandings = _selectedLeague!['standings'];
    if (rawStandings is! Map) {
      return {'record': '0-0', 'rank': '---', 'gamesOut': '0'};
    }
    final entries = rawStandings.entries.toList();
    entries.sort((a, b) {
      final wA = (a.value as Map?)?['w']?.toInt() ?? 0;
      final wB = (b.value as Map?)?['w']?.toInt() ?? 0;
      if (wA != wB) return wB.compareTo(wA);
      
      final pfA = (a.value as Map?)?['pf']?.toDouble() ?? 0.0;
      final pfB = (b.value as Map?)?['pf']?.toDouble() ?? 0.0;
      return pfB.compareTo(pfA);
    });

    final myUid = _userId ?? FirebaseAuth.instance.currentUser?.uid;
    final myRank = entries.indexWhere((e) => e.key == myUid) + 1;
    if (myRank == 0) return {'record': '0-0', 'rank': '---', 'gamesOut': '0'};

    final myData = entries[myRank - 1].value as Map;
    final int myWins = myData['w']?.toInt() ?? 0;
    final int myLosses = myData['l']?.toInt() ?? 0;
    final int myTies = myData['t']?.toInt() ?? 0;
    final String record = myTies > 0 ? '${myWins}-${myLosses}-${myTies}' : '${myWins}-${myLosses}';
    String rankStr = '${myRank}th';
    if (myRank == 1) rankStr = '1st';
    else if (myRank == 2) rankStr = '2nd';
    else if (myRank == 3) rankStr = '3rd';
    int gamesOut = 0;
    if (myRank > 4 && entries.length >= 4) {
      final fourthSeedData = entries[3].value as Map;
      final int fourthWins = fourthSeedData['w']?.toInt() ?? 0;
      gamesOut = fourthWins - myWins;
    }
    return {'record': record, 'rank': rankStr, 'gamesOut': gamesOut.toString()};
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _statsController.dispose();
    _logoController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _getGametimeText() {
    final now = DateTime.now().toUtc();
    final estNow = now.subtract(const Duration(hours: 5));
    var target = DateTime(estNow.year, estNow.month, estNow.day, 20, 0, 0); // 8 PM EST
    if (estNow.isAfter(target)) {
        target = target.add(const Duration(days: 1));
    }
    final diff = target.difference(estNow);
    final hours = diff.inHours.toString().padLeft(2, '0');
    final mins = (diff.inMinutes % 60).toString().padLeft(2, '0');
    final secs = (diff.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$mins:$secs';
  }

  void _showEditTeamDialog() {
    final TextEditingController controller = TextEditingController(text: _teamName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.h)),
        title: Text("EDIT TEAM", style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "TEAM NAME",
                labelStyle: TextStyle(color: AppColors.accentCyan, fontSize: 12.sp),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.accentCyan)),
              ),
            ),
            SizedBox(height: 20.h),
            Text("LOGO CUSTOMIZATION COMING SOON", style: TextStyle(color: Colors.white38, fontSize: 10.sp, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("CANCEL", style: TextStyle(color: Colors.white38, fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () {
              setState(() => _teamName = controller.text.trim().toUpperCase());
              Navigator.pop(context);
            },
            child: Text("SAVE", style: TextStyle(color: AppColors.accentCyan, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showLeaguePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.h)),
          border: Border.all(color: Colors.white10),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 16.h),
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2.h)),
              ),
              SizedBox(height: 16.h),
              Text("SWITCH LEAGUE", style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
              SizedBox(height: 12.h),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: EdgeInsets.only(bottom: 24.h),
                  children: _myLeagues.map((league) {
                    final isSelected = _selectedLeague?['id'] == league['id'];
                    return ListTile(
                      onTap: () {
                        setState(() => _selectedLeague = league);
                        LeagueService.activeLeague = league;
                        Navigator.pop(context);
                      },
                      leading: Container(
                        width: 32.w,
                        height: 32.w,
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.accentCyan : AppColors.surface,
                          borderRadius: BorderRadius.circular(8.h),
                        ),
                        child: Icon(Icons.shield_rounded, color: isSelected ? Colors.black : Colors.white24, size: 18.w),
                      ),
                      title: Text(
                        (league['name'] ?? "UNKNOWN").toString().toUpperCase(),
                        style: TextStyle(
                          color: isSelected ? AppColors.accentCyan : Colors.white,
                          fontSize: 14.sp,
                          fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
                        ),
                      ),
                      trailing: isSelected ? Icon(Icons.check_circle, color: AppColors.accentCyan, size: 20.w) : null,
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _triggerLiveSimulation() async {
    if (_selectedLeague == null) return;
    
    setState(() => _isSimulating = true);
    
    try {
      await LeagueService.simulateLeagueWeek(_selectedLeague!['id']);
      if (mounted) {
        AppDialogs.showSuccessDialog(
          context,
          title: "SIMULATION COMPLETE",
          message: "The week's matches have finished. New standings are ready!",
        );
      }
    } catch (e) {
      if (mounted) {
        AppDialogs.showPremiumErrorDialog(context, message: "League simulation encountered an error. Please try manually in Settings.");
      }
    } finally {
      if (mounted) {
        setState(() => _isSimulating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // SYNC: If the user opened a different league in another screen, 
    // update the HomeTab to reflect that league automatically.
    if (LeagueService.activeLeagueId != null && 
        _selectedLeague != null && 
        _selectedLeague!['id'] != LeagueService.activeLeagueId) {
      final matchingLeague = _myLeagues.firstWhere(
        (l) => l['id'] == LeagueService.activeLeagueId,
        orElse: () => {},
      );
      if (matchingLeague.isNotEmpty) {
        Future.delayed(Duration.zero, () {
          if (mounted) setState(() => _selectedLeague = matchingLeague);
        });
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: (_selectedLeague != null && _userId != null)
                ? LeagueService.getRosterStream(_selectedLeague!['id'], _userId!)
                : Stream.empty(),
            builder: (context, snapshot) {
              final players = snapshot.data ?? [];
              final teamSps = _calculateTeamSps(players);

              return ListView(
                controller: _scrollController,
                padding: EdgeInsets.zero,
                children: [
                  Stack(
                    children: [
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: 350.h,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: Image.asset(
                                'assets/images/signup_background.png',
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
                                      Colors.black.withOpacity(0.6),
                                      AppColors.background.withOpacity(0.9),
                                      AppColors.background,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SafeArea(
                        child: Column(
                          children: [
                             _buildTopBar(),
                             SizedBox(height: 10.h),
                             _buildTeamHeader(),
                             SizedBox(height: 20.h),
                             _buildOverallStatsCircle(teamSps),
                             SizedBox(height: 25.h),
                             _buildActionButtons(context),
                             if (_ageRange != null) ...[
                               SizedBox(height: 25.h),
                               _buildAgeBasedTipCard(),
                             ],
                             SizedBox(height: 20.h),
                             _buildRosterSection(context, players),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }
          ),
          if (_isSimulating) _buildSimulationOverlay(),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: AppColors.topBarBg.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16.h),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildTopBarItem("GAMETIME:", Text(_getGametimeText(), style: const TextStyle(color: AppColors.accentCyan, fontWeight: FontWeight.bold))),
          StreamBuilder<DocumentSnapshot>(
            stream: _selectedLeague == null 
              ? const Stream.empty() 
              : FirebaseFirestore.instance.collection('leagues').doc(_selectedLeague!['id']).collection('draft').doc('info').snapshots(),
            builder: (context, snapshot) {
              final data = snapshot.hasData && snapshot.data!.exists 
                  ? (snapshot.data!.data() is Map ? Map<String, dynamic>.from(snapshot.data!.data() as Map) : null)
                  : null;
              final status = _forceOffseason ? 'pending' : (data?['status'] as String? ?? 'active');

              if (status == 'active' || status == 'waiting') {
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (_selectedLeague != null) {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => DraftRoomScreen(leagueId: _selectedLeague!['id'])));
                    }
                  },
                  child: _buildTopBarItem("DRAFT DAY:", const Text("ENTER DRAFT", style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold))),
                );
              } else if (status == 'pending') {
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onDoubleTap: () => setState(() => _forceOffseason = false),
                  onTap: () {
                    if (_selectedLeague != null) {
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => OffseasonDashboardScreen(
                          leagueId: _selectedLeague!['id'],
                          leagueName: _selectedLeague!['name'] ?? 'League',
                          seasonNumber: _selectedLeague!['seasonNumber'] ?? 1,
                        ),
                      ));
                    }
                  },
                  child: _buildTopBarItem("OFFSEASON:", const Text("OPEN HUB", style: TextStyle(color: AppColors.accentCyan, fontWeight: FontWeight.bold))),
                );
              }
              return _buildTopBarItem("DRAFT DAY:", Text("${_getDaysUntilDraft()}d", style: const TextStyle(color: AppColors.orangeGradientStart, fontWeight: FontWeight.bold)));
            },
          ),
          StreamBuilder<int>(
            stream: CoinService.balanceStream(),
            builder: (context, snapshot) {
              final balance = snapshot.data ?? 0;
              return GestureDetector(
                onLongPress: () {
                  setState(() => _forceOffseason = !_forceOffseason);
                },
                child: _buildTopBarItem("COINS:", Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.monetization_on, color: AppColors.gold, size: 12.sp),
                    SizedBox(width: 4.w),
                    Text("$balance", style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold)),
                  ],
                )),
              );
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildTopBarItem(String label, Widget valueWidget) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: Colors.white38, fontSize: 9.sp, fontWeight: FontWeight.bold)),
        SizedBox(height: 4.h),
        valueWidget,
      ],
    );
  }

  Widget _buildTeamHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_ageRange != null)
           Padding(
             padding: EdgeInsets.only(left: 16.w, bottom: 4.h),
             child: Text(
               _ageRange == '18-plus' ? "PRO DYNASTY EDITION" : "YOUTH ACADEMY EDITION",
               style: TextStyle(
                 color: _ageRange == '18-plus' ? AppColors.accentCyan : AppColors.selectionGreenStart,
                 fontSize: 10.sp,
                 fontWeight: FontWeight.w900,
                 letterSpacing: 2.0,
               ),
             ),
           ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Row(
            children: [
               Container(
                 width: 50.w,
                 height: 50.w,
                 decoration: const BoxDecoration(
                   shape: BoxShape.circle,
                   color: AppColors.surface,
                   boxShadow: [
                     BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 4)),
                   ],
                 ),
                 child: AnimatedBuilder(
                   animation: _logoController,
                   builder: (context, child) {
                     return CustomPaint(
                       painter: ActionBorderPainter(
                         animationValue: _logoController.value,
                         gradientColors: [
                           AppColors.gold.withOpacity(0.0),
                           AppColors.gold,
                           AppColors.gold.withOpacity(0.0),
                         ],
                         hasGlow: true,
                       ),
                       child: child,
                     );
                   },
                   child: Icon(Icons.catching_pokemon, color: AppColors.gold, size: 30.w),
                 ),
               ),
               SizedBox(width: 12.w),
               Expanded(
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Row(
                       children: [
                         Flexible(
                           child: Text(
                             _teamName,
                             maxLines: 1,
                             overflow: TextOverflow.ellipsis,
                             style: TextStyle(
                               color: Colors.white,
                               fontSize: 18.sp,
                               fontWeight: FontWeight.w900,
                               letterSpacing: 1.2,
                             ),
                           ),
                         ),
                         if (_myLeagues.length > 1)
                            Padding(
                              padding: EdgeInsets.only(left: 8.w),
                              child: GestureDetector(
                                onTap: () => _showLeaguePicker(context),
                                child: Container(
                                  height: 24.h,
                                  padding: EdgeInsets.symmetric(horizontal: 10.w),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [AppColors.accentCyan.withOpacity(0.15), AppColors.accentTeal.withOpacity(0.15)],
                                    ),
                                    borderRadius: BorderRadius.circular(12.h),
                                    border: Border.all(color: AppColors.accentCyan.withOpacity(0.4)),
                                    boxShadow: [
                                      BoxShadow(color: AppColors.accentCyan.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2)),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        (_selectedLeague?['name'] ?? "UNKNOWN").toString().toUpperCase(),
                                        style: TextStyle(color: AppColors.accentCyan, fontSize: 8.sp, fontWeight: FontWeight.w900),
                                      ),
                                      SizedBox(width: 4.w),
                                      Icon(Icons.unfold_more_rounded, color: AppColors.accentCyan, size: 14.w),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          else if (_selectedLeague != null)
                             Padding(
                               padding: EdgeInsets.only(left: 8.w),
                               child: Text(
                                 (_selectedLeague!['name'] ?? "").toString().toUpperCase(),
                                 style: TextStyle(color: AppColors.accentCyan, fontSize: 9.sp, fontWeight: FontWeight.w900),
                               ),
                             ),
                       ],
                     ),
                     SizedBox(height: 2.h),
                     Builder(
                       builder: (context) {
                         final info = _getStandingsInfo();
                         return FittedBox(
                           fit: BoxFit.scaleDown,
                           alignment: Alignment.centerLeft,
                           child: Row(
                             children: [
                               Text("RECORD: ", style: TextStyle(color: Colors.white38, fontSize: 11.sp)),
                               Text(info['record']!, style: TextStyle(color: Colors.white70, fontSize: 11.sp, fontWeight: FontWeight.bold)),
                               Text("  |  RANK: ", style: TextStyle(color: Colors.white38, fontSize: 11.sp)),
                               Text(info['rank']!, style: TextStyle(color: Colors.white70, fontSize: 11.sp, fontWeight: FontWeight.bold)),
                               Text("  |  GAMES OUT: ", style: TextStyle(color: Colors.white38, fontSize: 11.sp)),
                               Text(info['gamesOut']!, style: TextStyle(color: Colors.white70, fontSize: 11.sp, fontWeight: FontWeight.bold)),
                             ],
                           ),
                         );
                       }
                     ),
                   ],
                 ),
               ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOverallStatsCircle(double teamSps) {
    return AnimatedBuilder(
      animation: _statsController,
      builder: (context, child) {
        // Slow pulse for a premium feel
        final scale = 1.0 + (math.sin(_statsController.value * 2 * math.pi) * 0.02);
        final glowOpacity = 0.2 + (math.sin(_statsController.value * 2 * math.pi) * 0.1);

        return Transform.scale(
          scale: scale,
          child: Container(
            width: 140.w,
            height: 140.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.footballBrown, width: 8.w),
              gradient: const RadialGradient(
                colors: [
                  AppColors.statsCircleBgStart,
                  AppColors.statsCircleBgEnd,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.gold.withOpacity(glowOpacity.clamp(0.0, 1.0)),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: child,
          ),
        );
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "OVERALL\nTEAM SPS:",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 9.sp,
              fontWeight: FontWeight.bold,
              height: 1.1,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            teamSps.toStringAsFixed(1),
            style: TextStyle(
              color: Colors.white,
              fontSize: 28.sp,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Row(
        children: [
          StreamBuilder<bool>(
            stream: CheckInService.checkInStatusStream(),
            builder: (context, snapshot) {
              return HomeActionCard(
                title: "DAILY",
                subtitle: "CHECK-IN",
                icon: Icons.calendar_today,
                colors: [AppColors.accentCyan, AppColors.createGradientPurple],
                duration: const Duration(seconds: 11),
                showNotification: snapshot.data == true,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DailyCheckInScreen())),
              );
            }
          ),
          HomeActionCard(
            title: "TRAIN",
            subtitle: "PLAYERS",
            icon: Icons.fitness_center,
            colors: [AppColors.blueGradientStart, AppColors.blueGradientEnd],
            duration: const Duration(seconds: 3),
            onTap: () {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent - 200,
                duration: const Duration(milliseconds: 1000),
                curve: Curves.easeInOutQuart,
              );
            },
          ),
          HomeActionCard(
            title: "SCOUT",
            subtitle: "PLAYERS",
            icon: Icons.search,
            colors: [AppColors.greenGradientStart, AppColors.greenGradientEnd],
            duration: const Duration(seconds: 5),
            onTap: () {
              if (_selectedLeague != null && _userId != null) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => ScoutPlayersScreen(
                  leagueId: _selectedLeague!['id'],
                  userId: _userId!,
                )));
              }
            },
          ),
          HomeActionCard(
            title: "LEAGUE",
            subtitle: "CHAT",
            icon: Icons.chat_bubble_outline_rounded,
            colors: [AppColors.accentCyan, AppColors.blueGradientStart],
            duration: const Duration(seconds: 4),
            onTap: () {
              if (_selectedLeague != null) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => LeagueChatScreen(
                  leagueId: _selectedLeague!['id'],
                  leagueName: _selectedLeague!['name'] ?? 'League',
                )));
              }
            },
          ),
          HomeActionCard(
            title: "VIEW",
            subtitle: "MATCHUP",
            icon: Icons.vignette,
            colors: [AppColors.orangeGradientStart, AppColors.orangeGradientEnd],
            duration: const Duration(seconds: 7),
            onTap: () {
              if (_selectedLeague != null) {
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => LeagueGamesScreen(leagueId: _selectedLeague!['id'] as String),
                ));
              }
            },
          ),
          HomeActionCard(
            title: "VIEW",
            subtitle: "ROSTER",
            icon: Icons.groups,
            colors: [AppColors.purpleGradientStart, AppColors.purpleGradientEnd],
            duration: const Duration(seconds: 9),
            onTap: () {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeInOutQuart,
              );
            },
          ),
          HomeActionCard(
            title: "GAME",
            subtitle: "RECAP",
            icon: Icons.history,
            colors: [AppColors.orangeGradientEnd, AppColors.logoutPink],
            duration: const Duration(seconds: 13),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GameRecapScreen())),
          ),
        ],
      ),
    );
  }

  Widget _buildRosterSection(BuildContext context, List<Map<String, dynamic>> players) {
    // Show discovery if no league joined yet, OR if in automated Bronze league but NOT a guest.
    final bool hasNoLeague = _selectedLeague == null && _myLeagues.isEmpty;
    final bool isBronzeLeague = _selectedLeague?['tier'] == 'Bronze';
    final bool showDiscovery = hasNoLeague || (isBronzeLeague && !_isGuest);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.rosterSectionBg,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          _buildRosterHeader(),
          if (showDiscovery)
            _buildDiscoveryPrompt(context)
          else ...[
            _buildPlayerFromSlot(context, "QB", _getPlayerBySlot(players, "QB"), players),
            _buildPlayerFromSlot(context, "RB", _getPlayerBySlot(players, "RB1"), players),
            _buildPlayerFromSlot(context, "RB", _getPlayerBySlot(players, "RB2"), players),
            _buildPlayerFromSlot(context, "WR", _getPlayerBySlot(players, "WR1"), players),
            _buildPlayerFromSlot(context, "WR", _getPlayerBySlot(players, "WR2"), players),
            _buildPlayerFromSlot(context, "WR", _getPlayerBySlot(players, "WR3"), players),
            _buildPlayerFromSlot(context, "TE", _getPlayerBySlot(players, "TE"), players),
            _buildPlayerFromSlot(context, "W/R/T", _getPlayerBySlot(players, "FLEX"), players),
            _buildPlayerFromSlot(context, "W/R/T/Q", _getPlayerBySlot(players, "SFLEX"), players),
            
            _buildSectionHeader("BENCH (${players.where((p) => p['pos'] == 'BN').length})"),
            ...players.where((p) => p['pos'] == 'BN').map((p) => _buildPlayerFromSlot(context, "BN", p, players)),
            
            _buildSectionHeader("IR (${players.where((p) => p['pos'] == 'IR').length})"),
            ...players.where((p) => p['pos'] == 'IR').map((p) => _buildPlayerFromSlot(context, "IR", p, players)),
            
            _buildSectionHeader("TAXI (${players.where((p) => p['pos'] == 'TAXI').length})"),
            ...players.where((p) => p['pos'] == 'TAXI').map((p) => _buildPlayerFromSlot(context, "TAXI", p, players)),
          ],
          SizedBox(height: 50.h),
        ],
      ),
    );
  }

  Widget _buildDiscoveryPrompt(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(32.w),
      child: Column(
        children: [
          Icon(Icons.sports_football, color: AppColors.accentCyan.withOpacity(0.5), size: 64.w),
          SizedBox(height: 24.h),
          Text(
            "READY TO PLAY NFL?",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 22.sp,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            "Take command of your own NFL franchise. Join or create a league to start building your dynasty today.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white38,
              fontSize: 14.sp,
              height: 1.5,
            ),
          ),
          SizedBox(height: 32.h),
          GestureDetector(
            onTap: () {
              // Switch to LEAGUE tab (Index 1)
              final matchesState = MatchesScreen.of(context);
              if (matchesState != null) {
                matchesState.setTab(1);
              }
            },
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 16.h),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.accentCyan, AppColors.createGradientPurple],
                ),
                borderRadius: BorderRadius.circular(16.h),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentCyan.withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  "CONTINUE TO LEAGUES",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic>? _getPlayerBySlot(List<Map<String, dynamic>> players, String slot) {
    // 1. Try exact match (for new data or single slots like QB/TE)
    final exact = players.where((p) => p['pos'] == slot).firstOrNull;
    if (exact != null) return exact;

    // 2. Fallback for legacy generic data ('RB' -> 'RB1'/'RB2')
    if (slot == 'RB1' || slot == 'RB2' || slot == 'RB') {
      final rbs = players.where((p) => p['pos'] == 'RB' || p['pos'] == 'RB1' || p['pos'] == 'RB2').toList();
      if (slot == 'RB1' && rbs.isNotEmpty) return rbs[0];
      if (slot == 'RB2' && rbs.length > 1) return rbs[1];
      if (slot == 'RB' && rbs.isNotEmpty) return rbs[0];
    }
    
    if (slot.startsWith('WR')) {
      final wrs = players.where((p) => p['pos'] == 'WR' || p['pos'].toString().startsWith('WR')).toList();
      if (slot == 'WR1' && wrs.isNotEmpty) return wrs[0];
      if (slot == 'WR2' && wrs.length > 1) return wrs[1];
      if (slot == 'WR3' && wrs.length > 2) return wrs[2];
    }

    if (slot == 'SFLEX' || slot == 'S-FLEX') {
      return players.where((p) => p['pos'] == 'SFLEX' || p['pos'] == 'S-FLEX').firstOrNull;
    }

    return null;
  }

  Widget _buildPlayerFromSlot(BuildContext context, String pos, Map<String, dynamic>? player, List<Map<String, dynamic>> allPlayers) {
    if (player == null) {
        return _buildPlayerRow(
          pos: pos, 
          name: "EMPTY", 
          sps: "-", 
          matchup: "-", 
          exp: "-", 
          img: Icons.person_outline, 
          context: context,
          isPlaceholder: true,
          onTrain: null,
        );
    }
    
    return _buildPlayerRow(
      pos: pos,
      name: player['name'] ?? 'Unknown',
      sps: player['sps']?.toString() ?? '??',
      matchup: player['matchup'] ?? '-',
      exp: player['exp']?.toString() ?? '?',
      img: Icons.person,
      context: context,
      onTrain: () {
        if (_selectedLeague != null && _userId != null) {
          final index = allPlayers.indexOf(player);
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => TrainingScreen(
              player: player,
              leagueId: _selectedLeague!['id'],
              userId: _userId!,
              playerIndex: index,
            ),
          ));
        }
      },
    );
  }

  Widget _buildRosterHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          SizedBox(width: 45.w, child: Text("Pos", style: _headerStyle)),
          Expanded(child: Text("Player", style: _headerStyle)),
          SizedBox(width: 45.w, child: Text("PROJ.", style: _headerStyle)),
          SizedBox(width: 55.w, child: Text("Matchup", style: _headerStyle)),
          SizedBox(width: 35.w, child: Text("Exp.", style: _headerStyle)),
          SizedBox(width: 60.w, child: Center(child: Text("Train", style: _headerStyle))),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      color: AppColors.sectionHeaderBg,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.white38,
          fontSize: 10.sp,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildPlayerRow({
    required String pos,
    required String name,
    required String sps,
    required String matchup,
    required String exp,
    required IconData img,
    required BuildContext context,
    required VoidCallback? onTrain,
    bool isPlaceholder = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 45.w,
            child: Text(
              pos,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.white38, fontSize: 11.sp, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14.w,
                  backgroundColor: Colors.white12,
                  child: Icon(img, size: 16.w, color: Colors.white54),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 45.w,
            child: Text(
              sps,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.white, fontSize: 11.sp, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(
            width: 55.w,
            child: Text(
              matchup,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.white38, fontSize: 11.sp),
            ),
          ),
          SizedBox(
            width: 35.w,
            child: Text(
              exp,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.white38, fontSize: 11.sp),
            ),
          ),
          SizedBox(
            width: 60.w,
            child: GestureDetector(
              onTap: onTrain,
              child: Container(
                height: 28.h,
                decoration: BoxDecoration(
                  gradient: isPlaceholder ? null : const LinearGradient(
                    colors: [AppColors.blueGradientStart, AppColors.blueGradientEnd],
                  ),
                  borderRadius: BorderRadius.circular(8.h),
                ),
                child: Center(
                  child: Text(
                    isPlaceholder ? "" : "Train",
                    style: TextStyle(color: Colors.white, fontSize: 10.sp, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  TextStyle get _headerStyle => TextStyle(
    color: Colors.white24,
    fontSize: 10.sp,
    fontWeight: FontWeight.bold,
  );
}

class HomeActionCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> colors;
  final Duration duration;
  final VoidCallback onTap;
  final bool showNotification;

  const HomeActionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.colors,
    required this.duration,
    required this.onTap,
    this.showNotification = false,
  });

  @override
  State<HomeActionCard> createState() => _HomeActionCardState();
}

class _HomeActionCardState extends State<HomeActionCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      value: math.Random().nextDouble(),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 4.w),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Container(
              width: 100.w,
              height: 60.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16.h),
                color: AppColors.cardBackground,
                boxShadow: [
                  BoxShadow(color: widget.colors.last.withOpacity(0.05), blurRadius: 10, spreadRadius: -2),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16.h),
                child: Stack(
                  children: [
                    // Moving the border logic here
                    Positioned.fill(
                      child: CustomPaint(
                        painter: ActionBorderPainter(
                          animationValue: _controller.value,
                          gradientColors: [
                            widget.colors.first.withOpacity(0.0),
                            widget.colors.first,
                            widget.colors.first.withOpacity(0.0),
                          ],
                          hasGlow: true,
                        ),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.all(1.5),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(14.h),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            right: -5.w,
                            bottom: -5.h,
                            child: Icon(widget.icon, size: 40.w, color: widget.colors.first.withOpacity(0.05)),
                          ),
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  widget.title,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9.sp,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                Text(
                                  widget.subtitle,
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 8.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (widget.showNotification)
                            Positioned(
                              top: 8.h,
                              right: 8.w,
                              child: const PulsingNotificationDot(),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class ActionBorderPainter extends CustomPainter {
  final double animationValue;
  final List<Color> gradientColors;
  final bool hasGlow;

  ActionBorderPainter({
    required this.animationValue,
    required this.gradientColors,
    this.hasGlow = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(size.height / 3.5));
    
    final paint = Paint()
      ..shader = SweepGradient(
        colors: gradientColors,
        stops: const [0.0, 0.5, 1.0],
        transform: GradientRotation(animationValue * 2 * 3.14159),
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = hasGlow ? 3.5 : 3;

    if (hasGlow) {
      final blurPaint = Paint()
        ..shader = SweepGradient(
          colors: [
            gradientColors[1].withOpacity(0.0),
            gradientColors[1].withOpacity(0.2),
            gradientColors[1].withOpacity(0.4),
            gradientColors[1].withOpacity(0.2),
            gradientColors[1].withOpacity(0.0),
          ],
          stops: const [0.0, 0.4, 0.5, 0.6, 1.0],
          transform: GradientRotation(animationValue * 2 * 3.14159),
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
      
      canvas.drawRRect(rrect, blurPaint);
    }

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant ActionBorderPainter oldDelegate) =>
      oldDelegate.animationValue != animationValue;
}
