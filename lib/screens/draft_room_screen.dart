import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/colors.dart';
import '../core/responsive_helper.dart';
import '../services/draft_service.dart';
import '../services/user_service.dart';
import '../widgets/app_dialogs.dart';
import 'mock_draft_screen.dart';

class DraftRoomScreen extends StatefulWidget {
  final String leagueId;

  const DraftRoomScreen({super.key, required this.leagueId});

  @override
  State<DraftRoomScreen> createState() => _DraftRoomScreenState();
}

class _DraftRoomScreenState extends State<DraftRoomScreen> {
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;
  Map<String, String> _userNames = {};
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  Future<String> _getUserName(String uid) async {
    if (_userNames.containsKey(uid)) return _userNames[uid]!;
    final name = await UserService.getUsername(uid);
    setState(() => _userNames[uid] = name);
    return name;
  }

  String _formatClockStream(Timestamp? deadline) {
    if (deadline == null) return "0:00";
    final diff = deadline.toDate().difference(DateTime.now());
    if (diff.inSeconds <= 0) return "0:00";
    final min = diff.inMinutes;
    final sec = (diff.inSeconds % 60).toString().padLeft(2, '0');
    return "$min:$sec";
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveHelper.init(context);
    final draftStream = FirebaseFirestore.instance
        .collection('leagues')
        .doc(widget.leagueId)
        .collection('draft')
        .doc('info')
        .snapshots();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            "DRAFT ROOM",
            style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.w900),
          ),
          bottom: const TabBar(
            indicatorColor: AppColors.gold,
            labelColor: AppColors.gold,
            unselectedLabelColor: Colors.white54,
            tabs: [
              Tab(text: "BOARD"),
              Tab(text: "ROOKIES"),
            ],
          ),
        ),
        body: StreamBuilder<DocumentSnapshot>(
          stream: draftStream,
          builder: (context, snapshot) {
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return _buildEmptyDraft();
            }

            final data = snapshot.data!.data() as Map<String, dynamic>;
            final status = data['status'] as String? ?? 'waiting';
            final draftOrder = List<String>.from(data['draftOrder'] ?? []);
            final currentIndex = data['currentPickIndex'] as int? ?? 0;
            final history = List<dynamic>.from(data['history'] ?? []);
            final deadline = data['pickDeadline'] as Timestamp?;

            bool isComplete = status == 'completed' || currentIndex >= draftOrder.length;
            String onTheClockId = isComplete ? '' : draftOrder[currentIndex];
            bool isMyTurn = onTheClockId == _currentUserId;

            return Column(
              children: [
                _buildDraftHeader(status, onTheClockId, deadline, isMyTurn, isComplete, currentIndex),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildDraftBoard(history),
                      _buildRookiesTab(status, isMyTurn),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyDraft() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory, color: Colors.white24, size: 60.sp),
          SizedBox(height: 16.h),
          Text(
            "DRAFT NOT INITIALIZED",
            style: TextStyle(color: Colors.white54, fontSize: 16.sp, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildDraftHeader(String status, String onClockId, Timestamp? deadline, bool isMyTurn, bool isComplete, int pickNum) {
    if (isComplete) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(16.h),
        color: AppColors.greenGradientEnd.withOpacity(0.2),
        child: Center(
          child: Text(
            "DRAFT COMPLETE",
            style: TextStyle(color: AppColors.gold, fontSize: 18.sp, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }
    
    if (status == 'waiting') {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(16.h),
        color: AppColors.surface,
        child: Center(
          child: Text(
            "WAITING FOR COMMISSIONER TO START",
            style: TextStyle(color: Colors.white54, fontSize: 14.sp, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    // Active
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: isMyTurn ? AppColors.gold.withOpacity(0.15) : AppColors.surface,
        border: Border(bottom: BorderSide(color: isMyTurn ? AppColors.gold : Colors.white10)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "PICK ${pickNum + 1} - ON THE CLOCK:",
                style: TextStyle(color: isMyTurn ? AppColors.gold : Colors.white54, fontSize: 10.sp, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4.h),
              FutureBuilder<String>(
                future: _getUserName(onClockId),
                builder: (context, snap) {
                  return Text(
                    isMyTurn ? "YOUR TURN!" : (snap.data ?? "Loading...").toUpperCase(),
                    style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.w900, letterSpacing: 1.0),
                  );
                }
              ),
            ],
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: isMyTurn ? AppColors.gold : Colors.black45,
              borderRadius: BorderRadius.circular(8.h),
            ),
            child: Text(
              _formatClockStream(deadline),
              style: TextStyle(
                color: isMyTurn ? Colors.black : Colors.white,
                fontSize: 20.sp,
                fontWeight: FontWeight.w900,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDraftBoard(List<dynamic> history) {
    return ListView(
      padding: EdgeInsets.all(16.h),
      children: [
        _buildDraftBoardSetup(),
        SizedBox(height: 16.h),
        if (history.isEmpty)
          Padding(
            padding: EdgeInsets.only(top: 40.h),
            child: Center(
              child: Text(
                "NO PICKS MADE YET",
                style: TextStyle(color: Colors.white54, fontSize: 14.sp, fontWeight: FontWeight.bold),
              ),
            ),
          )
        else
          ...List.generate(history.length, (index) {
            final pick = history[index] as Map<String, dynamic>;
            return GestureDetector(
              onTap: () {
                final userId = pick['userId']?.toString() ?? '';
                _getUserName(userId).then((name) {
                   _showTeamDraftRoster(userId, name, history);
                });
              },
              child: Container(
                margin: EdgeInsets.only(bottom: 12.h),
                padding: EdgeInsets.all(16.h),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12.h),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 40.w,
                      child: Text(
                        "#${pick['pickNumber']}",
                        style: TextStyle(color: AppColors.gold, fontSize: 16.sp, fontWeight: FontWeight.w900),
                      ),
                    ),
                    Container(
                      width: 40.w,
                      height: 40.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle, 
                        color: Colors.white10,
                        border: Border.all(color: Colors.white10),
                      ),
                      child: ClipOval(
                        child: pick['player_id'] != null
                            ? Image.network(
                                "https://sleepercdn.com/content/nfl/players/thumb/${pick['player_id']}.jpg",
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => 
                                    Center(child: Text(pick['position'] ?? '?', style: const TextStyle(color: Colors.white24))),
                              )
                            : Center(
                                child: Text(
                                  pick['position'] ?? '?',
                                  style: TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.bold),
                                ),
                              ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pick['playerName'] ?? 'Unknown',
                            style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.bold),
                          ),
                          FutureBuilder<String>(
                            future: _getUserName(pick['userId']),
                            builder: (context, snap) {
                              return Text(
                                "Selected by ${snap.data ?? '...'}",
                                style: TextStyle(color: Colors.white54, fontSize: 12.sp),
                              );
                            }
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildDraftBoardSetup() {
    const Color brandColor = AppColors.accentCyan;
    
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D1426), // Match image's deep navy background
        borderRadius: BorderRadius.circular(16.h),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.grid_view_rounded, color: Colors.blueAccent.withOpacity(0.5), size: 28.w),
              SizedBox(width: 12.w),
              Text(
                "Draftboard",
                style: TextStyle(color: Colors.white, fontSize: 20.sp, fontWeight: FontWeight.w900),
              ),
              const Spacer(),
              Text(
                "Edit",
                style: TextStyle(color: brandColor, fontSize: 14.sp, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            "Draft time has not been set",
            style: TextStyle(color: Colors.white38, fontSize: 13.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 24.h),
          Row(
            children: [
              // MOCK Button
              Expanded(
                flex: 1,
                child: GestureDetector(
                  onTap: () async {
                    // Fetch league settings to get accurate counts
                    final leagueSnap = await FirebaseFirestore.instance.collection('leagues').doc(widget.leagueId).get();
                    if (leagueSnap.exists) {
                      final lData = leagueSnap.data()!;
                      final teamsCount = lData['maxMembers'] as int? ?? 4;
                      final roundsCount = (lData['settings'] as Map?)?['draftRounds'] as int? ?? 4;
                      _showMockDraftSelection(context, teamsCount, roundsCount);
                    } else {
                      _showMockDraftSelection(context, 4, 4); // Fallback
                    }
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    height: 48.h,
                    decoration: BoxDecoration(
                      color: brandColor,
                      borderRadius: BorderRadius.circular(24.h),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      "MOCK",
                      style: TextStyle(color: const Color(0xFF0D1426), fontSize: 14.sp, fontWeight: FontWeight.w900, letterSpacing: 1.0),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              // SET TIME Button
              Expanded(
                flex: 2,
                child: Container(
                  height: 48.h,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24.h),
                    border: Border.all(color: brandColor, width: 2),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Center(
                          child: Text(
                            "SET TIME",
                            style: TextStyle(color: brandColor, fontSize: 14.sp, fontWeight: FontWeight.w900, letterSpacing: 1.0),
                          ),
                        ),
                      ),
                      Container(
                        width: 48.w,
                        height: 48.h,
                        decoration: BoxDecoration(
                          border: Border(left: BorderSide(color: brandColor, width: 2)),
                        ),
                        child: Icon(Icons.grid_view_rounded, color: brandColor, size: 20.w),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRookiesTab(String status, bool isMyTurn) {
    if (status != 'active') {
      return Center(
        child: Text(
          "DRAFT IS NOT ACTIVE",
          style: TextStyle(color: Colors.white54, fontSize: 14.sp, fontWeight: FontWeight.bold),
        ),
      );
    }

    final query = FirebaseFirestore.instance
        .collection('leagues')
        .doc(widget.leagueId)
        .collection('draft')
        .doc('info')
        .collection('availableRookies')
        .orderBy('sps', descending: true);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: AppColors.gold));

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return Center(
            child: Text(
              "NO ROOKIES AVAILABLE",
              style: TextStyle(color: Colors.white54, fontSize: 14.sp, fontWeight: FontWeight.bold),
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16.h),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final rc = docs[index].data() as Map<String, dynamic>;
            final sps = (rc['sps'] as num).toDouble();
            
            return Container(
              margin: EdgeInsets.only(bottom: 12.h),
              padding: EdgeInsets.all(16.h),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12.h),
              ),
              child: Row(
                children: [
                  Container(
                    width: 45.w,
                    height: 45.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle, 
                      color: Colors.white10,
                      border: Border.all(color: Colors.white10),
                    ),
                    child: ClipOval(
                      child: rc['player_id'] != null
                          ? Image.network(
                              "https://sleepercdn.com/content/nfl/players/thumb/${rc['player_id']}.jpg",
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => 
                                  Center(child: Text(rc['position'] ?? '?', style: const TextStyle(color: Colors.white24))),
                            )
                          : Center(
                              child: Text(
                                rc['position'] ?? '?',
                                style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.bold),
                              ),
                            ),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rc['name'] ?? 'Unknown',
                          style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.w900),
                        ),
                        SizedBox(height: 4.h),
                        Row(
                          children: [
                            Text("SPS: ", style: TextStyle(color: Colors.white54, fontSize: 12.sp)),
                            Text(sps.toStringAsFixed(1), style: TextStyle(color: AppColors.greenGradientStart, fontSize: 12.sp, fontWeight: FontWeight.bold)),
                            Text(" | Age: ${rc['age']}", style: TextStyle(color: Colors.white54, fontSize: 12.sp)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (isMyTurn)
                    GestureDetector(
                      onTap: () => _handleDraftPlayer(rc['id'], rc['name']),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                        decoration: BoxDecoration(
                          color: AppColors.gold,
                          borderRadius: BorderRadius.circular(8.h),
                        ),
                        child: Text(
                          "DRAFT",
                          style: TextStyle(color: Colors.black, fontSize: 12.sp, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showTeamDraftRoster(String userId, String teamName, List<dynamic> history) {
    // 1. Filter picks for this specific user
    final teamPicks = history.where((pick) => pick['userId'] == userId).toList();
    
    // 2. Define roster slots (matching mockup image exactly)
    final List<String> starterSlots = [
      'QB', 'RB', 'RB', 'WR', 'WR', 'TE', 'WRT', 'WRT', 'K', 'DEF'
    ];
    
    // 3. Map players to slots
    final List<Map<String, dynamic>?> mappedStarters = List.filled(starterSlots.length, null);
    final List<Map<String, dynamic>> benchPlayers = [];
    
    final List<Map<String, dynamic>> unassigned = List.from(teamPicks);
    
    for (int i = 0; i < starterSlots.length; i++) {
      final slot = starterSlots[i];
      for (int j = 0; j < unassigned.length; j++) {
        final p = unassigned[j];
        final pPos = p['position']?.toString().toUpperCase() ?? '';
        final isFlex = pPos == 'RB' || pPos == 'WR' || pPos == 'TE';
        
        if (slot == pPos || (slot == 'WRT' && isFlex)) {
          mappedStarters[i] = p;
          unassigned.removeAt(j);
          break;
        }
      }
    }
    benchPlayers.addAll(unassigned.cast<Map<String, dynamic>>());

    showGeneralDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.9),
      barrierDismissible: false,
      pageBuilder: (context, _, __) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Column(
            children: [
              // Header Row
              Padding(
                padding: EdgeInsets.only(top: 60.h, left: 24.w, right: 24.w, bottom: 20.h),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Icon(Icons.close_rounded, color: Colors.white38, size: 28.w),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          teamName.toUpperCase(),
                          style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.w900, letterSpacing: 1.0),
                        ),
                      ),
                    ),
                    SizedBox(width: 28.w), // Balance for center
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  children: [
                    // Starters Section
                    Row(
                      children: [
                        Text("Starters", style: TextStyle(color: Colors.white54, fontSize: 14.sp, fontWeight: FontWeight.bold)),
                        SizedBox(width: 8.w),
                        Icon(Icons.launch_rounded, color: Colors.white24, size: 14.w),
                      ],
                    ),
                    SizedBox(height: 24.h),
                    ...List.generate(starterSlots.length, (i) {
                      return _buildRosterSlot(starterSlots[i], mappedStarters[i]);
                    }),
                    
                    SizedBox(height: 32.h),
                    
                    // Bench Section
                    Text("Bench", style: TextStyle(color: Colors.white54, fontSize: 14.sp, fontWeight: FontWeight.bold)),
                    SizedBox(height: 24.h),
                    _buildRosterSlot("BN", benchPlayers.isNotEmpty ? benchPlayers[0] : null),
                    // If more than 1 bench player, list them too
                    ...List.generate(benchPlayers.length > 1 ? benchPlayers.length - 1 : 0, (i) {
                       return _buildRosterSlot("BN", benchPlayers[i+1]);
                    }),
                    SizedBox(height: 40.h),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRosterSlot(String slot, Map<String, dynamic>? player) {
    final bool isEmpty = player == null;
    final String label = player?['playerName'] ?? 'Empty';
    
    return Padding(
      padding: EdgeInsets.only(bottom: 24.h),
      child: Row(
        children: [
          Container(
            width: 36.w,
            height: 24.h,
            decoration: BoxDecoration(
              color: _getPosColor(slot).withOpacity(0.15),
              borderRadius: BorderRadius.circular(6.h),
            ),
            alignment: Alignment.center,
            child: Text(
              slot,
              style: TextStyle(
                color: _getPosColor(slot),
                fontSize: 9.sp,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ),
          SizedBox(width: 24.w),
          Text(
            label,
            style: TextStyle(
              color: isEmpty ? Colors.white24 : Colors.white,
              fontSize: 16.sp,
              fontWeight: isEmpty ? FontWeight.w600 : FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getPosColor(String pos) {
    switch (pos.toUpperCase()) {
      case 'QB': return const Color(0xFFFF4B4B);
      case 'RB': return const Color(0xFF00D7FF);
      case 'WR': return const Color(0xFF3498DB);
      case 'TE': return const Color(0xFFFF9F43);
      case 'K': return const Color(0xFF2ECC71);
      case 'DEF': return const Color(0xFFBDC3C7);
      case 'WRT': return const Color(0xFF9B59B6);
      default: return Colors.white38;
    }
  }

  Future<void> _handleDraftPlayer(String playerId, String playerName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text("Draft $playerName?", style: const TextStyle(color: Colors.white)),
        content: const Text("This pick is final and you cannot undo it.", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("CANCEL", style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("DRAFT", style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await DraftService.draftPlayer(widget.leagueId, playerId);
        if (mounted) {
          AppDialogs.showSuccessDialog(
            context,
            title: "PLAYER DRAFTED",
            message: "Successfully drafted $playerName!",
          );
        }
      } catch (e) {
        if (mounted) {
          AppDialogs.showPremiumErrorDialog(context, message: e.toString());
        }
      }
    }
  }
  void _showMockDraftSelection(BuildContext context, int teamsCount, int roundsCount) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "MockDrafts",
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            height: MediaQuery.of(context).size.height * 0.85,
            width: double.infinity,
            decoration: const BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
            ),
            child: Material(
              color: Colors.transparent,
              child: Column(
                children: [
                  // Gradient Header
                  Container(
                    height: 280.h,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF3F51B5), // Indigo
                          Color(0xFF1A237E), // Deep Indigo
                          Color(0xFF0A0F14), // Back to Black
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          top: 20.h,
                          left: 20.w,
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Icon(Icons.close, color: Colors.white, size: 28.w),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.fromLTRB(30.w, 70.h, 30.w, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Mock Drafts",
                                style: TextStyle(color: Colors.white, fontSize: 32.sp, fontWeight: FontWeight.w900),
                              ),
                              SizedBox(height: 12.h),
                              SizedBox(
                                width: 180.w,
                                child: Text(
                                  "Practice drafting with your league's settings",
                                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 16.sp, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          right: 10.w,
                          top: 40.h,
                          child: Icon(
                            Icons.smart_toy_rounded, 
                            color: Colors.white.withOpacity(0.9), 
                            size: 160.w,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // Start Button
                  Padding(
                    padding: EdgeInsets.all(30.w),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MockDraftScreen(
                              leagueId: widget.leagueId,
                              teamsCount: teamsCount,
                              roundsCount: roundsCount,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30.h),
                          border: Border.all(color: Colors.indigoAccent.shade100.withOpacity(0.5), width: 2),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.sports_football, color: AppColors.accentCyan, size: 24.w),
                            SizedBox(width: 12.w),
                            Text(
                              "START MOCK DRAFT",
                              style: TextStyle(
                                color: Colors.white, 
                                fontSize: 16.sp, 
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(anim1),
          child: child,
        );
      },
    );
  }
}
