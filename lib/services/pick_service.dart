import 'package:cloud_firestore/cloud_firestore.dart';

class PickService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Initializes future draft picks (3 years) for all members in a league.
  static Future<void> initializeFuturePicks(String leagueId, List<String> memberUids) async {
    final batch = _db.batch();
    final currentYear = DateTime.now().year;

    for (final uid in memberUids) {
      for (int y = 1; y <= 3; y++) {
        final year = currentYear + y;
        for (int round = 1; round <= 3; round++) {
          final pickRef = _db
              .collection('leagues')
              .doc(leagueId)
              .collection('picks')
              .doc();
          
          batch.set(pickRef, {
            'id': pickRef.id,
            'year': year,
            'round': round,
            'originalOwnerId': uid,
            'currentOwnerId': uid,
            'leagueId': leagueId,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }
    }
    await batch.commit();
  }

  /// Returns a stream of picks owned by a user in a league.
  static Stream<List<Map<String, dynamic>>> getUserPicksStream(String leagueId, String userId) {
    return _db
        .collection('leagues')
        .doc(leagueId)
        .collection('picks')
        .where('currentOwnerId', isEqualTo: userId)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => doc.data()).toList());
  }

  /// Fetches picks owned by a user (one-time fetch).
  static Future<List<Map<String, dynamic>>> getUserPicks(String leagueId, String userId) async {
    final snap = await _db
        .collection('leagues')
        .doc(leagueId)
        .collection('picks')
        .where('currentOwnerId', isEqualTo: userId)
        .get();

    return snap.docs.map((doc) => doc.data()).toList();
  }
}
