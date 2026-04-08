import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'coin_service.dart';

class ScoutingService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Calculates a displayed SPS value based on true SPS and scouting confidence.
  /// Formula: TrueSPS * (1 + (VarianceFactor * (1 - Confidence)))
  /// VarianceFactor is 0.5 (meaning max 50% error at 0% confidence).
  static double calculateEstimatedSps(double trueSps, double confidence, String playerId) {
    if (confidence >= 1.0) return trueSps;

    // Use playerId as seed to ensure the "estimate" is consistent for the same player/user
    // until they scout again (which increases confidence).
    final seed = playerId.hashCode ^ (confidence * 100).toInt();
    final random = math.Random(seed);
    
    // Random value between -1.0 and 1.0
    final factor = (random.nextDouble() * 2) - 1.0;
    
    // Variance narrows as confidence increases
    final maxVariance = 0.5 * (1.0 - confidence);
    final offset = trueSps * (factor * maxVariance);
    
    return double.parse((trueSps + offset).toStringAsFixed(1));
  }

  /// Gets a user's scouting report for a specific player in a league.
  static Future<Map<String, dynamic>> getScoutingReport({
    required String leagueId,
    required String userId,
    required String playerId,
  }) async {
    final reportRef = _db
        .collection('leagues')
        .doc(leagueId)
        .collection('scouting')
        .doc(userId)
        .collection('players')
        .doc(playerId);

    final doc = await reportRef.get();
    if (doc.exists) {
      return doc.data()!;
    } else {
      // Default: 20% confidence for all players initially
      return {
        'confidence': 0.2,
        'lastScoutedAt': FieldValue.serverTimestamp(),
      };
    }
  }

  /// Increases scouting confidence for a player.
  static Future<void> scoutPlayer({
    required String leagueId,
    required String userId,
    required String playerId,
    int cost = 50,
  }) async {
    // 1. Spend Coins
    await CoinService.spendCoins(cost, 'Scouted Player: $playerId');

    // 2. Update/Create Scouting Report
    final reportRef = _db
        .collection('leagues')
        .doc(leagueId)
        .collection('scouting')
        .doc(userId)
        .collection('players')
        .doc(playerId);

    final doc = await reportRef.get();
    double newConfidence = 0.2; // Start at 20%

    if (doc.exists) {
      newConfidence = (doc.data()?['confidence'] ?? 0.2) + 0.2;
    } else {
      newConfidence = 0.4; // First scout jump to 40%
    }

    if (newConfidence > 1.0) newConfidence = 1.0;

    await reportRef.set({
      'confidence': double.parse(newConfidence.toStringAsFixed(1)),
      'lastScoutedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
