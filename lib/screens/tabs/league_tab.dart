import 'package:flutter/material.dart';
import '../../core/colors.dart';
import '../../core/constants.dart';
import '../../core/responsive_helper.dart';
import '../../services/league_service.dart';
import '../../services/user_service.dart';
import '../../widgets/join_league_bottom_sheet.dart';
import '../../widgets/app_dialogs.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../create_league_screen.dart';
import '../league_details_screen.dart';
import '../league_games_screen.dart';
import '../trophy_room_screen.dart';
import '../commissioner_tools_screen.dart';
import '../league_chat_screen.dart';

class LeagueTab extends StatefulWidget {
  const LeagueTab({super.key});

  @override
  State<LeagueTab> createState() => _LeagueTabState();
}

class _LeagueTabState extends State<LeagueTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _showBracket = false;
  final Map<String, String> _managerNames = {};
  bool _isGuest = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final profile = await UserService.getCurrentUserProfile();
    if (mounted) {
      setState(() {
        _isGuest = profile?['isGuest'] ?? false;
      });
    }
  }

  void _fetchManagerNames(List<String> uids) async {
    // Only fetch if we have new UIDs
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
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _navigateToCreateLeague() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateLeagueScreen()),
    );
  }

  void _showJoinLeagueSheet() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const JoinLeagueBottomSheet(),
    );

    if (result == true) {
      if (mounted) {
        AppDialogs.showSuccessDialog(context, title: "WELCOME!", message: "Successfully joined the league.");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveHelper.init(context);
    return Container(
      color: AppColors.background,
      child: Column(
        children: [
          _buildHeader(),
          SizedBox(height: 10.h),
          _buildModeSelector(),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: LeagueService.getUserLeaguesStream(),
              builder: (context, snapshot) {
                final leagues = snapshot.data ?? [];
                final primaryLeague = leagues.isNotEmpty ? leagues.first : null;

                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildMyLeaguesTab(leagues, snapshot.connectionState == ConnectionState.waiting),
                    _buildLeaguesContent(league: primaryLeague),
                  ],
                );
              }
            ),
          ),
          SizedBox(height: 10.h),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.all(20.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "LEAGUE", 
                    style: AppTextStyles.heading,
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "PROGRESSION", 
                    style: AppTextStyles.heading.copyWith(color: AppColors.accentCyan),
                  ),
                ),
              ],
            ),
          ),
          // Action Buttons
          Row(
            children: [
              // Join League Button
              GestureDetector(
                onTap: _showJoinLeagueSheet,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12.h),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.login, color: Colors.white70, size: 16.w),
                      SizedBox(width: 6.w),
                      Text(
                        'JOIN',
                        style: TextStyle(color: Colors.white70, fontSize: 12.sp, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              // Create League Button
              GestureDetector(
                onTap: _navigateToCreateLeague,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.accentCyan, AppColors.createGradientPurple],
                    ),
                    borderRadius: BorderRadius.circular(12.h),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accentCyan.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.add, color: Colors.white, size: 16.w),
                      SizedBox(width: 6.w),
                      Text(
                        'CREATE',
                        style: TextStyle(color: Colors.white, fontSize: 12.sp, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTierCard() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.leagueCardBg, AppColors.brandDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24.w),
        border: Border.all(color: Colors.white10),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentCyan.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 60.w, height: 60.w,
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), shape: BoxShape.circle),
                child: Center(child: Icon(Icons.shield, color: AppColors.accentCyan, size: 35.w)),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("PRO LEAGUE TIER", style: TextStyle(color: Colors.white54, fontSize: 10.sp, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    Text("BRONZE DIVISION II", style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("RANK", style: TextStyle(color: Colors.white38, fontSize: 10.sp)),
                  Text("#425", style: TextStyle(color: AppColors.accentCyan, fontSize: 16.sp, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          SizedBox(height: 20.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("850 / 1000 XP", style: TextStyle(color: Colors.white70, fontSize: 12.sp, fontWeight: FontWeight.w600)),
              Text("SILVER TIER", style: TextStyle(color: Colors.white38, fontSize: 10.sp, fontWeight: FontWeight.bold)),
            ],
          ),
          SizedBox(height: 8.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(4.h),
            child: LinearProgressIndicator(
              value: 0.85,
              backgroundColor: Colors.white12,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accentCyan),
              minHeight: 8.h,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelector() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      height: 48.h,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.h),
        border: Border.all(color: Colors.white10),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(color: AppColors.accentCyan, borderRadius: BorderRadius.circular(10.h)),
        labelColor: Colors.black87,
        unselectedLabelColor: Colors.white70,
        labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.sp),
        tabs: [
          Tab(child: FittedBox(fit: BoxFit.scaleDown, child: Text("MY LEAGUES"))),
          Tab(child: FittedBox(fit: BoxFit.scaleDown, child: Text("LEADERBOARD"))),
        ],
      ),
    );
  }

  // ─── My Leagues Tab ───────────────────────────────────────────────────────

  Widget _buildMyLeaguesTab(List<Map<String, dynamic>> leagues, bool isLoading) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.accentCyan));
    }

    // Display all leagues the user is a member of
    final displayLeagues = leagues;

    if (displayLeagues.isEmpty) {
      return _buildEmptyState();
    }

    return ListView(
      padding: EdgeInsets.all(20.w),
      children: [
        _buildSectionHeader("YOUR LEAGUES"),
        SizedBox(height: 12.h),
        ...displayLeagues.map((league) => _buildLeagueCard(league)),
        SizedBox(height: 20.h),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events_outlined, color: Colors.white24, size: 64.w),
            SizedBox(height: 20.h),
            Text(
              "READY TO PLAY NFL?",
              style: TextStyle(color: Colors.white, fontSize: 20.sp, fontWeight: FontWeight.w900, letterSpacing: 1.0),
            ),
            SizedBox(height: 8.h),
            Text(
              "Join an existing league or create your own to start your NFL Dynasty journey.",
              style: TextStyle(color: Colors.white38, fontSize: 14.sp, height: 1.5),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32.h),
            // Join Button
            GestureDetector(
              onTap: _showJoinLeagueSheet,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 14.h),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16.h),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.login, color: Colors.white70, size: 20.w),
                    SizedBox(width: 8.w),
                    Text(
                      "JOIN AN NFL LEAGUE", 
                      style: TextStyle(color: Colors.white70, fontSize: 14.sp, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16.h),
            // Create Button
            GestureDetector(
              onTap: _navigateToCreateLeague,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 14.h),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.accentCyan, AppColors.createGradientPurple]),
                  borderRadius: BorderRadius.circular(16.h),
                  boxShadow: [
                    BoxShadow(color: AppColors.accentCyan.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5)),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add, color: Colors.white, size: 20.w),
                    SizedBox(width: 8.w),
                    Text(
                      "CREATE NEW LEAGUE", 
                      style: TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }

  Widget _buildLeagueCard(Map<String, dynamic> league) {
    final name = league['name'] as String? ?? 'Unknown League';
    final joinCode = league['joinCode'] as String? ?? '------';
    final members = (league['members'] as List?)?.length ?? 1;
    final maxMembers = league['maxMembers'] as int? ?? 10;
    final draftStatus = league['draftStatus'] as String? ?? 'pending';
    final scoringType = (league['scoringType'] as String? ?? 'standard').toUpperCase().replaceAll('_', ' ');
    
    // Privacy Logic
    final dynamic settingsRaw = league['settings'];
    final settings = settingsRaw is Map ? Map<String, dynamic>.from(settingsRaw) : {};
    final isPublic = settings['allowPublicJoin'] as bool? ?? false;

    final statusColor = draftStatus == 'active' ? Colors.green : draftStatus == 'complete' ? Colors.orange : AppColors.accentCyan;

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: AppColors.leagueCardBg,
        borderRadius: BorderRadius.circular(20.w),
        border: Border.all(color: Colors.white10),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20.w),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => LeagueDetailsScreen(league: league),
              ),
            );
          },
          child: Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(name.toUpperCase(), style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.w900, letterSpacing: 0.5), overflow: TextOverflow.ellipsis),
                    ),
                    Row(
                      children: [
                        // Privacy Tag
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: isPublic ? AppColors.accentCyan.withOpacity(0.1) : Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(20.h),
                            border: Border.all(color: isPublic ? AppColors.accentCyan.withOpacity(0.3) : Colors.white10),
                          ),
                          child: Text(
                            isPublic ? 'PUBLIC' : 'PRIVATE',
                            style: TextStyle(color: isPublic ? AppColors.accentCyan : Colors.white38, fontSize: 8.sp, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        // Computer Generated Tag
                        if (league['isOffline'] == true) ...[
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: Colors.purple.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20.h),
                              border: Border.all(color: Colors.purple.withOpacity(0.4)),
                            ),
                            child: Text(
                              'COMPUTER GENERATED',
                              style: TextStyle(color: Colors.purple[300], fontSize: 8.sp, fontWeight: FontWeight.bold),
                            ),
                          ),
                          SizedBox(width: 8.w),
                        ],
                        // Status Tag
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                          decoration: BoxDecoration(color: statusColor.withOpacity(0.15), borderRadius: BorderRadius.circular(20.h), border: Border.all(color: statusColor.withOpacity(0.4))),
                          child: Text(draftStatus.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 8.sp, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                Row(
                  children: [
                    _buildLeagueStat(Icons.group, '$members / $maxMembers', 'Members'),
                    SizedBox(width: 20.w),
                    _buildLeagueStat(Icons.scoreboard, scoringType, 'Scoring'),
                  ],
                ),
                if (!isPublic) ...[
                  SizedBox(height: 16.h),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                    decoration: BoxDecoration(
                      color: AppColors.accentCyan.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10.h),
                      border: Border.all(color: AppColors.accentCyan.withOpacity(0.2)),
                    ),
                    child: Column(
                      children: [
                        Text('JOIN CODE', style: TextStyle(color: Colors.white38, fontSize: 10.sp, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                        SizedBox(height: 4.h),
                        Text(joinCode, style: TextStyle(color: AppColors.accentCyan, fontSize: 22.sp, fontWeight: FontWeight.w900, letterSpacing: 6.0)),
                      ],
                    ),
                  ),
                ],
                SizedBox(height: 12.h),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LeagueGamesScreen(leagueId: league['id'] as String),
                      ),
                    );
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10.h),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.sports_football, color: AppColors.accentCyan, size: 14.w),
                          SizedBox(width: 8.w),
                          Text(
                            "VIEW GAMES",
                            style: TextStyle(color: Colors.white, fontSize: 10.sp, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeagueStat(IconData icon, String value, String label) {
    return Row(
      children: [
        Icon(icon, color: Colors.white38, size: 16.w),
        SizedBox(width: 6.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: Colors.white24, fontSize: 10.sp)),
            Text(value, style: TextStyle(color: Colors.white70, fontSize: 12.sp, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  // ─── Leaderboard Tab (static for now) ─────────────────────────────────────

  Widget _buildLeaguesContent({Map<String, dynamic>? league}) {
    if (league == null) {
      return _buildNoLeagueLeaderboard();
    }

    final standings = Map<String, dynamic>.from(league['standings'] ?? {});

    return ListView(
      padding: EdgeInsets.all(20.w),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionHeader(_showBracket ? "PLAYOFF BRACKET" : "STANDINGS"),
            Row(
              children: [
                // League Chat Button
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => LeagueChatScreen(
                      leagueId: league['id'] as String,
                      leagueName: league['name'] as String,
                    ),
                  )),
                  child: Container(
                    margin: EdgeInsets.only(right: 8.w),
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: AppColors.accentCyan.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10.h),
                      border: Border.all(color: AppColors.accentCyan.withOpacity(0.4)),
                    ),
                    child: Icon(Icons.chat_bubble_outline_rounded, color: AppColors.accentCyan, size: 18.sp),
                  ),
                ),
                // Commissioner gear — only visible to the league creator
                if (FirebaseAuth.instance.currentUser?.uid == league['createdBy'])
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => CommissionerToolsScreen(leagueId: league['id'] as String),
                    )),
                    child: Container(
                      margin: EdgeInsets.only(right: 8.w),
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10.h),
                        border: Border.all(color: AppColors.gold.withOpacity(0.4)),
                      ),
                      child: Icon(Icons.settings_rounded, color: AppColors.gold, size: 18.sp),
                    ),
                  ),
                GestureDetector(
                  onTap: () => setState(() => _showBracket = !_showBracket),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: _showBracket ? AppColors.accentCyan : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(10.h),
                      border: Border.all(color: _showBracket ? Colors.transparent : Colors.white10),
                    ),
                    child: Text(
                      "BRACKET",
                      style: TextStyle(
                        color: _showBracket ? Colors.black : Colors.white70,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: 12.h),
        _showBracket ? _buildPlayoffBracket(league['playoffs']) : _buildStandingsList(standings, league['members'] ?? []),
        SizedBox(height: 24.h),
        _buildSectionHeader("TROPHY COLLECTION"),
        SizedBox(height: 12.h),
        _buildTrophyRow(),
        SizedBox(height: 24.h),
        // League Tier System is at the bottom per spec
        _buildSectionHeader("LEAGUE TIER SYSTEM"),
        SizedBox(height: 12.h),
        _buildTierCard(),
        SizedBox(height: 24.h),
        _buildSectionHeader("RECENT ACTIVITY"),
        SizedBox(height: 12.h),
        _buildRecentActivity(league['id'] as String),
        SizedBox(height: 100.h),
      ],
    );
  }

  Widget _buildRecentActivity(String leagueId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('leagues')
          .doc(leagueId)
          .collection('transactions')
          .orderBy('timestamp', descending: true)
          .limit(10)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: AppColors.accentCyan));
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16.w), border: Border.all(color: Colors.white10)),
            child: Center(child: Text("NO RECENT TRANSACTIONS", style: TextStyle(color: Colors.white10, fontSize: 10.sp, fontWeight: FontWeight.bold))),
          );
        }

        // Pre-fetch UIDs for names
        final uids = <String>{};
        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          if (data['userId'] != null) uids.add(data['userId'] as String);
          if (data['fromUid'] != null) uids.add(data['fromUid'] as String);
          if (data['toUid'] != null) uids.add(data['toUid'] as String);
        }
        WidgetsBinding.instance.addPostFrameCallback((_) => _fetchManagerNames(uids.toList()));

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return _buildTransactionCard(data);
          },
        );
      },
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> data) {
    final type = data['type'] as String? ?? 'unknown';
    final timestamp = data['timestamp'] as Timestamp?;
    final dateStr = timestamp != null ? "${timestamp.toDate().month}/${timestamp.toDate().day}" : "";

    IconData icon;
    Color color;
    String title = "";
    String detail = "";

    if (type == 'trade') {
      icon = Icons.swap_horiz;
      color = AppColors.accentCyan;
      final fromName = _managerNames[data['fromUid']] ?? "MANAGER";
      final toName = _managerNames[data['toUid']] ?? "MANAGER";
      title = "TRADE COMPLETED";
      
      final offP = List<String>.from(data['offeringPlayers'] ?? []);
      final reqP = List<String>.from(data['requestingPlayers'] ?? []);
      final offK = List<String>.from(data['offeringPicks'] ?? []);
      final reqK = List<String>.from(data['requestingPicks'] ?? []);

      detail = "$fromName sent ${[...offP, ...offK].join(", ")} to $toName for ${[...reqP, ...reqK].join(", ")}";
    } else if (type == 'waiver') {
      icon = Icons.star;
      color = Colors.orangeAccent;
      final name = _managerNames[data['userId']] ?? "MANAGER";
      title = "WAIVER ADDITION";
      detail = "$name added ${data['playerName']} (Bid: \$${data['bidAmount']})";
    } else if (type == 'drop') {
      icon = Icons.content_cut;
      color = Colors.redAccent;
      final name = _managerNames[data['userId']] ?? "MANAGER";
      title = "PLAYER DROPPED";
      detail = "$name dropped ${data['playerName']} (${data['pos']})";
    } else {
      icon = Icons.info_outline;
      color = Colors.white24;
      title = "TRANSACTION";
      detail = "League update processed.";
    }

    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.h),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 16.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title, style: TextStyle(color: color.withOpacity(0.8), fontSize: 9.sp, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                    Text(dateStr, style: TextStyle(color: Colors.white24, fontSize: 8.sp)),
                  ],
                ),
                SizedBox(height: 4.h),
                Text(detail, style: TextStyle(color: Colors.white, fontSize: 11.sp, height: 1.3, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayoffBracket(Map<String, dynamic>? playoffs) {
    if (playoffs == null) {
      return Container(
        height: 200.h,
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16.w), border: Border.all(color: Colors.white10)),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, color: Colors.white10, size: 40.w),
              SizedBox(height: 12.h),
              Text("PLAYOFFS BEGIN AFTER WEEK 8", style: TextStyle(color: Colors.white38, fontSize: 12.sp, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
              SizedBox(height: 4.h),
              Text("TOP 4 TEAMS QUALIFY", style: TextStyle(color: Colors.white10, fontSize: 10.sp)),
            ],
          ),
        ),
      );
    }

    // Trigger name fetch for playoff teams
    final playoffUids = <String>{};
    for (var m in List<Map<String, dynamic>>.from(playoffs['semifinals'] ?? [])) {
      playoffUids.add(m['team1']); playoffUids.add(m['team2']);
    }
    final dynamic finalsRaw = playoffs['finals'];
    final Map<String, dynamic>? finals = finalsRaw is Map ? Map<String, dynamic>.from(finalsRaw) : null;
    if (finals != null) {
      if (finals['team1'] != null) playoffUids.add(finals['team1']);
      if (finals['team2'] != null) playoffUids.add(finals['team2']);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchManagerNames(playoffUids.toList());
    });

    return Container(
      height: 320.h,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.w),
        border: Border.all(color: Colors.white10),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.all(20.w),
        children: [
          _buildBracketRound("SEMIFINALS", List<Map<String, dynamic>>.from(playoffs['semifinals'])),
          _buildBracketDivider(),
          _buildBracketRound("FINALS", [playoffs['finals']]),
          _buildBracketDivider(),
          _buildChampionRound("CHAMPION", playoffs['champion']),
        ],
      ),
    );
  }

  Widget _buildBracketRound(String title, List<Map<String, dynamic>> matches) {
    return SizedBox(
      width: 150.w,
      child: Column(
        children: [
          Text(title, style: TextStyle(color: Colors.white38, fontSize: 9.sp, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
          SizedBox(height: 16.h),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: matches.map((m) => _buildBracketMatchup(m)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChampionRound(String title, String? championUid) {
    final name = championUid != null ? (_managerNames[championUid] ?? "LOADING...") : "TBD";
    
    return SizedBox(
      width: 160.w,
      child: Column(
        children: [
          Text(title, style: TextStyle(color: AppColors.gold, fontSize: 10.sp, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
          SizedBox(height: 12.h),
          Expanded(
            child: Center(
              child: Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: AppColors.gold.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20.h),
                  border: Border.all(color: AppColors.gold.withOpacity(0.3), width: 2),
                  boxShadow: [
                    BoxShadow(color: AppColors.gold.withOpacity(0.1), blurRadius: 20, spreadRadius: 5),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.emoji_events, color: AppColors.gold, size: 48.w),
                    SizedBox(height: 12.h),
                    Text(
                      name.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.w900),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      championUid != null ? "WINNER" : "WAITING",
                      style: TextStyle(color: championUid != null ? AppColors.gold : Colors.white24, fontSize: 9.sp, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBracketMatchup(Map<String, dynamic> match) {
    final t1 = match['team1'] as String?;
    final t2 = match['team2'] as String?;
    final s1 = (match['score1'] as num? ?? 0.0).toDouble();
    final s2 = (match['score2'] as num? ?? 0.0).toDouble();
    final winner = match['winner'] as String?;

    return Container(
      padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 10.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12.h),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          _buildBracketTeam(t1, score: s1, isWinner: winner != null && winner == t1),
          SizedBox(height: 6.h),
          Divider(color: Colors.white.withOpacity(0.05), height: 1.h),
          SizedBox(height: 6.h),
          _buildBracketTeam(t2, score: s2, isWinner: winner != null && winner == t2),
        ],
      ),
    );
  }

  Widget _buildBracketTeam(String? uid, {double score = 0.0, bool isWinner = false}) {
    final name = uid != null ? (_managerNames[uid] ?? "LOADING...") : "TBD";

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            name,
            style: TextStyle(
              color: uid == null ? Colors.white10 : (isWinner ? Colors.white : Colors.white60),
              fontSize: 10.sp,
              fontWeight: isWinner ? FontWeight.w900 : FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (uid != null && score > 0)
          Text(
            score.toStringAsFixed(1),
            style: TextStyle(
              color: isWinner ? AppColors.accentCyan : Colors.white24,
              fontSize: 9.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        if (isWinner) 
          Padding(
            padding: EdgeInsets.only(left: 4.w),
            child: Icon(Icons.check_circle, color: AppColors.accentCyan, size: 10.w),
          ),
      ],
    );
  }

  Widget _buildBracketDivider() {
    return Container(
      width: 20.w,
      alignment: Alignment.center,
      child: Container(width: 1, color: Colors.white10),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(width: 4.w, height: 16.h, decoration: BoxDecoration(color: AppColors.accentCyan, borderRadius: BorderRadius.circular(2.w))),
        SizedBox(width: 8.w),
        Text(title, style: TextStyle(color: Colors.white70, fontSize: 12.sp, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
      ],
    );
  }

  Widget _buildStandingsList(Map<String, dynamic> standingsData, List<dynamic> memberUids) {
    if (standingsData.isEmpty) {
      return Container(
        height: 100.h,
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16.w), border: Border.all(color: Colors.white10)),
        child: const Center(child: Text("No games played yet.", style: TextStyle(color: Colors.white38))),
      );
    }

    // Convert map to list and sort by Wins desc, then PF desc
    final List<MapEntry<String, dynamic>> entries = standingsData.entries.toList();
    entries.sort((a, b) {
      final wA = a.value['w'] as int? ?? 0;
      final wB = b.value['w'] as int? ?? 0;
      if (wA != wB) return wB.compareTo(wA);
      
      final pfA = (a.value['pf'] as num? ?? 0).toDouble();
      final pfB = (b.value['pf'] as num? ?? 0).toDouble();
      return pfB.compareTo(pfA);
    });

    // Trigger name fetch for all teams in standings
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchManagerNames(entries.map((e) => e.key).toList());
    });

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.w),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          // Header Row
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.02),
              border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.1))),
            ),
            child: Row(
              children: [
                SizedBox(width: 25.w, child: Text("RK", style: _standingHeaderStyle)),
                Expanded(child: Text("TEAM", style: _standingHeaderStyle)),
                SizedBox(width: 45.w, child: Center(child: Text("W-L", style: _standingHeaderStyle))),
                SizedBox(width: 40.w, child: Center(child: Text("PF", style: _standingHeaderStyle))),
                SizedBox(width: 40.w, child: Center(child: Text("PA", style: _standingHeaderStyle))),
                SizedBox(width: 50.w, child: Center(child: Text("STATUS", style: _standingHeaderStyle))),
              ],
            ),
          ),
          ...List.generate(entries.length, (index) {
            final entry = entries[index];
            final uid = entry.key;
            final data = entry.value;
            final isUser = uid == LeagueService.currentUser?.uid;

            return _buildStandingRow(
              rank: (index + 1).toString(),
              team: _managerNames[uid] ?? "MANAGER ${uid.substring(0, 4)}",
              record: "${data['w']}-${data['l']}",
              pf: (data['pf'] as num? ?? 0).toStringAsFixed(1),
              pa: (data['pa'] as num? ?? 0).toStringAsFixed(1),
              status: index == 0 ? "Z" : (index == 1 || index == 2) ? "X" : index == 3 ? "*" : "E",
              isHighlighted: isUser,
              isLast: index == entries.length - 1,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildNoLeagueLeaderboard() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.leaderboard_outlined, color: Colors.white24, size: 64.w),
          SizedBox(height: 16.h),
          Text("JOIN A LEAGUE", style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.bold)),
          Text("Standings will appear here once you join.", style: TextStyle(color: Colors.white38, fontSize: 12.sp)),
        ],
      ),
    );
  }

  TextStyle get _standingHeaderStyle => TextStyle(
    color: Colors.white38,
    fontSize: 10.sp,
    fontWeight: FontWeight.bold,
  );

  Widget _buildStandingRow({
    required String rank,
    required String team,
    required String record,
    required String pf,
    required String pa,
    required String status,
    required bool isHighlighted,
    bool isLast = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: isHighlighted ? AppColors.accentCyan.withOpacity(0.1) : Colors.transparent,
        border: isLast ? null : Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Row(
        children: [
          SizedBox(width: 25.w, child: Text(rank, style: TextStyle(color: isHighlighted ? AppColors.accentCyan : Colors.white38, fontWeight: FontWeight.bold, fontSize: 12.sp))),
          Expanded(child: Text(team, style: TextStyle(color: isHighlighted ? Colors.white : Colors.white70, fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal, fontSize: 12.sp))),
          SizedBox(width: 45.w, child: Center(child: Text(record, style: TextStyle(color: isHighlighted ? AppColors.accentCyan : Colors.white54, fontWeight: FontWeight.bold, fontSize: 12.sp)))),
          SizedBox(width: 40.w, child: Center(child: Text(pf, style: TextStyle(color: Colors.white70, fontSize: 11.sp)))),
          SizedBox(width: 40.w, child: Center(child: Text(pa, style: TextStyle(color: Colors.white38, fontSize: 11.sp)))),
          SizedBox(
            width: 50.w,
            child: Center(
              child: Text(
                // STATUS: only show when NOT in bracket view
                _showBracket ? "" : status,
                style: TextStyle(
                  color: status == "Z" ? AppColors.gold
                    : status == "X" ? AppColors.accentCyan
                    : status == "*" ? Colors.greenAccent
                    : status == "E" ? Colors.redAccent
                    : Colors.white24,
                  fontWeight: FontWeight.w900,
                  fontSize: 13.sp,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrophyRow() {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const TrophyRoomScreen()));
      },
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2B2B2B), Color(0xFF1E1E1E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24.w),
          border: Border.all(color: AppColors.gold.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: AppColors.gold.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: AppColors.gold.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.emoji_events, color: AppColors.gold, size: 30.w),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("TROPHY ROOM", style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                  SizedBox(height: 4.h),
                  Text("View historical championships and accolades", style: TextStyle(color: Colors.white54, fontSize: 11.sp)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 16.w),
          ],
        ),
      ),
    );
  }
}
