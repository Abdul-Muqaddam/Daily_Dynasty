import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/colors.dart';
import '../../core/constants.dart';
import '../../core/responsive_helper.dart';
import '../profile_screen.dart';
import '../player_profile_screen.dart';
import '../scout_players_screen.dart';
import '../daily_check_in_screen.dart';
import '../game_recap_screen.dart';
import '../../services/coin_service.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> with TickerProviderStateMixin {
  String _teamName = "GRIDIRON KINGS";
  late AnimationController _statsController;
  late AnimationController _logoController;

  @override
  void initState() {
    super.initState();
    _statsController = AnimationController(
        vsync: this, duration: const Duration(seconds: 10), value: 0.2)
      ..repeat();
    _logoController = AnimationController(
        vsync: this, duration: const Duration(seconds: 15), value: 0.5)
      ..repeat();
  }

  @override
  void dispose() {
    _statsController.dispose();
    _logoController.dispose();
    super.dispose();
  }

  void _showEditTeamDialog() {
    final TextEditingController controller = TextEditingController(text: _teamName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.h)),
        title: Text("EDIT TEAM", style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "TEAM NAME",
                labelStyle: TextStyle(color: AppColors.accentCyan, fontSize: 12.sp),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.accentCyan)),
              ),
            ),
            SizedBox(height: 20.h),
            Text("LOGO CUSTOMIZATION COMING SOON", style: TextStyle(color: Colors.white38, fontSize: 10.sp, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("CANCEL", style: TextStyle(color: Colors.white38, fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () {
              setState(() => _teamName = controller.text.trim().toUpperCase());
              Navigator.pop(context);
            },
            child: Text("SAVE", style: TextStyle(color: AppColors.accentCyan, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background Stadium Image
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 350.h,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/signup_background.png', // Switched to a more dynamic background
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                  ),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.6),
                          AppColors.background.withOpacity(0.9),
                          AppColors.background,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                   _buildTopBar(),
                   SizedBox(height: 10.h),
                   _buildTeamHeader(),
                   SizedBox(height: 20.h),
                   _buildOverallStatsCircle(),
                   SizedBox(height: 25.h),
                   _buildActionButtons(context),
                   SizedBox(height: 20.h),
                   _buildRosterSection(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: AppColors.topBarBg.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16.h),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: _buildTopBarItem("GAMEDAY:", "02:14:55", AppColors.accentCyan),
            ),
          ),
          Container(height: 20.h, width: 1, color: Colors.white24, margin: EdgeInsets.symmetric(horizontal: 8.w)),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: _buildTopBarItem("DRAFT DAY:", "06d 14h 30m", AppColors.orangeGradientStart),
            ),
          ),
          Container(height: 20.h, width: 1, color: Colors.white24, margin: EdgeInsets.symmetric(horizontal: 8.w)),
          StreamBuilder<int>(
            stream: CoinService.balanceStream(),
            builder: (context, snap) {
              final coins = snap.data ?? 0;
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppColors.gold.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20.h),
                  border: Border.all(color: AppColors.gold.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.monetization_on, color: AppColors.gold, size: 14.w),
                    SizedBox(width: 4.w),
                    Text(
                      '$coins',
                      style: TextStyle(color: AppColors.gold, fontSize: 11.sp, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTopBarItem(String label, String value, Color valueColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white54,
            fontSize: 10.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(width: 6.w),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 11.sp,
            fontWeight: FontWeight.w900,
            fontFamily: 'Courier',
          ),
        ),
      ],
    );
  }

  Widget _buildTeamHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        children: [
           // Lion Logo (Placeholder Icon)
           Container(
             width: 50.w,
             height: 50.w,
             decoration: const BoxDecoration(
               shape: BoxShape.circle,
               color: AppColors.surface,
               boxShadow: [
                 BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 4)),
               ],
             ),
             child: AnimatedBuilder(
               animation: _logoController,
               builder: (context, child) {
                 return CustomPaint(
                   painter: ActionBorderPainter(
                     animationValue: _logoController.value,
                     gradientColors: [
                       AppColors.gold.withOpacity(0.0),
                       AppColors.gold,
                       AppColors.gold.withOpacity(0.0),
                     ],
                     hasGlow: true,
                   ),
                   child: child,
                 );
               },
               child: Icon(Icons.catching_pokemon, color: AppColors.gold, size: 30.w), // Lion substitute
             ),
           ),
           SizedBox(width: 12.w),
           Expanded(
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Row(
                   children: [
                     Flexible(
                       child: Text(
                         _teamName,
                         maxLines: 1,
                         overflow: TextOverflow.ellipsis,
                         style: TextStyle(
                           color: Colors.white,
                           fontSize: 18.sp,
                           fontWeight: FontWeight.w900,
                           letterSpacing: 1.2,
                         ),
                       ),
                     ),
                     SizedBox(width: 8.w),
                      GestureDetector(
                        onTap: _showEditTeamDialog,
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                          child: Icon(Icons.edit_outlined, color: AppColors.accentCyan, size: 20.w),
                        ),
                      ),
                   ],
                 ),
                 SizedBox(height: 2.h),
                 FittedBox(
                   fit: BoxFit.scaleDown,
                   alignment: Alignment.centerLeft,
                   child: Row(
                     children: [
                       Text(
                         "RECORD: ",
                         style: TextStyle(color: Colors.white38, fontSize: 11.sp),
                       ),
                       Text(
                         "3-7",
                         style: TextStyle(color: Colors.white70, fontSize: 11.sp, fontWeight: FontWeight.bold),
                       ),
                       Text(
                         "  |  LEAGUE RANK: ",
                         style: TextStyle(color: Colors.white38, fontSize: 11.sp),
                       ),
                       Text(
                         "9th (4 GB)",
                         style: TextStyle(color: Colors.white70, fontSize: 11.sp, fontWeight: FontWeight.bold),
                       ),
                     ],
                   ),
                 ),
               ],
             ),
           ),
        ],
      ),
    );
  }

  Widget _buildOverallStatsCircle() {
    return Container(
      width: 140.w,
      height: 140.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.footballBrown, width: 8.w),
        gradient: const RadialGradient(
          colors: [
             AppColors.statsCircleBgStart,
             AppColors.statsCircleBgEnd,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: AnimatedBuilder(
        animation: _statsController,
        builder: (context, child) {
          return CustomPaint(
            painter: ActionBorderPainter(
              animationValue: _statsController.value,
              gradientColors: [
                AppColors.footballBrown.withOpacity(0.0),
                AppColors.footballBrown,
                AppColors.footballBrown.withOpacity(0.0),
              ],
              hasGlow: true,
            ),
            child: child,
          );
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "OVERALL\nTEAM SPS:",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 9.sp,
                fontWeight: FontWeight.bold,
                height: 1.1,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              "68.5",
              style: TextStyle(
                color: Colors.white,
                fontSize: 28.sp,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Row(
        children: [
          HomeActionCard(
            title: "TRAIN",
            subtitle: "PLAYERS",
            icon: Icons.fitness_center,
            colors: [AppColors.blueGradientStart, AppColors.blueGradientEnd],
            duration: const Duration(seconds: 3),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
          ),
          HomeActionCard(
            title: "SCOUT",
            subtitle: "PLAYERS",
            icon: Icons.search,
            colors: [AppColors.greenGradientStart, AppColors.greenGradientEnd],
            duration: const Duration(seconds: 5),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ScoutPlayersScreen())),
          ),
          HomeActionCard(
            title: "VIEW",
            subtitle: "MATCHUP",
            icon: Icons.vignette,
            colors: [AppColors.orangeGradientStart, AppColors.orangeGradientEnd],
            duration: const Duration(seconds: 7),
            onTap: () {},
          ),
          HomeActionCard(
            title: "VIEW",
            subtitle: "ROSTER",
            icon: Icons.groups,
            colors: [AppColors.purpleGradientStart, AppColors.purpleGradientEnd],
            duration: const Duration(seconds: 9),
            onTap: () {},
          ),
          HomeActionCard(
            title: "DAILY",
            subtitle: "CHECK-IN",
            icon: Icons.calendar_today,
            colors: [AppColors.accentCyan, AppColors.createGradientPurple],
            duration: const Duration(seconds: 11),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DailyCheckInScreen())),
          ),
          HomeActionCard(
            title: "GAME",
            subtitle: "RECAP",
            icon: Icons.history,
            colors: [AppColors.orangeGradientEnd, AppColors.logoutPink],
            duration: const Duration(seconds: 13),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GameRecapScreen())),
          ),
        ],
      ),
    );
  }


  Widget _buildRosterSection(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.rosterSectionBg,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          _buildRosterHeader(),
          _buildPlayerRow(pos: "QB", name: "J. Fields", sps: "78", matchup: "@LAR", exp: "4Y", img: Icons.person, context: context),
          _buildPlayerRow(pos: "RB", name: "S. Barkley", sps: "88", matchup: "vs DAL", exp: "6Y", img: Icons.person, context: context),
          _buildPlayerRow(pos: "RB", name: "K. Walker", sps: "72", matchup: "@SEA", exp: "2Y", img: Icons.person, context: context),
          _buildPlayerRow(pos: "WR", name: "J. Chase", sps: "91", matchup: "@CIN", exp: "3Y", img: Icons.person, context: context),
          _buildPlayerRow(pos: "WR", name: "D. Smith", sps: "85", matchup: "vs PHI", exp: "3Y", img: Icons.person, context: context),
          _buildPlayerRow(pos: "WR", name: "A. St. Brown", sps: "89", matchup: "@DET", exp: "3Y", img: Icons.person, context: context),
          _buildPlayerRow(pos: "TE", name: "T. Hockenson", sps: "84", matchup: "vs MIN", exp: "5Y", img: Icons.person, context: context),
          _buildPlayerRow(pos: "FLEX", name: "T. Pollard", sps: "82", matchup: "@TEN", exp: "5Y", img: Icons.person, context: context),
          _buildPlayerRow(pos: "SFX", name: "K. Cousins", sps: "80", matchup: "vs ATL", exp: "12Y", img: Icons.person, context: context),
          _buildSectionHeader("BENCH (18)"),
          _buildPlayerRow(pos: "BN", name: "C. Watson", sps: "76", matchup: "vs GB", exp: "2Y", img: Icons.person, context: context),
          _buildSectionHeader("IR (4)"),
          _buildPlayerRow(pos: "IR", name: "N. Chubb", sps: "88", matchup: "INJURED", exp: "6Y", img: Icons.person, context: context),
          _buildSectionHeader("TAXI (2)"),
          _buildPlayerRow(pos: "TX", name: "M. Harrison Jr.", sps: "75", matchup: "ROOKIE", exp: "R", img: Icons.person, context: context),
          SizedBox(height: 50.h),
        ],
      ),
    );
  }

  Widget _buildRosterHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          SizedBox(width: 30.w, child: Text("Pos", style: _headerStyle)),
          Expanded(child: Text("Player", style: _headerStyle)),
          SizedBox(width: 40.w, child: Text("PROJ.", style: _headerStyle)),
          SizedBox(width: 60.w, child: Text("Matchup", style: _headerStyle)),
          SizedBox(width: 30.w, child: Text("Exp.", style: _headerStyle)),
          SizedBox(width: 60.w, child: Center(child: Text("Train", style: _headerStyle))),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      color: AppColors.sectionHeaderBg,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.white38,
          fontSize: 10.sp,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildPlayerRow({
    required String pos,
    required String name,
    required String sps,
    required String matchup,
    required String exp,
    required IconData img,
    required BuildContext context,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 30.w,
            child: Text(
              pos,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.white38, fontSize: 11.sp, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14.w,
                  backgroundColor: Colors.white12,
                  child: Icon(img, size: 16.w, color: Colors.white54),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PlayerProfileScreen(
                          name: name,
                          pos: pos,
                          sps: sps,
                          exp: exp,
                        ),
                      ),
                    ),
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.white24,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 40.w,
            child: Text(
              sps,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.white, fontSize: 11.sp, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(
            width: 60.w,
            child: Text(
              matchup,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.white38, fontSize: 11.sp),
            ),
          ),
          SizedBox(
            width: 30.w,
            child: Text(
              exp,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.white38, fontSize: 11.sp),
            ),
          ),
          SizedBox(
            width: 60.w,
            child: GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
              child: Container(
                height: 28.h,
                decoration: BoxDecoration(
                  color: AppColors.cardBorder,
                  borderRadius: BorderRadius.circular(8.h),
                  border: Border.all(color: Colors.white12),
                ),
                child: Center(
                  child: Text(
                    "Train",
                    style: TextStyle(color: Colors.white70, fontSize: 10.sp, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  TextStyle get _headerStyle => TextStyle(
    color: Colors.white24,
    fontSize: 10.sp,
    fontWeight: FontWeight.bold,
  );
}

// Premium Animated Action Card for Home Screen
class HomeActionCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> colors;
  final Duration duration;
  final VoidCallback onTap;

  const HomeActionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.colors,
    required this.duration,
    required this.onTap,
  });

  @override
  State<HomeActionCard> createState() => _HomeActionCardState();
}

class _HomeActionCardState extends State<HomeActionCard> with SingleTickerProviderStateMixin {
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
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 4.w),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Container(
              width: 100.w,
              height: 60.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16.h),
                color: AppColors.cardBackground,
                boxShadow: [
                  BoxShadow(color: widget.colors.last.withOpacity(0.05), blurRadius: 10, spreadRadius: -2),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16.h),
                child: Stack(
                  children: [
                    // Moving the border logic here
                    Positioned.fill(
                      child: CustomPaint(
                        painter: ActionBorderPainter(
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
                    Container(
                      margin: const EdgeInsets.all(1.5),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(14.h),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            right: -5.w,
                            bottom: -5.h,
                            child: Icon(widget.icon, size: 40.w, color: widget.colors.first.withOpacity(0.05)),
                          ),
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  widget.title,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9.sp,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                Text(
                                  widget.subtitle,
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 8.sp,
                                    fontWeight: FontWeight.bold,
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
          },
        ),
      ),
    );
  }
}

class ActionBorderPainter extends CustomPainter {
  final double animationValue;
  final List<Color> gradientColors;
  final bool hasGlow;

  ActionBorderPainter({
    required this.animationValue,
    required this.gradientColors,
    this.hasGlow = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(size.height / 3.5));
    
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
  bool shouldRepaint(covariant ActionBorderPainter oldDelegate) =>
      oldDelegate.animationValue != animationValue;
}
