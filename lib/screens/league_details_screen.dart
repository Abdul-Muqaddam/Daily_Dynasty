import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/colors.dart';
import '../../core/responsive_helper.dart';
import '../../services/league_service.dart';
import '../../services/pick_service.dart';
import '../../widgets/app_dialogs.dart';
import 'mock_draft_screen.dart';
import 'league_settings_edit_screen.dart';
import 'league_scoring_edit_screen.dart';
import '../../services/player_service.dart';
import '../../services/sleeper_service.dart';
import '../../services/mock_draft_service.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'player_profile_screen.dart';

class LeagueDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> league;

  const LeagueDetailsScreen({super.key, required this.league});

  @override
  State<LeagueDetailsScreen> createState() => _LeagueDetailsScreenState();
}

class _LeagueDetailsScreenState extends State<LeagueDetailsScreen> {
  bool _isLoading = true;
  bool _isSimulating = false;
  List<Map<String, dynamic>> _members = [];
  int _playerFilter = 1; // 0=Search, 1=Trend, 2=Available, 3=Leaders, 4=Trade
  bool _trendingUp = true;   // true = trending up, false = trending down
  String _trendingPos = 'ALL'; // position filter for trend view
  bool _availableIsListView = true; // true = list view, false = grid view
  String _availablePos = 'ALL'; // position filter for available view
  bool _leadersIsListView = true; // true = list view, false = grid view
  String _leadersPos = 'ALL'; // position filter for leaders view
  final TextEditingController _searchController = TextEditingController();
  
  List<Map<String, dynamic>> _allPlayers = [];
  bool _isLoadingPlayers = true;
  bool _isLeagueStandingsView = true;
  final Set<String> _selectedPlayerIds = {}; // Track selected players for batch actions

  @override
  void initState() {
    super.initState();
    _fetchMembers();
    _loadPlayers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPlayers() async {
    try {
      // Fetch directly from Sleeper API bypassing Firestore constraints
      final players = await SleeperService.fetchAllNflPlayers();
      if (mounted) {
        setState(() {
          _allPlayers = players;
          _isLoadingPlayers = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingPlayers = false);
      }
      debugPrint('Failed to fetch from Sleeper: $e');
    }
  }

  Future<void> _fetchMembers() async {
    try {
      final uids = List<String>.from(widget.league['members'] ?? []);
      final members = await LeagueService.getLeagueMembers(uids);
      if (mounted) {
        setState(() {
          _members = members;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Color _getPositionColor(String position) {
    switch (position.toUpperCase()) {
      case 'QB': return const Color(0xFFFF4B4B); // Pink/Red
      case 'RB': return const Color(0xFF00D7FF); // Cyan
      case 'WR': return const Color(0xFF3498DB); // Blue
      case 'TE': return const Color(0xFFFF9F43); // Orange
      case 'K': return const Color(0xFF2ECC71);  // Green
      case 'DEF': return const Color(0xFFBDC3C7); // Silver
      case 'WRT': 
      case 'FLEX': return const Color(0xFF95A5A6); // Slate/Grey
      default: return AppColors.accentCyan;
    }
  }

  Future<void> _simulateWeek() async {
    setState(() => _isSimulating = true);
    try {
      await LeagueService.simulateLeagueWeek(widget.league['id'] as String);
      if (mounted) {
        AppDialogs.showSuccessDialog(
          context,
          title: "WEEK SIMULATED",
          message: "Standings and scores have been updated.",
          onDismiss: () => Navigator.pop(context),
        );
      }
    } catch (e) {
      if (mounted) {
        AppDialogs.showPremiumErrorDialog(context, message: "Simulation failed. Please try again.");
      }
    } finally {
      if (mounted) {
        setState(() => _isSimulating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveHelper.init(context);
    final name = widget.league['name'] as String? ?? 'LEAGUE DETAILS';
    final joinCode = widget.league['joinCode'] as String? ?? '------';
    final dynamic maxMembersRaw = widget.league['maxMembers'];
    final int maxMembers = maxMembersRaw is num ? maxMembersRaw.toInt() : int.tryParse(maxMembersRaw?.toString() ?? '10') ?? 10;
    final draftStatus = widget.league['draftStatus'] as String? ?? 'pending';
    final scoringType = (widget.league['scoringType'] as String? ?? 'standard').toUpperCase().replaceAll('_', ' ');

    final dynamic settingsRaw = widget.league['settings'];
    final settings = settingsRaw is Map ? Map<String, dynamic>.from(settingsRaw) : {};
    final isPublic = settings['allowPublicJoin'] as bool? ?? false;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            name.toUpperCase(),
            style: TextStyle(
              color: Colors.white,
              fontSize: 16.sp,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          centerTitle: true,
        ),
        body: Column(
          children: [
            // Header Stats
            Container(
              padding: EdgeInsets.all(20.w),
              margin: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.leagueCardBg, AppColors.brandDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20.h),
                border: Border.all(color: Colors.white10),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentCyan.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatCol(Icons.people, '${widget.league['members']?.length ?? 1}/$maxMembers', 'MEMBERS'),
                      _buildStatCol(Icons.scoreboard, scoringType, 'SCORING'),
                      _buildStatCol(
                        isPublic ? Icons.public : Icons.lock_outline, 
                        isPublic ? 'PUBLIC' : 'PRIVATE', 
                        'VISIBILITY', 
                        color: isPublic ? AppColors.accentCyan : Colors.white54
                      ),
                      _buildStatCol(Icons.info_outline, draftStatus.toUpperCase(), 'STATUS', color: AppColors.accentTeal),
                    ],
                  ),
                  if (!isPublic) ...[
                    SizedBox(height: 20.h),
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 20.w),
                      decoration: BoxDecoration(
                        color: AppColors.accentCyan.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12.h),
                        border: Border.all(color: AppColors.accentCyan.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('JOIN CODE:', style: TextStyle(color: Colors.white54, fontSize: 12.sp, fontWeight: FontWeight.bold)),
                          Text(joinCode, style: TextStyle(color: AppColors.accentCyan, fontSize: 18.sp, fontWeight: FontWeight.w900, letterSpacing: 4.0)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Tab Bar
            TabBar(
              isScrollable: false,
              indicatorColor: AppColors.accentCyan,
              indicatorWeight: 3,
              labelColor: AppColors.accentCyan,
              unselectedLabelColor: Colors.white38,
              dividerColor: Colors.transparent,
              labelStyle: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w900, letterSpacing: 1.5),
              tabs: const [
                Tab(text: 'DRAFT'),
                Tab(text: 'TEAM'),
                Tab(text: 'PLAYERS'),
                Tab(text: 'LEAGUE'),
              ],
            ),

            Expanded(
              child: TabBarView(
                children: [
                  _buildDraftTab(maxMembers),
                  _buildTeamTab(),
                  _buildPlayersTab(),
                  _buildLeagueTab(maxMembers),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDraftTab(int maxMembers) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.accentCyan));
    }

    return ListView(
      padding: EdgeInsets.all(24.w),
      children: [
        // 0. Draftboard setup section
        _buildDraftBoardSetup(),
        SizedBox(height: 32.h),

        // 1. Teams Section
        Row(
          children: [
            Container(width: 4.w, height: 16.h, decoration: BoxDecoration(color: AppColors.accentCyan, borderRadius: BorderRadius.circular(2.w))),
            SizedBox(width: 8.w),
            Text('LEAGUE MEMBERS', style: TextStyle(color: Colors.white70, fontSize: 12.sp, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
          ],
        ),
        SizedBox(height: 16.h),
        ...List.generate(maxMembers, (index) {
          if (index < _members.length) {
            final member = _members[index];
            final isCreator = member['uid'] == widget.league['createdBy'];
            return _buildMemberCard(member, isCreator);
          } else {
            return _buildPlaceholderCard(index);
          }
        }),

        SizedBox(height: 32.h),
        
        // 2. Settings Section (Card)
        Container(
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16.h),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'LEAGUE SETTINGS',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                  if (widget.league['createdBy'] == LeagueService.currentUser?.uid)
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LeagueSettingsEditScreen(league: widget.league),
                          ),
                        );
                      },
                      child: Text(
                        'EDIT',
                        style: TextStyle(
                          color: AppColors.accentCyan,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 24.h),
              _buildSettingItem("NUMBER OF TEAMS", "$maxMembers"),
              _buildSettingItem("ROSTER", "1 QB, 2 RB, 3 WR, 1 TE, 1 FLEX, 1 SFLEX, 18 BN, 4 IR, 2 TAXI"),
              _buildSettingItem("PLAYOFFS", "4 teams, starts week 9"),
              _buildSettingItem("CLEAR WAIVERS", "Wednesday (12 PM PKT)"),
              _buildSettingItem("WAIVER TIME", "2 Days"),
              _buildSettingItem("TRADE DEADLINE", "Week 6"),
              _buildSettingItem("INJURED RESERVE SLOTS", "4"),
              _buildSettingItem("DRAFT PICK TRADING ALLOWED", "YES"),
              _buildSettingItem("PLAYER AUTO SUBS", "ON"),
            ],
          ),
        ),
        SizedBox(height: 32.h),

        // 3. Scoring Settings
        _buildScoringSettingsCard(),
        SizedBox(height: 32.h),
        // Simulate Week Button (Admin/Dev)
        if (widget.league['createdBy'] == LeagueService.currentUser?.uid)
          GestureDetector(
            onTap: _isSimulating ? null : _simulateWeek,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 14.h),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isSimulating 
                    ? [Colors.white10, Colors.white10] 
                    : [AppColors.accentCyan, AppColors.createGradientPurple],
                ),
                borderRadius: BorderRadius.circular(12.h),
                boxShadow: _isSimulating ? [] : [
                  BoxShadow(color: AppColors.accentCyan.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Center(
                child: _isSimulating
                    ? SizedBox(width: 20.w, height: 20.w, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.play_circle_fill, color: Colors.white, size: 20.w),
                          SizedBox(width: 10.w),
                          Text(
                            "SIMULATE NEXT WEEK",
                            style: TextStyle(color: Colors.white, fontSize: 13.sp, fontWeight: FontWeight.w900, letterSpacing: 1.0),
                          ),
                        ],
                      ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSettingItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white38,
              fontSize: 10.sp,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoringSettingsCard() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.h),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.settings_suggest, color: Colors.white70, size: 20.w),
                  SizedBox(width: 12.w),
                  Text(
                    'SCORING SETTINGS',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              if (widget.league['createdBy'] == LeagueService.currentUser?.uid)
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LeagueScoringEditScreen(league: widget.league),
                      ),
                    );
                  },
                  child: Text(
                    'EDIT',
                    style: TextStyle(
                      color: AppColors.accentCyan,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 16.h),
          
          // Banner
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 16.w),
            decoration: BoxDecoration(
              color: AppColors.accentCyan.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.h),
            ),
            child: Text(
              'Non-standard scoring settings will be highlighted',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 10.sp, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(height: 24.h),

          // Categories
          _buildScoringCategory('PASSING', [
            _buildScoringItem('Passing Yards', '+${(1.0 / (_getScoringValue('PASSING', 'Passing Yards', 25.0) as num)).toStringAsFixed(2)}', 
              subValue: '(${(_getScoringValue('PASSING', 'Passing Yards', 25.0) as num).toInt()} yards = 1 pt)'),
            _buildScoringItem('Passing TD', _getScoringValue('PASSING', 'Passing TD', 4.0).toString()),
            _buildScoringItem('Passing 1st Down', _getScoringValue('PASSING', 'Passing 1st Down', 0.0).toString()),
            _buildScoringItem('2-Pt Conversion', _getScoringValue('PASSING', '2-Pt Conversion', 2.0).toString()),
            _buildScoringItem('Pass Intercepted', _getScoringValue('PASSING', 'Pass Intercepted', -1.0).toString(), isNegative: true),
            _buildScoringItem('Pick 6 Thrown', _getScoringValue('PASSING', 'Pick 6 Thrown', -1.0).toString(), isNegative: true),
            _buildScoringItem('Pass Completed', _getScoringValue('PASSING', 'Pass Completed', 0.0).toString()),
            _buildScoringItem('Incomplete Pass', _getScoringValue('PASSING', 'Incomplete Pass', 0.0).toString()),
            _buildScoringItem('Pass Attempts', _getScoringValue('PASSING', 'Pass Attempts', 0.0).toString()),
            _buildScoringItem('QB Sacked', _getScoringValue('PASSING', 'QB Sacked', 0.0).toString(), isNegative: true),
          ]),

          _buildScoringCategory('RUSHING', [
            _buildScoringItem('Rushing Yards', '+${(1.0 / (_getScoringValue('RUSHING', 'Rushing Yards', 10.0) as num)).toStringAsFixed(2)}', 
              subValue: '(${(_getScoringValue('RUSHING', 'Rushing Yards', 10.0) as num).toInt()} yards = 1 pt)'),
            _buildScoringItem('Rushing TD', _getScoringValue('RUSHING', 'Rushing TD', 6.0).toString()),
            _buildScoringItem('Rushing 1st Down', _getScoringValue('RUSHING', 'Rushing 1st Down', 0.0).toString()),
            _buildScoringItem('2-Pt Conversion', _getScoringValue('RUSHING', '2-Pt Conversion', 2.0).toString()),
            _buildScoringItem('Rush Attempts', _getScoringValue('RUSHING', 'Rush Attempts', 0.0).toString()),
          ]),

          _buildScoringCategory('RECEIVING', [
            _buildScoringItem('Reception', _getScoringValue('RECEIVING', 'Reception', 1.0).toString()),
            _buildScoringItem('Receiving Yards', '+${(1.0 / (_getScoringValue('RECEIVING', 'Receiving Yards', 10.0) as num)).toStringAsFixed(2)}', 
              subValue: '(${(_getScoringValue('RECEIVING', 'Receiving Yards', 10.0) as num).toInt()} yards = 1 pt)'),
            _buildScoringItem('Receiving TD', _getScoringValue('RECEIVING', 'Receiving TD', 6.0).toString()),
            _buildScoringItem('2-Pt Conversion', _getScoringValue('RECEIVING', '2-Pt Conversion', 2.0).toString()),
          ]),

          _buildScoringCategory('KICKING', [
            _buildScoringItem('FG Made 0-39', _getScoringValue('KICKING', 'FG Made 0-39', 3.0).toString()),
            _buildScoringItem('FG Made 40-49', _getScoringValue('KICKING', 'FG Made 40-49', 4.0).toString()),
            _buildScoringItem('FG Made 50+', _getScoringValue('KICKING', 'FG Made 50+', 5.0).toString()),
            _buildScoringItem('PAT Made', _getScoringValue('KICKING', 'PAT Made', 1.0).toString()),
            _buildScoringItem('FG Missed 0-39', _getScoringValue('KICKING', 'FG Missed 0-39', -1.0).toString(), isNegative: true),
          ]),

          _buildScoringCategory('TEAM DEFENSE', [
            _buildScoringItem('Defense TD', _getScoringValue('DEFENSE', 'Defense TD', 6.0).toString()),
            _buildScoringItem('Points Allowed 0', _getScoringValue('DEFENSE', 'Points Allowed 0', 10.0).toString()),
            _buildScoringItem('Points Allowed 1-6', _getScoringValue('DEFENSE', 'Points Allowed 1-6', 7.0).toString()),
            _buildScoringItem('Points Allowed 7-13', _getScoringValue('DEFENSE', 'Points Allowed 7-13', 4.0).toString()),
            _buildScoringItem('Points Allowed 14-20', _getScoringValue('DEFENSE', 'Points Allowed 14-20', 1.0).toString()),
            _buildScoringItem('Points Allowed 28-34', _getScoringValue('DEFENSE', 'Points Allowed 28-34', -1.0).toString(), isNegative: true),
            _buildScoringItem('Points Allowed 35+', _getScoringValue('DEFENSE', 'Points Allowed 35+', -4.0).toString(), isNegative: true),
            _buildScoringItem('Sacks', _getScoringValue('DEFENSE', 'Sacks', 1.0).toString()),
            _buildScoringItem('Interceptions', _getScoringValue('DEFENSE', 'Interceptions', 2.0).toString()),
            _buildScoringItem('Fumble Recovery', _getScoringValue('DEFENSE', 'Fumble Recovery', 2.0).toString()),
            _buildScoringItem('Safety', _getScoringValue('DEFENSE', 'Safety', 2.0).toString()),
            _buildScoringItem('Forced Fumble', _getScoringValue('DEFENSE', 'Forced Fumble', 1.0).toString()),
            _buildScoringItem('Blocked Kick', _getScoringValue('DEFENSE', 'Blocked Kick', 2.0).toString()),
          ]),

          _buildScoringCategory('SPECIAL TEAMS', [
            _buildScoringItem('Special teams td', _getScoringValue('SPECIAL TEAMS', 'Special teams td', 6.0).toString()),
            _buildScoringItem('Special Teams Forced Fumble', _getScoringValue('SPECIAL TEAMS', 'Special Teams Forced Fumble', 1.0).toString()),
            _buildScoringItem('Special Teams Fumble Recovery', _getScoringValue('SPECIAL TEAMS', 'Special Teams Fumble Recovery', 1.0).toString()),
          ]),

          _buildScoringCategory('SPECIAL TEAMS PLAYER', [
            _buildScoringItem('Special teams player td', _getScoringValue('SPECIAL TEAMS PLAYER', 'Special teams player td', 6.0).toString()),
            _buildScoringItem('Special Teams Player Forced Fumble', _getScoringValue('SPECIAL TEAMS PLAYER', 'Special Teams Player Forced Fumble', 1.0).toString()),
            _buildScoringItem('Special Teams Player Fumble Recovery', _getScoringValue('SPECIAL TEAMS PLAYER', 'Special Teams Player Fumble Recovery', 1.0).toString()),
          ]),

          _buildScoringCategory('MISCELLANEOUS', [
            _buildScoringItem('Fumble Lost', _getScoringValue('MISCELLANEOUS', 'Fumble Lost', -2.0).toString(), isNegative: true),
            _buildScoringItem('Fumble Recovery TD', _getScoringValue('MISCELLANEOUS', 'Fumble Recovery TD', 6.0).toString()),
          ]),
        ],
      ),
    );
  }

  Widget _buildScoringCategory(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 16.h),
        Text(
          title,
          style: TextStyle(
            color: Colors.white24,
            fontSize: 10.sp,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
          ),
        ),
        SizedBox(height: 16.h),
        ...items,
        Divider(color: Colors.white.withOpacity(0.05), height: 32.h),
      ],
    );
  }

  Widget _buildScoringItem(String label, String value, {String? subValue, bool isNegative = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: [
              Text(
                label,
                style: TextStyle(color: Colors.white70, fontSize: 13.sp, fontWeight: FontWeight.w500),
              ),
              SizedBox(width: 8.w),
              Icon(Icons.help_outline, color: Colors.white12, size: 14.w),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: isNegative ? Colors.redAccent.withOpacity(0.8) : AppColors.accentCyan,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (subValue != null)
                Text(
                  subValue,
                  style: TextStyle(color: AppColors.accentCyan.withOpacity(0.6), fontSize: 9.sp, fontWeight: FontWeight.bold),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMemberCard(Map<String, dynamic> member, bool isCreator) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.h),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20.w,
            backgroundColor: AppColors.accentCyan.withOpacity(0.2),
            backgroundImage: member['photoUrl'] != null ? NetworkImage(member['photoUrl']) : null,
            child: member['photoUrl'] == null 
                ? Icon(Icons.person, color: AppColors.accentCyan, size: 24.w) 
                : null,
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getDisplayName(member),
                  style: TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4.h),
                Text(
                  'NO DRAFT POSITION',
                  style: TextStyle(color: Colors.white38, fontSize: 10.sp, fontWeight: FontWeight.bold),
                ),
                if (isCreator)
                  Padding(
                    padding: EdgeInsets.only(top: 4.h),
                    child: Text('COMMISSIONER', style: TextStyle(color: AppColors.accentCyan, fontSize: 10.sp, fontWeight: FontWeight.w900)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderCard(int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16.h),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20.w,
            backgroundColor: Colors.white.withOpacity(0.05),
            child: Icon(Icons.person_outline, color: Colors.white24, size: 24.w),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'TEAM ${index + 1}',
                      style: TextStyle(color: Colors.white38, fontSize: 14.sp, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'NOT RESERVED YET',
                      style: TextStyle(color: AppColors.accentCyan.withOpacity(0.3), fontSize: 10.sp, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                Text(
                  'NO DRAFT POSITION',
                  style: TextStyle(color: Colors.white12, fontSize: 10.sp, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeagueTab(int maxMembers) {
    return Column(
      children: [
        // Header with Standings/Playoffs toggle
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Dynamic Title
              Row(
                children: [
                  Text(
                    _isLeagueStandingsView ? 'Standings' : 'Playoffs',
                    style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.bold),
                  ),
                  if (_isLeagueStandingsView) ...[
                    SizedBox(width: 8.w),
                    Text(
                      'Details >',
                      style: TextStyle(color: AppColors.accentCyan, fontSize: 12.sp, fontWeight: FontWeight.bold),
                    ),
                  ],
                ],
              ),
              // Toggle Pill
              Container(
                height: 36.h,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18.h),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => _isLeagueStandingsView = true),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _isLeagueStandingsView ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(18.h),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.leaderboard_rounded,
                              size: 16.w,
                              color: _isLeagueStandingsView ? AppColors.background : Colors.white54,
                            ),
                            if (_isLeagueStandingsView) ...[
                              SizedBox(width: 6.w),
                              Text(
                                'STAND.',
                                style: TextStyle(
                                  color: AppColors.background,
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ]
                          ],
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _isLeagueStandingsView = false),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: !_isLeagueStandingsView ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(18.h),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.account_tree_outlined, // Bracket icon
                              size: 16.w,
                              color: !_isLeagueStandingsView ? AppColors.background : Colors.white54,
                            ),
                            if (!_isLeagueStandingsView) ...[
                              SizedBox(width: 6.w),
                              Text(
                                'PLAYOFF',
                                style: TextStyle(
                                  color: AppColors.background,
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ]
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Body Content
        Expanded(
          child: AnimatedCrossFade(
            duration: const Duration(milliseconds: 300),
            crossFadeState: _isLeagueStandingsView ? CrossFadeState.showFirst : CrossFadeState.showSecond,
            firstChild: _buildStandingsView(maxMembers),
            secondChild: _buildPlayoffsView(),
          ),
        ),
      ],
    );
  }

  Widget _buildStandingsView(int numTeams) {
    // Dynamically build standings using pulled league members where available
    final teams = List.generate(numTeams, (i) {
      if (i < _members.length) {
        final member = _members[i];
        return {
          'rank': i + 1,
          'name': _getDisplayName(member),
          'photoUrl': member['photoUrl'],
          'record': '0-0',
          'waiver': i + 1,
          'pf': '0.00',
          'pa': '0'
        };
      } else {
        return {
          'rank': i + 1,
          'name': 'Open Slot',
          'photoUrl': null,
          'record': '---',
          'waiver': '-',
          'pf': '-',
          'pa': '-'
        };
      }
    });

    return Column(
      children: [
        // Table Header
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
          child: Row(
            children: [
              SizedBox(width: 32.w, child: Text('RANK', style: TextStyle(color: Colors.white38, fontSize: 10.sp, fontWeight: FontWeight.bold))),
              Expanded(child: Text('NAME', style: TextStyle(color: Colors.white38, fontSize: 10.sp, fontWeight: FontWeight.bold))),
              SizedBox(width: 60.w, child: Text('WAIVER', textAlign: TextAlign.center, style: TextStyle(color: Colors.white38, fontSize: 10.sp, fontWeight: FontWeight.bold))),
              SizedBox(width: 50.w, child: Text('PF', textAlign: TextAlign.center, style: TextStyle(color: Colors.white38, fontSize: 10.sp, fontWeight: FontWeight.bold))),
              SizedBox(width: 40.w, child: Text('PA', textAlign: TextAlign.center, style: TextStyle(color: Colors.white38, fontSize: 10.sp, fontWeight: FontWeight.bold))),
            ],
          ),
        ),
        
        // Standings List
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            itemCount: teams.length,
            itemBuilder: (context, index) {
              final team = teams[index];
              final rank = team['rank'] as int;
              final photoUrl = team['photoUrl'] as String?;
              
              // Crown colors: Gold for 1st, Silver for 2nd, Bronze for 3rd
              Color? crownColor;
              if (rank == 1) crownColor = const Color(0xFFFFD700);
              else if (rank == 2) crownColor = const Color(0xFFC0C0C0);
              else if (rank == 3) crownColor = const Color(0xFFCD7F32);

              return Padding(
                padding: EdgeInsets.only(bottom: 24.h),
                child: Row(
                  children: [
                    // Rank
                    SizedBox(
                      width: 20.w,
                      child: Text(
                        rank.toString(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    // Avatar with Crown Stack
                    SizedBox(
                      width: 44.w,
                      height: 52.h,
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          Container(
                            width: 44.w,
                            height: 44.w,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white10),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: photoUrl != null 
                              ? Image.network(photoUrl, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => Icon(Icons.person, color: Colors.white38, size: 20.w))
                              : Icon(Icons.smart_toy_outlined, color: Colors.white38, size: 20.w), // Default Bot avatar
                          ),
                          if (crownColor != null)
                            Positioned(
                              top: 0,
                              child: Icon(Icons.workspace_premium_rounded, color: crownColor, size: 20.w),
                            ),
                        ],
                      ),
                    ),
                    SizedBox(width: 12.w),
                    // Name and Record
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            team['name'].toString(),
                            style: TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            team['record'].toString(),
                            style: TextStyle(color: Colors.white54, fontSize: 12.sp),
                          ),
                        ],
                      ),
                    ),
                    // Stats
                    SizedBox(
                      width: 60.w,
                      child: Text(
                        team['waiver'].toString(),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white54, fontSize: 12.sp, fontWeight: FontWeight.w500),
                      ),
                    ),
                    SizedBox(
                      width: 50.w,
                      child: Text(
                        team['pf'].toString(),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white54, fontSize: 12.sp, fontWeight: FontWeight.w500),
                      ),
                    ),
                    SizedBox(
                      width: 40.w,
                      child: Text(
                        team['pa'].toString(),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white54, fontSize: 12.sp, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        
        // Bottom Activity Divider and Section
        Container(
          width: double.infinity,
          height: 1.5,
          color: AppColors.accentCyan.withOpacity(0.3),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
          color: AppColors.background,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Activity', style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.bold)),
                  Text('View all', style: TextStyle(color: AppColors.accentCyan, fontSize: 12.sp, fontWeight: FontWeight.bold)),
                ],
              ),
              SizedBox(height: 16.h),
              Text('No Transactions', style: TextStyle(color: Colors.white38, fontSize: 13.sp)),
              SizedBox(height: 16.h), // Extra padding for tabbar
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlayoffsView() {
    String getT(int index, String fallback) {
      if (index < _members.length) {
        return _getDisplayName(_members[index]);
      }
      return fallback;
    }

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Playoff Headers
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRoundHeader("ROUND 1", "Week 15"),
                  SizedBox(width: 48.w),
                  _buildRoundHeader("ROUND 2", "Week 16"),
                  SizedBox(width: 48.w),
                  _buildRoundHeader("FINALS", "Week 17"),
                ],
              ),
              SizedBox(height: 24.h),
              
              // Bracket Tree Layout
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ROUND 1 COLUMN (4 Matches)
                  Column(
                    children: [
                      _buildBracketMatch(getT(0, "Team 1"), "", "", "", isBye: true),
                      SizedBox(height: 32.h),
                      _buildBracketMatch(getT(3, "Team 4"), "0.00", getT(4, "Team 5"), "0.00"),
                      SizedBox(height: 32.h),
                      _buildBracketMatch(getT(1, "Team 2"), "", "", "", isBye: true),
                    ],
                  ),
                  
                  // CONNECTING LINES ROUND 1 -> 2
                  _buildConnectingLinesColumn(isFinal: false),

                  // ROUND 2 COLUMN (2 Matches)
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: 54.h), // Offset to middle of top 2 matches
                      _buildBracketMatch(getT(0, "Team 1"), "0.00", "Winner M2", "0.00"),
                      SizedBox(height: 110.h),
                      _buildBracketMatch(getT(1, "Team 2"), "0.00", "Winner M4", "0.00"),
                    ],
                  ),

                  // CONNECTING LINES ROUND 2 -> FINALS
                  _buildConnectingLinesColumn(isFinal: true),

                  // FINALS COLUMN (1 Match)
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: 190.h), // Offset to middle of Round 2 matches
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.emoji_events, color: const Color(0xFFFFD700), size: 16.w),
                          SizedBox(width: 4.w),
                          Text(
                            "Championship",
                            style: TextStyle(color: Colors.white, fontSize: 12.sp, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      _buildBracketMatch("", "", "", ""), // Empty mock finals
                    ],
                  ),
                ],
              ),
              
              SizedBox(height: 48.h),
              
              // Consolation / Placements (Image 3)
              Row(
                children: [
                  Column(
                    children: [
                      Text("Consolation M1", style: TextStyle(color: Colors.white, fontSize: 12.sp, fontWeight: FontWeight.bold)),
                      SizedBox(height: 8.h),
                      _buildBracketMatch(getT(5, "Team 6"), "0.00", getT(6, "Team 7"), "0.00"),
                    ],
                  ),
                  SizedBox(width: 32.w),
                  Column(
                    children: [
                      Text("Consolation M2", style: TextStyle(color: Colors.white, fontSize: 12.sp, fontWeight: FontWeight.bold)),
                      SizedBox(height: 8.h),
                      _buildBracketMatch(getT(7, "Team 8"), "0.00", getT(8, "Team 9"), "0.00"),
                    ],
                  ),
                ],
              ),
              
              SizedBox(height: 48.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConnectingLinesColumn({required bool isFinal}) {
    // A primitive column representation of bracket trees using Container borders.
    // In a production app, CustomPainter is used for complex dynamic trees.
    return Container(
      width: 48.w,
      padding: EdgeInsets.symmetric(vertical: 40.h),
      child: Column(
        children: [
          // Lines mock space
          SizedBox(height: isFinal ? 120.h : 60.h),
          Container(
            width: double.infinity,
            height: isFinal ? 200.h : 80.h,
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.white.withOpacity(0.2), width: 2),
                right: BorderSide(color: Colors.white.withOpacity(0.2), width: 2),
                bottom: BorderSide(color: Colors.white.withOpacity(0.2), width: 2),
              ),
            ),
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                width: 16.w, 
                height: 2, 
                color: Colors.white.withOpacity(0.2)
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildRoundHeader(String title, String subtitle) {
    return SizedBox(
      width: 120.w, // Match width of bracket boxes
      child: Column(
        children: [
          Text(title, style: TextStyle(color: Colors.white, fontSize: 12.sp, fontWeight: FontWeight.w900)),
          Text("($subtitle)", style: TextStyle(color: Colors.white54, fontSize: 10.sp)),
        ],
      ),
    );
  }

  Widget _buildBracketMatch(String team1, String score1, String team2, String score2, {bool isBye = false}) {
    return Container(
      width: 120.w,
      decoration: BoxDecoration(
        color: AppColors.surface, // Very dark blue/grey
        borderRadius: BorderRadius.circular(12.h),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          // Top Team
          _buildBracketTeamRow(team1, score1),
          Divider(height: 1, color: Colors.white.withOpacity(0.05)),
          // Bottom Team or BYE
          if (isBye)
            Container(
              height: 40.h,
              alignment: Alignment.center,
              child: Text(
                'BYE',
                style: TextStyle(color: Colors.white38, fontSize: 12.sp, fontWeight: FontWeight.w900, letterSpacing: 1.0),
              ),
            )
          else
            _buildBracketTeamRow(team2, score2),
        ],
      ),
    );
  }

  Widget _buildBracketTeamRow(String name, String score) {
    return Container(
      height: 40.h,
      padding: EdgeInsets.symmetric(horizontal: 8.w),
      child: Row(
        children: [
          Container(
            width: 20.w,
            height: 20.w,
            decoration: BoxDecoration(
              color: AppColors.background,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white10),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              name.isEmpty ? " " : name,
              style: TextStyle(color: Colors.white70, fontSize: 11.sp, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (score.isNotEmpty)
            Text(
              score,
              style: TextStyle(color: Colors.white38, fontSize: 9.sp),
            ),
        ],
      ),
    );
  }

  Widget _buildTeamTab() {
    final userId = LeagueService.currentUser?.uid;
    final leagueId = widget.league['id'] as String?;
    if (userId == null || leagueId == null) return _buildPlaceholderTab("PlEASE LOGIN TO VIEW TEAM");

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
      builder: (context, userSnap) {
        final dynamic rawUserData = userSnap.data?.data();
        final Map<String, dynamic> userData = rawUserData is Map ? Map<String, dynamic>.from(rawUserData) : {};
        final username = userData['username']?.toString() ?? 'Manager';
        final teamName = username.toUpperCase();

        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: LeagueService.getRosterStream(leagueId, userId),
          builder: (context, rosterSnap) {
            return StreamBuilder<List<Map<String, dynamic>>>(
              stream: PickService.getUserPicksStream(leagueId, userId),
              builder: (context, picksSnap) {
                if (rosterSnap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.accentCyan));
                }

                final players = rosterSnap.data ?? [];
                final picks = picksSnap.data ?? [];

                // 10 standard starter slots
                final List<String> rosterSlots = [
                  'QB', 'RB', 'RB', 'WR', 'WR', 'WR', 'TE', 'WRT', 'SFLEX', 'K'
                ];
                const int benchSlots = 5;

                // Map players to starter slots
                final List<Map<String, dynamic>?> starterRows = List.filled(rosterSlots.length, null);
                final List<Map<String, dynamic>> unassignedStarters = List.from(players.where((p) {
                   final pos = p['pos']?.toString().toUpperCase() ?? 'BN';
                   return !pos.startsWith('BN') && !pos.startsWith('TAXI') && !pos.startsWith('IR');
                }));

                // Slot-matching logic — supports FLEX (WRT) and SFLEX (anyone)
                for (int i = 0; i < rosterSlots.length; i++) {
                  final slot = rosterSlots[i];
                  for (int j = 0; j < unassignedStarters.length; j++) {
                    final p = unassignedStarters[j];
                    final pPos = p['pos']?.toString().toUpperCase() ?? '';
                    final isFlexEligible = pPos == 'WR' || pPos == 'RB' || pPos == 'TE';
                    final isSuperFlexEligible = isFlexEligible || pPos == 'QB';
                    if (slot == pPos ||
                        (slot == 'WRT' && isFlexEligible) ||
                        (slot == 'SFLEX' && isSuperFlexEligible)) {
                      starterRows[i] = p;
                      unassignedStarters.removeAt(j);
                      break;
                    }
                  }
                }

                // Bench: real players with BN pos + overflow starters
                final List<Map<String, dynamic>> benchPlayers = players.where((p) {
                  final pos = p['pos']?.toString().toUpperCase() ?? 'BN';
                  return pos.startsWith('BN');
                }).toList();
                benchPlayers.addAll(unassignedStarters);

                final picksList = List<Map<String, dynamic>>.from(picks);
                picksList.sort((a, b) {
                  final yearA = a['year'] is num ? (a['year'] as num).toInt() : int.tryParse(a['year']?.toString() ?? '0') ?? 0;
                  final yearB = b['year'] is num ? (b['year'] as num).toInt() : int.tryParse(b['year']?.toString() ?? '0') ?? 0;
                  int yearComp = yearA.compareTo(yearB);
                  if (yearComp != 0) return yearComp;
                  final roundA = a['round'] is num ? (a['round'] as num).toInt() : int.tryParse(a['round']?.toString() ?? '0') ?? 0;
                  final roundB = b['round'] is num ? (b['round'] as num).toInt() : int.tryParse(b['round']?.toString() ?? '0') ?? 0;
                  return roundA.compareTo(roundB);
                });

                return ListView(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  children: [
                    SizedBox(height: 24.h),
                    _buildTeamHeader(teamName, username),
                    // --- 10 Starter Slots ---
                    _buildTeamSectionHeader("Starters"),
                    ...List.generate(rosterSlots.length, (i) {
                      final slot = rosterSlots[i];
                      final player = starterRows[i];
                      return _buildPlayerRow(
                        player ?? {'pos': slot},
                        isPlaceholder: player == null,
                      );
                    }),
                    // --- 5 Bench Slots (always visible) ---
                    _buildTeamSectionHeader("BENCH"),
                    ...List.generate(benchSlots, (i) {
                      final player = i < benchPlayers.length ? benchPlayers[i] : null;
                      return _buildPlayerRow(
                        player ?? {'pos': 'BN'},
                        slot: 'BN',
                        isPlaceholder: player == null,
                      );
                    }),
                    if (picksList.isNotEmpty) ...[
                      _buildTeamSectionHeader("FUTURE DRAFT PICKS"),
                      ...picksList.map((p) => _buildPickRow(p)),
                    ],
                    SizedBox(height: 32.h),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildTeamHeader(String teamName, String username) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
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
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                children: [
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: AppColors.accentCyan.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.shield, color: AppColors.accentCyan, size: 24.w),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: EdgeInsets.all(4.w),
                      decoration: const BoxDecoration(color: AppColors.surface, shape: BoxShape.circle),
                      child: Icon(Icons.settings, color: Colors.white38, size: 10.w),
                    ),
                  ),
                ],
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      teamName.toUpperCase(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Text(
                          "@$username",
                          style: TextStyle(color: Colors.white38, fontSize: 10.sp, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(width: 8.w),
                        Container(width: 4.w, height: 4.w, decoration: const BoxDecoration(color: Colors.white10, shape: BoxShape.circle)),
                        SizedBox(width: 8.w),
                        Text(
                          "0-0",
                          style: TextStyle(color: Colors.white38, fontSize: 10.sp, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          Row(
            children: [
              _buildHeaderAction("Trade", Icons.swap_horiz, onTap: () {
                AppDialogs.showInfoDialog(context, message: "Trading system is coming in the next update.", title: "DEVELOPER NOTICE");
              }),
              Container(width: 1.w, height: 20.h, color: Colors.white10, margin: EdgeInsets.symmetric(horizontal: 1.w)),
              _buildHeaderAction("Trans.", Icons.assignment_outlined, onTap: () {
                AppDialogs.showInfoDialog(context, message: "Transaction history is coming in the next update.", title: "DEVELOPER NOTICE");
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDraftBoardSetup() {
    const Color brandColor = AppColors.accentCyan;
    
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D1426), // Match image's deep navy background
        borderRadius: BorderRadius.circular(16.h),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.grid_view_rounded, color: Colors.blueAccent.withOpacity(0.5), size: 28.w),
              SizedBox(width: 12.w),
              Text(
                "Draftboard",
                style: TextStyle(color: Colors.white, fontSize: 20.sp, fontWeight: FontWeight.w900, letterSpacing: 1.0),
              ),
              const Spacer(),
              Text(
                "Edit",
                style: TextStyle(color: brandColor, fontSize: 14.sp, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            "Draft time has not been set",
            style: TextStyle(color: Colors.white38, fontSize: 13.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 24.h),
          Row(
            children: [
              // MOCK Button
              Expanded(
                flex: 1,
                child: GestureDetector(
                  onTap: () {
                    final settings = widget.league['settings'] as Map<String, dynamic>? ?? {};
                    final roundsCount = settings['draftRounds'] as int? ?? 4;
                    _showMockDraftSelection(context, widget.league['maxMembers'] ?? 10, roundsCount);
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    height: 48.h,
                    decoration: BoxDecoration(
                      color: brandColor,
                      borderRadius: BorderRadius.circular(24.h),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      "MOCK",
                      style: TextStyle(color: const Color(0xFF0D1426), fontSize: 13.sp, fontWeight: FontWeight.w900, letterSpacing: 1.0),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              // SET TIME Button
              Expanded(
                flex: 2,
                child: Container(
                  height: 48.h,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24.h),
                    border: Border.all(color: brandColor, width: 2),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Center(
                          child: Text(
                            "SET TIME",
                            style: TextStyle(color: brandColor, fontSize: 13.sp, fontWeight: FontWeight.w900, letterSpacing: 1.0),
                          ),
                        ),
                      ),
                      Container(
                        width: 48.w,
                        height: 48.h,
                        decoration: BoxDecoration(
                          border: Border(left: BorderSide(color: brandColor, width: 2)),
                        ),
                        child: Icon(Icons.grid_view_rounded, color: brandColor, size: 20.w),
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

  Widget _buildHeaderAction(String label, IconData icon, {VoidCallback? onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 10.h),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(10.h),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.accentCyan, size: 16.w),
              SizedBox(width: 8.w),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeamSectionHeader(String title) {
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
          // Slot Badge
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
          // Avatar
          CircleAvatar(
            radius: 18.w,
            backgroundColor: AppColors.createGradientPurple.withOpacity(0.1),
            backgroundImage: player['photoUrl'] != null ? NetworkImage(player['photoUrl']) : null,
            child: player['photoUrl'] == null 
                ? Icon(Icons.person, color: Colors.white24, size: 20.w) 
                : null,
          ),
          SizedBox(width: 12.w),
          // Name & Details
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
          // Grade
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

  Widget _buildPickRow(Map<String, dynamic> pick) {
    final year = pick['year']?.toString() ?? '2026';
    final round = pick['round']?.toString() ?? '1';
    final ordinal = round == '1' ? 'st' : (round == '2' ? 'nd' : 'rd');

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.h),
        border: Border.all(color: AppColors.accentCyan.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(Icons.airplane_ticket, color: AppColors.accentCyan.withOpacity(0.3), size: 20.w),
          SizedBox(width: 16.w),
          Text(
            '$year $round$ordinal RD'.toUpperCase(),
            style: TextStyle(color: Colors.white, fontSize: 13.sp, fontWeight: FontWeight.w900, letterSpacing: 1.0),
          ),
          const Spacer(),
          Text(
            'DRAFT PICK',
            style: TextStyle(color: Colors.white12, fontSize: 10.sp, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayersTab() {
    // Filter definitions
    final filters = [
      {'label': 'Search',    'icon': Icons.search_rounded},
      {'label': 'Trend',     'icon': Icons.trending_up_rounded},
      {'label': 'Available', 'icon': Icons.person_add_alt_1_outlined},
      {'label': 'Leaders',   'icon': Icons.leaderboard_rounded},
      {'label': 'Trade',     'icon': Icons.swap_horiz_rounded},
    ];

    return Column(
      children: [
        // ── Filter pill bar ──────────────────────────────────────────
        Container(
          margin: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
          padding: EdgeInsets.symmetric(vertical: 6.h, horizontal: 6.w),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16.h),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(filters.length, (i) {
              final isActive = _playerFilter == i;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _playerFilter = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.accentCyan.withOpacity(0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10.h),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          filters[i]['icon'] as IconData,
                          size: 20.w,
                          color: isActive ? AppColors.accentCyan : Colors.white38,
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          filters[i]['label'] as String,
                          style: TextStyle(
                            color: isActive ? AppColors.accentCyan : Colors.white38,
                            fontSize: 9.sp,
                            fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),

        // ── Content area ─────────────────────────────────────────────
        Expanded(
          child: _buildPlayerFilterContent(),
        ),
      ],
    );
  }

  Widget _buildPlayerFilterContent() {
    switch (_playerFilter) {
      case 0: // Search
        return _buildSearchTab();
      case 1: // Trend
        return _buildTrendingTab();
      case 2: // Available
        return _buildAvailableTab();
      case 3: // Leaders
        return _buildLeadersTab();
      case 4: // Trade
        return _buildTradeTab();
      default:
        return const SizedBox.shrink();
    }
  }
  Widget _buildTradeTab() {
    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
      children: [
        // ── Trade Block Section ──
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Trade Block',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16.h),
                border: Border.all(color: AppColors.accentCyan, width: 1.5),
              ),
              child: Row(
                children: [
                  Text(
                    'TRADE',
                    style: TextStyle(
                      color: AppColors.accentCyan,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Icon(Icons.swap_horiz_rounded, color: AppColors.accentCyan, size: 14.w),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 24.h),
        // Trade block placeholder
        Center(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.smart_toy_rounded, color: Colors.white24, size: 40.w),
                  SizedBox(width: 8.w),
                  Icon(Icons.arrow_forward_rounded, color: AppColors.brandBlueLight, size: 24.w),
                  SizedBox(width: 8.w),
                  Icon(Icons.arrow_back_rounded, color: AppColors.brandBlueLight, size: 24.w),
                  SizedBox(width: 8.w),
                  Icon(Icons.smart_toy_outlined, color: Colors.white12, size: 40.w),
                ],
              ),
              SizedBox(height: 16.h),
              Text(
                'No players on the block yet...',
                style: TextStyle(color: Colors.white54, fontSize: 13.sp),
              ),
            ],
          ),
        ),
        SizedBox(height: 48.h),

        // ── Active Trades Section ──
        Text(
          'Active Trades',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 32.h),
        // Active trades placeholder
        Center(
          child: Column(
            children: [
              SizedBox(
                height: 100.h,
                width: 140.w,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Back card
                    Positioned(
                      left: 10.w,
                      top: 0,
                      child: Transform.rotate(
                        angle: -0.1,
                        child: Container(
                          width: 60.w,
                          height: 80.h,
                          decoration: BoxDecoration(
                            color: AppColors.brandBlueLight.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(8.h),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Center(child: Icon(Icons.person, color: Colors.white24, size: 30.w)),
                        ),
                      ),
                    ),
                    // Front card
                    Positioned(
                      right: 10.w,
                      bottom: 0,
                      child: Transform.rotate(
                        angle: 0.1,
                        child: Container(
                          width: 60.w,
                          height: 80.h,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: const [AppColors.brandBlueLight, AppColors.brandDark],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(8.h),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Center(child: Icon(Icons.person_outline, color: Colors.white54, size: 30.w)),
                        ),
                      ),
                    ),
                    // Wrapping arrows mapped using existing icons
                    Positioned(
                      left: 0,
                      bottom: 10.h,
                      child: Transform.rotate(
                        angle: -0.5,
                        child: Icon(Icons.subdirectory_arrow_right_rounded, color: AppColors.accentCyan.withOpacity(0.8), size: 30.w),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      top: 10.h,
                      child: Transform.rotate(
                        angle: 2.6,
                        child: Icon(Icons.subdirectory_arrow_right_rounded, color: AppColors.accentTeal.withOpacity(0.8), size: 30.w),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24.h),
              Text(
                'No active trades...',
                style: TextStyle(color: Colors.white54, fontSize: 13.sp, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8.h),
              Text(
                'PROPOSE A TRADE',
                style: TextStyle(
                  color: AppColors.accentCyan,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 48.h),

        // ── Trade History Section ──
        Text(
          'Trade History',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 24.h),
        // Trade history placeholder
        Center(
          child: Column(
            children: [
              Container(
                width: 80.w,
                height: 50.h,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.brandBlueLight.withOpacity(0.5), AppColors.background],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(8.h), topRight: Radius.circular(8.h)),
                  border: Border.all(color: Colors.white10),
                ),
                alignment: Alignment.topCenter,
                padding: EdgeInsets.only(top: 8.h),
                child: Icon(Icons.history_rounded, color: Colors.white24, size: 24.w),
              ),
            ],
          ),
        ),
        SizedBox(height: 100.h), // Extra padding for bottom navigation visibility
      ],
    );
  }

  Widget _buildTrendingTab() {
    final positions = ['ALL', 'QB', 'RB', 'WR', 'TE', 'K', 'DEF'];

    return Column(
      children: [
        // Title and toggle row
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
          child: Row(
            children: [
              Text(
                'Trending',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(width: 12.w),
              // Custom up/down toggle
              GestureDetector(
                onTap: () => setState(() => _trendingUp = !_trendingUp),
                child: Container(
                  width: 54.w,
                  height: 28.h,
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: AppColors.accentCyan.withOpacity(0.2), // Darker cyan background
                    borderRadius: BorderRadius.circular(14.h),
                    border: Border.all(color: AppColors.accentCyan, width: 1.5), // Vibrant cyan border
                  ),
                  child: Stack(
                    children: [
                      // Inactive icons behind the sliding circle
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: EdgeInsets.only(left: 4.w),
                          child: Icon(Icons.trending_up_rounded, color: Colors.white, size: 14.w),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: EdgeInsets.only(right: 4.w),
                          child: Icon(Icons.trending_down_rounded, color: Colors.white, size: 14.w),
                        ),
                      ),
                      // Animated sliding circle with active icon
                      AnimatedAlign(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutBack,
                        alignment: _trendingUp ? Alignment.centerLeft : Alignment.centerRight,
                        child: Container(
                          width: 24.w,
                          height: 24.w, // Match height to make perfect circle inside container
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            _trendingUp ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                            color: Colors.black, // Dark icon on white circle
                            size: 16.w,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Position Filter Pills
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
          child: Row(
            children: positions.map((pos) {
              final isSelected = _trendingPos == pos;
              return GestureDetector(
                onTap: () => setState(() => _trendingPos = pos),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: EdgeInsets.only(right: 8.w),
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.accentCyan.withOpacity(0.15) : AppColors.surface,
                    borderRadius: BorderRadius.circular(20.h), // Fully rounded like the design
                    border: Border.all(
                      color: isSelected ? AppColors.accentCyan : Colors.white.withOpacity(0.05),
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    pos,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white38, // White text when selected
                      fontSize: 12.sp,
                      fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold, // Bolder when selected
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        // Content placeholder below the filters
        Expanded(
          child: _isLoadingPlayers 
          ? const Center(child: CircularProgressIndicator(color: AppColors.accentCyan))
          : Builder(
              builder: (context) {
                var filtered = _allPlayers.toList();
                if (_trendingPos != 'ALL') {
                  filtered = filtered.where((p) => p['pos'] == _trendingPos).toList();
                }
                
                // Sort by trend score
                filtered.sort((a, b) {
                  final tA = a['trend'] as int? ?? 0;
                  final tB = b['trend'] as int? ?? 0;
                  return _trendingUp ? tB.compareTo(tA) : tA.compareTo(tB);
                });
                
                // Keep only top 200
                final displayList = filtered.take(200).toList();

                if (displayList.isEmpty) {
                  return Center(
                    child: Text('No $_trendingPos players trending.', style: TextStyle(color: Colors.white54, fontSize: 13.sp)),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
                  itemCount: displayList.length,
                  itemBuilder: (context, index) {
                    final player = displayList[index];
                    return _buildPlayerListCard(player, trailing: Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: _trendingUp ? AppColors.accentTeal.withOpacity(0.2) : AppColors.error.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _trendingUp ? Icons.trending_up_rounded : Icons.trending_down_rounded, 
                        color: _trendingUp ? AppColors.accentTeal : AppColors.error, 
                        size: 20.w
                      ),
                    ));
                  },
                );
              },
            ),
        ),
      ],
    );
  }

  Widget _buildPlayerListCard(Map<String, dynamic> player, {Widget? trailing}) {
    final String name = player['name'] ?? 'Unknown Player';
    final String team = player['team'] ?? 'FA';
    final String pos = player['pos'] ?? 'UNK';
    final String age = player['age']?.toString() ?? '--';
    final String imageUrl = player['imageUrl'] ?? '';
    final String sps = player['sps']?.toString() ?? '0.0';
    final String exp = player['exp']?.toString() ?? '0';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PlayerProfileScreen(
              name: name,
              pos: pos,
              team: team,
              sps: sps,
              exp: exp,
              player: player,
              leagueId: widget.league['id']?.toString(),
              userId: LeagueService.currentUser?.uid,
            ),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 8.h),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.h),
        border: Border.all(color: Colors.white.withOpacity(0.05), width: 1.5),
      ),
      child: Row(
        children: [
          // Player Image
          Container(
            width: 48.w,
            height: 48.w,
            decoration: BoxDecoration(
              color: AppColors.brandDark,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white10),
            ),
            clipBehavior: Clip.antiAlias,
            child: imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Icon(Icons.person, color: Colors.white38, size: 24.w),
                  )
                : Icon(Icons.person, color: Colors.white38, size: 24.w),
          ),
          SizedBox(width: 12.w),
          // Player Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Text(
                      '$pos - $team',
                      style: TextStyle(
                        color: _getPositionColor(pos),
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'AGE $age',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Right side: Trailing content (Trend/Add icon) + Selection Checkbox
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (trailing != null) trailing else Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'SPS',
                    style: TextStyle(color: Colors.white38, fontSize: 9.sp, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
                  Text(
                    sps,
                    style: TextStyle(color: AppColors.accentCyan, fontSize: 16.sp, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
              SizedBox(width: 16.w),
              // Custom Animated Checkbox
              GestureDetector(
                onTap: () {
                  setState(() {
                    final id = player['player_id']?.toString() ?? player['id']?.toString() ?? '';
                    if (id.isNotEmpty) {
                      if (_selectedPlayerIds.contains(id)) {
                        _selectedPlayerIds.remove(id);
                      } else {
                        _selectedPlayerIds.add(id);
                      }
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 24.w,
                  height: 24.w,
                  decoration: BoxDecoration(
                    color: _selectedPlayerIds.contains(player['player_id']?.toString() ?? player['id']?.toString()) 
                        ? AppColors.accentCyan 
                        : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(6.h),
                    border: Border.all(
                      color: _selectedPlayerIds.contains(player['player_id']?.toString() ?? player['id']?.toString())
                          ? AppColors.accentCyan
                          : Colors.white24,
                      width: 1.5,
                    ),
                  ),
                  child: _selectedPlayerIds.contains(player['player_id']?.toString() ?? player['id']?.toString())
                      ? Icon(Icons.check_rounded, color: Colors.black, size: 16.w)
                      : null,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

  Widget _buildAvailableTab() {
    final positions = ['ALL', 'QB', 'RB', 'WR', 'TE', 'K', 'DEF'];

    return Column(
      children: [
        // Title, toggle, and dropdown row
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
          child: Row(
            children: [
              Text(
                'Available',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(width: 12.w),
              // Custom list/grid toggle
              GestureDetector(
                onTap: () => setState(() => _availableIsListView = !_availableIsListView),
                child: Container(
                  width: 54.w,
                  height: 28.h,
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: AppColors.accentCyan.withOpacity(0.2), // Darker cyan background
                    borderRadius: BorderRadius.circular(14.h),
                    border: Border.all(color: AppColors.accentCyan, width: 1.5), // Vibrant cyan border
                  ),
                  child: Stack(
                    children: [
                      // Inactive icons behind the sliding circle
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: EdgeInsets.only(left: 4.w),
                          child: Icon(Icons.format_list_bulleted_rounded, color: Colors.white, size: 14.w),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: EdgeInsets.only(right: 4.w),
                          child: Icon(Icons.grid_view_rounded, color: Colors.white, size: 14.w),
                        ),
                      ),
                      // Animated sliding circle with active icon
                      AnimatedAlign(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutBack,
                        alignment: _availableIsListView ? Alignment.centerLeft : Alignment.centerRight,
                        child: Container(
                          width: 24.w,
                          height: 24.w,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            _availableIsListView ? Icons.format_list_bulleted_rounded : Icons.grid_view_rounded,
                            color: Colors.black, // Dark icon on white circle
                            size: 14.w,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              // Season ADP text dropdown
              Row(
                children: [
                  Text(
                    'SEASON ADP',
                    style: TextStyle(
                      color: AppColors.accentCyan,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.accentCyan, size: 16.w),
                ],
              ),
            ],
          ),
        ),

        // Filter Pills Row
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
          child: Row(
            children: [
              // Filter tune icon
              Container(
                margin: EdgeInsets.only(right: 8.w),
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20.h),
                  border: Border.all(color: Colors.white.withOpacity(0.05), width: 1.5),
                ),
                child: Icon(Icons.tune_rounded, color: Colors.white38, size: 16.w),
              ),
              // FA Pill
              Container(
                margin: EdgeInsets.only(right: 8.w),
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20.h),
                  border: Border.all(color: Colors.white.withOpacity(0.05), width: 1.5),
                ),
                child: Text(
                  'FA',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              // Vertical divider
              Container(
                margin: EdgeInsets.only(right: 8.w),
                height: 24.h,
                width: 1.w,
                color: Colors.white12,
              ),
              // Star Icon Pill
              Container(
                margin: EdgeInsets.only(right: 8.w),
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20.h),
                  border: Border.all(color: Colors.white.withOpacity(0.05), width: 1.5),
                ),
                child: Icon(Icons.star_border_rounded, color: Colors.white38, size: 18.w),
              ),
              // Position Pills
              ...positions.map((pos) {
                final isSelected = _availablePos == pos;
                return GestureDetector(
                  onTap: () => setState(() => _availablePos = pos),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: EdgeInsets.only(right: 8.w),
                    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.accentCyan.withOpacity(0.15) : AppColors.surface,
                      borderRadius: BorderRadius.circular(20.h),
                      border: Border.all(
                        color: isSelected ? AppColors.accentCyan : Colors.white.withOpacity(0.05),
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      pos,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white38,
                        fontSize: 12.sp,
                        fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        ),

        // Content placeholder depending on view mode
        Expanded(
          child: _isLoadingPlayers 
          ? const Center(child: CircularProgressIndicator(color: AppColors.accentCyan))
          : Builder(
              builder: (context) {
                var filtered = _allPlayers.toList();
                if (_availablePos != 'ALL') {
                  filtered = filtered.where((p) => p['pos'] == _availablePos).toList();
                }

                // Sort by SPS (Best available first)
                filtered.sort((a, b) {
                  final sA = double.tryParse(a['sps']?.toString() ?? '0') ?? 0.0;
                  final sB = double.tryParse(b['sps']?.toString() ?? '0') ?? 0.0;
                  return sB.compareTo(sA);
                });
                
                // Keep only top 200
                final displayList = filtered.take(200).toList();

                if (displayList.isEmpty) {
                  return Center(
                    child: Text('No $_availablePos players available.', style: TextStyle(color: Colors.white54, fontSize: 13.sp)),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
                  itemCount: displayList.length,
                  itemBuilder: (context, index) {
                    final player = displayList[index];
                    return _buildPlayerListCard(player, trailing: Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: AppColors.accentCyan.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.add_rounded, color: AppColors.accentCyan, size: 20.w),
                    ));
                  },
                );
              },
            ),
        ),
      ],
    );
  }

  Widget _buildLeadersTab() {
    final positions = ['ALL', 'QB', 'RB', 'WR', 'TE', 'K', 'DEF'];

    return Column(
      children: [
        // Title, toggle, and dropdown row
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
          child: Row(
            children: [
              Text(
                'Leaders',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(width: 12.w),
              // Custom list/grid toggle
              GestureDetector(
                onTap: () => setState(() => _leadersIsListView = !_leadersIsListView),
                child: Container(
                  width: 54.w,
                  height: 28.h,
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: AppColors.accentCyan.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(14.h),
                    border: Border.all(color: AppColors.accentCyan, width: 1.5),
                  ),
                  child: Stack(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: EdgeInsets.only(left: 4.w),
                          child: Icon(Icons.format_list_bulleted_rounded, color: Colors.white, size: 14.w),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: EdgeInsets.only(right: 4.w),
                          child: Icon(Icons.grid_view_rounded, color: Colors.white, size: 14.w),
                        ),
                      ),
                      AnimatedAlign(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutBack,
                        alignment: _leadersIsListView ? Alignment.centerLeft : Alignment.centerRight,
                        child: Container(
                          width: 24.w,
                          height: 24.w,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            _leadersIsListView ? Icons.format_list_bulleted_rounded : Icons.grid_view_rounded,
                            color: Colors.black,
                            size: 14.w,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              // Season ADP text dropdown
              Row(
                children: [
                  Text(
                    'SEASON ADP',
                    style: TextStyle(
                      color: AppColors.accentCyan,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.accentCyan, size: 16.w),
                ],
              ),
            ],
          ),
        ),

        // Filter Pills Row
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
          child: Row(
            children: [
              // Filter tune icon
              Container(
                margin: EdgeInsets.only(right: 8.w),
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20.h),
                  border: Border.all(color: Colors.white.withOpacity(0.05), width: 1.5),
                ),
                child: Icon(Icons.tune_rounded, color: Colors.white38, size: 16.w),
              ),
              // Vertical divider
              Container(
                margin: EdgeInsets.only(right: 8.w),
                height: 24.h,
                width: 1.w,
                color: Colors.white12,
              ),
              // Star Icon Pill
              Container(
                margin: EdgeInsets.only(right: 8.w),
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20.h),
                  border: Border.all(color: Colors.white.withOpacity(0.05), width: 1.5),
                ),
                child: Icon(Icons.star_border_rounded, color: Colors.white38, size: 18.w),
              ),
              // Position Pills
              ...positions.map((pos) {
                final isSelected = _leadersPos == pos;
                return GestureDetector(
                  onTap: () => setState(() => _leadersPos = pos),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: EdgeInsets.only(right: 8.w),
                    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.accentCyan.withOpacity(0.15) : AppColors.surface,
                      borderRadius: BorderRadius.circular(20.h),
                      border: Border.all(
                        color: isSelected ? AppColors.accentCyan : Colors.white.withOpacity(0.05),
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      pos,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white38,
                        fontSize: 12.sp,
                        fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        ),

        // Content placeholder depending on view mode
        Expanded(
          child: _isLoadingPlayers 
          ? const Center(child: CircularProgressIndicator(color: AppColors.accentCyan))
          : Builder(
              builder: (context) {
                var filtered = _allPlayers.toList();
                if (_leadersPos != 'ALL') {
                  filtered = filtered.where((p) => p['pos'] == _leadersPos).toList();
                }

                // Sort by SPS (Leaders/Top scorers)
                filtered.sort((a, b) {
                  final sA = double.tryParse(a['sps']?.toString() ?? '0') ?? 0.0;
                  final sB = double.tryParse(b['sps']?.toString() ?? '0') ?? 0.0;
                  return sB.compareTo(sA);
                });
                
                // Sort by SPS or something logic for "Leaders"
                filtered.sort((a, b) => (double.tryParse(b['sps']?.toString() ?? '0') ?? 0).compareTo((double.tryParse(a['sps']?.toString() ?? '0') ?? 0)));

                // Keep only top 200
                final displayList = filtered.take(200).toList();

                if (displayList.isEmpty) {
                  return Center(
                    child: Text('No $_leadersPos leaders found.', style: TextStyle(color: Colors.white54, fontSize: 13.sp)),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
                  itemCount: displayList.length,
                  itemBuilder: (context, index) {
                    final player = displayList[index];
                    return _buildPlayerListCard(player, trailing: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16.h),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Text('#${index + 1}', style: TextStyle(color: AppColors.accentCyan, fontSize: 12.sp, fontWeight: FontWeight.w900)),
                    ));
                  },
                );
              },
            ),
        ),
      ],
    );
  }

  Widget _buildSearchTab() {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16.h),
              border: Border.all(color: Colors.white10),
            ),
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: Colors.white, fontSize: 14.sp),
              decoration: InputDecoration(
                hintText: 'Search for a player...',
                hintStyle: TextStyle(color: Colors.white38, fontSize: 14.sp),
                prefixIcon: Icon(Icons.search_rounded, color: Colors.white38, size: 20.w),
                suffixIcon: _searchController.text.isNotEmpty ? IconButton(
                  icon: Icon(Icons.clear_rounded, color: Colors.white38, size: 18.w),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                ) : null,
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 14.h),
              ),
              onChanged: (val) => setState(() {}),
            ),
          ),
        ),
        Expanded(
          child: _isLoadingPlayers 
          ? const Center(child: CircularProgressIndicator(color: AppColors.accentCyan))
          : Builder(
              builder: (context) {
                final query = _searchController.text.trim().toLowerCase();
                
                var filtered = _allPlayers.toList();
                if (query.isNotEmpty) {
                  filtered = filtered.where((p) {
                    final name = (p['name'] ?? '').toString().toLowerCase();
                    return name.contains(query);
                  }).toList();
                }

                final displayList = filtered.take(100).toList();

                if (displayList.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off_rounded, color: Colors.white12, size: 52.w),
                        SizedBox(height: 12.h),
                        Text('No results found.', style: TextStyle(color: Colors.white24, fontSize: 13.sp, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  );
                }

                if (query.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_rounded, color: Colors.white12, size: 52.w),
                        SizedBox(height: 12.h),
                        Text('Search Players', style: TextStyle(color: Colors.white24, fontSize: 13.sp, fontWeight: FontWeight.bold)),
                        SizedBox(height: 6.h),
                        Text('Type above to find players.', style: TextStyle(color: Colors.white12, fontSize: 11.sp)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
                  itemCount: displayList.length,
                  itemBuilder: (context, index) {
                    final player = displayList[index];
                    return _buildPlayerListCard(player);
                  },
                );
              },
            ),
        ),
      ],
    );
  }

  Widget _buildPlaceholderTab(String text) {
    return Center(
      child: Text(
        text,
        style: TextStyle(color: Colors.white12, fontSize: 16.sp, fontWeight: FontWeight.bold),
      ),
    );
  }

  String _getDisplayName(Map<String, dynamic> member) {
    final bool isMe = member['uid'] == LeagueService.currentUser?.uid;
    final bool isYouth = member['ageRange'] == 'under-18';
    
    // Privacy: If user is under 18 and not the current viewing user, hide their real name/email
    if (isYouth && !isMe) {
      return (member['username'] as String? ?? "GUEST MANAGER").toUpperCase();
    }
    
    return member['username'] ?? member['fullName'] ?? member['email'] ?? 'Unknown Manager';
  }

  Widget _buildStatCol(IconData icon, String value, String label, {Color color = Colors.white}) {
    return Column(
      children: [
        Icon(icon, color: Colors.white38, size: 20.w),
        SizedBox(height: 8.h),
        Text(value, style: TextStyle(color: color, fontSize: 14.sp, fontWeight: FontWeight.bold)),
        SizedBox(height: 4.h),
        Text(label, style: TextStyle(color: Colors.white38, fontSize: 10.sp)),
      ],
    );
  }
  dynamic _getScoringValue(String category, String rule, dynamic defaultValue) {
    if (widget.league['scoringSettings'] == null) return defaultValue;
    final scoring = widget.league['scoringSettings'] as Map<String, dynamic>;
    return scoring[category]?[rule] ?? defaultValue;
  }

  void _showMockDraftSelection(BuildContext context, int initialTeamsCount, int initialRoundsCount) {
    int teamsCount = initialTeamsCount;
    int roundsCount = initialRoundsCount;
    int selectedSlot = 1;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "MockDrafts",
      barrierColor: Colors.black87,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.85,
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: Column(
                    children: [
                      // Gradient Header
                      Container(
                        height: 240.h,
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFF3F51B5), // Indigo
                              Color(0xFF1A237E), // Deep Indigo
                              Color(0xFF0A0F14), // Back to Black
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              top: 20.h,
                              left: 20.w,
                              child: GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Icon(Icons.close, color: Colors.white, size: 28.w),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.fromLTRB(30.w, 60.h, 30.w, 0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Mock Drafts",
                                    style: TextStyle(color: Colors.white, fontSize: 32.sp, fontWeight: FontWeight.w900, letterSpacing: 1.0),
                                  ),
                                  SizedBox(height: 12.h),
                                  SizedBox(
                                    width: 220.w,
                                    child: Text(
                                      "Practice your strategy with elite AI competition.",
                                      style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 16.sp, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Positioned(
                              right: 0,
                              top: 40.h,
                              child: Opacity(
                                opacity: 0.8,
                                child: Icon(
                                  Icons.smart_toy_rounded, 
                                  color: Colors.white.withOpacity(0.1), 
                                  size: 200.w,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      Expanded(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.symmetric(horizontal: 30.w),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 32.h),

                              // LEAGUE INFO (Non-editable)
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildInfoItem("TEAMS", teamsCount.toString(), Icons.group_outlined),
                                  ),
                                  Expanded(
                                    child: _buildInfoItem("ROUNDS", roundsCount.toString(), Icons.format_list_numbered_outlined),
                                  ),
                                ],
                              ),

                              SizedBox(height: 48.h),

                              // YOUR DRAFT SLOT
                              Text("YOUR DRAFT SLOT", style: TextStyle(color: Colors.white38, fontSize: 10.sp, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                              SizedBox(height: 16.h),
                              Container(
                                height: 50.h,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: teamsCount,
                                  itemBuilder: (context, index) {
                                    final slot = index + 1;
                                    final isSelected = selectedSlot == slot;
                                    return GestureDetector(
                                      onTap: () => setDialogState(() => selectedSlot = slot),
                                      child: Container(
                                        width: 50.h,
                                        margin: EdgeInsets.only(right: 10.w),
                                        decoration: BoxDecoration(
                                          color: isSelected ? AppColors.accentCyan.withOpacity(0.1) : Colors.white.withOpacity(0.03),
                                          shape: BoxShape.circle,
                                          border: Border.all(color: isSelected ? AppColors.accentCyan : Colors.white10),
                                        ),
                                        child: Center(
                                          child: Text(slot.toString(), style: TextStyle(color: isSelected ? AppColors.accentCyan : Colors.white38, fontWeight: FontWeight.bold)),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              
                              SizedBox(height: 40.h),

                              // RECENT DRAFTS
                              Text("RECENT DRAFTS", style: TextStyle(color: Colors.white38, fontSize: 10.sp, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                              SizedBox(height: 16.h),
                              StreamBuilder<QuerySnapshot>(
                                stream: MockDraftService.getRecentMockDrafts(widget.league['id'] ?? widget.league['league_id'] ?? ''),
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                                    return Container(
                                      padding: EdgeInsets.symmetric(vertical: 20.h),
                                      alignment: Alignment.center,
                                      child: Text("No recent drafts yet", style: TextStyle(color: Colors.white24, fontSize: 12.sp)),
                                    );
                                  }

                                  return Column(
                                    children: snapshot.data!.docs.map((doc) {
                                      final data = doc.data() as Map<String, dynamic>;
                                      final timestamp = (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
                                      final topPicks = (data['topPicks'] as List? ?? []);
                                      
                                      return Container(
                                        margin: EdgeInsets.only(bottom: 12.h),
                                        padding: EdgeInsets.all(16.w),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.03),
                                          borderRadius: BorderRadius.circular(16.r),
                                          border: Border.all(color: Colors.white.withOpacity(0.05)),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  DateFormat('MMM dd, yyyy').format(timestamp),
                                                  style: TextStyle(color: Colors.white70, fontSize: 12.sp, fontWeight: FontWeight.bold),
                                                ),
                                                Text(
                                                  "${data['teamsCount']} Teams • ${data['roundsCount']} Rounds",
                                                  style: TextStyle(color: Colors.white38, fontSize: 10.sp),
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: 12.h),
                                            Row(
                                              children: topPicks.map((pick) => Container(
                                                margin: EdgeInsets.only(right: 8.w),
                                                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                                                decoration: BoxDecoration(
                                                  color: AppColors.accentCyan.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(8.r),
                                                ),
                                                child: Text(
                                                  pick['playerName'].split(' ').last,
                                                  style: TextStyle(color: AppColors.accentCyan, fontSize: 9.sp, fontWeight: FontWeight.bold),
                                                ),
                                              )).toList(),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Start Button
                      Padding(
                        padding: EdgeInsets.all(30.w),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MockDraftScreen(
                                  leagueId: widget.league['id'] ?? widget.league['league_id'] ?? '',
                                  userSlot: selectedSlot,
                                  teamsCount: teamsCount,
                                  roundsCount: roundsCount,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 18.h),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF00E5FF), Color(0xFF00B8D4)],
                              ),
                              borderRadius: BorderRadius.circular(30.h),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.accentCyan.withOpacity(0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.sports_football, color: Colors.black87, size: 24.w),
                                SizedBox(width: 12.w),
                                Text(
                                  "START MOCK DRAFT",
                                  style: TextStyle(
                                    color: Colors.black87, 
                                    fontSize: 16.sp, 
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: MediaQuery.of(context).padding.bottom),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(anim1),
          child: child,
        );
      },
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.white38, fontSize: 10.sp, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        SizedBox(height: 8.h),
        Row(
          children: [
            Icon(icon, color: AppColors.accentCyan, size: 20.w),
            SizedBox(width: 8.w),
            Text(value, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18.sp)),
          ],
        ),
      ],
    );
  }
}
