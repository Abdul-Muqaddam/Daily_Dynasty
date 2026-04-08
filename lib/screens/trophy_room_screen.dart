import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/colors.dart';
import '../core/responsive_helper.dart';
import '../services/user_service.dart';

class TrophyRoomScreen extends StatefulWidget {
  final Map<String, dynamic>? initialProfile;

  const TrophyRoomScreen({super.key, this.initialProfile});

  @override
  State<TrophyRoomScreen> createState() => _TrophyRoomScreenState();
}

class _TrophyRoomScreenState extends State<TrophyRoomScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _accolades = [];
  String _teamName = "MY TEAM";

  @override
  void initState() {
    super.initState();
    if (widget.initialProfile != null) {
      _loadFromProfile(widget.initialProfile!);
    } else {
      _fetchProfile();
    }
  }

  void _loadFromProfile(Map<String, dynamic> profile) {
    setState(() {
      _teamName = (profile['username']?.toString() ?? profile['teamName']?.toString() ?? "MY TEAM").toUpperCase();
      _accolades = List<Map<String, dynamic>>.from(profile['accolades'] ?? []);
      _isLoading = false;
    });
  }

  Future<void> _fetchProfile() async {
    try {
      final profile = await UserService.getCurrentUserProfile();
      if (mounted && profile != null) {
        _loadFromProfile(profile);
      } else if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveHelper.init(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "TROPHY ROOM",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20.sp,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_accolades.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events_outlined, color: Colors.white10, size: 80.w),
            SizedBox(height: 20.h),
            Text(
              "NO TROPHIES YET",
              style: TextStyle(
                color: Colors.white38,
                fontSize: 18.sp,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              "Win league tournaments to fill your case.",
              style: TextStyle(color: Colors.white24, fontSize: 14.sp),
            ),
          ],
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 40.h),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(24.w),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.surface, AppColors.background],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(20.h),
                    border: Border.all(color: AppColors.gold.withOpacity(0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.gold.withOpacity(0.1),
                        blurRadius: 30,
                        spreadRadius: -5,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.military_tech, color: AppColors.gold, size: 60.w),
                      SizedBox(height: 16.h),
                      Text(
                        _teamName.toUpperCase(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22.sp,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.0,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        "${_accolades.length} CAREER CHAMPIONSHIPS",
                        style: TextStyle(color: AppColors.gold, fontSize: 12.sp, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16.w,
              crossAxisSpacing: 16.w,
              childAspectRatio: 0.8,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return _buildTrophyCard(_accolades[index]);
              },
              childCount: _accolades.length,
            ),
          ),
        ),
        SliverToBoxAdapter(child: SizedBox(height: 40.h)),
      ],
    );
  }

  Widget _buildTrophyCard(Map<String, dynamic> accolade) {
    final title = accolade['title'] as String? ?? 'CHAMPION';
    final dateStr = accolade['date'] as String?;
    final leagueId = accolade['leagueId'] as String? ?? 'Unknown League';

    String displayDate = 'Unknown Date';
    if (dateStr != null) {
      try {
        final date = DateTime.parse(dateStr);
        displayDate = DateFormat.yMMMd().format(date);
      } catch (_) {}
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.h),
        border: Border.all(color: AppColors.gold.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.gold.withOpacity(0.1),
            ),
            child: Icon(Icons.emoji_events, color: AppColors.gold, size: 40.w),
          ),
          SizedBox(height: 16.h),
          Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14.sp,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.w),
            child: Text(
              leagueId.toUpperCase(),
              style: TextStyle(color: Colors.white38, fontSize: 9.sp, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            displayDate,
            style: TextStyle(color: Colors.white24, fontSize: 9.sp),
          ),
        ],
      ),
    );
  }
}
