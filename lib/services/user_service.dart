import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'league_service.dart';

class UserService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final Map<String, String> _nameCache = {};

  /// Restored Legacy Method: Fetches the current user's profile document.
  static Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return getUserProfile(user.uid);
  }

  /// Fetches a specific user's profile document by UID.
  static Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        return {'uid': uid, ...doc.data()!};
      }
    } catch (e) {
      print("Error fetching user profile for $uid: $e");
    }
    return null;
  }

  /// Restored Legacy Method: Updates the team name for the current user.
  static Future<void> updateTeamName(String newName) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _db.collection('users').doc(user.uid).update({
      'teamName': newName,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Restored Legacy Method: Initializes a new user by setting up their starting league.
  static Future<void> initializeNewUser(String uid) async {
    // 1. Ensure the user document has basic fields if not already set by signup
    await _db.collection('users').doc(uid).set({
      'registrationCompleted': true,
      'coins': 500, // Starting bonus
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // User initialized with profile only; will choose league in Discovery flow.
  }

  /// New Method: Fetches a username for a given UID, using a local cache.
  static Future<String> getUsername(String uid) async {
    if (_nameCache.containsKey(uid)) {
      return _nameCache[uid]!;
    }

    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        final name = doc.data()?['username'] as String? ?? "MANAGER ${uid.substring(0, 4)}";
        _nameCache[uid] = name;
        return name;
      }
    } catch (e) {
      print("Error fetching username for $uid: $e");
    }

    final fallback = "MANAGER ${uid.substring(0, 4)}";
    _nameCache[uid] = fallback;
    return fallback;
  }

  /// New Method: Bulk fetch usernames for a list of UIDs to optimize loads.
  static Future<void> preloadUsernames(List<String> uids) async {
    final missingUids = uids.where((id) => !_nameCache.containsKey(id)).toList();
    if (missingUids.isEmpty) return;

    try {
      final query = await _db.collection('users')
          .where(FieldPath.documentId, whereIn: missingUids.take(30).toList())
          .get();

      for (var doc in query.docs) {
        final name = doc.data()['username'] as String? ?? "MANAGER ${doc.id.substring(0, 4)}";
        _nameCache[doc.id] = name;
      }

      for (var id in missingUids) {
        if (!_nameCache.containsKey(id)) {
          _nameCache[id] = "MANAGER ${id.substring(0, 4)}";
        }
      }
    } catch (e) {
      print("Error preloading usernames: $e");
    }
  }

  /// Synchronous cache access.
  static String? getCachedUsername(String uid) {
    return _nameCache[uid];
  }
}
