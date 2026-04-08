import 'package:cloud_firestore/cloud_firestore.dart';

class WaiverService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Submits a secret FAAB bid for a free agent player.
  static Future<void> submitBid({
    required String leagueId,
    required String userId,
    required Map<String, dynamic> player,
    required int bidAmount,
  }) async {
    final rosterRef = _db.collection('leagues').doc(leagueId).collection('rosters').doc(userId);
    final snapshot = await rosterRef.get();
    final balance = snapshot.data()?['faabBalance'] ?? 0;

    if (bidAmount > balance) throw Exception('Insufficient FAAB balance');

    final bidRef = _db.collection('leagues').doc(leagueId).collection('waiver_bids').doc('${userId}_${player['id']}');
    await bidRef.set({
      'userId': userId,
      'playerId': player['id'],
      'playerName': player['name'],
      'amount': bidAmount,
      'playerData': player,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  /// Returns a stream of active bids for a specific user in a league.
  static Stream<List<Map<String, dynamic>>> getActiveBidsStream(String leagueId, String userId) {
    return _db
        .collection('leagues')
        .doc(leagueId)
        .collection('waiver_bids')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => doc.data()).toList());
  }

  /// Cancels an existing waiver bid.
  static Future<void> cancelBid(String leagueId, String userId, String playerId) async {
    await _db
        .collection('leagues')
        .doc(leagueId)
        .collection('waiver_bids')
        .doc('${userId}_${playerId}')
        .delete();
  }

  /// Processes all active waiver bids. Awards players to the highest bidders,
  /// deducts FAAB, and logs the transactions.
  static Future<void> processWaivers(String leagueId) async {
    final bidsSnap = await _db.collection('leagues').doc(leagueId).collection('waiver_bids').get();
    if (bidsSnap.docs.isEmpty) return;

    // Group bids by playerId
    final Map<String, List<DocumentSnapshot>> bidsByPlayer = {};
    for (var doc in bidsSnap.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final pid = data['playerId'] as String;
      bidsByPlayer.putIfAbsent(pid, () => []).add(doc);
    }

    // Resolve each player's bidding
    for (var playerId in bidsByPlayer.keys) {
      final playerBids = bidsByPlayer[playerId]!;
      // Sort by amount descending, then by timestamp (earliest bid wins tie)
      playerBids.sort((a, b) {
        final dataA = a.data() as Map<String, dynamic>;
        final dataB = b.data() as Map<String, dynamic>;
        final amtA = dataA['amount'] as int? ?? 0;
        final amtB = dataB['amount'] as int? ?? 0;
        if (amtA != amtB) return amtB.compareTo(amtA);
        
        final tsA = (dataA['timestamp'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
        final tsB = (dataB['timestamp'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
        return tsA.compareTo(tsB);
      });

      final winningBid = playerBids.first;
      final winData = winningBid.data() as Map<String, dynamic>;
      final winnerId = winData['userId'] as String;
      final amount = winData['amount'] as int;
      final playerData = Map<String, dynamic>.from(winData['playerData']);

      await _db.runTransaction((transaction) async {
        final rosterRef = _db.collection('leagues').doc(leagueId).collection('rosters').doc(winnerId);
        final rosterDoc = await transaction.get(rosterRef);
        if (!rosterDoc.exists) return;

        final currentBalance = (rosterDoc.data() as Map<String, dynamic>)['faabBalance'] as int? ?? 0;
        if (currentBalance < amount) return; // Skip if they no longer have the funds

        List<dynamic> players = List.from(rosterDoc.data()?['players'] ?? []);
        playerData['pos'] = 'BN'; // Moves to bench by default
        players.add(playerData);

        // Update Roster
        transaction.update(rosterRef, {
          'players': players,
          'faabBalance': currentBalance - amount,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Log Transaction
        final transRef = _db.collection('leagues').doc(leagueId).collection('transactions').doc();
        transaction.set(transRef, {
          'type': 'waiver',
          'userId': winnerId,
          'playerName': playerData['name'],
          'bidAmount': amount,
          'timestamp': FieldValue.serverTimestamp(),
        });

        // Clear all bids for this specific player
        for (var bid in playerBids) {
          transaction.delete(bid.reference);
        }
      });
    }
  }
}
