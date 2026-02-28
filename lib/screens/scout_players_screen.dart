import 'package:flutter/material.dart';
import '../core/colors.dart';
import '../core/responsive_helper.dart';

class ScoutPlayersScreen extends StatefulWidget {
  const ScoutPlayersScreen({super.key});

  @override
  State<ScoutPlayersScreen> createState() => _ScoutPlayersScreenState();
}

class _ScoutPlayersScreenState extends State<ScoutPlayersScreen> {
  final TextEditingController _searchController = TextEditingController();
  
  // Mock data for demonstration
  final List<Map<String, String>> _allPlayers = [
    {"name": "Patrick Mahomes", "team": "KC", "pos": "QB", "adp": "1.2", "sps": "99", "grade": "A+", "isDrafted": "true"},
    {"name": "Justin Jefferson", "team": "MIN", "pos": "WR", "adp": "2.1", "sps": "98", "grade": "A+", "isDrafted": "true"},
    {"name": "Christian McCaffrey", "team": "SF", "pos": "RB", "adp": "3.5", "sps": "97", "grade": "A", "isDrafted": "true"},
    {"name": "Tyreek Hill", "team": "MIA", "pos": "WR", "adp": "4.8", "sps": "96", "grade": "A", "isDrafted": "true"},
    {"name": "Travis Kelce", "team": "KC", "pos": "TE", "adp": "6.2", "sps": "95", "grade": "A-", "isDrafted": "true"},
    {"name": "Josh Allen", "team": "BUF", "pos": "QB", "adp": "7.5", "sps": "94", "grade": "A-", "isDrafted": "true"},
    {"name": "Breece Hall", "team": "NYJ", "pos": "RB", "adp": "9.1", "sps": "92", "grade": "B+", "isDrafted": "false"},
    {"name": "Garrett Wilson", "team": "NYJ", "pos": "WR", "adp": "11.4", "sps": "90", "grade": "B", "isDrafted": "false"},
  ];

  late List<Map<String, String>> _filteredPlayers;

  @override
  void initState() {
    super.initState();
    _filteredPlayers = _allPlayers;
  }

  void _onSearchChanged(String query) {
    setState(() {
      _filteredPlayers = _allPlayers
          .where((p) => p['name']!.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
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
          "SCOUT PLAYERS",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildTableHeader(),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredPlayers.length,
              itemBuilder: (context, index) => _buildPlayerRow(_filteredPlayers[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.all(20.w),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16.h),
          border: Border.all(color: Colors.white10),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "Search players...",
            hintStyle: TextStyle(color: Colors.white38, fontSize: 14.sp),
            prefixIcon: Icon(Icons.search, color: AppColors.accentCyan, size: 20.w),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 14.h),
          ),
        ),
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          Expanded(flex: 8, child: Text("PLAYER", style: _headerStyle)),
          Expanded(flex: 2, child: Center(child: Text("POS", style: _headerStyle))),
          Expanded(flex: 2, child: Center(child: Text("ADP", style: _headerStyle))),
          Expanded(flex: 3, child: Center(child: Text("SPS GRADE", style: _headerStyle))),
          Expanded(flex: 3, child: Center(child: FittedBox(fit: BoxFit.scaleDown, child: Text("ACTION", style: _headerStyle)))),
        ],
      ),
    );
  }

  Widget _buildPlayerRow(Map<String, String> player) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 8,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16.w,
                  backgroundColor: AppColors.accentCyan.withOpacity(0.1),
                  child: Text(
                    player['name']![0],
                    style: TextStyle(color: AppColors.accentCyan, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    player['name']!,
                    style: TextStyle(color: Colors.white, fontSize: 13.sp, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Text(
                player['team']!,
                style: TextStyle(color: Colors.white70, fontSize: 12.sp),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Text(
                player['pos']!,
                style: TextStyle(color: Colors.white70, fontSize: 12.sp, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Text(
                player['adp']!,
                style: TextStyle(color: Colors.white38, fontSize: 12.sp),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Center(
              child: player['isDrafted'] == 'true' 
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        player[' grade'] ?? player['grade']!,
                        style: TextStyle(
                          color: _getGradeColor(player['grade']!),
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        "(${player['sps']} CONF)",
                        style: TextStyle(color: Colors.white24, fontSize: 8.sp, fontWeight: FontWeight.bold),
                      ),
                    ],
                  )
                : Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: AppColors.accentCyan.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.h),
                      border: Border.all(color: AppColors.accentCyan.withOpacity(0.3)),
                    ),
                    child: Text(
                      "PROSPECT",
                      style: TextStyle(color: AppColors.accentCyan, fontSize: 9.sp, fontWeight: FontWeight.bold),
                    ),
                  ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Center(
              child: IconButton(
                icon: Icon(Icons.remove_red_eye_outlined, color: AppColors.accentCyan, size: 20.w),
                onPressed: () {
                  // View player profile logic
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getGradeColor(String grade) {
    if (grade.startsWith('A')) return Colors.greenAccent;
    if (grade.startsWith('B')) return AppColors.accentCyan;
    if (grade.startsWith('C')) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  TextStyle get _headerStyle => TextStyle(
    color: Colors.white38,
    fontSize: 10.sp,
    fontWeight: FontWeight.bold,
    letterSpacing: 1.0,
  );
}