import 'package:flutter/material.dart';
import '../../core/colors.dart';
import '../../core/constants.dart';
import '../../core/responsive_helper.dart';
import '../../services/league_service.dart';
import '../../widgets/join_league_bottom_sheet.dart';
import '../create_league_screen.dart';
import '../league_details_screen.dart';
import '../league_games_screen.dart';

class LeagueTab extends StatefulWidget {
  const LeagueTab({super.key});

  @override
  State<LeagueTab> createState() => _LeagueTabState();
}

class _LeagueTabState extends State<LeagueTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _showBracket = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Successfully joined league!')),
        );
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
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMyLeaguesTab(),
                _buildLeaguesContent(isOnline: true),
              ],
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

  Widget _buildMyLeaguesTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: LeagueService.getUserLeaguesStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.accentCyan));
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState();
        }

        final leagues = snapshot.data!;

        return ListView(
          padding: EdgeInsets.all(20.w),
          children: [
            _buildSectionHeader("YOUR LEAGUES"),
            SizedBox(height: 12.h),
            ...leagues.map((league) => _buildLeagueCard(league)),
            SizedBox(height: 20.h),
            _buildTierCard(),
            SizedBox(height: 20.h),
          ],
        );
      },
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
              "NO LEAGUES YET",
              style: TextStyle(color: Colors.white, fontSize: 20.sp, fontWeight: FontWeight.w900, letterSpacing: 1.0),
            ),
            SizedBox(height: 8.h),
            Text(
              "Create your first league and invite friends to join the competition.",
              style: TextStyle(color: Colors.white38, fontSize: 14.sp, height: 1.5),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32.h),
            GestureDetector(
              onTap: _navigateToCreateLeague,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 14.h),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.accentCyan, AppColors.createGradientPurple]),
                  borderRadius: BorderRadius.circular(30.h),
                  boxShadow: [
                    BoxShadow(color: AppColors.accentCyan.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5)),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, color: Colors.white, size: 20.w),
                    SizedBox(width: 8.w),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        "CREATE YOUR FIRST LEAGUE", 
                        style: TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 40.h),
            _buildTierCard(),
            SizedBox(height: 20.h),
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
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(color: statusColor.withOpacity(0.15), borderRadius: BorderRadius.circular(20.h), border: Border.all(color: statusColor.withOpacity(0.4))),
                      child: Text(draftStatus.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 10.sp, fontWeight: FontWeight.bold)),
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
                SizedBox(height: 12.h),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LeagueGamesScreen()),
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

  Widget _buildLeaguesContent({required bool isOnline}) {
    return ListView(
      padding: EdgeInsets.all(20.w),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionHeader(_showBracket ? "PLAYOFF BRACKET" : "STANDINGS"),
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
        SizedBox(height: 12.h),
        _showBracket ? _buildPlayoffBracket() : _buildStandingsList(),
        SizedBox(height: 24.h),
        _buildSectionHeader("TROPHY COLLECTION"),
        SizedBox(height: 12.h),
        _buildTrophyRow(),
        SizedBox(height: 24.h),
        _buildTierCard(),
        SizedBox(height: 20.h),
      ],
    );
  }

  Widget _buildPlayoffBracket() {
    return Container(
      height: 300.h,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.w),
        border: Border.all(color: Colors.white10),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.all(16.w),
        children: [
          _buildBracketRound("QUARTERFINALS", [
            ["TEAM A", "TEAM B"],
            ["TEAM C", "TEAM D"],
            ["TEAM E", "TEAM F"],
            ["TEAM G", "TEAM H"],
          ]),
          _buildBracketDivider(),
          _buildBracketRound("SEMIFINALS", [
            ["TBD", "TBD"],
            ["TBD", "TBD"],
          ]),
          _buildBracketDivider(),
          _buildBracketRound("FINALS", [
            ["TBD", "TBD"],
          ]),
          _buildBracketDivider(),
          _buildChampionRound("CHAMPION", "TBD"),
        ],
      ),
    );
  }

  Widget _buildBracketRound(String title, List<List<String>> matchups) {
    return SizedBox(
      width: 140.w,
      child: Column(
        children: [
          Text(title, style: TextStyle(color: Colors.white38, fontSize: 9.sp, fontWeight: FontWeight.bold)),
          SizedBox(height: 12.h),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: matchups.map((m) => _buildBracketMatchup(m[0], m[1])).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChampionRound(String title, String teamName) {
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
                      teamName.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.w900),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      "WINNER",
                      style: TextStyle(color: AppColors.gold, fontSize: 9.sp, fontWeight: FontWeight.bold),
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

  Widget _buildBracketMatchup(String team1, String team2) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 4.h, horizontal: 10.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(8.h),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          _buildBracketTeam(team1, isWinner: team1 != "TBD"),
          Divider(color: Colors.white10, height: 4.h),
          _buildBracketTeam(team2, isWinner: false),
        ],
      ),
    );
  }

  Widget _buildBracketTeam(String name, {bool isWinner = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(child: Text(name, style: TextStyle(color: isWinner ? Colors.white : Colors.white54, fontSize: 10.sp, fontWeight: isWinner ? FontWeight.bold : FontWeight.normal), overflow: TextOverflow.ellipsis)),
        if (isWinner) Icon(Icons.check_circle, color: AppColors.accentCyan, size: 10.w),
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

  Widget _buildStandingsList() {
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
                SizedBox(width: 45.w, child: Center(child: Text("STATUS", style: _standingHeaderStyle))),
              ],
            ),
          ),
          _buildStandingRow(rank: "1", team: "CYBER TITANS", record: "12-0", pf: "245.5", pa: "180.2", status: "Z", isHighlighted: false),
          _buildStandingRow(rank: "2", team: "NEON KNIGHTS", record: "10-2", pf: "210.8", pa: "195.4", status: "X", isHighlighted: false),
          _buildStandingRow(rank: "3", team: "DYNASTY WARRIORS", record: "10-2", pf: "205.1", pa: "188.9", status: "*", isHighlighted: false),
          _buildStandingRow(rank: "4", team: "GRIDIRON KINGS", record: "9-3", pf: "198.4", pa: "202.1", status: "*", isHighlighted: true),
          _buildStandingRow(rank: "5", team: "SHADOW RAIDERS", record: "8-4", pf: "185.2", pa: "210.3", status: "E", isHighlighted: false, isLast: true),
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
            width: 45.w,
            child: Center(
              child: Text(
                _showBracket ? "" : status,
                style: TextStyle(
                  color: isHighlighted ? AppColors.accentCyan : Colors.white24,
                  fontWeight: FontWeight.w900,
                  fontSize: 14.sp,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrophyRow() {
    return Row(
      children: [
        _buildTrophyItem(Icons.emoji_events, "CHAMPION", "2025"),
        SizedBox(width: 12.w),
        _buildTrophyItem(Icons.military_tech, "MVP", "2024"),
        SizedBox(width: 12.w),
        _buildTrophyItem(Icons.stars, "ALL-STAR", "2024"),
        SizedBox(width: 12.w),
        _buildTrophyItem(Icons.workspace_premium, "LEGEND", "2023"),
      ],
    );
  }

  Widget _buildTrophyItem(IconData icon, String label, String year) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16.w), border: Border.all(color: Colors.white10)),
        child: Column(
          children: [
            Icon(icon, color: AppColors.gold, size: 24.w),
            SizedBox(height: 8.h),
            Text(label, style: TextStyle(color: Colors.white70, fontSize: 8.sp, fontWeight: FontWeight.bold)),
            Text(year, style: TextStyle(color: Colors.white24, fontSize: 8.sp)),
          ],
        ),
      ),
    );
  }
}
