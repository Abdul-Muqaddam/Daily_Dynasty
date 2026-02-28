import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LeagueService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Generates a unique 6-character alphanumeric join code.
  static Future<String> generateJoinCode() async {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    while (true) {
      final code = String.fromCharCodes(
        List.generate(6, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
      );
      // Check for collision
      final query = await _db
          .collection('leagues')
          .where('joinCode', isEqualTo: code)
          .limit(1)
          .get();
      if (query.docs.isEmpty) return code;
    }
  }

  /// Creates a new league in Firestore and returns the league document ID.
  static Future<String> createLeague({
    required String name,
    int maxMembers = 10,
    String scoringType = 'standard',
    bool allowPublicJoin = false,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final joinCode = await generateJoinCode();

    final docRef = await _db.collection('leagues').add({
      'name': name,
      'joinCode': joinCode,
      'createdBy': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
      'draftStatus': 'pending',
      'maxMembers': maxMembers,
      'scoringType': scoringType,
      'members': [user.uid],
      'settings': {
        'allowPublicJoin': allowPublicJoin,
        'tradeDeadline': null,
      },
    });

    return docRef.id;
  }

  /// Fetches leagues the current user is a member of (one-time fetch).
  static Future<List<Map<String, dynamic>>> getUserLeagues() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    final query = await _db
        .collection('leagues')
        .where('members', arrayContains: user.uid)
        .orderBy('createdAt', descending: true)
        .get();

    return query.docs
        .map((doc) => {'id': doc.id, ...doc.data()})
        .toList();
  }

  /// Returns a real-time Stream of leagues the current user is a member of.
  static Stream<List<Map<String, dynamic>>> getUserLeaguesStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _db
        .collection('leagues')
        .where('members', arrayContains: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList());
  }

  /// Attempts to join a league with a 6-character string.
  static Future<void> joinLeague(String joinCode) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    joinCode = joinCode.trim().toUpperCase();
    if (joinCode.length != 6) throw Exception('Invalid join code length');

    // 1. Find the league by joinCode
    final query = await _db
        .collection('leagues')
        .where('joinCode', isEqualTo: joinCode)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      throw Exception('League not found');
    }

    final docSnap = query.docs.first;
    final leagueData = docSnap.data();
    final leagueId = docSnap.id;
    final maxMembers = leagueData['maxMembers'] as int? ?? 10;
    final members = List<String>.from(leagueData['members'] ?? []);

    // 2. Check conditions
    if (members.contains(user.uid)) {
      throw Exception('You are already a member of this league');
    }
    if (members.length >= maxMembers) {
      throw Exception('This league is full');
    }

    // 3. Add to members array
    await _db.collection('leagues').doc(leagueId).update({
      'members': FieldValue.arrayUnion([user.uid])
    });
  }

  /// Fetches the user profiles for a list of UIDs.
  static Future<List<Map<String, dynamic>>> getLeagueMembers(List<String> memberUids) async {
    if (memberUids.isEmpty) return [];

    // Firestore 'whereIn' limits to 10 items.
    // If a league has more than 10 members, we need to batch the requests.
    final List<Map<String, dynamic>> members = [];
    
    // Create a map for faster lookup after fetching
    final Map<String, Map<String, dynamic>> memberMap = {};

    for (var i = 0; i < memberUids.length; i += 10) {
      final batchUids = memberUids.sublist(i, min(i + 10, memberUids.length));
      
      final query = await _db
          .collection('users')
          .where(FieldPath.documentId, whereIn: batchUids)
          .get();
          
      for (var doc in query.docs) {
        memberMap[doc.id] = {'uid': doc.id, ...doc.data()};
      }
    }

    // Ensure every requested UID is in the final list, even if document wasn't found
    for (var uid in memberUids) {
      if (memberMap.containsKey(uid)) {
        members.add(memberMap[uid]!);
      } else {
        // Fallback for missing user document
        members.add({'uid': uid, 'username': 'Manager ${uid.substring(0, 4)}'});
      }
    }

    // Sort to keep creator or first member at top, depending on implementation needs.
    // For now, basic alphabetical sort by username.
    members.sort((a, b) => (a['username'] as String? ?? '').compareTo(b['username'] as String? ?? ''));
    
    return members;
  }
}
