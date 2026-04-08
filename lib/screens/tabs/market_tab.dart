import 'package:flutter/material.dart';
import '../../core/colors.dart';
import '../../core/responsive_helper.dart';
import '../store_screen.dart';
import '../trade_block_screen.dart';
import '../coin_market_screen.dart';

class MarketTab extends StatelessWidget {
  const MarketTab({super.key});

  @override
  Widget build(BuildContext context) {
    ResponsiveHelper.init(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 10.h),
                children: [
                  _buildMarketOptionCard(
                    context,
                    title: "STORE",
                    subtitle: "Get exclusive packs, players, and coins",
                    icon: Icons.storefront,
                    colors: [AppColors.accentCyan, AppColors.createGradientPurple],
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StoreScreen())),
                  ),
                  SizedBox(height: 16.h),
                  _buildMarketOptionCard(
                    context,
                    title: "COIN MARKET",
                    subtitle: "Purchase coins to build your dynasty",
                    icon: Icons.monetization_on,
                    colors: [AppColors.gold, Color(0xFFFF6B00)],
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CoinMarketScreen())),
                  ),
                  SizedBox(height: 16.h),
                  _buildMarketOptionCard(
                    context,
                    title: "TRADE BLOCK",
                    subtitle: "Make deals with players in your league",
                    icon: Icons.swap_horiz,
                    colors: [AppColors.blueGradientStart, AppColors.blueGradientEnd],
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TradeBlockScreen())),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 10.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "MARKET",
            style: TextStyle(
              color: Colors.white,
              fontSize: 28.sp,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            "Select a market destination",
            style: TextStyle(
              color: Colors.white54,
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarketOptionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> colors,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20.h),
          border: Border.all(color: Colors.white10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Row(
            children: [
              Container(
                width: 60.w,
                height: 60.w,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: colors),
                  borderRadius: BorderRadius.circular(16.h),
                  boxShadow: [
                    BoxShadow(
                      color: colors[0].withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 30.w),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12.sp,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.white38, size: 24.w),
            ],
          ),
        ),
      ),
    );
  }
}
