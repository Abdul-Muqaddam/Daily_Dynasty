import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/colors.dart';
import '../core/responsive_helper.dart';
import '../services/coin_service.dart';
import '../widgets/countdown_timer.dart';
import '../widgets/app_dialogs.dart';
import 'matches_screen.dart';

class DailyCheckInScreen extends StatefulWidget {
  const DailyCheckInScreen({super.key});

  @override
  State<DailyCheckInScreen> createState() => _DailyCheckInScreenState();
}

class _DailyCheckInScreenState extends State<DailyCheckInScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  bool _claimedToday = false;
  int _currentStreak = 0;
  List<bool> _weekChecks = List.filled(7, false);
  late AnimationController _flameController;
  late Animation<double> _flameAnim;

  @override
  void initState() {
    super.initState();
    _flameController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _flameAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _flameController, curve: Curves.easeInOut),
    );
    _loadCheckInData();
  }

  @override
  void dispose() {
    _flameController.dispose();
    super.dispose();
  }

  Future<void> _loadCheckInData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final data = doc.data() ?? {};
    final int streak = data['streak'] ?? 0;
    final Timestamp? lastCheckIn = data['lastCheckIn'];
    final List<dynamic> weekRaw = data['weekCheckIns'] ?? [];
    final List<bool> weekChecks = List.filled(7, false);

    // Populate week check-ins
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    for (final ts in weekRaw) {
      if (ts is Timestamp) {
        final d = ts.toDate();
        final diff = d.difference(startOfWeek).inDays;
        if (diff >= 0 && diff < 7) weekChecks[diff] = true;
      }
    }

    bool claimedToday = false;
    if (lastCheckIn != null) {
      final last = lastCheckIn.toDate();
      claimedToday =
          last.year == now.year && last.month == now.month && last.day == now.day;
    }

    setState(() {
      _currentStreak = streak;
      _weekChecks = weekChecks;
      _claimedToday = claimedToday;
      _isLoading = false;
    });
  }

  Future<void> _claimReward() async {
    if (_claimedToday) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    final now = DateTime.now();
    final ref = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final doc = await ref.get();
    final data = doc.data() ?? {};
    final Timestamp? lastCheckIn = data['lastCheckIn'];
    int streak = data['streak'] ?? 0;

    bool isContinuingStreak = false;
    if (lastCheckIn != null) {
      final last = lastCheckIn.toDate();
      final yesterday = now.subtract(const Duration(days: 1));
      isContinuingStreak =
          last.year == yesterday.year &&
          last.month == yesterday.month &&
          last.day == yesterday.day;
    }

    streak = isContinuingStreak ? streak + 1 : 1;

    // Store this check-in
    final List<dynamic> weekRaw = data['weekCheckIns'] ?? [];
    // Remove entries from previous weeks
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final filtered = weekRaw.where((ts) {
      if (ts is Timestamp) {
        return ts.toDate().isAfter(startOfWeek.subtract(const Duration(hours: 1)));
      }
      return false;
    }).toList();
    filtered.add(Timestamp.fromDate(now));

    await ref.set({
      'streak': streak,
      'lastCheckIn': Timestamp.fromDate(now),
      'weekCheckIns': filtered,
    }, SetOptions(merge: true));

    // Award coins for the check-in
    await CoinService.awardCoins(50, 'daily_checkin');

    if (mounted) {
      final matchesState = MatchesScreen.globalKey.currentState;
      AppDialogs.showSuccessDialog(
        context,
        title: "COINS CLAIMED!",
        message: "50 coins added to your wallet.",
        onDismiss: () {
          Navigator.pop(context);
          matchesState?.setTab(0);
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveHelper.init(context);
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
          "DAILY CHECK-IN",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accentCyan))
          : SingleChildScrollView(
              padding: EdgeInsets.all(24.w),
              child: Column(
                children: [
                  _buildStreakCard(),
                  SizedBox(height: 32.h),
                  _buildRewardsRow(),
                  SizedBox(height: 32.h),
                  _buildWeeklyProgress(),
                  SizedBox(height: 40.h),
                  _buildClaimButton(),
                  SizedBox(height: 24.h),
                ],
              ),
            ),
    );
  }

  Widget _buildStreakCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(32.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.accentCyan, AppColors.createGradientPurple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24.h),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentCyan.withOpacity(0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _flameAnim,
            builder: (_, __) => Transform.scale(
              scale: _flameAnim.value,
              child: Icon(Icons.local_fire_department, color: Colors.white, size: 72.w),
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            "CURRENT STREAK",
            style: TextStyle(
              color: Colors.white.withOpacity(0.75),
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.4,
            ),
          ),
          Text(
            "$_currentStreak DAY${_currentStreak == 1 ? '' : 'S'}",
            style: TextStyle(
              color: Colors.white,
              fontSize: 38.sp,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (_claimedToday)
            Padding(
              padding: EdgeInsets.only(top: 8.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: Colors.white70, size: 16.w),
                  SizedBox(width: 6.w),
                  Text(
                    "Checked in today!",
                    style: TextStyle(color: Colors.white70, fontSize: 13.sp),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRewardsRow() {
    final rewards = [
      {"day": "Day 1", "reward": "50 coins", "icon": Icons.monetization_on},
      {"day": "Day 3", "reward": "Pack", "icon": Icons.card_giftcard},
      {"day": "Day 7", "reward": "Badge", "icon": Icons.military_tech},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "STREAK REWARDS",
          style: TextStyle(
            color: Colors.white70,
            fontSize: 13.sp,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        SizedBox(height: 12.h),
        Row(
          children: rewards.map((r) {
            final isUnlocked = _currentStreak >= int.parse(
              (r["day"] as String).replaceAll("Day ", ""),
            );
            return Expanded(
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 4.w),
                padding: EdgeInsets.symmetric(vertical: 14.h),
                decoration: BoxDecoration(
                  color: isUnlocked
                      ? AppColors.accentCyan.withOpacity(0.12)
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(14.h),
                  border: Border.all(
                    color: isUnlocked
                        ? AppColors.accentCyan.withOpacity(0.4)
                        : Colors.white10,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      r["icon"] as IconData,
                      color: isUnlocked ? AppColors.accentCyan : Colors.white24,
                      size: 24.w,
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      r["day"] as String,
                      style: TextStyle(
                        color: isUnlocked ? Colors.white : Colors.white38,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      r["reward"] as String,
                      style: TextStyle(
                        color: isUnlocked ? AppColors.accentCyan : Colors.white24,
                        fontSize: 9.sp,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildWeeklyProgress() {
    final days = ["MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN"];
    final todayIndex = DateTime.now().weekday - 1; // Mon=0

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "THIS WEEK",
          style: TextStyle(
            color: Colors.white70,
            fontSize: 13.sp,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        SizedBox(height: 14.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(7, (index) {
            final isChecked = _weekChecks[index];
            final isToday = index == todayIndex;
            final isFuture = index > todayIndex;

            return Column(
              children: [
                Container(
                  width: 40.w,
                  height: 48.h,
                  decoration: BoxDecoration(
                    color: isChecked
                        ? AppColors.accentCyan
                        : isFuture
                            ? AppColors.surface.withOpacity(0.4)
                            : AppColors.surface,
                    borderRadius: BorderRadius.circular(12.h),
                    border: Border.all(
                      color: isToday && !isChecked
                          ? AppColors.accentCyan
                          : Colors.white10,
                      width: isToday ? 2 : 1,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      isChecked
                          ? Icons.check
                          : isFuture
                              ? Icons.lock_outline
                              : Icons.radio_button_unchecked,
                      color: isChecked
                          ? Colors.black
                          : isFuture
                              ? Colors.white12
                              : Colors.white38,
                      size: 20.w,
                    ),
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  days[index],
                  style: TextStyle(
                    color: isChecked
                        ? Colors.white
                        : isToday
                            ? AppColors.accentCyan
                            : Colors.white24,
                    fontSize: 9.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }

  Widget _buildClaimButton() {
    return GestureDetector(
      onTap: _claimedToday ? null : _claimReward,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 18.h),
        decoration: BoxDecoration(
          gradient: _claimedToday
              ? null
              : const LinearGradient(
                  colors: [AppColors.accentCyan, AppColors.createGradientPurple],
                ),
          color: _claimedToday ? AppColors.surface : null,
          borderRadius: BorderRadius.circular(16.h),
          boxShadow: _claimedToday
              ? null
              : [
                  BoxShadow(
                    color: AppColors.accentCyan.withOpacity(0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!_claimedToday) ...[
                Icon(Icons.redeem, color: Colors.black, size: 20.w),
                SizedBox(width: 10.w),
                Text(
                  "CLAIM TODAY'S REWARD",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ] else ...[
                CheckInCountdown(
                  prefix: "NEXT REWARD IN ",
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
