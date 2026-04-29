import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/colors.dart';
import '../core/responsive_helper.dart';
import 'login_screen.dart';
import 'matches_screen.dart';
import 'create_username_screen.dart';
import '../services/player_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _progress;
  @override
  void initState() {
    super.initState();
    PlayerService.seedInitialPlayers(); // Initialize global players
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 7));
    _progress = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.25).chain(CurveTween(curve: Curves.easeOut)), weight: 2),
      TweenSequenceItem(tween: ConstantTween(0.25), weight: 1), // small pause
      TweenSequenceItem(tween: Tween(begin: 0.25, end: 0.6).chain(CurveTween(curve: Curves.easeInOut)), weight: 3),
      TweenSequenceItem(tween: ConstantTween(0.6), weight: 1), // small pause
      TweenSequenceItem(tween: Tween(begin: 0.6, end: 1.0).chain(CurveTween(curve: Curves.easeIn)), weight: 2),
    ]).animate(_controller);
    _controller.addStatusListener((status) async {
      if (status == AnimationStatus.completed && mounted) {
        // Safely wait for the auth state to initialize
        User? user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          // Sometimes currentUser is null right at launch, wait for the first event
          try {
            user = await FirebaseAuth.instance.authStateChanges().first;
          } catch (_) {}
        }

        // Check traditional "Remember Me" persistence
        final prefs = await SharedPreferences.getInstance();
        final rememberMe = prefs.getBool('remember_me') ?? true; // default to true if never set

        if (user != null && !rememberMe) {
          // If they explicitly unchecked "Remember Me", clear their session on restart
          await FirebaseAuth.instance.signOut();
          user = null;
        }

        if (user == null) {
          // 1. Not logged in -> Login Screen
          _navigateTo(const LoginScreen());
          return;
        }

        try {
          // 2. Logged in -> Check if registration is completed
          final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
          final registrationCompleted = userDoc.data()?['registrationCompleted'] ?? false;

          if (registrationCompleted) {
            _navigateTo(MatchesScreen());
          } else {
            // User left in between registration. Delete incomplete account and restart.
            try {
              await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();
              await user.delete();
            } catch (_) {}
            await FirebaseAuth.instance.signOut();
            _navigateTo(const LoginScreen());
          }
        } catch (e) {
          // If fetching user document fails (e.g. offline), 
          // do NOT kick them out to login. Send to MatchesScreen so they stay authenticated.
          print('Error checking registration status in splash: $e');
          _navigateTo(MatchesScreen());
        }
      }
    });
    _controller.forward();
  }

  void _navigateTo(Widget screen) {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => screen),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveHelper.init(context);
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/splash_background.png',
              fit: BoxFit.cover,
              alignment: Alignment.center,
              filterQuality: FilterQuality.high,
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.overlayTop,
                    AppColors.overlayBottom,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                Center(
                  child: Image.asset(
                    'assets/images/splash_logo.png',
                    width: 260.w,
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8.h),
                        child: AnimatedBuilder(
                          animation: _progress,
                          builder: (context, _) {
                            return LinearProgressIndicator(
                              value: _progress.value,
                              minHeight: 6.h,
                              backgroundColor: Colors.white24,
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.gradientBlue),
                            );
                          },
                        ),
                      ),
                      SizedBox(height: 8.h),
                      AnimatedBuilder(
                        animation: _progress,
                        builder: (context, _) {
                          final pct = (_progress.value * 100).clamp(0, 100).round();
                          return Text(
                            '$pct%',
                            style: TextStyle(color: Colors.white70, fontSize: 14.sp),
                          );
                        },
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
