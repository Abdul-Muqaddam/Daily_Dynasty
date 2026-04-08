import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CheckInService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Returns true if the user has not checked in yet today.
  static Future<bool> isCheckInReady() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final doc = await _db.collection('users').doc(user.uid).get();
    if (!doc.exists) return true;

    final data = doc.data() ?? {};
    final Timestamp? lastCheckIn = data['lastCheckIn'];

    if (lastCheckIn == null) return true;

    final now = DateTime.now();
    final last = lastCheckIn.toDate();

    return !(last.year == now.year && last.month == now.month && last.day == now.day);
  }

  /// Returns a stream that emits true/false when the check-in status might have changed.
  /// Note: This is a simplified version; for a real production app, 
  /// you might use a more robust state management solution.
  static Stream<bool> checkInStatusStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(false);

    return _db.collection('users').doc(user.uid).snapshots().map((doc) {
      if (!doc.exists) return true;
      final data = doc.data() ?? {};
      final Timestamp? lastCheckIn = data['lastCheckIn'];
      if (lastCheckIn == null) return true;

      final now = DateTime.now();
      final last = lastCheckIn.toDate();
      return !(last.year == now.year && last.month == now.month && last.day == now.day);
    });
  }

  /// Calculates the duration until the next midnight.
  static Duration getTimeUntilNextCheckIn() {
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    return nextMidnight.difference(now);
  }
}
