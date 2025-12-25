import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class PhoneAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Format phone number for Firebase authentication
  String _formatPhoneNumber(String phoneNumber) {
    // Remove all non-digit characters
    String digitsOnly = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

    // Ensure proper format for Pakistan phone numbers
    if (digitsOnly.startsWith('92') && digitsOnly.length == 12) {
      // +92 format: +92XXXXXXXXXX -> +92XXXXXXXXXX
      return '+$digitsOnly';
    } else if (digitsOnly.startsWith('03') && digitsOnly.length == 11) {
      // 03XXXXXXXXX format -> +923XXXXXXXXX
      return '+92${digitsOnly.substring(1)}';
    } else if (digitsOnly.length == 10 && digitsOnly.startsWith('3')) {
      // XXXXXXXXXX format (starting with 3) -> +923XXXXXXXXX
      return '+92$digitsOnly';
    }

    // If format is not recognized, return as is (Firebase will handle validation)
    return phoneNumber;
  }

  /// Send verification code to the provided phone number using Firebase's built-in phone auth
  Future<String> sendVerificationCode(String phoneNumber) async {
    final Completer<String> completer = Completer<String>();

    // Format phone number for Firebase
    final formattedPhoneNumber = _formatPhoneNumber(phoneNumber);

    // Debug: Print the formatted phone number
    print('Original phone number: $phoneNumber');
    print('Formatted phone number: $formattedPhoneNumber');

    // Verify phone number using Firebase's built-in phone auth
    await _auth.verifyPhoneNumber(
      phoneNumber: formattedPhoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        // This callback is called when SMS code is auto-retrieved (Android only)
        print('Auto-verification completed for $formattedPhoneNumber');
        try {
          await _auth.signInWithCredential(credential);
          if (!completer.isCompleted) {
            completer.complete('');
          }
        } catch (e) {
          print('Error in auto-verification: $e');
          if (!completer.isCompleted) {
            completer.completeError(e);
          }
        }
      },
      verificationFailed: (FirebaseAuthException e) {
        // This callback is called when verification fails
        print(
            'Verification failed for $formattedPhoneNumber: ${e.code} - ${e.message}');
        if (!completer.isCompleted) {
          completer.completeError(e);
        }
      },
      codeSent: (String verificationId, [int? forceResendingToken]) {
        // This callback is called when SMS code is sent to the phone number
        print('OTP sent to $formattedPhoneNumber');
        print('Verification ID: $verificationId');
        if (!completer.isCompleted) {
          completer.complete(verificationId);
        }
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        // This callback is called when auto-retrieval times out
        print('Auto-retrieval timeout for $formattedPhoneNumber');
      },
      timeout: const Duration(seconds: 60),
    );

    return completer.future;
  }

  /// Sign in with phone number and SMS code using Firebase's built-in phone auth
  Future<UserCredential> signInWithPhoneNumber(
      String verificationId, String smsCode) async {
    final AuthCredential credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );

    return await _auth.signInWithCredential(credential);
  }

  /// Link phone number with existing user account
  Future<UserCredential> linkPhoneNumberToUser(
      String verificationId, String smsCode) async {
    final AuthCredential credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );

    final User? user = _auth.currentUser;
    if (user != null) {
      return await user.linkWithCredential(credential);
    } else {
      throw Exception('No user is currently signed in');
    }
  }
}
