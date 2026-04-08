import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/colors.dart';
import '../core/constants.dart';
import '../core/responsive_helper.dart';

class MatchCard extends StatefulWidget {
  final String team1Name;
  final String team2Name;
  final String team1Logo;
  final String team2Logo;
  final Duration? remainingTime;
  final String? fixedTime; // For non-live matches e.g. "8:00 PM"
  final String location;
  final bool isLive;

  const MatchCard({
    super.key,
    required this.team1Name,
    required this.team2Name,
    required this.team1Logo,
    required this.team2Logo,
    this.remainingTime,
    this.fixedTime,
    required this.location,
    this.isLive = false,
  });

  @override
  State<MatchCard> createState() => _MatchCardState();
}

class _MatchCardState extends State<MatchCard>
    with SingleTickerProviderStateMixin {
  late Duration _currentRemaining;
  Timer? _timer;
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _currentRemaining = widget.remainingTime ?? Duration.zero;
    if (widget.isLive && widget.remainingTime != null) {
      _startTimer();
    }

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
      value: math.Random().nextDouble(), // Randomize starting position
    )..repeat();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_currentRemaining.inSeconds > 0) {
        setState(() {
          _currentRemaining -= const Duration(seconds: 1);
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _rotationController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      width: double.infinity,
      child: AnimatedBuilder(
        animation: _rotationController,
        builder: (context, child) {
          Widget cardContent = Container(
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(20.w),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: EdgeInsets.all(15.w),
                  child: Row(
                    children: [
                      Expanded(
                          child: _buildTeamInfo(widget.team1Name, widget.team1Logo)),
                      _buildMatchStatus(),
                      Expanded(
                          child: _buildTeamInfo(widget.team2Name, widget.team2Logo)),
                    ],
                  ),
                ),
                if (widget.isLive) _buildLiveFooter(),
                if (!widget.isLive) _buildUpcomingFooter(),
              ],
            ),
          );

          try {
            return CustomPaint(
              painter: GlowingBorderPainter(
                animationValue: _rotationController.value,
                color: AppColors.accentCyan,
              ),
              child: cardContent,
            );
          } catch (e) {
            // Fallback for when late init fails during hot reload transitions
            return Container(
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(20.w),
                border: Border.all(color: AppColors.accentCyan.withOpacity(0.3)),
              ),
              child: cardContent,
            );
          }
        },
      ),
    );
  }

  Widget _buildTeamInfo(String name, String logo) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 28.w,
          backgroundColor: AppColors.surface,
          child: Padding(
            padding: EdgeInsets.all(8.w),
            child: Image.network(
              "https://sleepercdn.com/images/team_logos/nfl/${logo.toLowerCase()}.png",
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => 
                  Center(child: Text(logo, style: TextStyle(color: Colors.white24, fontSize: 16.sp, fontWeight: FontWeight.bold))),
            ),
          ),
        ),
        SizedBox(height: 8.h),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(name,
              style: AppTextStyles.subHeading, textAlign: TextAlign.center),
        ),
      ],
    );
  }

  Widget _buildMatchStatus() {
    final timeStr = widget.isLive
        ? "Starts in ${_formatDuration(_currentRemaining).substring(0, 5)}" // Showing HH:MM in VS section
        : widget.fixedTime ?? "";

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("VS", style: AppTextStyles.heading),
          SizedBox(height: 5.h),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
                widget.isLive ? "Starts in $timeStr" : "TOMORROW, $timeStr",
                style: AppTextStyles.body),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(widget.location, style: AppTextStyles.stadium),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveFooter() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: AppColors.surface.withAlpha(150),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20.w),
          bottomRight: Radius.circular(20.w),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Row(
              children: [
                Icon(Icons.add_circle_outline,
                    color: AppColors.accentCyan, size: 18.w),
                SizedBox(width: 4.w),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text("Add to My Matches", style: AppTextStyles.body),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            flex: 3,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(_formatDuration(_currentRemaining),
                  style: AppTextStyles.time),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            flex: 3,
            child: TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 8.w),
                backgroundColor: Colors.transparent,
                side: const BorderSide(color: AppColors.accentCyan),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.w)),
              ),
              child: FittedBox(
                child: Text("View Details",
                    style: TextStyle(
                        color: AppColors.accentCyan, fontSize: 13.sp)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingFooter() {
    return SizedBox(height: 10.h);
  }
}

class GlowingBorderPainter extends CustomPainter {
  final double animationValue;
  final Color color;

  GlowingBorderPainter({required this.animationValue, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(20.w));

    final paint = Paint()
      ..shader = SweepGradient(
        colors: [
          color.withOpacity(0.0),
          color.withOpacity(0.5),
          color,
          color.withOpacity(0.5),
          color.withOpacity(0.0),
        ],
        stops: const [0.0, 0.45, 0.5, 0.55, 1.0],
        // Start from top-right (approx -45 degrees or 315 degrees)
        transform: GradientRotation((animationValue * 2 * 3.14159) - (3.14159 / 4)),
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawRRect(rrect, paint);
    
    // Add a soft glow behind the border matching the animation
    final blurPaint = Paint()
      ..shader = SweepGradient(
        colors: [
          color.withOpacity(0.0),
          color.withOpacity(0.1),
          color.withOpacity(0.2),
          color.withOpacity(0.1),
          color.withOpacity(0.0),
        ],
        stops: const [0.0, 0.4, 0.5, 0.6, 1.0],
        transform: GradientRotation((animationValue * 2 * 3.14159) - (3.14159 / 4)),
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
    
    canvas.drawRRect(rrect, blurPaint);
  }

  @override
  bool shouldRepaint(covariant GlowingBorderPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
