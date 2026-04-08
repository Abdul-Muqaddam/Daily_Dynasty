import 'package:flutter/material.dart';
import '../core/colors.dart';
import '../core/responsive_helper.dart';
import '../services/coin_service.dart';
import '../services/check_in_service.dart';
import '../widgets/app_dialogs.dart';
import '../widgets/notification_badge.dart';
import '../widgets/countdown_timer.dart';

class StoreScreen extends StatefulWidget {
  final bool isEmbedded;
  const StoreScreen({super.key, this.isEmbedded = false});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  bool _isPurchasing = false;

  final List<Map<String, dynamic>> _items = [
    {
      'name': 'GOLD PACK',
      'desc': 'Contains 5 premium player cards',
      'cost': 500,
      'icon': Icons.card_giftcard,
      'colors': [Color(0xFFFFD700), Color(0xFFFFA500)],
      'tag': 'POPULAR',
    },
    {
      'name': 'SILVER PACK',
      'desc': 'Contains 3 standard player cards',
      'cost': 200,
      'icon': Icons.style,
      'colors': [Color(0xFFAAAAAA), Color(0xFF666666)],
      'tag': null,
    },
    {
      'name': 'DYNASTY BADGE',
      'desc': 'Exclusive profile badge for legends',
      'cost': 1000,
      'icon': Icons.military_tech,
      'colors': [AppColors.accentCyan, AppColors.createGradientPurple],
      'tag': 'RARE',
    },
    {
      'name': 'XP BOOSTER',
      'desc': 'Double XP for your next 3 games',
      'cost': 300,
      'icon': Icons.bolt,
      'colors': [AppColors.orangeGradientStart, AppColors.orangeGradientEnd],
      'tag': null,
    },
    {
      'name': 'COIN BUNDLE',
      'desc': '250 bonus coins — best value',
      'cost': 150,
      'icon': Icons.monetization_on,
      'colors': [Color(0xFF36D1DC), Color(0xFF5B86E5)],
      'tag': 'VALUE',
    },
    {
      'name': 'LEGEND TITLE',
      'desc': 'Display a custom title below your name',
      'cost': 2000,
      'icon': Icons.workspace_premium,
      'colors': [AppColors.gold, Color(0xFFFF6B00)],
      'tag': 'LIMITED',
    },
  ];

  Future<void> _purchase(Map<String, dynamic> item) async {
    if (_isPurchasing) return;
    setState(() => _isPurchasing = true);

    try {
      await CoinService.spendCoins(item['cost'] as int, 'store:${item['name']}');
      if (mounted) {
        AppDialogs.showSuccessDialog(
          context,
          title: "PURCHASE SUCCESSFUL",
          message: "${item['name']} added to your inventory.",
        );
      }
    } catch (e) {
      if (mounted) {
        final message = e.toString().contains('Insufficient')
            ? 'Not enough coins! Earn more by checking in daily.'
            : 'Purchase failed. Please try again.';
        AppDialogs.showPremiumErrorDialog(
          context,
          message: message,
          isNetworkError: false,
        );
      }
    } finally {
      if (mounted) setState(() => _isPurchasing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveHelper.init(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: widget.isEmbedded ? null : AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "STORE",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 16.w),
            child: StreamBuilder<int>(
              stream: CoinService.balanceStream(),
              builder: (_, snap) {
                final coins = snap.data ?? 0;
                return Row(
                  children: [
                    Icon(Icons.monetization_on, color: AppColors.gold, size: 18.w),
                    SizedBox(width: 4.w),
                    Text(
                      '$coins',
                      style: TextStyle(
                        color: AppColors.gold,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBanner(),
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.all(20.w),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.78,
                crossAxisSpacing: 14.w,
                mainAxisSpacing: 14.h,
              ),
              itemCount: _items.length,
              itemBuilder: (_, i) => _buildStoreCard(_items[i]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBanner() {
    return Container(
      margin: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 4.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.accentCyan, AppColors.createGradientPurple],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16.h),
      ),
      child: Row(
        children: [
           StreamBuilder<bool>(
            stream: CheckInService.checkInStatusStream(),
            builder: (context, snapshot) {
              final isReady = snapshot.data ?? false;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(Icons.local_fire_department, color: Colors.white, size: 32.w),
                  if (isReady)
                    Positioned(
                      top: -5.h,
                      right: -5.w,
                      child: const PulsingNotificationDot(),
                    ),
                ],
              );
            }
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "DAILY CHECK-IN SPECIAL",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
                StreamBuilder<bool>(
                  stream: CheckInService.checkInStatusStream(),
                  builder: (context, snap) {
                    if (snap.data == false) {
                      return CheckInCountdown(
                        prefix: "Next reward in ",
                        style: TextStyle(color: Colors.white70, fontSize: 11.sp),
                      );
                    }
                    return Text(
                      "Earn 50 coins every day by checking in!",
                      style: TextStyle(color: Colors.white70, fontSize: 11.sp),
                    );
                  }
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreCard(Map<String, dynamic> item) {
    final colors = item['colors'] as List<Color>;
    final tag = item['tag'] as String?;

    return GestureDetector(
      onTap: () => _showPurchaseDialog(item),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20.h),
          border: Border.all(color: Colors.white10),
        ),
        child: Stack(
          children: [
            // Tag badge
            if (tag != null)
              Positioned(
                top: 10.h,
                right: 10.w,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: colors[0].withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8.h),
                    border: Border.all(color: colors[0].withOpacity(0.5)),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(
                      color: colors[0],
                      fontSize: 8.sp,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            // Content
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48.w,
                    height: 48.w,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: colors),
                      borderRadius: BorderRadius.circular(14.h),
                      boxShadow: [
                        BoxShadow(
                          color: colors[0].withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(item['icon'] as IconData, color: Colors.white, size: 26.w),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    item['name'] as String,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    item['desc'] as String,
                    style: TextStyle(color: Colors.white38, fontSize: 10.sp, height: 1.3),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: colors),
                      borderRadius: BorderRadius.circular(10.h),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.monetization_on, color: Colors.white, size: 14.w),
                        SizedBox(width: 4.w),
                        Text(
                          '${item['cost']}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPurchaseDialog(Map<String, dynamic> item) {
    final colors = item['colors'] as List<Color>;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.h),
          side: BorderSide(color: colors[0].withOpacity(0.3)),
        ),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: colors),
                borderRadius: BorderRadius.circular(10.h),
              ),
              child: Icon(item['icon'] as IconData, color: Colors.white, size: 20.w),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                item['name'] as String,
                style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item['desc'] as String, style: TextStyle(color: Colors.white54, fontSize: 13.sp)),
            SizedBox(height: 16.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12.h),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Cost", style: TextStyle(color: Colors.white38, fontSize: 12.sp)),
                  Row(
                    children: [
                      Icon(Icons.monetization_on, color: AppColors.gold, size: 16.w),
                      SizedBox(width: 4.w),
                      Text(
                        '${item['cost']} coins',
                        style: TextStyle(color: AppColors.gold, fontSize: 14.sp, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("CANCEL", style: TextStyle(color: Colors.white38, fontWeight: FontWeight.bold)),
          ),
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
              _purchase(item);
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: colors),
                borderRadius: BorderRadius.circular(12.h),
              ),
              child: Text(
                "BUY NOW",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13.sp),
              ),
            ),
          ),
          SizedBox(width: 4.w),
        ],
      ),
    );
  }
}
