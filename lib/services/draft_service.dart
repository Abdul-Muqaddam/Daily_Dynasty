import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DraftService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static final List<String> _firstNames = [
    'James', 'Marcus', 'Elijah', 'Trevor', 'CJ', 'DeMarcus', 'Jalen', 'DaVonta',
    'Trey', 'Caleb', 'Zack', 'Derrick', 'Kyler', 'Lamar', 'Christian', 'DAndre'
  ];

  static final List<String> _lastNames = [
    'Jackson', 'Williams', 'Johnson', 'Smith', 'Carter', 'Fields', 'McCaffrey',
    'Henderson', 'Taylor', 'Moore', 'Brown', 'Davis', 'Miller', 'Wilson'
  ];

  static final List<String> _positions = ['QB', 'RB', 'WR', 'TE', 'K'];

  /// Generates a pool of ~50 rookies and determines the draft order based on final standings (reverse order).
  static Future<void> initializeDraft(String leagueId) async {
    final draftRef = _db.collection('leagues').doc(leagueId).collection('draft').doc('info');
    final rookiesRef = draftRef.collection('availableRookies');
    
    // Check if a draft is already initialized
    final draftDoc = await draftRef.get();
    if (draftDoc.exists) return; // Prevent overwriting 
    
    final leagueDoc = await _db.collection('leagues').doc(leagueId).get();
    final data = leagueDoc.data();
    if (data == null) return;
    
    // Sort draft order: lowest wins first
    Map<String, dynamic> standings = data['standings'] ?? {};
    List<MapEntry<String, dynamic>> records = standings.entries.toList();
    records.sort((a, b) {
      int aWins = a.value['wins'] ?? 0;
      int bWins = b.value['wins'] ?? 0;
      int aLosses = a.value['losses'] ?? 0;
      int bLosses = b.value['losses'] ?? 0;
      
      double aPct = (aWins + aLosses) > 0 ? aWins / (aWins + aLosses) : 0.0;
      double bPct = (bWins + bLosses) > 0 ? bWins / (bWins + bLosses) : 0.0;
      return aPct.compareTo(bPct); // Lowest first
    });
    
    List<String> draftOrder = records.map((e) => e.key).toList();
    // Create a 3-round sequential draft order (Snake or Linear, we go Linear for NFL style)
    List<String> masterDraftOrder = [];
    for (int i = 0; i < 3; i++) {
        masterDraftOrder.addAll(draftOrder);
    }

    // Generate Rookies
    final random = Random();
    int rookiesCount = masterDraftOrder.length + 15; // Extra players to choose from
    
    for (int i = 0; i < rookiesCount; i++) {
      String first = _firstNames[random.nextInt(_firstNames.length)];
      String last = _lastNames[random.nextInt(_lastNames.length)];
      String pos = _positions[random.nextInt(_positions.length)];
      
      // Rookies range from 50 to 80 SPS
      double sps = 50.0 + random.nextDouble() * 30.0;
      
      final playerDoc = rookiesRef.doc();
      await playerDoc.set({
        'id': playerDoc.id,
        'name': '$first $last',
        'position': pos,
        'sps': sps, // Base SPS
        'exp': 0, // Rookie Exp
        'age': 20 + random.nextInt(3),
        'team': 'FA', // Free Agent pool,
        'status': 'active', // Just normal status
        'isRookie': true,
      });
    }

    // Initialize Draft Data
    await draftRef.set({
      'status': 'waiting', // waiting -> scheduled -> active -> completed
      'currentPickIndex': 0,
      'draftOrder': masterDraftOrder,
      'pickDeadline': null, 
      'scheduledStartTime': null, // Can be set via Commissioner HQ
      'history': [], // Ledger of picks
    });
  }

  /// Drafts a player for the currently "On The Clock" user.
  static Future<void> draftPlayer(String leagueId, String playerId) async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    final draftRef = _db.collection('leagues').doc(leagueId).collection('draft').doc('info');
    final playerRef = draftRef.collection('availableRookies').doc(playerId);
    final rosterRef = _db.collection('leagues').doc(leagueId).collection('rosters').doc(user.uid);

    await _db.runTransaction((transaction) async {
      // 1. Read Draft State
      final draftDoc = await transaction.get(draftRef);
      if (!draftDoc.exists) throw Exception('Draft not found');
      final data = draftDoc.data()!;
      if (data['status'] != 'active') throw Exception('Draft is not active');
      
      List<dynamic> draftOrder = data['draftOrder'] ?? [];
      int currentIndex = data['currentPickIndex'] ?? 0;
      
      if (currentIndex >= draftOrder.length) throw Exception('Draft is already complete');
      if (draftOrder[currentIndex] != user.uid) throw Exception('It is not your turn to pick');
      
      // 2. Read Player
      final playerDoc = await transaction.get(playerRef);
      if (!playerDoc.exists) throw Exception('Player not available');
      final playerData = playerDoc.data()!;
      
      // 3. Read Roster
      final rosterDoc = await transaction.get(rosterRef);
      List<dynamic> currentRoster = rosterDoc.data()?['players'] ?? [];
      
      // 4. Update data
      playerData['team'] = user.uid;
      playerData['lineup'] = 'BN'; // Bench by default
      currentRoster.add(playerData);
      
      // Ledger entry
      List<dynamic> history = data['history'] ?? [];
      history.add({
        'userId': user.uid,
        'playerId': playerId,
        'playerName': playerData['name'],
        'position': playerData['position'],
        'pickNumber': currentIndex + 1,
        'timestamp': Timestamp.now(),
      });
      
      // Advance pick
      int nextIndex = currentIndex + 1;
      String newStatus = nextIndex >= draftOrder.length ? 'completed' : 'active';
      
      // 5. Commit mutations
      transaction.delete(playerRef); // Remove from pool
      transaction.update(rosterRef, {'players': currentRoster}); // Add to roster
      transaction.update(draftRef, {
        'currentPickIndex': nextIndex,
        'history': history,
        'status': newStatus,
        'pickDeadline': newStatus == 'active' 
          ? Timestamp.fromDate(DateTime.now().add(const Duration(minutes: 2))) 
          : null,
      });
    });
  }
}
