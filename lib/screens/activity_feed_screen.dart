import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/colors.dart';
import '../core/responsive_helper.dart';
import '../services/notification_service.dart';

class ActivityFeedScreen extends StatefulWidget {
  const ActivityFeedScreen({super.key});

  @override
  State<ActivityFeedScreen> createState() => _ActivityFeedScreenState();
}

class _ActivityFeedScreenState extends State<ActivityFeedScreen> {
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;

  static const Map<String, IconData> _typeIcons = {
    'trade_offer': Icons.swap_horiz_rounded,
    'draft_started': Icons.how_to_vote_rounded,
    'draft_on_clock': Icons.timer_rounded,
    'match_result': Icons.sports_football_rounded,
    'coin_award': Icons.monetization_on_rounded,
  };

  static const Map<String, Color> _typeColors = {
    'trade_offer': AppColors.accentCyan,
    'draft_started': AppColors.gold,
    'draft_on_clock': AppColors.orangeGradientStart,
    'match_result': AppColors.greenGradientStart,
    'coin_award': AppColors.gold,
  };

  @override
  void initState() {
    super.initState();
    if (_uid != null) NotificationService.markAllRead(_uid!);
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveHelper.init(context);
    if (_uid == null) return const Scaffold(backgroundColor: AppColors.background);

    final query = FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(50);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "ACTIVITY FEED",
          style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.w900, letterSpacing: 1.5),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.done_all, color: AppColors.accentCyan, size: 22.sp),
            tooltip: "Mark all read",
            onPressed: () => NotificationService.markAllRead(_uid!),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: AppColors.accentCyan));
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none_rounded, color: Colors.white24, size: 64.sp),
                  SizedBox(height: 16.h),
                  Text(
                    "NO NOTIFICATIONS YET",
                    style: TextStyle(color: Colors.white38, fontSize: 14.sp, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    "Trade offers, draft alerts, and match\nresults will appear here.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white24, fontSize: 12.sp, height: 1.5),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.symmetric(vertical: 8.h),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final type = data['type'] as String? ?? 'match_result';
              final title = data['title'] as String? ?? '';
              final body = data['body'] as String? ?? '';
              final isRead = data['isRead'] as bool? ?? true;
              final ts = data['createdAt'] as Timestamp?;

              final icon = _typeIcons[type] ?? Icons.notifications_rounded;
              final color = _typeColors[type] ?? Colors.white54;

              return Container(
                margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: isRead ? AppColors.surface : AppColors.surface.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(16.h),
                  border: Border.all(
                    color: isRead ? Colors.white10 : color.withOpacity(0.4),
                  ),
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  leading: Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 20.sp),
                  ),
                  title: Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.sp,
                      fontWeight: isRead ? FontWeight.w600 : FontWeight.w900,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 4.h),
                      Text(
                        body,
                        style: TextStyle(color: Colors.white54, fontSize: 12.sp, height: 1.4),
                      ),
                      if (ts != null) ...[
                        SizedBox(height: 6.h),
                        Text(
                          _formatTimestamp(ts),
                          style: TextStyle(color: Colors.white24, fontSize: 10.sp),
                        ),
                      ],
                    ],
                  ),
                  trailing: isRead
                      ? null
                      : Container(
                          width: 8.w,
                          height: 8.w,
                          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                        ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatTimestamp(Timestamp ts) {
    final dt = ts.toDate();
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
