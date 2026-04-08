import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class CoinService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Returns the current user's coin balance as a real-time stream.
  static Stream<int> balanceStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value(0);
    return _db
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .map((snap) => (snap.data()?['coins'] as int?) ?? 0);
  }

  /// Returns the current balance (one-time fetch).
  static Future<int> getBalance() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 0;
    final doc = await _db.collection('users').doc(user.uid).get();
    return (doc.data()?['coins'] as int?) ?? 0;
  }

  /// Awards [amount] coins to the current user with a reason label.
  static Future<void> awardCoins(int amount, String reason) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userRef = _db.collection('users').doc(user.uid);

    // 1. Update the coin balance on the user document.
    // Use set with merge: true to ensure the document exists and fields are updated/created.
    debugPrint('CoinService: Awarding $amount coins for $reason...');
    await userRef.set({
      'coins': FieldValue.increment(amount),
    }, SetOptions(merge: true));
    debugPrint('CoinService: Coins awarded successfully.');

    // 2. Attempt to write to the subcollection (transaction log).
    // We wrap this in a separate try-catch because Firestore rules might block subcollections
    // but allowing the main document update. This ensures the user still gets their coins.
    try {
      final txRef = userRef.collection('coinTransactions').doc();
      await txRef.set({
        'amount': amount,
        'reason': reason,
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'credit',
      });
    } catch (e) {
      // ignore suppressed error for logging - at least coins were awarded
      debugPrint('CoinService: Failed to write transaction log: $e');
    }
  }

  /// Spends [amount] coins. Throws if the user has insufficient balance.
  static Future<void> spendCoins(int amount, String reason) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final userRef = _db.collection('users').doc(user.uid);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(userRef);
      final current = (snap.data()?['coins'] as int?) ?? 0;
      if (current < amount) {
        throw Exception('Insufficient coins');
      }

      tx.update(userRef, {'coins': FieldValue.increment(-amount)});

      // Attempt to log transaction
      try {
        final txRef = userRef.collection('coinTransactions').doc();
        tx.set(txRef, {
          'amount': -amount,
          'reason': reason,
          'timestamp': FieldValue.serverTimestamp(),
          'type': 'debit',
        });
      } catch (e) {
        debugPrint('CoinService: Failed to log debit: $e');
      }
    });
  }
}
