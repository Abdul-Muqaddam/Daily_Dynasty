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
      {"name": "JACKSON STORM", "team": "KC", "pos": "QB", "adp": "1.2", "sps": "99", "grade": "A+", "isDrafted": true, "imageUrl": "https://api.dicebear.com/7.x/avataaars/png?seed=JacksonStorm"},
      {"name": "TYRELL BARKLEY", "team": "MIN", "pos": "WR", "adp": "2.1", "sps": "98", "grade": "A+", "isDrafted": true, "imageUrl": "https://api.dicebear.com/7.x/avataaars/png?seed=TyrellBarkley"},
      {"name": "CASH MCCLOUD", "team": "SF", "pos": "RB", "adp": "3.5", "sps": "97", "grade": "A", "isDrafted": true, "imageUrl": "https://api.dicebear.com/7.x/avataaars/png?seed=CashMcCloud"},
      {"name": "DAX THUNDER", "team": "MIA", "pos": "WR", "adp": "4.8", "sps": "96", "grade": "A", "isDrafted": true, "imageUrl": "https://api.dicebear.com/7.x/avataaars/png?seed=DaxThunder"},
      {"name": "BEAR KNIGHT", "team": "KC", "pos": "TE", "adp": "6.2", "sps": "95", "grade": "A-", "isDrafted": true, "imageUrl": "https://api.dicebear.com/7.x/avataaars/png?seed=BearKnight"},
      {"name": "ZANE ROCKET", "team": "BUF", "pos": "QB", "adp": "7.5", "sps": "94", "grade": "A-", "isDrafted": true, "imageUrl": "https://api.dicebear.com/7.x/avataaars/png?seed=ZaneRocket"},
      {"name": "BLAZE BROOKS", "team": "NYJ", "pos": "RB", "adp": "9.1", "sps": "92", "grade": "B+", "isDrafted": false, "imageUrl": "https://api.dicebear.com/7.x/avataaars/png?seed=BlazeBrooks"},
      {"name": "GUNNER WEST", "team": "NYJ", "pos": "WR", "adp": "11.4", "sps": "90", "grade": "B", "isDrafted": false, "imageUrl": "https://api.dicebear.com/7.x/avataaars/png?seed=GunnerWest"},
      {"name": "KINGSTON STEEL", "team": "BAL", "pos": "QB", "adp": "12.8", "sps": "91", "grade": "B+", "isDrafted": false, "imageUrl": "https://api.dicebear.com/7.x/avataaars/png?seed=KingstonSteel"},
      {"name": "JAXON CHASE", "team": "CIN", "pos": "WR", "adp": "13.5", "sps": "93", "grade": "A-", "isDrafted": true, "imageUrl": "https://api.dicebear.com/7.x/avataaars/png?seed=JaxonChase"},
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
    final firstNames = [
      "James", "John", "Robert", "Michael", "William", "David", "Richard", "Joseph", "Thomas", "Charles", 
      "Christopher", "Daniel", "Matthew", "Anthony", "Mark", "Donald", "Steven", "Paul", "Andrew", "Joshua",
      "Kevin", "Brian", "George", "Edward", "Ronald", "Timothy", "Jason", "Jeffrey", "Ryan", "Jacob",
      "Gary", "Nicholas", "Eric", "Jonathan", "Stephen", "Larry", "Justin", "Scott", "Brandon", "Benjamin",
      "Samuel", "Gregory", "Alexander", "Frank", "Patrick", "Raymond", "Jack", "Dennis", "Jerry", "Tyler"
    ];
    final lastNames = [
      "Smith", "Johnson", "Williams", "Brown", "Jones", "Garcia", "Miller", "Davis", "Rodriguez", "Martinez", 
      "Hernandez", "Lopez", "Gonzalez", "Wilson", "Anderson", "Thomas", "Taylor", "Moore", "Jackson", "Martin",
      "Lee", "Perez", "Thompson", "White", "Harris", "Sanchez", "Clark", "Ramirez", "Lewis", "Robinson",
      "Walker", "Young", "Allen", "King", "Wright", "Scott", "Torres", "Nguyen", "Hill", "Flores",
      "Green", "Adams", "Nelson", "Baker", "Hall", "Rivera", "Campbell", "Mitchell", "Carter", "Roberts"
    ];
    
    final firstName = firstNames[random.nextInt(firstNames.length)];
    final lastName = lastNames[random.nextInt(lastNames.length)];
    final name = "$firstName $lastName".toUpperCase();
    final grade = minGrade + random.nextInt(maxGrade - minGrade + 1);
    
    // Use DiceBear for unique fake images
    final imageUrl = "https://api.dicebear.com/7.x/avataaars/png?seed=${firstName}${lastName}${random.nextInt(1000)}";
    
    String primaryPos = pos;
    if (['BN', 'TAXI', 'IR', 'WRT', 'SFLEX', 'FLEX'].contains(pos.toUpperCase())) {
      final possible = ['QB', 'RB', 'RB', 'WR', 'WR', 'WR', 'TE']; // Weighted
      primaryPos = possible[random.nextInt(possible.length)];
    }

    return {
      'playerId': 'fake_${firstName.toLowerCase()}_${lastName.toLowerCase()}_${random.nextInt(10000)}',
      'name': name,
      'imageUrl': imageUrl,
      'pos': pos, // Current roster slot
      'primaryPos': primaryPos, // Inherent position (e.g. QB, RB)
      'grade': grade.toString(),
      'sps': (grade + random.nextDouble()).toStringAsFixed(1),
      'exp': isRookie ? 'R' : '${random.nextInt(12) + 1}Y',
      'team': 'FA', // Free Agent or placeholder for initial team
      'isDrafted': true,
      'isRookie': isRookie,
      'createdAt': Timestamp.now(),
    };
  }

  /// Generates a full starting roster (33 players total: 9 starters + 18 bench + 4 IR + 2 Taxi)
  static List<Map<String, dynamic>> generateInitialTeam({int minGrade = 43, int maxGrade = 47}) {
    final roster = <Map<String, dynamic>>[];
    
    // Core Starters (10)
    roster.add(generateRandomPlayer(pos: 'QB', minGrade: minGrade, maxGrade: maxGrade));
    roster.add(generateRandomPlayer(pos: 'RB', minGrade: minGrade, maxGrade: maxGrade));
    roster.add(generateRandomPlayer(pos: 'RB', minGrade: minGrade, maxGrade: maxGrade));
    roster.add(generateRandomPlayer(pos: 'WR', minGrade: minGrade, maxGrade: maxGrade));
    roster.add(generateRandomPlayer(pos: 'WR', minGrade: minGrade, maxGrade: maxGrade));
    roster.add(generateRandomPlayer(pos: 'WR', minGrade: minGrade, maxGrade: maxGrade));
    roster.add(generateRandomPlayer(pos: 'TE', minGrade: minGrade, maxGrade: maxGrade));
    roster.add(generateRandomPlayer(pos: 'WRT', minGrade: minGrade, maxGrade: maxGrade)); 
    roster.add(generateRandomPlayer(pos: 'SFLEX', minGrade: minGrade, maxGrade: maxGrade));
    roster.add(generateRandomPlayer(pos: 'K', minGrade: minGrade, maxGrade: maxGrade));
    
    // Bench (18)
    for (int i = 0; i < 18; i++) {
      roster.add(generateRandomPlayer(pos: 'BN', minGrade: minGrade, maxGrade: maxGrade));
    }

    // IR (4)
    for (int i = 0; i < 4; i++) {
      roster.add(generateRandomPlayer(pos: 'IR', minGrade: minGrade, maxGrade: maxGrade));
    }
    
    // Taxi (2 rookies)
    roster.add(generateRandomPlayer(pos: 'TAXI', isRookie: true, minGrade: minGrade, maxGrade: maxGrade));
    roster.add(generateRandomPlayer(pos: 'TAXI', isRookie: true, minGrade: minGrade, maxGrade: maxGrade));
    
    return roster;
  }
}
