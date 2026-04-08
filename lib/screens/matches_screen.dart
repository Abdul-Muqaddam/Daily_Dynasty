import 'package:flutter/material.dart';
import '../core/colors.dart';
import '../core/constants.dart';
import '../core/responsive_helper.dart';
import 'tabs/home_tab.dart';
import 'tabs/league_tab.dart';
import 'tabs/market_tab.dart';
import 'tabs/leaderboard_tab.dart';
import 'profile_screen.dart';

class MatchesScreen extends StatefulWidget {
  static final GlobalKey<MatchesScreenState> globalKey = GlobalKey<MatchesScreenState>();
  
  MatchesScreen() : super(key: globalKey);

  @override
  State<MatchesScreen> createState() => MatchesScreenState();

  static MatchesScreenState? of(BuildContext context) =>
      context.findAncestorStateOfType<MatchesScreenState>();
}

class MatchesScreenState extends State<MatchesScreen> {
  late PageController _pageController;
  int _currentIndex = 0; // Start on TEAM tab

  void setTab(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _onNavBarTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveHelper.init(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          onPageChanged: _onPageChanged,
          children: [
            const HomeTab(),       // 0 - TEAM
            const LeagueTab(),     // 1 - LEAGUE
            const MarketTab(),     // 2 - MARKET
            const LeaderboardTab(), // 3 - LEADERBOARD
            const ProfileScreen(), // 4 - PROFILE
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.06))),
      ),
      child: BottomNavigationBar(
        backgroundColor: AppColors.background,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.accentCyan,
        unselectedItemColor: AppColors.textSecondary,
        selectedLabelStyle: TextStyle(fontSize: 9.sp, fontWeight: FontWeight.w900, letterSpacing: 0.5),
        unselectedLabelStyle: TextStyle(fontSize: 9.sp, fontWeight: FontWeight.bold),
        currentIndex: _currentIndex,
        elevation: 0,
        onTap: _onNavBarTapped,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.shield_outlined),
            activeIcon: Icon(Icons.shield),
            label: "TEAM",
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events_outlined),
            activeIcon: Icon(Icons.emoji_events),
            label: "LEAGUE",
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.storefront_outlined),
            activeIcon: Icon(Icons.storefront),
            label: "MARKET",
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.leaderboard_outlined),
            activeIcon: Icon(Icons.leaderboard),
            label: "RANKINGS",
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: "PROFILE",
          ),
        ],
      ),
    );
  }
}
