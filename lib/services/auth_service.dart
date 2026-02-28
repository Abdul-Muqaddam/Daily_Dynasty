import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Handles Google Sign-In and Firebase Authentication.
  static Future<User?> signInWithGoogle() async {
    try {
      // 1. Trigger the Google Authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // User cancelled the sign-in

      // 2. Obtain details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // 3. Create a new credential
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Sign in to Firebase with the credential
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        // 5. Check if user document exists in Firestore, if not create one
        final userDoc = await _db.collection('users').doc(user.uid).get();
        if (!userDoc.exists) {
          await _db.collection('users').doc(user.uid).set({
            'fullName': user.displayName ?? '',
            'email': user.email ?? '',
            'registrationCompleted': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }

      return user;
    } catch (e) {
      print('Error during Google Sign-In: $e');
      return null;
    }
  }

  /// Signs out the user from both Firebase and Google.
  static Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
  }
}
