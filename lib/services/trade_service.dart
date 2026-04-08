import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TradeService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Proposes a new trade including players and draft picks.
  static Future<void> proposeTrade({
    required String leagueId,
    required String toUid,
    required String fromTeamName,
    required String toTeamName,
    required List<String> offering,
    required List<String> requesting,
    required List<Map<String, dynamic>> offeringFull,
    required List<Map<String, dynamic>> requestingFull,
    List<Map<String, dynamic>> offeringPicks = const [],
    List<Map<String, dynamic>> requestingPicks = const [],
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await _db.collection('trades').add({
      'leagueId': leagueId,
      'fromUid': user.uid,
      'fromTeamName': fromTeamName,
      'toUid': toUid,
      'toTeamName': toTeamName,
      'offering': offering,
      'requesting': requesting,
      'offeringFull': offeringFull,
      'requestingFull': requestingFull,
      'offeringPicks': offeringPicks,
      'requestingPicks': requestingPicks,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Returns a stream of trades involving the current user in a specific league (or all leagues).
  static Stream<List<Map<String, dynamic>>> getTradesStream({String? leagueId}) {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    Query query = _db.collection('trades');
    
    return query
        .where('leagueId', isEqualTo: leagueId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>}).toList());
  }

  /// Updates the status of a trade.
  static Future<void> updateTradeStatus(String tradeId, String status) async {
    await _db.collection('trades').doc(tradeId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Fetches outgoing trades for current user.
  static Stream<List<Map<String, dynamic>>> getOutgoingTradesStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _db.collection('trades')
        .where('fromUid', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>}).toList());
  }

  /// Fetches incoming trades for current user.
  static Stream<List<Map<String, dynamic>>> getIncomingTradesStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _db.collection('trades')
        .where('toUid', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>}).toList());
  }


  /// Accepts a trade and executes the player/pick swap.
  static Future<void> acceptTrade(String tradeId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final tradeRef = _db.collection('trades').doc(tradeId);

    await _db.runTransaction((transaction) async {
      final tradeDoc = await transaction.get(tradeRef);
      if (!tradeDoc.exists) throw Exception('Trade not found');
      
      final data = tradeDoc.data()!;
      if (data['status'] != 'pending') throw Exception('Trade is no longer pending');
      if (data['toUid'] != user.uid) throw Exception('Unauthorized to accept this trade');

      final leagueId = data['leagueId'] as String;
      final fromUid = data['fromUid'] as String;
      final toUid = data['toUid'] as String;
      
      final offeringFull = List<Map<String, dynamic>>.from(data['offeringFull'] ?? []);
      final requestingFull = List<Map<String, dynamic>>.from(data['requestingFull'] ?? []);
      final offeringPicks = List<Map<String, dynamic>>.from(data['offeringPicks'] ?? []);
      final requestingPicks = List<Map<String, dynamic>>.from(data['requestingPicks'] ?? []);

      final fromRosterRef = _db.collection('leagues').doc(leagueId).collection('rosters').doc(fromUid);
      final toRosterRef = _db.collection('leagues').doc(leagueId).collection('rosters').doc(toUid);

      final fromRosterDoc = await transaction.get(fromRosterRef);
      final toRosterDoc = await transaction.get(toRosterRef);

      if (!fromRosterDoc.exists || !toRosterDoc.exists) {
        throw Exception('One of the rosters could not be found');
      }

      List<dynamic> fromPlayers = fromRosterDoc.data()?['players'] ?? [];
      List<dynamic> toPlayers = toRosterDoc.data()?['players'] ?? [];

      // 1. Move Players (Offered by fromUid, Requested by toUid)
      for (var player in offeringFull) {
        int index = fromPlayers.indexWhere((p) => p['id'] == player['id']);
        if (index == -1) throw Exception('${player['name']} is no longer on the sender\'s roster.');
        fromPlayers.removeAt(index);
        player['pos'] = 'BN';
        toPlayers.add(player);
      }

      for (var player in requestingFull) {
        int index = toPlayers.indexWhere((p) => p['id'] == player['id']);
        if (index == -1) throw Exception('${player['name']} is no longer on your roster.');
        toPlayers.removeAt(index);
        player['pos'] = 'BN';
        fromPlayers.add(player);
      }

      // 2. Move Picks (Offered by fromUid, Requested by toUid)
      for (var pick in offeringPicks) {
        final pickRef = _db.collection('leagues').doc(leagueId).collection('picks').doc(pick['id']);
        transaction.update(pickRef, {'currentOwnerId': toUid, 'updatedAt': FieldValue.serverTimestamp()});
      }
      for (var pick in requestingPicks) {
        final pickRef = _db.collection('leagues').doc(leagueId).collection('picks').doc(pick['id']);
        transaction.update(pickRef, {'currentOwnerId': fromUid, 'updatedAt': FieldValue.serverTimestamp()});
      }

      // Update rosters
      transaction.update(fromRosterRef, {'players': fromPlayers, 'updatedAt': FieldValue.serverTimestamp()});
      transaction.update(toRosterRef, {'players': toPlayers, 'updatedAt': FieldValue.serverTimestamp()});

      // Update trade status
      transaction.update(tradeRef, {
        'status': 'accepted',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Log Transaction
      final transRef = _db.collection('leagues').doc(leagueId).collection('transactions').doc();
      transaction.set(transRef, {
        'type': 'trade',
        'fromUid': fromUid,
        'toUid': toUid,
        'offeringPlayers': offeringFull.map((p) => p['name']).toList(),
        'requestingPlayers': requestingFull.map((p) => p['name']).toList(),
        'offeringPicks': offeringPicks.map((p) => "${p['year']} RD ${p['round']}").toList(),
        'requestingPicks': requestingPicks.map((p) => "${p['year']} RD ${p['round']}").toList(),
        'timestamp': FieldValue.serverTimestamp(),
      });
    });
  }
}