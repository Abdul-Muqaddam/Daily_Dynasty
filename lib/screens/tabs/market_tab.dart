import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/colors.dart';
import '../../core/responsive_helper.dart';
import '../store_screen.dart';
import '../trade_block_screen.dart';

class MarketTab extends StatelessWidget {
  const MarketTab({super.key});

  @override
  Widget build(BuildContext context) {
    ResponsiveHelper.init(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 10.h),
              children: [
                AnimatedMarketCard(
                  title: "STORE",
                  subtitle: "Purchase packs, badges, and coins",
                  icon: Icons.local_mall_outlined,
                  colors: [AppColors.blueGradientStart, AppColors.blueGradientEnd],
                  duration: const Duration(seconds: 4),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const StoreScreen()),
                    );
                  },
                ),
                SizedBox(height: 24.h),
                AnimatedMarketCard(
                  title: "COIN MARKET",
                  subtitle: "Buy and sell players using coins",
                  icon: Icons.monetization_on_outlined,
                  colors: [AppColors.orangeGradientStart, AppColors.orangeGradientEnd],
                  duration: const Duration(seconds: 8),
                  onTap: () {},
                ),
                SizedBox(height: 24.h),
                AnimatedMarketCard(
                  title: "TRADE BLOCK",
                  subtitle: "Trade players and picks directly",
                  icon: Icons.swap_horiz_outlined,
                  colors: [AppColors.purpleGradientStart, AppColors.purpleGradientEnd],
                  duration: const Duration(seconds: 12),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TradeBlockScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.fromLTRB(24.w, 40.h, 24.w, 20.h),
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
            "Select a marketplace to explore",
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
}

class AnimatedMarketCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> colors;
  final Duration duration;
  final VoidCallback onTap;

  const AnimatedMarketCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.colors,
    required this.duration,
    required this.onTap,
  });

  @override
  State<AnimatedMarketCard> createState() => _AnimatedMarketCardState();
}

class _AnimatedMarketCardState extends State<AnimatedMarketCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      value: math.Random().nextDouble(),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            height: 120.h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24.h),
              color: AppColors.cardBackground,
              boxShadow: [
                BoxShadow(
                  color: widget.colors.last.withOpacity(0.1),
                  blurRadius: 20,
                  spreadRadius: -5,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24.h),
              child: Stack(
                children: [
                  // Rotating Border
                  Positioned.fill(
                    child: CustomPaint(
                      painter: BorderPainter(
                        animationValue: _controller.value,
                        gradientColors: [
                          widget.colors.first.withOpacity(0.0),
                          widget.colors.first,
                          widget.colors.first.withOpacity(0.0),
                        ],
                        hasGlow: true,
                      ),
                    ),
                  ),
                  
                  // Content
                  Container(
                    margin: const EdgeInsets.all(2), // Space for the border
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(22.h),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -10.w,
                          bottom: -10.h,
                          child: Icon(
                            widget.icon,
                            size: 100.w,
                            color: widget.colors.first.withOpacity(0.05),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20.w),
                          child: Row(
                            children: [
                              Container(
                                width: 50.w,
                                height: 50.w,
                                decoration: BoxDecoration(
                                  color: widget.colors.first.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16.h),
                                  border: Border.all(color: widget.colors.first.withOpacity(0.2)),
                                ),
                                child: Icon(widget.icon, color: widget.colors.first, size: 28.w),
                              ),
                              SizedBox(width: 16.w),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.title,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20.sp,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                    SizedBox(height: 2.h),
                                    Text(
                                      widget.subtitle,
                                      style: TextStyle(
                                        color: Colors.white54,
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 16.w),
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
        },
      ),
    );
  }
}

class BorderPainter extends CustomPainter {
  final double animationValue;
  final List<Color> gradientColors;
  final bool hasGlow;

  BorderPainter({
    required this.animationValue,
    required this.gradientColors,
    this.hasGlow = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(size.height / 5));
    
    final paint = Paint()
      ..shader = SweepGradient(
        colors: gradientColors,
        stops: const [0.0, 0.5, 1.0],
        transform: GradientRotation(animationValue * 2 * 3.14159),
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = hasGlow ? 3.5 : 3;

    if (hasGlow) {
      final blurPaint = Paint()
        ..shader = SweepGradient(
          colors: [
            gradientColors[1].withOpacity(0.0),
            gradientColors[1].withOpacity(0.2),
            gradientColors[1].withOpacity(0.4),
            gradientColors[1].withOpacity(0.2),
            gradientColors[1].withOpacity(0.0),
          ],
          stops: const [0.0, 0.4, 0.5, 0.6, 1.0],
          transform: GradientRotation(animationValue * 2 * 3.14159),
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
      
      canvas.drawRRect(rrect, blurPaint);
    }

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant BorderPainter oldDelegate) =>
      oldDelegate.animationValue != animationValue;
}
