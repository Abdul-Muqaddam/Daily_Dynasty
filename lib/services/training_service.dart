import 'package:cloud_firestore/cloud_firestore.dart';
import 'coin_service.dart';

enum TrainingBadgeType {
  bronze,
  silver,
  gold,
}

class TrainingService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const Map<TrainingBadgeType, Map<String, dynamic>> badgeConfigs = {
    TrainingBadgeType.bronze: {
      'name': 'BRONZE BADGE',
      'boost': 1.5,
      'duration': Duration(hours: 2),
      'skipCost': 50,
    },
    TrainingBadgeType.silver: {
      'name': 'SILVER BADGE',
      'boost': 3.0,
      'duration': Duration(hours: 8),
      'skipCost': 150,
    },
    TrainingBadgeType.gold: {
      'name': 'GOLD BADGE',
      'boost': 6.0,
      'duration': Duration(hours: 24),
      'skipCost': 400,
    },
  };

  /// Starts training for a player in a specific league.
  static Future<void> startTraining({
    required String leagueId,
    required String userId,
    required String playerIndex, // Index in the roster array
    required TrainingBadgeType badgeType,
  }) async {
    if (leagueId.isEmpty || userId.isEmpty) {
      throw Exception('Incomplete path: leagueId=$leagueId, userId=$userId');
    }

    final config = badgeConfigs[badgeType]!;
    final endTime = DateTime.now().add(config['duration'] as Duration);

    final rosterRef = _db
        .collection('leagues')
        .doc(leagueId)
        .collection('rosters')
        .doc(userId);

    final doc = await rosterRef.get();
    if (!doc.exists) throw Exception('Roster not found');

    List<dynamic> roster = List.from(doc.data()?['players'] ?? []);
    int index = int.parse(playerIndex);
    
    if (index < 0 || index >= roster.length) throw Exception('Invalid player index');

    Map<String, dynamic> player = Map<String, dynamic>.from(roster[index]);
    
    // Check if already training
    if (player['trainingEndTime'] != null) {
      final existingEnd = (player['trainingEndTime'] as Timestamp).toDate();
      if (existingEnd.isAfter(DateTime.now())) {
        throw Exception('Player is already training');
      }
    }

    player['trainingStatus'] = 'training';
    player['trainingBadgeType'] = badgeType.toString();
    player['trainingEndTime'] = Timestamp.fromDate(endTime);
    player['pendingBoost'] = config['boost'];

    roster[index] = player;
    await rosterRef.update({'players': roster});
  }

  /// Skips training wait time using coins.
  static Future<void> skipTraining({
    required String leagueId,
    required String userId,
    required String playerIndex,
  }) async {
    final rosterRef = _db
        .collection('leagues')
        .doc(leagueId)
        .collection('rosters')
        .doc(userId);

    final doc = await rosterRef.get();
    List<dynamic> roster = List.from(doc.data()?['players'] ?? []);
    int index = int.parse(playerIndex);
    Map<String, dynamic> player = Map<String, dynamic>.from(roster[index]);

    final badgeTypeStr = player['trainingBadgeType'];
    final badgeType = TrainingBadgeType.values.firstWhere((e) => e.toString() == badgeTypeStr);
    final cost = badgeConfigs[badgeType]!['skipCost'] as int;

    // Deduct coins
    await CoinService.spendCoins(cost, 'Skip Training: ${player['name']}');

    // Complete immediately
    player['trainingEndTime'] = Timestamp.fromDate(DateTime.now());
    roster[index] = player;
    await rosterRef.update({'players': roster});
  }

  /// Claims the rewards for completed training.
  static Future<void> claimTrainingReward({
    required String leagueId,
    required String userId,
    required String playerIndex,
  }) async {
    final rosterRef = _db
        .collection('leagues')
        .doc(leagueId)
        .collection('rosters')
        .doc(userId);

    final doc = await rosterRef.get();
    List<dynamic> roster = List.from(doc.data()?['players'] ?? []);
    int index = int.parse(playerIndex);
    Map<String, dynamic> player = Map<String, dynamic>.from(roster[index]);

    if (player['trainingEndTime'] == null) throw Exception('No training in progress');
    
    final endTime = (player['trainingEndTime'] as Timestamp).toDate();
    if (endTime.isAfter(DateTime.now())) throw Exception('Training not yet complete');

    double boost = (player['pendingBoost'] ?? 0.0).toDouble();
    
    // Applying as temporary boost instead of permanent SPS increase
    player['tempBoost'] = double.parse(boost.toStringAsFixed(1));
    player['trainingStatus'] = 'idle';
    player.remove('trainingEndTime');
    player.remove('trainingBadgeType');
    player.remove('pendingBoost');

    roster[index] = player;
    await rosterRef.update({'players': roster});
  }
}
