import 'package:flutter/material.dart';
import '../core/colors.dart';
import '../core/constants.dart';
import '../core/responsive_helper.dart';
import '../widgets/match_card.dart';
import 'tabs/home_tab.dart';
import 'tabs/league_tab.dart';
import 'tabs/market_tab.dart';
import 'profile_screen.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  late PageController _pageController;
  int _currentIndex = 0; // Start on HOME tab

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
            const HomeTab(),
            _buildPlaceholderTab("ROSTER"),
            const MarketTab(),
            const LeagueTab(),
            _buildMatchesTab(),
            const ProfileScreen(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildPlaceholderTab(String title) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.construction, color: AppColors.accentCyan, size: 64.w),
          SizedBox(height: 16.h),
          Text(
            "$title TAB",
            style: AppTextStyles.heading.copyWith(color: Colors.white70),
          ),
          SizedBox(height: 8.h),
          Text(
            "Coming Soon",
            style: AppTextStyles.body,
          ),
        ],
      ),
    );
  }

  Widget _buildMatchesTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        _buildDateSelector(),
        Expanded(
          child: ListView(
            children: const [
              MatchCard(
                team1Name: "LIVERPOOL",
                team2Name: "CHELSEA",
                team1Logo: "L",
                team2Logo: "C",
                remainingTime: Duration(hours: 3, minutes: 45, seconds: 17),
                location: "Anfield Stadium",
                isLive: true,
              ),
              MatchCard(
                team1Name: "MAN. UTD",
                team2Name: "MAN. CITY",
                team1Logo: "M",
                team2Logo: "C",
                fixedTime: "8:00 PM",
                location: "Old Trafford",
              ),
              MatchCard(
                team1Name: "MARSEILLE",
                team2Name: "PSG",
                team1Logo: "M",
                team2Logo: "P",
                fixedTime: "OCT 24, 2:45 PM",
                location: "Parc des Princes",
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.all(20.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("UPCOMING", style: AppTextStyles.heading),
              Text("MATCHES", style: AppTextStyles.heading),
            ],
          ),
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20.w),
                  border: Border.all(color: AppColors.textSecondary.withAlpha(50)),
                ),
                child: Row(
                  children: [
                    Text("All Leagues",
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 14.sp)),
                    Icon(Icons.keyboard_arrow_down,
                        color: AppColors.textSecondary, size: 20.w),
                  ],
                ),
              ),
              SizedBox(width: 15.w),
              Icon(Icons.notifications_none,
                  color: AppColors.textSecondary, size: 24.w),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    final dates = ["TODAY", "TOMORROW", "OCT 23", "OCT 24"];
    return SizedBox(
      height: 50.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        itemCount: dates.length,
        itemBuilder: (context, index) {
          final isSelected = index == 0;
          return Container(
            margin: EdgeInsets.only(right: 10.w),
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: isSelected ? Colors.transparent : AppColors.surface,
              borderRadius: BorderRadius.circular(25.w),
              border: Border.all(
                color: isSelected ? AppColors.accentCyan : Colors.transparent,
              ),
            ),
            child: Center(
              child: Text(
                dates[index],
                style: TextStyle(
                  color:
                      isSelected ? AppColors.accentCyan : AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14.sp,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      backgroundColor: AppColors.background,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.accentCyan,
      unselectedItemColor: AppColors.textSecondary,
      currentIndex: _currentIndex,
      onTap: _onNavBarTapped,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: "TEAM"),
        BottomNavigationBarItem(icon: Icon(Icons.emoji_events_outlined), label: "ROSTER"),
        BottomNavigationBarItem(icon: Icon(Icons.sports_soccer), label: "MARKET"),
        BottomNavigationBarItem(icon: Icon(Icons.layers_outlined), label: "LEAGUE"),
        BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: "MATCHES"),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "PROFILE"),
      ],
    );
  }
}
