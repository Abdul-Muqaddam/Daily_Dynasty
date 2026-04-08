import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MockDraftService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final String _userId = FirebaseAuth.instance.currentUser?.uid ?? '';

  static Future<void> saveMockDraft({
    required String leagueId,
    required List<Map<String, dynamic>> picks,
    required int userSlot,
    required int teamsCount,
    required int roundsCount,
  }) async {
    if (_userId.isEmpty) return;

    // Extract the top 3 picks for the history preview
    final topPicks = picks
        .where((p) => p['player'] != null)
        .take(3)
        .map((p) => {
              'playerName': p['player']['name'] ?? 'Unknown',
              'pos': p['player']['pos'] ?? '?',
              'pickId': p['id'],
            })
        .toList();

    await _db.collection('mock_drafts').add({
      'userId': _userId,
      'leagueId': leagueId,
      'userSlot': userSlot,
      'teamsCount': teamsCount,
      'roundsCount': roundsCount,
      'topPicks': topPicks,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  static Stream<QuerySnapshot> getRecentMockDrafts(String leagueId) {
    return _db
        .collection('mock_drafts')
        .where('userId', isEqualTo: _userId)
        .where('leagueId', isEqualTo: leagueId)
        .orderBy('timestamp', descending: true)
        .limit(3)
        .snapshots();
  }
}
