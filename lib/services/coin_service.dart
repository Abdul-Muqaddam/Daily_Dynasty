import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

    final batch = _db.batch();
    final userRef = _db.collection('users').doc(user.uid);
    final txRef = userRef.collection('coinTransactions').doc();

    batch.update(userRef, {
      'coins': FieldValue.increment(amount),
    });
    batch.set(txRef, {
      'amount': amount,
      'reason': reason,
      'timestamp': FieldValue.serverTimestamp(),
      'type': 'credit',
    });

    await batch.commit();
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

      final txRef = userRef.collection('coinTransactions').doc();
      tx.update(userRef, {'coins': FieldValue.increment(-amount)});
      tx.set(txRef, {
        'amount': -amount,
        'reason': reason,
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'debit',
      });
    });
  }
}
