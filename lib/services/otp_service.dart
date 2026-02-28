import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class OtpService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Generates a 6-digit OTP and saves it to Firestore.
  /// Also prepares a document for the "Trigger Email" extension if configured.
  static Future<String> generateAndSaveOtp(String email) async {
    // 1. Generate 6-digit code
    final random = Random();
    final otp = (100000 + random.nextInt(900000)).toString();

    // 2. Save to a dedicated verification collection
    // We use a separate collection to avoid cluttering user profiles
    await _db.collection('otps').doc(email).set({
      'code': otp,
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': DateTime.now().add(const Duration(minutes: 10)).toIso8601String(),
    });

    // 3. For "Trigger Email" extension integration:
    // Create a document in a 'mail' collection that the extension listens to.
    await _db.collection('mail').add({
      'to': [email],
      'message': {
        'subject': 'Your Daily Dynasty Verification Code',
        'html': '''
          <div style="font-family: Arial, sans-serif; max-width: 600px; margin: auto; padding: 20px; border: 1px solid #eee; border-radius: 10px;">
            <h2 style="color: #00E5FF;">Welcome to Daily Dynasty!</h2>
            <p>Use the code below to verify your email address and complete your registration:</p>
            <div style="background: #f4f4f4; padding: 20px; text-align: center; border-radius: 5px;">
              <span style="font-size: 32px; font-weight: bold; letter-spacing: 5px; color: #333;">$otp</span>
            </div>
            <p style="color: #777; font-size: 12px; margin-top: 20px;">This code will expire in 10 minutes.</p>
          </div>
        ''',
      },
    });

    return otp;
  }

  /// Verifies the OTP provided by the user.
  static Future<bool> verifyOtp(String email, String enteredCode) async {
    try {
      final doc = await _db.collection('otps').doc(email).get();
      
      if (!doc.exists) return false;

      final data = doc.data()!;
      final correctCode = data['code'] as String;
      final expiresAt = DateTime.parse(data['expiresAt'] as String);

      if (DateTime.now().isAfter(expiresAt)) {
        return false; // Code expired
      }

      return correctCode == enteredCode;
    } catch (e) {
      return false;
    }
  }
}
