import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:async';

class PhoneAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Store the ConfirmationResult for web platform
  ConfirmationResult? _webConfirmationResult;

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
    // Format phone number for Firebase
    final formattedPhoneNumber = _formatPhoneNumber(phoneNumber);

    // Debug: Print the formatted phone number
    print('Original phone number: $phoneNumber');
    print('Formatted phone number: $formattedPhoneNumber');
    print('Running on web: $kIsWeb');

    if (kIsWeb) {
      // Use web-specific phone authentication
      return _sendVerificationCodeWeb(formattedPhoneNumber);
    } else {
      // Use mobile phone authentication
      return _sendVerificationCodeMobile(formattedPhoneNumber);
    }
  }

  /// Send verification code on web platform using signInWithPhoneNumber
  /// Firebase will automatically handle reCAPTCHA verification
  Future<String> _sendVerificationCodeWeb(String formattedPhoneNumber) async {
    try {
      print('Starting web phone authentication for $formattedPhoneNumber');
      print('Auth domain: ${_auth.app.options.authDomain}');
      print(
          'Current _webConfirmationResult before call: $_webConfirmationResult');

      // For web, we need to set the app verification to be more lenient for localhost
      // This helps with reCAPTCHA issues in development
      _auth.setSettings(
        appVerificationDisabledForTesting: false,
      );

      // Use signInWithPhoneNumber without custom RecaptchaVerifier
      // Firebase will automatically show the reCAPTCHA challenge
      print('Calling signInWithPhoneNumber...');
      final result = await _auth.signInWithPhoneNumber(
        formattedPhoneNumber,
      );

      print('signInWithPhoneNumber returned: $result');
      print('Result verificationId: ${result.verificationId}');

      // Store the result
      _webConfirmationResult = result;

      print('_webConfirmationResult after storing: $_webConfirmationResult');
      print('Web OTP sent successfully to $formattedPhoneNumber');

      // Return a placeholder verification ID for web
      // The actual verification will use _webConfirmationResult
      return 'web-verification-${DateTime.now().millisecondsSinceEpoch}';
    } on FirebaseAuthException catch (e) {
      print('Web phone auth FirebaseAuthException: ${e.code} - ${e.message}');
      // Clear any stale result
      _webConfirmationResult = null;

      // Provide more helpful error messages
      if (e.code == 'captcha-check-failed') {
        throw FirebaseAuthException(
          code: e.code,
          message: 'reCAPTCHA verification failed. Please try again.',
        );
      } else if (e.code == 'invalid-phone-number') {
        throw FirebaseAuthException(
          code: e.code,
          message:
              'Invalid phone number format. Please use +923XXXXXXXXX format.',
        );
      } else if (e.code == 'too-many-requests') {
        throw FirebaseAuthException(
          code: e.code,
          message: 'Too many SMS requests. Please wait before trying again.',
        );
      } else if (e.code == 'quota-exceeded') {
        throw FirebaseAuthException(
          code: e.code,
          message: 'SMS quota exceeded for this project. Contact support.',
        );
      } else if (e.code == 'operation-not-allowed') {
        throw FirebaseAuthException(
          code: e.code,
          message:
              'Phone authentication is not enabled. Enable it in Firebase Console.',
        );
      }
      rethrow;
    } catch (e) {
      print('Web phone auth general error: $e');
      // Clear any stale result
      _webConfirmationResult = null;
      rethrow;
    }
  }

  /// Send verification code on mobile platform using verifyPhoneNumber
  Future<String> _sendVerificationCodeMobile(
      String formattedPhoneNumber) async {
    final Completer<String> completer = Completer<String>();

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

  /// Verify OTP code on web platform
  Future<UserCredential> verifyOtpWeb(String smsCode) async {
    print('verifyOtpWeb called with code: $smsCode');
    print('_webConfirmationResult is null: ${_webConfirmationResult == null}');

    if (_webConfirmationResult == null) {
      throw FirebaseAuthException(
        code: 'invalid-verification-id',
        message:
            'No verification session found. Please request a new code. This can happen if: 1) The OTP was never sent successfully, 2) You refreshed the page, or 3) Too much time has passed.',
      );
    }

    try {
      print('Confirming OTP code...');
      final result = await _webConfirmationResult!.confirm(smsCode);
      print('OTP confirmed successfully!');
      // Clean up after successful verification
      _webConfirmationResult = null;
      return result;
    } on FirebaseAuthException catch (e) {
      print(
          'Web OTP verification FirebaseAuthException: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      print('Web OTP verification error: $e');
      rethrow;
    }
  }

  /// Check if we're using web verification
  bool get isWebVerification => kIsWeb && _webConfirmationResult != null;

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
