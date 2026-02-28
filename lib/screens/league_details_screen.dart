import 'package:flutter/material.dart';
import '../../core/colors.dart';
import '../../core/responsive_helper.dart';
import '../../services/league_service.dart';

class LeagueDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> league;

  const LeagueDetailsScreen({super.key, required this.league});

  @override
  State<LeagueDetailsScreen> createState() => _LeagueDetailsScreenState();
}

class _LeagueDetailsScreenState extends State<LeagueDetailsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _members = [];

  @override
  void initState() {
    super.initState();
    _fetchMembers();
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

  @override
  Widget build(BuildContext context) {
    ResponsiveHelper.init(context);
    final name = widget.league['name'] as String? ?? 'LEAGUE DETAILS';
    final joinCode = widget.league['joinCode'] as String? ?? '------';
    final maxMembers = widget.league['maxMembers'] as int? ?? 10;
    final draftStatus = widget.league['draftStatus'] as String? ?? 'pending';
    final scoringType = (widget.league['scoringType'] as String? ?? 'standard').toUpperCase().replaceAll('_', ' ');

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
                    _buildStatCol(Icons.info_outline, draftStatus.toUpperCase(), 'STATUS', color: AppColors.accentTeal),
                  ],
                ),
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
            ),
          ),

          // Members List section
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
            child: Row(
              children: [
                Container(width: 4.w, height: 16.h, decoration: BoxDecoration(color: AppColors.accentCyan, borderRadius: BorderRadius.circular(2.w))),
                SizedBox(width: 8.w),
                Text('LEAGUE MEMBERS', style: TextStyle(color: Colors.white70, fontSize: 12.sp, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
              ],
            ),
          ),
          
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.accentCyan))
                : ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                    itemCount: _members.length,
                    itemBuilder: (context, index) {
                      final member = _members[index];
                      final isCreator = member['uid'] == widget.league['createdBy'];
                      
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
                                    member['username'] ?? member['fullName'] ?? member['email'] ?? 'Unknown Manager',
                                    style: TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.bold),
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
                    },
                  ),
          ),
        ],
      ),
    );
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
}
