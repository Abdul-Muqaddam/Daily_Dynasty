import 'package:flutter/material.dart';
import '../core/colors.dart';
import '../core/responsive_helper.dart';
import '../services/league_service.dart';
import 'app_dialogs.dart';

class JoinLeagueBottomSheet extends StatefulWidget {
  const JoinLeagueBottomSheet({super.key});

  @override
  State<JoinLeagueBottomSheet> createState() => _JoinLeagueBottomSheetState();
}

class _JoinLeagueBottomSheetState extends State<JoinLeagueBottomSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = false;
  Future<List<Map<String, dynamic>>>? _publicLeaguesFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _refreshPublicLeagues();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _refreshPublicLeagues() {
    setState(() {
      _publicLeaguesFuture = LeagueService.getPublicLeagues();
    });
  }

  Future<void> _handleJoinWithCode() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.length != 6) {
      AppDialogs.showPremiumErrorDialog(context, message: 'Code must be exactly 6 characters');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await LeagueService.joinLeague(code);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleDirectJoin(String leagueId) async {
    setState(() => _isLoading = true);
    try {
      await LeagueService.joinLeagueById(leagueId);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(dynamic e) {
    if (mounted) {
      final errorStr = e.toString().toLowerCase();
      final isNetwork = errorStr.contains('network') || errorStr.contains('connection');
      AppDialogs.showPremiumErrorDialog(
        context,
        message: isNetwork ? "STABLE CONNECTION REQUIRED" : e.toString().replaceAll('Exception: ', ''),
        isNetworkError: isNetwork,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveHelper.init(context);
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: 600.h,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32.w)),
        border: Border(top: BorderSide(color: AppColors.accentCyan.withOpacity(0.3), width: 2)),
      ),
      child: Column(
        children: [
          _buildHandle(),
          _buildHeader(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPublicDiscovery(),
                _buildPrivateJoin(bottomPadding),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      margin: EdgeInsets.only(top: 12.h),
      width: 40.w,
      height: 4.h,
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(2.h),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 10.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'JOIN LEAGUE',
            style: TextStyle(color: Colors.white, fontSize: 20.sp, fontWeight: FontWeight.w900, letterSpacing: 1.0),
          ),
          IconButton(
            icon: Icon(Icons.close, color: Colors.white54, size: 24.w),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24.w, vertical: 10.h),
      height: 44.h,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12.h),
      ),
      child: TabBar(
        controller: _tabController,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: AppColors.accentCyan,
          borderRadius: BorderRadius.circular(10.h),
        ),
        labelColor: Colors.black,
        unselectedLabelColor: Colors.white54,
        labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.sp),
        tabs: const [
          Tab(text: 'PUBLIC'),
          Tab(text: 'PRIVATE'),
        ],
      ),
    );
  }

  Widget _buildPublicDiscovery() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _publicLeaguesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.accentCyan));
        }
        
        final leagues = snapshot.data ?? [];
        if (leagues.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, color: Colors.white10, size: 64.w),
                SizedBox(height: 16.h),
                Text('NO PUBLIC LEAGUES FOUND', style: TextStyle(color: Colors.white24, fontSize: 12.sp, fontWeight: FontWeight.bold)),
                TextButton(onPressed: _refreshPublicLeagues, child: const Text('REFRESH', style: TextStyle(color: AppColors.accentCyan))),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(24.w),
          itemCount: leagues.length,
          itemBuilder: (context, index) => _buildPublicLeagueCard(leagues[index]),
        );
      },
    );
  }

  Widget _buildPublicLeagueCard(Map<String, dynamic> league) {
    final members = List<String>.from(league['members'] ?? []);
    final maxMembers = league['maxMembers'] as int? ?? 10;
    final type = (league['leagueType'] as String? ?? 'Redraft').toUpperCase();
    final draft = (league['draftType'] as String? ?? 'Snake').toUpperCase();

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.leagueCardBg,
        borderRadius: BorderRadius.circular(16.h),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48.w, height: 48.w,
                decoration: BoxDecoration(color: AppColors.accentCyan.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(Icons.shield, color: AppColors.accentCyan, size: 24.w),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(league['name'].toString().toUpperCase(), style: TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        _buildTag(type),
                        SizedBox(width: 6.w),
                        _buildTag(draft),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${members.length}/$maxMembers', style: TextStyle(color: Colors.white, fontSize: 12.sp, fontWeight: FontWeight.bold)),
                  Text('MEMBERS', style: TextStyle(color: Colors.white24, fontSize: 8.sp, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          SizedBox(height: 16.h),
          GestureDetector(
            onTap: _isLoading ? null : () => _handleDirectJoin(league['id']),
            child: Container(
              height: 44.h,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.accentCyan, AppColors.createGradientPurple]),
                borderRadius: BorderRadius.circular(10.h),
              ),
              child: Center(
                child: Text('JOIN LEAGUE', style: TextStyle(color: Colors.white, fontSize: 13.sp, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(4.h)),
      child: Text(text, style: TextStyle(color: Colors.white54, fontSize: 8.sp, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildPrivateJoin(double bottomPadding) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 24.h + bottomPadding),
      child: Column(
        children: [
          Text(
            'Enter the 6-character join code provided by your league commissioner.',
            style: TextStyle(color: Colors.white54, fontSize: 13.sp, height: 1.5),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 32.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: AppColors.leagueCardBg,
              borderRadius: BorderRadius.circular(16.w),
              border: Border.all(color: AppColors.accentCyan.withOpacity(0.3)),
            ),
            child: TextField(
              controller: _codeController,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              maxLength: 6,
              style: TextStyle(color: AppColors.accentCyan, fontSize: 24.sp, fontWeight: FontWeight.w900, letterSpacing: 8.0),
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                counterText: '',
                hintText: '      ',
                hintStyle: TextStyle(color: Colors.white24, letterSpacing: 8.0),
                border: InputBorder.none,
              ),
            ),
          ),
          SizedBox(height: 40.h),
          GestureDetector(
            onTap: _isLoading ? null : _handleJoinWithCode,
            child: Container(
              height: 56.h,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.accentCyan, AppColors.createGradientPurple]),
                borderRadius: BorderRadius.circular(16.w),
                boxShadow: [
                  BoxShadow(color: AppColors.accentCyan.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5)),
                ],
              ),
              child: Center(
                child: _isLoading
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text('JOIN WITH CODE', style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
