import 'package:flutter/material.dart';
import 'dart:math';
import '../core/colors.dart';
import '../core/responsive_helper.dart';
import '../services/sleeper_service.dart';
import '../services/user_service.dart';
import '../services/mock_draft_service.dart';
import '../widgets/app_dialogs.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:typed_data';

class MockDraftScreen extends StatefulWidget {
  final String leagueId;
  final int userSlot;
  final int teamsCount;
  final int roundsCount;

  const MockDraftScreen({
    super.key, 
    required this.leagueId, 
    this.userSlot = 1,
    this.teamsCount = 12,
    this.roundsCount = 15,
  });

  @override
  State<MockDraftScreen> createState() => _MockDraftScreenState();
}

class _MockDraftScreenState extends State<MockDraftScreen> {
  bool _isLoadingPlayers = true;
  List<Map<String, dynamic>> _allPlayers = [];
  List<Map<String, dynamic>> _filteredPlayers = [];
  String _selectedPosition = 'ALL';
  String _searchQuery = '';
  bool _isPaneExpanded = false;
  
  // Mock Draft State
  int _currentPick = 1;
  int _selectedTeamTabSlotIndex = 0;
  List<Map<String, dynamic>> _picks = [];

  // Chat State
  final TextEditingController _chatController = TextEditingController();
  late Stream<QuerySnapshot> _chatStream;
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  String _currentUserName = 'User';

  // Audio Recording & Playback State
  late AudioRecorder _audioRecorder;
  late AudioPlayer _audioPlayer;
  bool _isRecording = false;
  bool _isSending = false;
  bool _isSendingText = false;
  int _recordDuration = 0;
  Timer? _recordTimer;
  String? _playingMessageId;
  PlayerState _playerState = PlayerState.stopped;
  Duration _playPosition = Duration.zero;
  Duration _playDuration = Duration.zero;
  
  // Queue State
  List<Map<String, dynamic>> _queuedPlayers = [];
  bool _isAutoPickEnabled = false;
  bool _isDrafting = false;
  late int _userSlot;
  bool _isDraftStarted = false;
  bool _isDraftSaved = false;

  @override
  void initState() {
    super.initState();
    _userSlot = widget.userSlot;
    _initializePicks();
    _loadPlayers();
    _initializeChat();
    _initializeAudio();
    
    // Load user profile for chat display
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      UserService.getUserProfile(uid).then((profile) {
        if (profile != null && mounted) {
          setState(() {
            _currentUserName = profile['username'] ?? profile['fullName'] ?? 'User';
          });
        }
      });
    }
  }

  void _initializeAudio() {
    _audioRecorder = AudioRecorder();
    _audioPlayer = AudioPlayer();

    // Listen to player state changes
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _playerState = state);
    });

    _audioPlayer.onPositionChanged.listen((pos) {
      if (mounted) setState(() => _playPosition = pos);
    });

    _audioPlayer.onDurationChanged.listen((dur) {
      if (mounted) setState(() => _playDuration = dur);
    });
  }

  Future<void> _startRecording() async {
    try {
      // Use permission_handler for explicit request
      final status = await Permission.microphone.request();
      
      if (status.isGranted) {
        // Ensure recorder is initialized and not currently recording
        if (await _audioRecorder.isRecording()) return;

        // Vibrate or provide haptic feedback
        HapticFeedback.heavyImpact();

        final dir = await getTemporaryDirectory();
        final path = p.join(dir.path, 'audio_${DateTime.now().millisecondsSinceEpoch}.m4a');
        
        await _audioRecorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: path);
        
        setState(() {
          _isRecording = true;
          _recordDuration = 0;
        });
        
        _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() => _recordDuration++);
        });
      } else if (status.isPermanentlyDenied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Microphone permission permanently denied. Enable it in settings.")),
        );
        openAppSettings();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Microphone permission required to record voice notes.")),
        );
      }
    } catch (e) {
      print("Recording error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to start recording: $e")),
      );
      _resetRecordingState();
    }
  }

  void _resetRecordingState() {
    _recordTimer?.cancel();
    setState(() {
      _isRecording = false;
      _recordDuration = 0;
    });
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;

    try {
      final path = await _audioRecorder.stop();
      _recordTimer?.cancel();
      
      HapticFeedback.mediumImpact();

      // Check for minimum duration (at least 1 second or 500ms)
      if (_recordDuration < 1 && path != null) {
          final file = File(path);
          if (file.existsSync()) file.delete();
          setState(() {
            _isRecording = false;
            _recordDuration = 0;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Recording too short"), duration: Duration(seconds: 1)),
          );
          return;
      }

      setState(() {
        _isRecording = false;
        _isSending = true;
        _recordDuration = 0;
      });
      
      if (path != null) {
        final file = File(path);
        if (!file.existsSync()) {
            setState(() => _isSending = false);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Audio file not found.")));
            return;
        }

        // Small delay to ensure file is closed
        await Future.delayed(const Duration(milliseconds: 200));

        // Read file bytes and convert to Base64
        final bytes = await file.readAsBytes();
        
        // Firestore document limit is 1MB. Base64 is ~1.33x larger.
        // We check if the data is well within the limit (around 800KB to be safe).
        if (bytes.length > 800000) {
          throw "Recording is too long for the free tier. Please keep it under 60 seconds.";
        }

        final String base64Audio = base64Encode(bytes);
        debugPrint("Voice note encoded. Base64 length: ${base64Audio.length}");
            
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Processing voice note..."), duration: Duration(seconds: 1)),
        );
        
        await _sendMessage(text: "Voice Note", type: 'voice', voiceData: base64Audio, localPath: path);
        
        if (mounted) {
          setState(() => _isSending = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Voice note sent successfully!")),
          );
        }
      } else {
        debugPrint("Recording path was null");
        setState(() => _isSending = false);
      }
    } catch (e) {
      debugPrint("Stop recording error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Upload failed: $e")),
      );
      setState(() => _isSending = false);
      _resetRecordingState();
    }
  }

  void _playVoiceMessage(String? localPath, String? remoteUrl, String? voiceData, String messageId) async {
    if (localPath == null && remoteUrl == null && voiceData == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Voice message unreadable")));
      return;
    }
    
    if (_playingMessageId == messageId && _playerState == PlayerState.playing) {
       await _audioPlayer.pause();
       return;
    }

    try {
      bool playedLocal = false;
      if (localPath != null) {
        final file = File(localPath);
        if (file.existsSync()) {
            if (_playingMessageId != messageId) {
                await _audioPlayer.stop();
                setState(() {
                _playingMessageId = messageId;
                _playPosition = Duration.zero;
                _playDuration = Duration.zero;
                });
            }
            await _audioPlayer.setVolume(1.0);
            await _audioPlayer.play(DeviceFileSource(localPath));
          playedLocal = true;
        }
      }
      
      bool playedData = false;
      if (!playedLocal && voiceData != null && voiceData.isNotEmpty) {
          if (_playingMessageId != messageId) {
                await _audioPlayer.stop();
                setState(() {
                _playingMessageId = messageId;
                _playPosition = Duration.zero;
                _playDuration = Duration.zero;
                });
            }
            final bytes = base64Decode(voiceData);
            await _audioPlayer.setVolume(1.0);
            await _audioPlayer.play(BytesSource(bytes));
            playedData = true;
      }

      if (!playedLocal && !playedData && remoteUrl != null && remoteUrl.isNotEmpty) {
        if (_playingMessageId != messageId) {
          await _audioPlayer.stop();
          setState(() {
            _playingMessageId = messageId;
            _playPosition = Duration.zero;
            _playDuration = Duration.zero;
          });
        }
        await _audioPlayer.setVolume(1.0);
        await _audioPlayer.play(UrlSource(remoteUrl));
      }
      
    } catch (e) {
      debugPrint("Error playing voice message: $e");
    }
  }

  void _initializeChat() {
    _chatStream = FirebaseFirestore.instance
        .collection('leagues')
        .doc(widget.leagueId)
        .collection('mock_draft_messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
    
    // Fetch user name for attribution
    UserService.getUserProfile(_currentUserId).then((profile) {
      if (mounted && profile != null) {
        setState(() => _currentUserName = profile['username'] ?? 'User');
      }
    });
  }

  @override
  void dispose() {
    _chatController.dispose();
    _recordTimer?.cancel();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _initializePicks() {
    _picks = List.generate(widget.roundsCount * widget.teamsCount, (index) {
      int round = (index ~/ widget.teamsCount) + 1;
      int pickInRound = (index % widget.teamsCount) + 1;
      return {
        'id': "${round}.${pickInRound}",
        'round': round,
        'pick': pickInRound,
        'overall': index + 1,
        'player': null,
        'teamName': "TEAM ${pickInRound}",
        'isClaimed': false,
      };
    });
  }

  Future<void> _loadPlayers() async {
    try {
      final players = await SleeperService.fetchAllNflPlayers();
      if (mounted) {
        setState(() {
          _allPlayers = players;
          _filteredPlayers = players;
          _isLoadingPlayers = false;
        });
      }
    } catch (e) {
        AppDialogs.showPremiumErrorDialog(context, message: "Failed to load players for mock draft.");
    }
  }

  void _filterPlayers() {
    setState(() {
      _filteredPlayers = _allPlayers.where((p) {
        final matchesPos = _selectedPosition == 'ALL' || p['pos'] == _selectedPosition;
        final matchesSearch = p['name'].toLowerCase().contains(_searchQuery.toLowerCase());
        return matchesPos && matchesSearch;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveHelper.init(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) => SizeTransition(sizeFactor: animation, child: child),
              child: _isPaneExpanded ? const SizedBox.shrink() : _buildInviteBanner(),
            ),
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                      constraints: BoxConstraints(minHeight: 120.h),
                      child: _buildDraftBoardGrid(),
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    height: _isPaneExpanded 
                        ? MediaQuery.of(context).size.height * 0.7 
                        : 260.h,
                    child: _buildPlayerScoutingPane(),
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
    // Safety check for end of draft
    final isDraftComplete = _currentPick > _picks.length;
    final safePickIndex = isDraftComplete ? _picks.length - 1 : _currentPick - 1;
    
    final currentPickData = _picks[safePickIndex];
    final currentSlot = (safePickIndex % widget.teamsCount) + 1;
    final currentRound = (safePickIndex ~/ widget.teamsCount) + 1;
    final actualSlot = (currentRound % 2 == 1) 
        ? currentSlot 
        : (widget.teamsCount - currentSlot + 1);

    String statusText;
    if (isDraftComplete) {
      statusText = "DRAFT COMPLETE";
    } else if (_isYourTurn()) {
      statusText = "YOUR TURN";
    } else {
      statusText = "TEAM $actualSlot IS PICKING...";
    }

    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 40.h, 20.w, 20.h),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1426),
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 24.w),
          ),
          Column(
            children: [
              if (!_isDraftStarted) 
                GestureDetector(
                  onTap: () {
                    setState(() => _isDraftStarted = true);
                    if (!_isYourTurn()) {
                      _simulateOpponentPicks();
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: AppColors.accentCyan,
                      borderRadius: BorderRadius.circular(20.r),
                      boxShadow: [
                        BoxShadow(color: AppColors.accentCyan.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.play_arrow_rounded, color: Colors.black, size: 18.w),
                        SizedBox(width: 4.w),
                        Text(
                          "START MOCK DRAFT",
                          style: TextStyle(color: Colors.black, fontSize: 10.sp, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                Text(
                  "PICK ${currentPickData['id']}",
                  style: TextStyle(color: AppColors.accentCyan, fontSize: 18.sp, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                ),
                Text(
                  statusText,
                  style: TextStyle(
                    color: _isYourTurn() ? AppColors.accentCyan : Colors.white38, 
                    fontSize: 10.sp, 
                    fontWeight: FontWeight.bold, 
                    letterSpacing: 1.2
                  ),
                ),
              ],
            ],
          ),
          SizedBox(width: 24.w),
        ],
      ),
    );
  }

  Widget _buildInviteBanner() {
    return Container(
      margin: EdgeInsets.all(16.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12.h),
      ),
      child: Row(
        children: [
          Icon(Icons.smart_toy_rounded, color: Colors.blueAccent.withOpacity(0.7), size: 32.w),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Invite friends", style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.bold)),
                Text("Mock draft together", style: TextStyle(color: Colors.white54, fontSize: 13.sp)),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: AppColors.accentCyan,
              borderRadius: BorderRadius.circular(20.h),
            ),
            child: Text("INVITE", style: TextStyle(color: const Color(0xFF0D1426), fontSize: 12.sp, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  Widget _buildDraftBoardGrid() {
    final double slotWidth = 70.w;
    final double spacing = 8.w;

    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 16.h),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. CLAIM Header Row
            Row(
              children: List.generate(widget.teamsCount, (teamIndex) {
                return Container(
                  width: slotWidth,
                  margin: EdgeInsets.only(right: spacing, bottom: 8.h),
                  padding: EdgeInsets.symmetric(vertical: 6.h),
                  decoration: BoxDecoration(
                    color: AppColors.accentCyan,
                    borderRadius: BorderRadius.circular(10.h),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    "CLAIM", 
                    style: TextStyle(color: const Color(0xFF0D1426), fontSize: 10.sp, fontWeight: FontWeight.w900, letterSpacing: 1.0)
                  ),
                );
              }),
            ),
            
            // 2. Draft Pick Matrix (Rows = Rounds)
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Column(
                  children: List.generate(widget.roundsCount, (roundIndex) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: 12.h),
                      child: Row(
                        children: List.generate(widget.teamsCount, (teamIndex) {
                          final int pickIndex = (roundIndex * widget.teamsCount) + teamIndex;
                          final pick = _picks[pickIndex];
                          return Container(
                            width: slotWidth,
                            margin: EdgeInsets.only(right: spacing),
                            child: _buildGridSlot(pick),
                          );
                        }),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridSlot(Map<String, dynamic> pick) {
    final bool hasPlayer = pick['player'] != null;
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 400),
      tween: Tween<double>(begin: 0.8, end: 1.0),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: hasPlayer ? value : 1.0,
          child: Container(
            height: 60.h,
            decoration: BoxDecoration(
              color: hasPlayer ? _getPositionColor(pick['player']['pos']).withOpacity(0.12) : const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(8.h),
              border: Border.all(
                color: hasPlayer 
                    ? _getPositionColor(pick['player']['pos']).withOpacity(0.6) 
                    : (_currentPick.toString() == pick['id'].split('.').join('') 
                        ? AppColors.accentCyan 
                        : Colors.white10),
                width: hasPlayer || (_currentPick.toString() == pick['id'].split('.').join('')) ? 1.5 : 1,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 4.h,
                  right: 4.w,
                  child: Text(pick['id'], style: TextStyle(color: Colors.white24, fontSize: 8.sp, fontWeight: FontWeight.bold)),
                ),
                if (hasPlayer)
                   Center(
                     child: AnimatedOpacity(
                       duration: const Duration(milliseconds: 300),
                       opacity: 1.0,
                       child: Column(
                         mainAxisAlignment: MainAxisAlignment.center,
                         children: [
                           ClipRRect(
                             borderRadius: BorderRadius.circular(15.r),
                             child: CachedNetworkImage(
                               imageUrl: 'https://sleepercdn.com/content/nfl/players/thumb/${pick['player']['player_id']}.jpg',
                               width: 28.w,
                               height: 28.w,
                             ),
                           ),
                           SizedBox(height: 2.h),
                           Padding(
                             padding: EdgeInsets.symmetric(horizontal: 2.w),
                             child: Text(
                               pick['player']['name'].split(' ').last,
                               maxLines: 1,
                               overflow: TextOverflow.ellipsis,
                               style: TextStyle(color: Colors.white, fontSize: 8.sp, fontWeight: FontWeight.bold),
                             ),
                           ),
                         ],
                       ),
                     ),
                   )
                else
                   const Center(child: Icon(Icons.arrow_forward_rounded, color: Colors.white10, size: 16)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlayerScoutingPane() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D1426), // Match image's deep navy background
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20, spreadRadius: 5),
        ],
      ),
      child: DefaultTabController(
        length: 4,
        child: Column(
          children: [
            // Toggle Handle & Arrow
            GestureDetector(
              onTap: () => setState(() => _isPaneExpanded = !_isPaneExpanded),
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 8.h),
                child: Column(
                  children: [
                    Container(
                      width: 40.w,
                      height: 4.h,
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(2.h),
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Icon(
                      _isPaneExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                      color: AppColors.accentCyan,
                      size: 24.w,
                    ),
                  ],
                ),
              ),
            ),
            TabBar(
              isScrollable: false,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white38,
              dividerColor: Colors.transparent,
              labelStyle: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w900, letterSpacing: 1.2),
              tabs: const [
                Tab(text: 'PLAYERS'),
                Tab(text: 'QUEUE'),
                Tab(text: 'TEAM'),
                Tab(text: 'CHAT'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildPlayersTabContent(),
                  _buildQueueTabContent(),
                  _buildTeamTabContent(),
                  _buildChatTabContent(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayersTabContent() {
    return Column(
      children: [
        _buildScoutFilters(),
        Expanded(
          child: _isLoadingPlayers 
            ? const Center(child: CircularProgressIndicator(color: AppColors.accentCyan))
            : ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                itemCount: _filteredPlayers.length,
                itemBuilder: (context, index) {
                  return _buildPlayerListItem(_filteredPlayers[index]);
                },
              ),
        ),
      ],
    );
  }

  Widget _buildQueueTabContent() {
    return Column(
      children: [
        // Auto-pick Header
        Padding(
          padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 8.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(Icons.info_outline, color: Colors.white24, size: 16.w),
              SizedBox(width: 8.w),
              Text(
                "Auto-pick",
                style: TextStyle(color: Colors.white54, fontSize: 13.sp, fontWeight: FontWeight.w500),
              ),
              SizedBox(width: 8.w),
              Transform.scale(
                scale: 0.8,
                child: Switch(
                  value: _isAutoPickEnabled,
                  onChanged: (val) => setState(() => _isAutoPickEnabled = val),
                  activeColor: AppColors.accentCyan,
                  activeTrackColor: AppColors.accentCyan.withOpacity(0.2),
                  inactiveThumbColor: Colors.white24,
                  inactiveTrackColor: Colors.white10,
                ),
              ),
            ],
          ),
        ),
        
        Expanded(
          child: _queuedPlayers.isEmpty 
              ? _buildEmptyQueueState()
              : ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                  itemCount: _queuedPlayers.length,
                  itemBuilder: (context, index) {
                    final player = _queuedPlayers[index];
                    return _buildQueuedPlayerItem(player);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyQueueState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration Box (Matching screenshot's stylized icons)
          Container(
            width: 280.w,
            padding: EdgeInsets.all(32.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.05),
                  Colors.white.withOpacity(0.02),
                ],
              ),
              borderRadius: BorderRadius.circular(30.r),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Column(
              children: [
                // Stylized Document+ Icon
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 100.w,
                      height: 100.w,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.02),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const Opacity(
                      opacity: 0.1,
                      child: Icon(Icons.description, size: 60, color: Colors.white),
                    ),
                    Positioned(
                       bottom: 5,
                       right: 5,
                       child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: AppColors.accentCyan,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: AppColors.accentCyan, blurRadius: 10, spreadRadius: -2)],
                        ),
                        child: const Icon(Icons.add_rounded, size: 30, color: Color(0xFF0D1426)),
                       ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 32.h),
          Text(
            "Draft queue is empty",
            style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 12.h),
          Text(
            "Speed up the draft by adding players to\nyour queue from the players tab",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white38, fontSize: 13.sp, fontWeight: FontWeight.w500, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildQueuedPlayerItem(Map<String, dynamic> player) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          // Player Photo
          ClipRRect(
            borderRadius: BorderRadius.circular(25.r),
            child: CachedNetworkImage(
              imageUrl: player['imageUrl'] ?? 'https://sleepercdn.com/content/nfl/players/thumb/${player['player_id']}.jpg',
              width: 40.w,
              height: 40.w,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(color: Colors.white10),
              errorWidget: (context, url, error) => Container(
                color: Colors.white10,
                child: const Icon(Icons.person, color: Colors.white24),
              ),
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(player['name'], style: TextStyle(color: Colors.white, fontSize: 15.sp, fontWeight: FontWeight.bold)),
                Text(player['pos'], style: TextStyle(color: Colors.white38, fontSize: 12.sp)),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _toggleQueue(player),
            icon: const Icon(Icons.remove_circle_outline, color: Colors.white24),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamTabContent() {
    return Column(
      children: [
        _buildTeamSlotSelector(),
        Expanded(child: _buildRosterList()),
      ],
    );
  }

  Widget _buildChatTabContent() {
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _chatStream,
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return _buildEmptyChatState();
              }
              
              final messages = snapshot.data!.docs;
              return Column(
                children: [
                  if (_isRecording)
                    _buildRecordingBanner(),
                  Expanded(
                    child: ListView.builder(
                      padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 10.h),
                      reverse: true, // Show most recent at bottom
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final doc = messages[index];
                        final data = doc.data() as Map<String, dynamic>;
                        return _buildMessageBubble(data, doc.id);
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        _buildChatInputBar(),
      ],
    );
  }



  void _toggleQueue(Map<String, dynamic> player) {
    if (player['isDrafted'] == true) return;
    
    setState(() {
      final isQueued = _queuedPlayers.any((p) => p['player_id'] == player['player_id']);
      if (isQueued) {
        _queuedPlayers.removeWhere((p) => p['player_id'] == player['player_id']);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${player['name']} removed from queue"), duration: const Duration(seconds: 1)),
        );
      } else {
        _queuedPlayers.add(player);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${player['name']} added to queue"), duration: const Duration(seconds: 1)),
        );
      }
    });

    // If it's your turn and you just added to queue, check auto-pick
    if (_isAutoPickEnabled && _isYourTurn()) {
      _checkAutoPick();
    }
  }

  bool _isYourTurn() {
    if (_currentPick > _picks.length) return false;
    return _picks[_currentPick - 1]['slot'] == _userSlot;
  }

  Future<void> _draftPlayer(Map<String, dynamic> player) async {
    if (_isDrafting || _currentPick > _picks.length) return;
    if (player['isDrafted'] == true) return;

    setState(() {
      _isDrafting = true;
      
      // Update Pick
      _picks[_currentPick - 1]['player'] = player;
      
      // Mark player as drafted
      final playerIndex = _allPlayers.indexWhere((p) => p['player_id'] == player['player_id']);
      if (playerIndex != -1) {
        _allPlayers[playerIndex]['isDrafted'] = true;
      }
      
      // Remove from queue
      _queuedPlayers.removeWhere((p) => p['player_id'] == player['player_id']);
      
      _currentPick++;
      _isDrafting = false;
    });

    // Check if it's an opponent's turn and the draft has started
    if (_isDraftStarted && _currentPick <= _picks.length && !_isYourTurn()) {
      _simulateOpponentPicks();
    } else if (_isYourTurn() && _isAutoPickEnabled) {
      _checkAutoPick();
    }

    // Save mock draft if completed
    if (_currentPick > _picks.length && !_isDraftSaved) {
      _isDraftSaved = true;
      MockDraftService.saveMockDraft(
        leagueId: widget.leagueId,
        picks: _picks,
        userSlot: widget.userSlot,
        teamsCount: widget.teamsCount,
        roundsCount: widget.roundsCount,
      );
    }
  }

  Future<void> _simulateOpponentPicks() async {
    while (_currentPick <= _picks.length && !_isYourTurn()) {
      // Simulate "thinking" time
      await Future.delayed(const Duration(milliseconds: 1400));
      if (!mounted) return;

      // Smarter AI: Pick from the top available players with some variance
      final availablePlayers = _allPlayers.where((p) => p['isDrafted'] != true).toList();
      if (availablePlayers.isNotEmpty) {
        // Decide between top players (85% top player, 10% second, 5% third)
        final rand = Random().nextDouble();
        int pickIdx = 0;
        if (rand > 0.85 && availablePlayers.length > 1) pickIdx = 1;
        if (rand > 0.95 && availablePlayers.length > 2) pickIdx = 2;
        
        await _draftPlayer(availablePlayers[pickIdx]);
      } else {
        break;
      }
    }

    // Save if draft is now complete (all rounds done, no more user turns)
    if (_currentPick > _picks.length && !_isDraftSaved && mounted) {
      _isDraftSaved = true;
      MockDraftService.saveMockDraft(
        leagueId: widget.leagueId,
        picks: _picks,
        userSlot: widget.userSlot,
        teamsCount: widget.teamsCount,
        roundsCount: widget.roundsCount,
      );
    }
  }

  void _checkAutoPick() {
    if (!_isAutoPickEnabled || !_isYourTurn()) return;

    Map<String, dynamic>? playerToPick;
    
    if (_queuedPlayers.isNotEmpty) {
      playerToPick = _queuedPlayers.first;
    } else {
      // Pick best available if enabled but queue is empty? 
      // Usually Auto-pick only drafts from queue. 
      // We'll only draft if queue has someone.
    }

    if (playerToPick != null) {
      _draftPlayer(playerToPick);
    }
  }

  Widget _buildEmptyChatState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(40.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Ready... Set...",
              style: TextStyle(color: Colors.white, fontSize: 24.sp, fontWeight: FontWeight.w900),
            ),
            SizedBox(height: 12.h),
            Text(
              "This is the beginning of the chat room.\nType something to kick it off!",
              style: TextStyle(color: Colors.white54, fontSize: 16.sp, fontWeight: FontWeight.w500, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildMessageBubble(Map<String, dynamic> data, String messageId) {
    bool isMe = data['senderId'] == _currentUserId;
    final type = data['type'] ?? 'text';
    
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.symmetric(
          horizontal: (type == 'voice' || type == 'pick_share') ? 12.w : 16.w, 
          vertical: type == 'image' ? 4.h : 10.h
        ),
        decoration: BoxDecoration(
          color: isMe ? AppColors.accentCyan.withOpacity(0.15) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16.h),
          border: Border.all(color: isMe ? AppColors.accentCyan.withOpacity(0.2) : Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isMe)
              Text(
                data['senderName'] ?? "Guest",
                style: TextStyle(color: AppColors.accentCyan.withOpacity(0.8), fontSize: 10.sp, fontWeight: FontWeight.bold),
              ),
            if (type == 'voice')
              _buildVoiceMessageBubble(data, messageId)
            else if (type != 'text')
              const Text("[Feature removed]", style: TextStyle(color: Colors.white24, fontSize: 12, fontStyle: FontStyle.italic))
            else
              Text(
                data['text'] ?? "",
                style: TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.normal, height: 1.4),
              ),
          ],
        ),
      ),
    );
  }



  Widget _buildChatInputBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 24.h),
      decoration: const BoxDecoration(
        color: Color(0xFF0D1426),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Press and hold to record a voice note"),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            onLongPress: _startRecording,
            onLongPressUp: _stopRecording,
            child: Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: _isRecording ? Colors.red.withOpacity(0.1) : Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
                border: Border.all(color: _isRecording ? Colors.red.withOpacity(0.3) : Colors.white10),
              ),
              child: _isSending 
                  ? SizedBox(
                      width: 20.w,
                      height: 20.w,
                      child: const CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentCyan),
                    )
                  : Icon(_isRecording ? Icons.mic : Icons.mic_none, color: _isRecording ? Colors.red : Colors.white54, size: 20.w),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(24.h),
                border: Border.all(color: Colors.white10),
              ),
              child: TextField(
                controller: _chatController,
                style: TextStyle(color: Colors.white, fontSize: 14.sp),
                decoration: const InputDecoration(
                  hintText: "Start chatting",
                  hintStyle: TextStyle(color: Colors.white24),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          GestureDetector(
            onTap: _isSendingText ? null : () => _sendMessage(),
            child: Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: AppColors.accentCyan.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.accentCyan.withOpacity(0.3)),
              ),
              child: _isSendingText 
                  ? SizedBox(
                      width: 20.w,
                      height: 20.w,
                      child: const CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentCyan),
                    )
                  : Icon(Icons.send, color: AppColors.accentCyan, size: 20.w),
            ),
          ),
        ],
      ),
    );
  }



  Future<void> _sendMessage({
    String? text, 
    String type = 'text',
    String? voiceUrl,
    String? voiceData,
    String? localPath,
  }) async {
    final messageText = text ?? _chatController.text.trim();
    if (type == 'text' && messageText.isEmpty) return;
    
    // Get fresh user ID every time to ensure we aren't blocked by a stale state
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid ?? '';
    
    if (type == 'text') {
      _chatController.clear();
      setState(() => _isSendingText = true);
    }
    
    try {
      final String lid = widget.leagueId.trim();
      debugPrint("Sending message to league: $lid");

      if (lid.isEmpty) {
        throw "League ID is missing";
      }

      if (uid.isEmpty) {
        throw "Not logged in. Check your connection.";
      }

      // We remove the timeout on Firestore .add()!
      // Firestore has its own robust offline queuing and retry mechanism.
      // Blocking it with our own timeout can actually prevent it from syncing.
      final docRef = await FirebaseFirestore.instance
          .collection('leagues')
          .doc(lid)
          .collection('mock_draft_messages')
          .add({
            'text': messageText,
            'type': type,
            'voiceUrl': voiceUrl,
            'voiceData': voiceData,
            'localPath': localPath,
            'senderId': uid,
            'senderName': _currentUserName,
            'timestamp': FieldValue.serverTimestamp(),
          });
      
      debugPrint("Message sent with ID: ${docRef.id}");
      if (type == 'text') setState(() => _isSendingText = false);
    } catch (e) {
      debugPrint("Send message error details: $e");
      setState(() {
        if (type == 'text') _isSendingText = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to send: $e"),
          action: SnackBarAction(label: "Retry", onPressed: () => _sendMessage(text: messageText, type: type, voiceUrl: voiceUrl, localPath: localPath)),
        ),
      );
    }
  }

  Widget _buildRecordingBanner() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      color: Colors.red.withOpacity(0.1),
      child: Row(
        children: [
          Icon(Icons.mic, color: Colors.red, size: 16.w),
          SizedBox(width: 8.w),
          Text(
            "Recording... ${_recordDuration}s",
            style: TextStyle(color: Colors.red, fontSize: 13.sp, fontWeight: FontWeight.w900),
          ),
          const Spacer(),
          Text(
            "RELEASE TO SEND",
            style: TextStyle(color: Colors.white, fontSize: 10.sp, fontWeight: FontWeight.w900, letterSpacing: 1),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceMessageBubble(Map<String, dynamic> data, String messageId) {
    final isMe = data['senderId'] == _currentUserId;
    final isPlaying = _playingMessageId == messageId && _playerState == PlayerState.playing;
    
    return Container(
      width: 200.w,
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _playVoiceMessage(data['localPath'], data['voiceUrl'], data['voiceData'], messageId),
            child: Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: isMe ? AppColors.accentCyan.withOpacity(0.2) : Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPlaying ? Icons.pause : Icons.play_arrow,
                color: isMe ? AppColors.accentCyan : Colors.white,
                size: 20.w,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 3.h,
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: isPlaying
                      ? FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: _playDuration.inMilliseconds > 0 
                              ? _playPosition.inMilliseconds / _playDuration.inMilliseconds 
                              : 0.0,
                          child: Container(color: isMe ? AppColors.accentCyan : Colors.white),
                        )
                      : const SizedBox.shrink(),
                ),
                SizedBox(height: 4.h),
                Text(
                  "Voice Note",
                  style: TextStyle(color: Colors.white54, fontSize: 10.sp),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamSlotSelector() {
    return Container(
      height: 44.h,
      margin: EdgeInsets.symmetric(vertical: 8.h),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: widget.teamsCount,
        itemBuilder: (context, index) {
          final isSelected = _selectedTeamTabSlotIndex == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedTeamTabSlotIndex = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(right: 8.w),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20.h),
                border: isSelected ? null : Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  Icon(Icons.shield_outlined, color: isSelected ? Colors.black : AppColors.accentCyan, size: 14.w),
                  SizedBox(width: 8.w),
                  Text(
                    "Slot ${index + 1}",
                    style: TextStyle(
                      color: isSelected ? Colors.black : Colors.white70,
                      fontSize: 11.sp,
                      fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
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

  Widget _buildRosterList() {
    final positions = _getRosterPositions(widget.roundsCount);
    
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 10.h),
      itemCount: positions.length,
      itemBuilder: (context, index) {
        final pos = positions[index];
        final targetSlot = _selectedTeamTabSlotIndex + 1;
        
        // Find if this specific team drafted a player at this round/position
        // We find the pick by looking for the slot and sorting by pick order
        final teamPicks = _picks.where((p) => p['slot'] == targetSlot && p['player'] != null).toList();
        
        Map<String, dynamic>? player;
        if (index < teamPicks.length) {
          player = teamPicks[index]['player'];
        }
        
        return _buildRosterSlot(pos, player);
      },
    );
  }

  List<String> _getRosterPositions(int rounds) {
    const List<String> standardOrder = ['QB', 'RB', 'RB', 'WR', 'WR', 'TE', 'WRT', 'WRT', 'WRT'];
    List<String> positions = [];
    for (int i = 0; i < rounds; i++) {
      if (i < standardOrder.length) {
        positions.add(standardOrder[i]);
      } else {
        positions.add('BN');
      }
    }
    return positions;
  }

  Widget _buildRosterSlot(String pos, Map<String, dynamic>? player) {
    final color = _getPositionColor(pos);
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      child: Row(
        children: [
          // Position Badge
          Container(
            width: 44.w,
            height: 32.h,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8.h),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            alignment: Alignment.center,
            child: Text(
              pos,
              style: TextStyle(
                color: color,
                fontSize: 10.sp,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          SizedBox(width: 16.w),
          Text(
            player != null ? player['name'].toString().toUpperCase() : "Empty",
            style: TextStyle(
              color: player != null ? Colors.white : Colors.white24,
              fontSize: 16.sp,
              fontWeight: player != null ? FontWeight.w900 : FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getPositionColor(String pos) {
    switch (pos) {
      case 'QB': return const Color(0xFFFF5C8D); // Pink
      case 'RB': return const Color(0xFF00FFBB); // Teal/Green
      case 'WR': return const Color(0xFF5AB9FF); // Blue
      case 'TE': return const Color(0xFFFFB55E); // Orange
      case 'WRT': return const Color(0xFF8B9EB7); // Muted Blue/Gray
      default: return Colors.white10;
    }
  }

  Widget _buildScoutFilters() {
    final positions = ['ALL', 'QB', 'RB', 'WR', 'TE', 'K'];
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16.h),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Row(
          children: [
            // Search Icon
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: const BoxDecoration(color: Color(0xFF1E293B), shape: BoxShape.circle),
              child: Icon(Icons.search, color: Colors.white, size: 20.w),
            ),
            SizedBox(width: 12.w),
            ...positions.map((pos) => GestureDetector(
              onTap: () {
                setState(() => _selectedPosition = pos);
                _filterPlayers();
              },
              child: Container(
                margin: EdgeInsets.only(right: 12.w),
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: _selectedPosition == pos ? Colors.white : const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(24.h),
                ),
                child: Column(
                  children: [
                    Text(pos, style: TextStyle(color: _selectedPosition == pos ? Colors.black : Colors.white70, fontSize: 13.sp, fontWeight: FontWeight.w900)),
                    Text("0/3", style: TextStyle(color: _selectedPosition == pos ? Colors.black38 : Colors.white24, fontSize: 9.sp, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerListItem(Map<String, dynamic> player) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left Column: DRAFT Button + Photo
          Column(
            children: [
              GestureDetector(
                onTap: _isYourTurn() && player['isDrafted'] != true 
                    ? () => _draftPlayer(player) 
                    : null,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: _isYourTurn() && player['isDrafted'] != true 
                      ? AppColors.brandDark 
                      : Colors.white10,
                    borderRadius: BorderRadius.circular(16.h),
                    border: _isYourTurn() && player['isDrafted'] != true 
                        ? Border.all(color: AppColors.accentCyan, width: 1) 
                        : null,
                  ),
                  child: Text(
                    player['isDrafted'] == true ? "DRAFTED" : "DRAFT", 
                    style: TextStyle(
                      color: _isYourTurn() && player['isDrafted'] != true 
                          ? AppColors.accentCyan 
                          : Colors.white38, 
                      fontSize: 10.sp, 
                      fontWeight: FontWeight.w900
                    )
                  ),
                ),
              ),
              SizedBox(height: 8.h),
              ClipRRect(
                borderRadius: BorderRadius.circular(20.r),
                child: CachedNetworkImage(
                  imageUrl: player['imageUrl'] ?? 'https://sleepercdn.com/content/nfl/players/thumb/${player['player_id']}.jpg',
                  width: 36.w,
                  height: 36.w,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(color: Colors.white10),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.white10,
                    child: const Icon(Icons.person, color: Colors.white24),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(width: 12.w),
          Text(
            "16", // Rank placeholder
            style: TextStyle(color: Colors.white24, fontSize: 14.sp, fontWeight: FontWeight.w900),
          ),
          SizedBox(width: 12.w),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(player['name'], style: TextStyle(color: Colors.white, fontSize: 15.sp, fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    Container(width: 6.w, height: 6.w, decoration: const BoxDecoration(color: Color(0xFF00FF88), shape: BoxShape.circle)),
                    SizedBox(width: 4.w),
                    Text(player['pos'], style: TextStyle(color: Colors.white38, fontSize: 11.sp, fontWeight: FontWeight.bold)),
                    SizedBox(width: 6.w),
                    Icon(Icons.auto_awesome, color: Colors.purpleAccent, size: 12.w),
                  ],
                ),
              ],
            ),
          ),
          
          // Queue Button (The only one)
          GestureDetector(
            onTap: () => _toggleQueue(player),
            child: Container(
              padding: EdgeInsets.all(8.w),
              margin: EdgeInsets.only(right: 8.w),
              decoration: BoxDecoration(
                color: _queuedPlayers.any((p) => p['player_id'] == player['player_id']) 
                    ? AppColors.accentCyan.withOpacity(0.1) 
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(
                _queuedPlayers.any((p) => p['player_id'] == player['player_id']) 
                    ? Icons.note_add 
                    : Icons.note_add_outlined, 
                color: _queuedPlayers.any((p) => p['player_id'] == player['player_id']) 
                    ? AppColors.accentCyan 
                    : Colors.white38, 
                size: 24.w
              ),
            ),
          ),

          SizedBox(width: 16.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text("ADP", style: TextStyle(color: Colors.white24, fontSize: 9.sp, fontWeight: FontWeight.bold)),
              Text("16.3", style: TextStyle(color: Colors.white, fontSize: 13.sp, fontWeight: FontWeight.w900)),
            ],
          ),
          SizedBox(width: 12.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text("PTS", style: TextStyle(color: Colors.white24, fontSize: 9.sp, fontWeight: FontWeight.bold)),
              Text("249", style: TextStyle(color: Colors.white, fontSize: 13.sp, fontWeight: FontWeight.w900)),
            ],
          ),
        ],
      ),
    );
  }
}
