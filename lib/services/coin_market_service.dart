import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'league_service.dart';
import 'coin_service.dart';

class CoinMarketService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Lists a player on the coin market.
  static Future<void> listPlayerForCoins({
    required String leagueId,
    required String userId,
    required Map<String, dynamic> player,
    required int askingPrice,
    required String teamName,
  }) async {
    final user = _auth.currentUser;
    if (user == null || user.uid != userId) throw Exception('Unauthorized');

    // 1. Verify player is on roster
    final rosterRef = _db.collection('leagues').doc(leagueId).collection('rosters').doc(userId);
    final doc = await rosterRef.get();
    if (!doc.exists) throw Exception('Roster not found');
    
    List<dynamic> players = doc.data()?['players'] ?? [];
    if (!players.any((p) => p['id'] == player['id'])) {
      throw Exception('Player is no longer on your roster');
    }

    // 2. We can either remove them from the roster now and hold in escrow, or keep them on roster until sold.
    // Keeping it simple: remove from roster now, place in market escrow.
    players.removeWhere((p) => p['id'] == player['id']);
    
    // Batch write to ensure consistency
    final batch = _db.batch();
    batch.update(rosterRef, {'players': players, 'updatedAt': FieldValue.serverTimestamp()});
    
    final listingRef = _db.collection('leagues').doc(leagueId).collection('coin_market').doc();
    batch.set(listingRef, {
      'sellerId': userId,
      'sellerTeamName': teamName,
      'player': player,
      'askingPrice': askingPrice,
      'status': 'active', // active, sold
      'createdAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  /// Returns a stream of active player listings in the league.
  static Stream<List<Map<String, dynamic>>> getActiveListingsStream(String leagueId) {
    return _db
        .collection('leagues')
        .doc(leagueId)
        .collection('coin_market')
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
  }

  /// Buys a listed player using coins.
  static Future<void> buyPlayer(String leagueId, String listingId) async {
    final buyer = _auth.currentUser;
    if (buyer == null) throw Exception('Unauthorized');

    final listingRef = _db.collection('leagues').doc(leagueId).collection('coin_market').doc(listingId);
    
    await _db.runTransaction((transaction) async {
      // 1. Read listing
      final listingDoc = await transaction.get(listingRef);
      if (!listingDoc.exists) throw Exception('Listing not found');
      
      final listingData = listingDoc.data()!;
      if (listingData['status'] != 'active') throw Exception('Player is no longer available');
      
      final sellerId = listingData['sellerId'];
      final askingPrice = listingData['askingPrice'] as int;
      final playerToTransfer = listingData['player'] as Map<String, dynamic>;
      
      if (sellerId == buyer.uid) throw Exception('You cannot buy your own listing');

      // 2. Read buyer's coins
      final buyerRef = _db.collection('users').doc(buyer.uid);
      final buyerDoc = await transaction.get(buyerRef);
      if (!buyerDoc.exists) throw Exception('Buyer profile not found');
      final buyerCoins = buyerDoc.data()?['coins'] as int? ?? 0;
      
      if (buyerCoins < askingPrice) throw Exception('Insufficient coins');

      // 3. Read buyer's roster
      final buyerRosterRef = _db.collection('leagues').doc(leagueId).collection('rosters').doc(buyer.uid);
      final buyerRosterDoc = await transaction.get(buyerRosterRef);
      if (!buyerRosterDoc.exists) throw Exception('Roster not found');
      
      // 4. Determine destination position (Bench)
      final pos = 'BN'; // Send to bench
      playerToTransfer['pos'] = pos;
      
      // 5. Apply writes
      // Deduct coins from buyer
      transaction.update(buyerRef, {'coins': buyerCoins - askingPrice});
      
      // Add coins to seller
      final sellerRef = _db.collection('users').doc(sellerId);
      final sellerDoc = await transaction.get(sellerRef);
      if (sellerDoc.exists) {
        final sellerCoins = sellerDoc.data()?['coins'] as int? ?? 0;
        transaction.update(sellerRef, {'coins': sellerCoins + askingPrice});
      }

      // Add player to buyer's roster
      List<dynamic> buyerPlayers = buyerRosterDoc.data()?['players'] ?? [];
      buyerPlayers.add(playerToTransfer);
      transaction.update(buyerRosterRef, {'players': buyerPlayers, 'updatedAt': FieldValue.serverTimestamp()});
      
      // Mark listing as sold
      transaction.update(listingRef, {
        'status': 'sold', 
        'buyerId': buyer.uid,
        'soldAt': FieldValue.serverTimestamp()
      });
    });
  }

  /// Cancels a listing and returns the player to the seller's bench.
  static Future<void> cancelListing(String leagueId, String listingId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Unauthorized');

    final listingRef = _db.collection('leagues').doc(leagueId).collection('coin_market').doc(listingId);
    
    await _db.runTransaction((transaction) async {
      final listingDoc = await transaction.get(listingRef);
      if (!listingDoc.exists) throw Exception('Listing not found');
      
      final listingData = listingDoc.data()!;
      if (listingData['sellerId'] != user.uid) throw Exception('Unauthorized to cancel this listing');
      if (listingData['status'] != 'active') throw Exception('Listing is no longer active');
      
      final playerToReturn = listingData['player'] as Map<String, dynamic>;
      playerToReturn['pos'] = 'BN';
      
      final rosterRef = _db.collection('leagues').doc(leagueId).collection('rosters').doc(user.uid);
      final rosterDoc = await transaction.get(rosterRef);
      if (!rosterDoc.exists) throw Exception('Roster not found');
      
      List<dynamic> players = rosterDoc.data()?['players'] ?? [];
      players.add(playerToReturn);
      
      transaction.update(rosterRef, {'players': players, 'updatedAt': FieldValue.serverTimestamp()});
      transaction.delete(listingRef);
    });
  }
}
