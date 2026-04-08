import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'sleeper_service.dart';

class PlayerService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Syncs real NFL players from Sleeper to Firestore.
  /// 
  /// Fetches filtered offensive players and performs a batched write
  /// to the global 'players' collection.
  static Future<void> syncSleeperPlayers() async {
    final players = await SleeperService.fetchAllNflPlayers();
    
    // Firestore batch limit is 500 operations.
    for (var i = 0; i < players.length; i += 500) {
      final batch = _db.batch();
      final end = (i + 500 > players.length) ? players.length : i + 500;
      final chunk = players.sublist(i, end);
      
      for (var player in chunk) {
        final playerId = player['player_id'];
        // Use Sleeper's player_id as the document ID to prevent duplicates
        final docRef = _db.collection('players').doc(playerId);
        
        batch.set(docRef, {
          ...player,
          'lastSyncAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      
      await batch.commit();
    }
  }

  /// Fetches all players from the global collection.
  static Future<List<Map<String, dynamic>>> getAllPlayers() async {
    final query = await _db.collection('players').orderBy('name').get();
    return query.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  /// Searches players by name (client-side filtering for now, or prefix search).
  static Future<List<Map<String, dynamic>>> searchPlayers(String query) async {
    if (query.isEmpty) return getAllPlayers();
    
    final searchTerm = query.toUpperCase();
    final snapshot = await _db
        .collection('players')
        .where('name', isGreaterThanOrEqualTo: searchTerm)
        .where('name', isLessThanOrEqualTo: '$searchTerm\uf8ff')
        .get();

    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  /// Seeds initial player data into Firestore. 
  /// Only runs if the collection is empty.
  static Future<void> seedInitialPlayers() async {
    final existing = await _db.collection('players').limit(1).get();
    if (existing.docs.isNotEmpty) return;

    final batch = _db.batch();
    final initialPlayers = [
      {"name": "PATRICK MAHOMES", "team": "KC", "pos": "QB", "adp": "1.2", "sps": "99", "grade": "A+", "isDrafted": true},
      {"name": "JUSTIN JEFFERSON", "team": "MIN", "pos": "WR", "adp": "2.1", "sps": "98", "grade": "A+", "isDrafted": true},
      {"name": "CHRISTIAN MCCAFFREY", "team": "SF", "pos": "RB", "adp": "3.5", "sps": "97", "grade": "A", "isDrafted": true},
      {"name": "TYREEK HILL", "team": "MIA", "pos": "WR", "adp": "4.8", "sps": "96", "grade": "A", "isDrafted": true},
      {"name": "TRAVIS KELCE", "team": "KC", "pos": "TE", "adp": "6.2", "sps": "95", "grade": "A-", "isDrafted": true},
      {"name": "JOSH ALLEN", "team": "BUF", "pos": "QB", "adp": "7.5", "sps": "94", "grade": "A-", "isDrafted": true},
      {"name": "BREECE HALL", "team": "NYJ", "pos": "RB", "adp": "9.1", "sps": "92", "grade": "B+", "isDrafted": false},
      {"name": "GARRETT WILSON", "team": "NYJ", "pos": "WR", "adp": "11.4", "sps": "90", "grade": "B", "isDrafted": false},
      {"name": "LAMAR JACKSON", "team": "BAL", "pos": "QB", "adp": "12.8", "sps": "91", "grade": "B+", "isDrafted": false},
      {"name": "JA'MARR CHASE", "team": "CIN", "pos": "WR", "adp": "13.5", "sps": "93", "grade": "A-", "isDrafted": true},
    ];

    for (var player in initialPlayers) {
      final docRef = _db.collection('players').doc();
      batch.set(docRef, {
        ...player,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  /// Generates a random player with a grade between minGrade and maxGrade.
  static Map<String, dynamic> generateRandomPlayer({
    required String pos,
    int minGrade = 43,
    int maxGrade = 47,
    bool isRookie = false,
  }) {
    final random = math.Random();
    final firstNames = ["James", "John", "Robert", "Michael", "William", "David", "Richard", "Joseph", "Thomas", "Charles", "Christopher", "Daniel", "Matthew", "Anthony", "Mark", "Donald", "Steven", "Paul", "Andrew", "Joshua"];
    final lastNames = ["Smith", "Johnson", "Williams", "Brown", "Jones", "Garcia", "Miller", "Davis", "Rodriguez", "Martinez", "Hernandez", "Lopez", "Gonzalez", "Wilson", "Anderson", "Thomas", "Taylor", "Moore", "Jackson", "Martin"];
    
    final name = "${firstNames[random.nextInt(firstNames.length)]} ${lastNames[random.nextInt(lastNames.length)]}".toUpperCase();
    final grade = minGrade + random.nextInt(maxGrade - minGrade + 1);
    
    return {
      'name': name,
      'pos': pos, // Current roster slot
      'primaryPos': pos, // Inherent position
      'grade': grade.toString(),
      'sps': (grade + random.nextDouble()).toStringAsFixed(1),
      'exp': isRookie ? 'R' : '${random.nextInt(5) + 1}Y',
      'team': 'FA', // Free Agent or placeholder for initial team
      'isDrafted': true,
      'isRookie': isRookie,
      'createdAt': Timestamp.now(),
    };
  }

  /// Generates a full starting roster (33 players total: 9 starters + 18 bench + 4 IR + 2 Taxi)
  static List<Map<String, dynamic>> generateInitialTeam() {
    final roster = <Map<String, dynamic>>[];
    
    // Core Starters (9)
    roster.add(generateRandomPlayer(pos: 'QB'));
    roster.add(generateRandomPlayer(pos: 'RB1'));
    roster.add(generateRandomPlayer(pos: 'RB2'));
    roster.add(generateRandomPlayer(pos: 'WR1'));
    roster.add(generateRandomPlayer(pos: 'WR2'));
    roster.add(generateRandomPlayer(pos: 'WR3'));
    roster.add(generateRandomPlayer(pos: 'TE'));
    roster.add(generateRandomPlayer(pos: 'FLEX')); 
    roster.add(generateRandomPlayer(pos: 'SFLEX'));
    
    // Bench (18)
    for (int i = 0; i < 18; i++) {
      roster.add(generateRandomPlayer(pos: 'BN'));
    }

    // IR (4)
    for (int i = 0; i < 4; i++) {
      roster.add(generateRandomPlayer(pos: 'IR'));
    }
    
    // Taxi (2 rookies)
    roster.add(generateRandomPlayer(pos: 'TAXI', isRookie: true));
    roster.add(generateRandomPlayer(pos: 'TAXI', isRookie: true));
    
    return roster;
  }
}
