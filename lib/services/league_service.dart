import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'player_service.dart';
import 'match_engine.dart';
import 'pick_service.dart';

class LeagueService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static const int REGULAR_SEASON_WEEKS = 8;

  static User? get currentUser => _auth.currentUser;

  /// Generates a unique 6-character alphanumeric join code.
  static Future<String> generateJoinCode() async {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = math.Random();
    while (true) {
      final code = String.fromCharCodes(
        List.generate(6, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
      );
      // Check for collision
      final query = await _db
          .collection('leagues')
          .where('joinCode', isEqualTo: code)
          .limit(1)
          .get();
      if (query.docs.isEmpty) return code;
    }
  }

  /// Creates a new league in Firestore and returns the league document ID.
  static Future<String> createLeague({
    required String name,
    required String leagueType,
    required String draftType,
    int maxMembers = 10,
    String scoringType = 'standard',
    bool allowPublicJoin = false,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final joinCode = await generateJoinCode();

    final docRef = await _db.collection('leagues').add({
      'name': name,
      'leagueType': leagueType,
      'draftType': draftType,
      'joinCode': joinCode,
      'createdBy': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
      'draftStatus': 'pending',
      'maxMembers': maxMembers,
      'scoringType': scoringType,
      'members': [user.uid],
      'settings': {
        'allowPublicJoin': allowPublicJoin,
        'tradeDeadline': null,
      },
    });

    await docRef.update({'members': [user.uid]}); // Ensure creator is in members before pick init
    await PickService.initializeFuturePicks(docRef.id, [user.uid]);
    
    // Initialize roster for creator
    await initializeRoster(docRef.id, user.uid);

    return docRef.id;
  }

  /// Sets up the initial Bronze-tier offline league for a new user.
  static Future<String> setupInitialBronzeLeague(String userId) async {
    final leagueCode = await generateJoinCode();
    final leagueName = "BRONZE LEAGUE ${leagueCode.substring(0, 3)}";

    // 1. Create the league document
    final docRef = await _db.collection('leagues').add({
      'name': leagueName,
      'joinCode': leagueCode,
      'createdBy': userId,
      'createdAt': FieldValue.serverTimestamp(),
      'draftStatus': 'completed', // Pre-filled for initial offline league
      'maxMembers': 12,
      'scoringType': 'standard',
      'members': [userId],
      'tier': 'Bronze',
      'isOffline': true,
      'settings': {
        'allowPublicJoin': false,
        'tradeDeadline': null,
      },
    });

    final leagueId = docRef.id;

    // 2. Initialize the user's roster with random players (43-47 grade)
    await initializeRoster(leagueId, userId);

    // 3. Generate 11 bot teams (grades 50-65)
    await _generateBotTeams(leagueId);

    return leagueId;
  }

  /// Generates 11 bot teams for a league.
  static Future<void> _generateBotTeams(String leagueId) async {
    final random = math.Random();
    final botNames = [
      "Steelers Bot", "Comets Bot", "Titans Bot", "Raptors Bot", 
      "Vikings Bot", "Dragons Bot", "Ravens Bot", "Warriors Bot",
      "Lions Bot", "Wolves Bot", "Panthers Bot"
    ];

    final batch = _db.batch();

    for (var i = 0; i < 11; i++) {
      final botId = "bot_${leagueId}_$i";
      final botGrade = 50 + random.nextInt(16); // 50-65

      // Bot User Record
      final userRef = _db.collection('users').doc(botId);
      batch.set(userRef, {
        'username': botNames[i],
        'teamName': botNames[i].toUpperCase(),
        'isBot': true,
        'registrationCompleted': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Add to league members
      batch.update(_db.collection('leagues').doc(leagueId), {
        'members': FieldValue.arrayUnion([botId])
      });

      // Bot Roster (random players 50-65 grade)
      final rosterRef = _db.collection('leagues').doc(leagueId).collection('rosters').doc(botId);
      final botRoster = <Map<String, dynamic>>[];
      // For bots, we can just store the average grade or a simplified roster if full roster isn't needed yet.
      // But let's generate some placeholder players for consistency.
      for (int p = 0; p < 33; p++) {
        botRoster.add(PlayerService.generateRandomPlayer(pos: 'BOT', minGrade: 50, maxGrade: 65));
      }

      batch.set(rosterRef, {
        'players': botRoster,
        'teamGrade': botGrade,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  /// Fetches leagues the current user is a member of (one-time fetch).
  static Future<List<Map<String, dynamic>>> getUserLeagues() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    final query = await _db
        .collection('leagues')
        .where('members', arrayContains: user.uid)
        .orderBy('createdAt', descending: true)
        .get();

    return query.docs
        .map((doc) => {'id': doc.id, ...doc.data()})
        .toList();
  }

  /// Returns a real-time Stream of leagues the current user is a member of.
  static Stream<List<Map<String, dynamic>>> getUserLeaguesStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _db
        .collection('leagues')
        .where('members', arrayContains: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList());
  }

  /// Fetches all public leagues that are not full and still in pending draft state.
  static Future<List<Map<String, dynamic>>> getPublicLeagues() async {
    try {
      final query = await _db
          .collection('leagues')
          .where('settings.allowPublicJoin', isEqualTo: true)
          .where('draftStatus', isEqualTo: 'pending')
          .get();

      final user = _auth.currentUser;
      final results = query.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .where((l) {
            final members = List<String>.from(l['members'] ?? []);
            final maxMembers = l['maxMembers'] as int? ?? 10;
            // Hide if full OR if user is already a member
            return members.length < maxMembers && (user == null || !members.contains(user.uid));
          })
          .toList();

      // Manual sort: newest first
      results.sort((a, b) {
        final dateA = (a['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
        final dateB = (b['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
        return dateB.compareTo(dateA);
      });

      return results;
    } catch (e) {
      print('DEBUG: Error fetching public leagues: $e');
      return [];
    }
  }

  /// Attempts to join a league with a 6-character string.
  static Future<void> joinLeague(String joinCode) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    joinCode = joinCode.trim().toUpperCase();
    if (joinCode.length != 6) throw Exception('Invalid join code length');

    // 1. Find the league by joinCode
    final query = await _db
        .collection('leagues')
        .where('joinCode', isEqualTo: joinCode)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      throw Exception('League not found');
    }

    final docSnap = query.docs.first;
    final leagueData = docSnap.data();
    final leagueId = docSnap.id;
    final maxMembers = leagueData['maxMembers'] as int? ?? 10;
    final members = List<String>.from(leagueData['members'] ?? []);

    // 2. Check conditions
    if (members.contains(user.uid)) {
      throw Exception('You are already a member of this league');
    }
    if (members.length >= maxMembers) {
      throw Exception('This league is full');
    }

    // 3. Add to members array and initialize roster
    await _db.collection('leagues').doc(leagueId).update({
      'members': FieldValue.arrayUnion([user.uid])
    });

    await initializeRoster(leagueId, user.uid);
  }

  /// Join a league by its direct document ID (bypasses join code requirement for public discovery).
  static Future<void> joinLeagueById(String leagueId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final docSnap = await _db.collection('leagues').doc(leagueId).get();
    if (!docSnap.exists) throw Exception('League not found');

    final leagueData = docSnap.data()!;
    final maxMembers = leagueData['maxMembers'] as int? ?? 10;
    final members = List<String>.from(leagueData['members'] ?? []);

    if (members.contains(user.uid)) throw Exception('You are already a member');
    if (members.length >= maxMembers) throw Exception('League is full');

    await _db.collection('leagues').doc(leagueId).update({
      'members': FieldValue.arrayUnion([user.uid])
    });

    await initializeRoster(leagueId, user.uid);
  }

  /// Fetches the user profiles for a list of UIDs.
  static Future<List<Map<String, dynamic>>> getLeagueMembers(List<String> memberUids) async {
    if (memberUids.isEmpty) return [];

    final List<Map<String, dynamic>> members = [];
    final Map<String, Map<String, dynamic>> memberMap = {};

    for (var i = 0; i < memberUids.length; i += 10) {
      final batchUids = memberUids.sublist(i, math.min(i + 10, memberUids.length));
      
      final query = await _db
          .collection('users')
          .where(FieldPath.documentId, whereIn: batchUids)
          .get();
          
      for (var doc in query.docs) {
        memberMap[doc.id] = {'uid': doc.id, ...doc.data()};
      }
    }

    for (var uid in memberUids) {
      if (memberMap.containsKey(uid)) {
        members.add(memberMap[uid]!);
      } else {
        members.add({'uid': uid, 'username': 'Manager ${uid.substring(0, 4)}'});
      }
    }

    members.sort((a, b) => (a['username'] as String? ?? '').compareTo(b['username'] as String? ?? ''));
    
    return members;
  }

  /// Fetches a user's roster within a specific league.
  static Future<List<Map<String, dynamic>>> getUserRoster(String leagueId, String userId) async {
    final doc = await _db
        .collection('leagues')
        .doc(leagueId)
        .collection('rosters')
        .doc(userId)
        .get();

    if (doc.exists) {
      final List<dynamic> players = doc.data()?['players'] ?? [];
      return players.map((p) => Map<String, dynamic>.from(p)).toList();
    }
    return [];
  }

  /// Returns a real-time Stream of a user's roster within a specific league.
  /// Only returns real players (those with a `playerId` field).
  /// Generated mock players (from the old initializeRoster) are automatically
  /// excluded because they were never assigned a real playerId.
  static Stream<List<Map<String, dynamic>>> getRosterStream(String leagueId, String userId) {
    return _db
        .collection('leagues')
        .doc(leagueId)
        .collection('rosters')
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        final List<dynamic> players = doc.data()?['players'] ?? [];
        return players
            .map((p) => Map<String, dynamic>.from(p))
            // Only include real players — generated mock players have no playerId
            .where((p) => p.containsKey('playerId') && p['playerId'] != null)
            .toList();
      }
      return [];
    });
  }

  /// Initializes an empty roster for a user when they join or create a league.
  static Future<void> initializeRoster(String leagueId, String userId) async {
    await _db
        .collection('leagues')
        .doc(leagueId)
        .collection('rosters')
        .doc(userId)
        .set({
      'players': [], // Roster starts empty — players are added via draft/free agency
      'faabBalance': 100,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }


  /// Calculates "Games Out" for a team in a league.
  /// This is the number of wins behind the 1st place team.
  static Future<int> getGamesOut(String leagueId, String userId) async {
    // For now, return a random or mock value unless we have full standings logic
    return 0; 
  }

  /// Resets all temporary boosts for a user's roster (call after a match).
  static Future<void> resetTemporaryBoosts(String leagueId, String userId) async {
    final rosterRef = _db
        .collection('leagues')
        .doc(leagueId)
        .collection('rosters')
        .doc(userId);

    final doc = await rosterRef.get();
    if (!doc.exists) return;

    List<dynamic> roster = List.from(doc.data()?['players'] ?? []);
    bool changed = false;

    for (var i = 0; i < roster.length; i++) {
      Map<String, dynamic> player = Map<String, dynamic>.from(roster[i]);
      if (player.containsKey('tempBoost') && player['tempBoost'] != 0) {
        player['tempBoost'] = 0;
        roster[i] = player;
        changed = true;
      }
    }

    if (changed) {
      await rosterRef.update({'players': roster});
    }
  }

  /// Simulates a full week of matches for a specific league.
  /// This iterates through all members, pairs them up, and updates standings.
  static Future<void> simulateLeagueWeek(String leagueId) async {
    final leagueRef = _db.collection('leagues').doc(leagueId);
    final leagueDoc = await leagueRef.get();
    if (!leagueDoc.exists) throw Exception('League not found');

    final data = leagueDoc.data()!;
    final List<String> members = List<String>.from(data['members'] ?? []);
    final int currentWeek = data['currentWeek'] as int? ?? 1;
    Map<String, dynamic> standings = Map<String, dynamic>.from(data['standings'] ?? {});
    Map<String, dynamic>? playoffs = data['playoffs'] != null ? Map<String, dynamic>.from(data['playoffs']) : null;

    // Check if we are in playoffs
    if (playoffs != null && playoffs['status'] != 'completed') {
      await _simulatePlayoffRound(leagueId, playoffs);
      return;
    }

    if (members.length < 2) throw Exception('Not enough members to simulate');

    // Shuffle members to create random pairings for this week
    final List<String> shuffled = List.from(members)..shuffle();
    final List<Map<String, dynamic>> matchResults = [];

    // Simulate matches for pairs
    for (int i = 0; i < shuffled.length; i += 2) {
      // Handle "Bye" week if odd number of members
      if (i + 1 >= shuffled.length) break;

      final uid1 = shuffled[i];
      final uid2 = shuffled[i + 1];

      // 1. Fetch Rosters
      final roster1 = await getUserRoster(leagueId, uid1);
      final roster2 = await getUserRoster(leagueId, uid2);

      // 2. Simulate Match
      final scores = MatchEngine.simulateMatch(
        team1Roster: roster1,
        team2Roster: roster2,
      );

      final score1 = scores['score1']!;
      final score2 = scores['score2']!;

      // 3. Update Standings Data
      _updateStandings(standings, uid1, score1, score2);
      _updateStandings(standings, uid2, score2, score1);

      // 4. Prep Match Record
      matchResults.add({
        'week': currentWeek,
        'team1': uid1,
        'team2': uid2,
        'score1': score1,
        'score2': score2,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }

    // Write all results to Firestore
    final batch = _db.batch();

    // 1. Update League Document
    batch.update(leagueRef, {
      'currentWeek': currentWeek + 1,
      'standings': standings,
      'lastSimulation': FieldValue.serverTimestamp(),
    });

    // Check if regular season just ended
    if (currentWeek == REGULAR_SEASON_WEEKS) {
      await _initializePlayoffs(leagueId, standings);
    }

    // 2. Add Match Records to subcollection
    for (var result in matchResults) {
      final matchRef = leagueRef.collection('matches').doc();
      batch.set(matchRef, result);
    }

    await batch.commit();

    // 3. Reset all boosts for all members involved
    for (var uid in members) {
      await resetTemporaryBoosts(leagueId, uid);
    }
  }

  /// Helper to update the standings map for a specific user.
  static void _updateStandings(Map<String, dynamic> standings, String uid, double pf, double pa) {
    final s = Map<String, dynamic>.from(standings[uid] ?? {
      'w': 0,
      'l': 0,
      't': 0,
      'pf': 0.0,
      'pa': 0.0,
    });

    if (pf > pa) {
      s['w'] = (s['w'] as int) + 1;
    } else if (pf < pa) {
      s['l'] = (s['l'] as int) + 1;
    } else {
      s['t'] = (s['t'] as int) + 1;
    }

    s['pf'] = (s['pf'] as num).toDouble() + pf;
    s['pa'] = (s['pa'] as num).toDouble() + pa;

    standings[uid] = s;
  }

  /// Selects top 4 teams and creates semifinal matchups.
  static Future<void> _initializePlayoffs(String leagueId, Map<String, dynamic> standings) async {
    final entries = standings.entries.toList();
    entries.sort((a, b) {
      final wA = a.value['w'] as int? ?? 0;
      final wB = b.value['w'] as int? ?? 0;
      if (wA != wB) return wB.compareTo(wA);
      final pfA = (a.value['pf'] as num? ?? 0).toDouble();
      final pfB = (b.value['pf'] as num? ?? 0).toDouble();
      return pfB.compareTo(pfA);
    });

    if (entries.length < 4) return; // Need at least 4 teams for playoffs

    final top4 = entries.take(4).map((e) => e.key).toList();

    final playoffs = {
      'status': 'semifinals',
      'semifinals': [
        {'team1': top4[0], 'team2': top4[3], 'score1': 0.0, 'score2': 0.0, 'winner': null}, // #1 vs #4
        {'team1': top4[1], 'team2': top4[2], 'score1': 0.0, 'score2': 0.0, 'winner': null}, // #2 vs #3
      ],
      'finals': {'team1': null, 'team2': null, 'score1': 0.0, 'score2': 0.0, 'winner': null},
      'champion': null,
    };

    await _db.collection('leagues').doc(leagueId).update({'playoffs': playoffs});
  }

  /// Public wrapper allowing the Commissioner to manually trigger playoff seeding.
  static Future<void> seedPlayoffs(String leagueId) async {
    final doc = await _db.collection('leagues').doc(leagueId).get();
    final standings = Map<String, dynamic>.from(doc.data()?['standings'] ?? {});
    await _initializePlayoffs(leagueId, standings);
  }

  static Future<void> _simulatePlayoffRound(String leagueId, Map<String, dynamic> playoffs) async {
    final status = playoffs['status'];
    final batch = _db.batch();
    final leagueRef = _db.collection('leagues').doc(leagueId);

    if (status == 'semifinals') {
      final semis = List<Map<String, dynamic>>.from(playoffs['semifinals']);
      final winners = <String>[];

      for (var match in semis) {
        final r1 = await getUserRoster(leagueId, match['team1']);
        final r2 = await getUserRoster(leagueId, match['team2']);
        final scores = MatchEngine.simulateMatch(team1Roster: r1, team2Roster: r2);
        
        match['score1'] = scores['score1'];
        match['score2'] = scores['score2'];
        match['winner'] = scores['score1']! > scores['score2']! ? match['team1'] : match['team2'];
        winners.add(match['winner']);
      }

      playoffs['status'] = 'finals';
      playoffs['semifinals'] = semis;
      playoffs['finals'] = {'team1': winners[0], 'team2': winners[1], 'score1': 0.0, 'score2': 0.0, 'winner': null};
    } 
    else if (status == 'finals') {
      final finals = Map<String, dynamic>.from(playoffs['finals']);
      final r1 = await getUserRoster(leagueId, finals['team1']);
      final r2 = await getUserRoster(leagueId, finals['team2']);
      final scores = MatchEngine.simulateMatch(team1Roster: r1, team2Roster: r2);
      
      finals['score1'] = scores['score1'];
      finals['score2'] = scores['score2'];
      finals['winner'] = scores['score1']! > scores['score2']! ? finals['team1'] : finals['team2'];
      
      playoffs['status'] = 'completed';
      playoffs['finals'] = finals;
      playoffs['champion'] = finals['winner'];
    }

    batch.update(leagueRef, {
      'playoffs': playoffs,
      'lastSimulation': FieldValue.serverTimestamp(),
    });

    await batch.commit();

    // Reset boosts for playoff participants
    final participants = <String>{};
    if (status == 'semifinals') {
      for (var m in playoffs['semifinals']) { participants.add(m['team1']); participants.add(m['team2']); }
    } else if (status == 'finals') {
      participants.add(playoffs['finals']['team1']); participants.add(playoffs['finals']['team2']);
    }
    for (var uid in participants) {
      await resetTemporaryBoosts(leagueId, uid);
    }
  }

  /// Swaps positions of two players in a user's roster.
  /// Validates that the new positions are legal for each player.
  static Future<void> swapPlayers(String leagueId, String userId, int index1, int index2) async {
    final rosterRef = _db.collection('leagues').doc(leagueId).collection('rosters').doc(userId);
    final doc = await rosterRef.get();
    if (!doc.exists) throw Exception('Roster not found');

    List<Map<String, dynamic>> players = List<Map<String, dynamic>>.from(
      (doc.data()?['players'] as List? ?? []).map((e) => Map<String, dynamic>.from(e))
    );

    if (index1 < 0 || index1 >= players.length || index2 < 0 || index2 >= players.length) {
      throw Exception('Invalid player indices');
    }

    final p1 = players[index1];
    final p2 = players[index2];

    // 1. Block swaps if either player is in Training
    if (_isPlayerInTraining(p1) || _isPlayerInTraining(p2)) {
      throw Exception('Cannot swap players currently in active training');
    }

    // 2. Perform the swap of the 'pos' field
    final slot1 = p1['pos'] ?? 'BN';
    final slot2 = p2['pos'] ?? 'BN';

    // 3. Validate if p2 can play in slot1 and p1 can play in slot2
    validatePosition(p2, slot1);
    validatePosition(p1, slot2);

    p1['pos'] = slot2;
    p2['pos'] = slot1;

    players[index1] = p1;
    players[index2] = p2;

    await rosterRef.update({
      'players': players,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Moves a player to a specific empty slot (e.g. TAXI, IR, or a starter spot).
  static Future<void> movePlayerToSlot(String leagueId, String userId, int playerIndex, String targetSlot) async {
    final rosterRef = _db.collection('leagues').doc(leagueId).collection('rosters').doc(userId);
    final doc = await rosterRef.get();
    if (!doc.exists) throw Exception('Roster not found');

    List<Map<String, dynamic>> players = List<Map<String, dynamic>>.from(
      (doc.data()?['players'] as List? ?? []).map((e) => Map<String, dynamic>.from(e))
    );

    if (playerIndex < 0 || playerIndex >= players.length) {
      throw Exception('Invalid player index');
    }

    final p = players[playerIndex];

    if (_isPlayerInTraining(p)) {
      throw Exception('Cannot move a player currently in active training');
    }

    // 1. Validate the move
    validatePosition(p, targetSlot);

    // 2. Perform the update
    p['pos'] = targetSlot.toUpperCase();
    players[playerIndex] = p;

    await rosterRef.update({
      'players': players,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Drops a player from a user's roster
  static Future<void> dropPlayer(String leagueId, String userId, String playerId) async {
    final rosterRef = _db.collection('leagues').doc(leagueId).collection('rosters').doc(userId);
    final doc = await rosterRef.get();
    if (!doc.exists) throw Exception('Roster not found');

    List<Map<String, dynamic>> players = List<Map<String, dynamic>>.from(
      (doc.data()?['players'] as List? ?? []).map((e) => Map<String, dynamic>.from(e))
    );

    int index = players.indexWhere((p) => p['id']?.toString() == playerId);
    if (index == -1) throw Exception('Player not found in roster');

    final player = players[index];

    if (_isPlayerInTraining(player)) {
      throw Exception('Cannot drop a player currently in active training');
    }

    players.removeAt(index);

    final batch = _db.batch();
    batch.update(rosterRef, {
      'players': players,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Log Transaction
    final transRef = _db.collection('leagues').doc(leagueId).collection('transactions').doc();
    batch.set(transRef, {
      'type': 'drop',
      'userId': userId,
      'playerName': player['name'],
      'pos': player['pos'],
      'timestamp': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  static bool _isPlayerInTraining(Map<String, dynamic> player) {
    final endTime = player['trainingEndTime'] as Timestamp?;
    if (endTime == null) return false;
    return endTime.toDate().isAfter(DateTime.now());
  }

  /// Ensures a player's primary position and status are compatible with the target roster slot.
  static void validatePosition(Map<String, dynamic> player, String slot) {
    final primaryPos = player['primaryPos'] ?? player['pos'];
    if (primaryPos == null) return; 
    
    final pos = primaryPos.toString().toUpperCase();
    final target = slot.toUpperCase();
    final injuryStatus = player['injury_status']?.toString() ?? '';
    final isRookie = player['isRookie'] == true || player['exp'] == 'R';

    // 1. Bench accepts everyone
    if (target.startsWith('BN')) return;

    // 2. IR Validation
    if (target.startsWith('IR')) {
      final allowed = ['OUT', 'IR', 'DOUBTFUL', 'PUP', 'SUS'];
      if (allowed.contains(injuryStatus.toUpperCase())) return;
      throw Exception('Only players with OUT, IR, or PUP status can be placed on IR.');
    }

    // 3. Taxi Validation
    if (target.startsWith('TAXI')) {
      if (isRookie) return;
      throw Exception('Only rookies can be placed on the Taxi Squad.');
    }

    // 4. Starter Slot Validation
    if (target == 'SFLEX') {
      if (['QB', 'RB', 'WR', 'TE'].contains(pos)) return;
      throw Exception('Only QB, RB, WR, or TE can be placed in SFLEX');
    }

    if (target == 'FLEX') {
      if (['RB', 'WR', 'TE'].contains(pos)) return;
      throw Exception('Only RB, WR, or TE can be placed in FLEX');
    }

    if (target.startsWith(pos)) return;

    throw Exception('A $pos player cannot play in a $target slot');
  }

  /// Ages all players +1 year, retires those 37+, and resets league standings for a new season.
  static Future<void> advanceToNextSeason(String leagueId) async {
    final leagueDoc = await _db.collection('leagues').doc(leagueId).get();
    final members = List<String>.from(leagueDoc.data()?['members'] ?? []);

    for (final uid in members) {
      final rosterRef = _db.collection('leagues').doc(leagueId).collection('rosters').doc(uid);
      final rosterDoc = await rosterRef.get();
      if (!rosterDoc.exists) continue;

      List<dynamic> players = List.from(rosterDoc.data()?['players'] ?? []);
      List<dynamic> updatedPlayers = [];

      for (var p in players) {
        final player = Map<String, dynamic>.from(p);
        final int currentAge = player['age'] ?? 25;
        final newAge = currentAge + 1;

        if (newAge > 36) {
          // Player is retired — record it for the dashboard
          await _db.collection('leagues').doc(leagueId).collection('transactions').add({
            'type': 'retirement',
            'playerName': player['name'] ?? 'Unknown Player',
            'pos': player['pos'] ?? '??',
            'age': newAge,
            'ownerId': uid,
            'timestamp': FieldValue.serverTimestamp(),
          });
          continue;
        }

        player['age'] = newAge;
        // Reset temporary scouting boosts
        player.remove('tempBoost');
        updatedPlayers.add(player);
      }

      await rosterRef.update({'players': updatedPlayers});
    }

    // Reset all standings to 0-0
    final leagueData = leagueDoc.data() ?? {};
    Map<String, dynamic> standings = Map<String, dynamic>.from(leagueData['standings'] ?? {});
    for (final uid in standings.keys) {
      standings[uid] = {'wins': 0, 'losses': 0, 'ties': 0, 'pf': 0.0, 'pa': 0.0};
    }

    await _db.collection('leagues').doc(leagueId).update({
      'standings': standings,
      'seasonNumber': FieldValue.increment(1),
      'playoffState': null,
    });
  }

  /// Updates the league settings in Firestore.
  static Future<void> updateLeagueSettings(String leagueId, Map<String, dynamic> data) async {
    await _db.collection('leagues').doc(leagueId).update(data);
  }

  /// Updates the global database with the latest roster moves from Sleeper.
  static Future<void> syncSleeperPlayers() async {
    await PlayerService.syncSleeperPlayers();
  }
}
