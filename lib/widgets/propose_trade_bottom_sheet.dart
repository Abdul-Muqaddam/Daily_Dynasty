import 'package:flutter/material.dart';
import '../core/colors.dart';
import '../core/responsive_helper.dart';
import '../services/league_service.dart';
import '../services/trade_service.dart';
import '../services/user_service.dart';
import '../services/pick_service.dart';
import '../widgets/app_dialogs.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProposeTradeBottomSheet extends StatefulWidget {
  const ProposeTradeBottomSheet({super.key});

  @override
  State<ProposeTradeBottomSheet> createState() => _ProposeTradeBottomSheetState();
}

class _ProposeTradeBottomSheetState extends State<ProposeTradeBottomSheet> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  // Selection state
  Map<String, dynamic>? _selectedLeague;
  Map<String, dynamic>? _selectedManager;
  final List<String> _myOfferedPlayers = [];
  final List<String> _theirRequestedPlayers = [];
  final List<Map<String, dynamic>> _myOfferedPlayersFull = [];
  final List<Map<String, dynamic>> _theirRequestedPlayersFull = [];
  
  // Pick Selection state
  final List<Map<String, dynamic>> _myOfferedPicks = [];
  final List<Map<String, dynamic>> _theirRequestedPicks = [];

  // Data
  List<Map<String, dynamic>> _myLeagues = [];
  List<Map<String, dynamic>> _leagueMembers = [];
  List<Map<String, dynamic>> _myRoster = [];
  List<Map<String, dynamic>> _theirRoster = [];
  List<Map<String, dynamic>> _myPicks = [];
  List<Map<String, dynamic>> _theirPicks = [];

  String _myTeamName = "GRIDIRON KINGS";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final leagues = await LeagueService.getUserLeagues();
      final profile = await UserService.getCurrentUserProfile();
      setState(() {
        _myLeagues = leagues;
        _myTeamName = profile?['teamName'] ?? "MY TEAM";
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        AppDialogs.showPremiumErrorDialog(context, message: "Error loading data: $e");
      }
    }
  }

  Future<void> _loadMembers(String leagueId) async {
    setState(() => _isLoading = true);
    try {
      final membersList = (List<String>.from(_selectedLeague!['members'] ?? []));
      final myUid = FirebaseAuth.instance.currentUser?.uid;
      membersList.remove(myUid);
      
      final memberProfiles = await LeagueService.getLeagueMembers(membersList);
      setState(() {
        _leagueMembers = memberProfiles;
        _isLoading = false;
      });
      
      if (myUid != null) {
        final roster = await LeagueService.getUserRoster(leagueId, myUid);
        final picks = await PickService.getUserPicks(leagueId, myUid);
        setState(() {
          _myRoster = roster;
          _myPicks = picks;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadTheirAssets() async {
    if (_selectedLeague == null || _selectedManager == null) return;
    setState(() => _isLoading = true);
    try {
      final roster = await LeagueService.getUserRoster(_selectedLeague!['id'], _selectedManager!['uid']);
      final picks = await PickService.getUserPicks(_selectedLeague!['id'], _selectedManager!['uid']);
      setState(() {
        _theirRoster = roster;
        _theirPicks = picks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _nextPage() {
    if (_currentStep == 0 && _selectedManager != null) {
      _loadTheirAssets();
    }
    
    if (_currentStep < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep++);
    }
  }

  void _previousPage() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep--);
    }
  }

  Future<void> _submitTrade() async {
    if (_selectedLeague == null || _selectedManager == null) return;
    
    setState(() => _isLoading = true);
    try {
      await TradeService.proposeTrade(
        leagueId: _selectedLeague!['id'],
        toUid: _selectedManager!['uid'],
        fromTeamName: _myTeamName,
        toTeamName: _selectedManager!['username'] ?? "Opponent",
        offering: _myOfferedPlayers,
        requesting: _theirRequestedPlayers,
        offeringFull: _myOfferedPlayersFull,
        requestingFull: _theirRequestedPlayersFull,
        offeringPicks: _myOfferedPicks,
        requestingPicks: _theirRequestedPicks,
      );
      if (mounted) {
        Navigator.pop(context, true);
        AppDialogs.showSuccessDialog(
          context,
          title: "PROPOSAL SENT",
          message: "Your trade proposal was sent successfully!",
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppDialogs.showPremiumErrorDialog(context, message: "Failed to send trade: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveHelper.init(context);
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          _buildHandle(),
          _buildHeader(),
          _buildProgressBar(),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: AppColors.accentCyan))
              : PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildStep1(), // League & Manager
                    _buildStep2(), // My Players & Picks
                    _buildStep3(), // Their Players & Picks
                    _buildStep4(), // Review
                  ],
                ),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 12.h),
      width: 40.w,
      height: 4.h,
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader() {
    String title = "PROPOSE TRADE";
    if (_currentStep == 1) title = "WHAT ARE YOU OFFERING?";
    if (_currentStep == 2) title = "WHAT DO YOU WANT?";
    if (_currentStep == 3) title = "REVIEW PROPOSAL";

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.w900, letterSpacing: 1.2),
          ),
          GestureDetector(onTap: () => Navigator.pop(context), child: const Icon(Icons.close, color: Colors.white54)),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
      height: 4.h,
      decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(2)),
      child: Row(
        children: List.generate(4, (index) {
          return Expanded(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 2.w),
              decoration: BoxDecoration(
                color: index <= _currentStep ? AppColors.accentCyan : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStep1() {
    if (_myLeagues.isEmpty) {
      return Center(child: Text("Join a league first to trade!", style: TextStyle(color: Colors.white54, fontSize: 14.sp)));
    }
    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      children: [
        Text("SELECT LEAGUE", style: _labelStyle),
        SizedBox(height: 12.h),
        ..._myLeagues.map((l) => _buildSelectionCard(
          title: l['name'] ?? 'League',
          isSelected: _selectedLeague?['id'] == l['id'],
          onTap: () {
            setState(() { _selectedLeague = l; _selectedManager = null; });
            _loadMembers(l['id']);
          },
        )),
        if (_selectedLeague != null) ...[
          SizedBox(height: 24.h),
          Text("SELECT MANAGER", style: _labelStyle),
          SizedBox(height: 12.h),
          ..._leagueMembers.map((m) => _buildSelectionCard(
            title: m['username'] ?? 'Manager',
            isSelected: _selectedManager?['uid'] == m['uid'],
            onTap: () => setState(() => _selectedManager = m),
          )),
        ],
      ],
    );
  }

  Widget _buildStep2() {
    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      children: [
        Text("YOUR PLAYERS", style: _labelStyle),
        SizedBox(height: 12.h),
        ..._myRoster.map((player) {
          final name = player['name'] ?? "UNKNOWN";
          return _buildPlayerSelectionCard(
            player: name,
            isSelected: _myOfferedPlayers.contains(name),
            onTap: () {
              setState(() {
                if (_myOfferedPlayers.contains(name)) {
                   _myOfferedPlayers.remove(name);
                   _myOfferedPlayersFull.removeWhere((p) => p['id'] == player['id']);
                } else {
                   _myOfferedPlayers.add(name);
                   _myOfferedPlayersFull.add(player);
                }
              });
            },
            color: AppColors.accentCyan,
          );
        }),
        SizedBox(height: 24.h),
        Text("YOUR DRAFT PICKS", style: _labelStyle),
        SizedBox(height: 12.h),
        if (_myPicks.isEmpty) Text("No draft picks owned.", style: TextStyle(color: Colors.white24, fontSize: 11.sp))
        else ..._myPicks.map((pick) => _buildPickSelectionCard(
          pick: pick,
          isSelected: _myOfferedPicks.any((p) => p['id'] == pick['id']),
          onTap: () {
            setState(() {
              _myOfferedPicks.any((p) => p['id'] == pick['id']) 
                ? _myOfferedPicks.removeWhere((p) => p['id'] == pick['id']) 
                : _myOfferedPicks.add(pick);
            });
          },
          color: AppColors.accentCyan,
        )),
        SizedBox(height: 40.h),
      ],
    );
  }

  Widget _buildStep3() {
    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      children: [
        Text("${(_selectedManager?['username'] ?? 'THEIR').toUpperCase()}'S PLAYERS", style: _labelStyle),
        SizedBox(height: 12.h),
        ..._theirRoster.map((player) {
          final name = player['name'] ?? "UNKNOWN";
          return _buildPlayerSelectionCard(
            player: name,
            isSelected: _theirRequestedPlayers.contains(name),
            onTap: () {
              setState(() {
                if (_theirRequestedPlayers.contains(name)) {
                   _theirRequestedPlayers.remove(name);
                   _theirRequestedPlayersFull.removeWhere((p) => p['id'] == player['id']);
                } else {
                   _theirRequestedPlayers.add(name);
                   _theirRequestedPlayersFull.add(player);
                }
              });
            },
            color: AppColors.orangeGradientStart,
          );
        }),
        SizedBox(height: 24.h),
        Text("${(_selectedManager?['username'] ?? 'THEIR').toUpperCase()}'S DRAFT PICKS", style: _labelStyle),
        SizedBox(height: 12.h),
        if (_theirPicks.isEmpty) Text("No draft picks owned.", style: TextStyle(color: Colors.white24, fontSize: 11.sp))
        else ..._theirPicks.map((pick) => _buildPickSelectionCard(
          pick: pick,
          isSelected: _theirRequestedPicks.any((p) => p['id'] == pick['id']),
          onTap: () {
            setState(() {
              _theirRequestedPicks.any((p) => p['id'] == pick['id']) 
                ? _theirRequestedPicks.removeWhere((p) => p['id'] == pick['id']) 
                : _theirRequestedPicks.add(pick);
            });
          },
          color: AppColors.orangeGradientStart,
        )),
        SizedBox(height: 40.h),
      ],
    );
  }

  Widget _buildStep4() {
    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      children: [
        Container(
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20.h),
            border: Border.all(color: AppColors.accentCyan.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   _buildSummaryColumn("YOU SEND", _myOfferedPlayers, _myOfferedPicks, AppColors.accentCyan),
                   Padding(padding: EdgeInsets.only(top: 20.h), child: const Icon(Icons.swap_horiz, color: Colors.white38)),
                   _buildSummaryColumn("YOU GET", _theirRequestedPlayers, _theirRequestedPicks, AppColors.orangeGradientStart),
                ],
              ),
              const Divider(color: Colors.white10, height: 32),
              Row(children: [
                const Icon(Icons.person_outline, color: Colors.white38, size: 16),
                SizedBox(width: 8.w),
                Text("Trading with ${_selectedManager?['username'] ?? 'Manager'}", style: TextStyle(color: Colors.white70, fontSize: 13.sp)),
              ]),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryColumn(String label, List<String> players, List<Map<String, dynamic>> picks, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: color, fontSize: 10.sp, fontWeight: FontWeight.bold)),
          SizedBox(height: 12.h),
          ...players.map((it) => Text(it, style: TextStyle(color: Colors.white, fontSize: 11.sp, fontWeight: FontWeight.bold))),
          if (players.isNotEmpty && picks.isNotEmpty) SizedBox(height: 8.h),
          ...picks.map((pk) => Text("${pk['year']} Rd ${pk['round']}", style: TextStyle(color: Colors.white70, fontSize: 10.sp, fontStyle: FontStyle.italic))),
          if (players.isEmpty && picks.isEmpty) Text("Nothing selected", style: TextStyle(color: Colors.white24, fontSize: 11.sp)),
        ],
      ),
    );
  }

  Widget _buildSelectionCard({required String title, required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 10.h),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentCyan.withOpacity(0.1) : AppColors.surface,
          borderRadius: BorderRadius.circular(12.h),
          border: Border.all(color: isSelected ? AppColors.accentCyan : Colors.white10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: TextStyle(color: isSelected ? Colors.white : Colors.white70)),
            if (isSelected) const Icon(Icons.check_circle, color: AppColors.accentCyan, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerSelectionCard({required String player, required bool isSelected, required VoidCallback onTap, required Color color}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 10.h),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : AppColors.surface,
          borderRadius: BorderRadius.circular(12.h),
          border: Border.all(color: isSelected ? color : Colors.white10),
        ),
        child: Row(
          children: [
            CircleAvatar(radius: 12.w, backgroundColor: isSelected ? color : Colors.white10, child: Icon(Icons.person, color: isSelected ? Colors.black : Colors.white38, size: 14.w)),
            SizedBox(width: 12.w),
            Expanded(child: Text(player, style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontSize: 12.sp))),
            Icon(isSelected ? Icons.check_box : Icons.check_box_outline_blank, color: isSelected ? color : Colors.white24, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPickSelectionCard({required Map<String, dynamic> pick, required bool isSelected, required VoidCallback onTap, required Color color}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 10.h),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : AppColors.surface,
          borderRadius: BorderRadius.circular(12.h),
          border: Border.all(color: isSelected ? color : Colors.white10),
        ),
        child: Row(
          children: [
            Container(
              width: 24.w, height: 24.w,
              decoration: BoxDecoration(color: isSelected ? color : Colors.white10, shape: BoxShape.circle),
              child: Center(child: Text(pick['round'].toString(), style: TextStyle(color: isSelected ? Colors.black : Colors.white, fontSize: 10.sp, fontWeight: FontWeight.bold))),
            ),
            SizedBox(width: 12.w),
            Expanded(child: Text("${pick['year']} Round ${pick['round']}", style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontSize: 12.sp))),
            Icon(isSelected ? Icons.check_box : Icons.check_box_outline_blank, color: isSelected ? color : Colors.white24, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    bool canContinue = false;
    if (_currentStep == 0) canContinue = _selectedLeague != null && _selectedManager != null;
    if (_currentStep == 1) canContinue = _myOfferedPlayers.isNotEmpty || _myOfferedPicks.isNotEmpty;
    if (_currentStep == 2) canContinue = _theirRequestedPlayers.isNotEmpty || _theirRequestedPicks.isNotEmpty;
    if (_currentStep == 3) canContinue = true;

    return Padding(
      padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 30.h),
      child: Row(
        children: [
          if (_currentStep > 0) ...[
            Expanded(
              child: GestureDetector(
                onTap: _previousPage,
                child: Container(
                  height: 56.h,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(16.h), border: Border.all(color: Colors.white10)),
                  child: const Center(child: Text("BACK", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold))),
                ),
              ),
            ),
            SizedBox(width: 12.w),
          ],
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: canContinue ? (_currentStep == 3 ? _submitTrade : _nextPage) : null,
              child: Container(
                height: 56.h,
                decoration: BoxDecoration(
                  gradient: canContinue ? const LinearGradient(colors: [AppColors.accentCyan, AppColors.createGradientPurple]) : null,
                  color: canContinue ? null : Colors.white10,
                  borderRadius: BorderRadius.circular(16.h),
                ),
                child: Center(child: Text(_currentStep == 3 ? "PROPOSE TRADE" : "NEXT STEP", style: TextStyle(color: canContinue ? Colors.black : Colors.white24, fontWeight: FontWeight.w900))),
              ),
            ),
          ),
        ],
      ),
    );
  }

  TextStyle get _labelStyle => TextStyle(color: Colors.white24, fontSize: 10.sp, fontWeight: FontWeight.bold, letterSpacing: 1.5);
}
