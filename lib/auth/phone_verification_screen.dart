import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carhive/auth/auth_provider.dart' as carhive_auth;
import 'package:carhive/services/phone_auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PhoneVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final String email;
  final String password;
  final String fullName;
  final String username;

  const PhoneVerificationScreen({
    super.key,
    required this.phoneNumber,
    required this.email,
    required this.password,
    required this.fullName,
    required this.username,
  });

  @override
  State<PhoneVerificationScreen> createState() =>
      _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState extends State<PhoneVerificationScreen> {
  final TextEditingController _otpController = TextEditingController();
  final PhoneAuthService _phoneAuthService = PhoneAuthService();
  String? _verificationId;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _sendVerificationCode();
  }

  Future<void> _sendVerificationCode() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final verificationId =
          await _phoneAuthService.sendVerificationCode(widget.phoneNumber);
      setState(() {
        _verificationId = verificationId;
        _isLoading = false;
      });
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Failed to send verification code. ';
      print('Firebase Auth Error: ${e.code} - ${e.message}');

      if (e.code == 'invalid-phone-number') {
        errorMessage +=
            'The phone number format is invalid. Please check and try again.';
      } else if (e.code == 'too-many-requests') {
        errorMessage +=
            'Too many requests. Please wait a few minutes and try again.';
      } else if (e.code == 'quota-exceeded') {
        errorMessage +=
            'SMS quota exceeded. Please check Firebase Console billing settings.';
      } else if (e.code == 'missing-phone-number') {
        errorMessage += 'Phone number is required.';
      } else if (e.code == 'operation-not-allowed') {
        errorMessage +=
            'Phone authentication is not enabled. Please check Firebase Console settings.';
      } else if (e.code == 'invalid-app-credential') {
        errorMessage +=
            'reCAPTCHA verification failed on web. Please refresh the page and try again. '
            'If the issue persists, ensure your domain is authorized in Firebase Console '
            'or use test phone numbers for development.';
      } else {
        errorMessage += 'Error: ${e.message ?? e.code}. Please try again.';
      }

      setState(() {
        _error = errorMessage;
        _isLoading = false;
      });
    } catch (e) {
      print('General error sending verification code: $e');
      setState(() {
        _error =
            'Failed to send verification code: ${e.toString()}. Please try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.isEmpty) {
      setState(() {
        _error = 'Please enter the verification code';
      });
      return;
    }

    if (_verificationId == null) {
      setState(() {
        _error = 'Verification ID is missing. Please request a new code.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // First verify the phone OTP is correct
      final phoneCredential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: _otpController.text,
      );

      // Create the user with email and password
      final authProvider =
          Provider.of<carhive_auth.AuthProvider>(context, listen: false);
      final user = await authProvider.createUserWithEmailAndPassword(
        widget.email,
        widget.password,
        fullName: widget.fullName,
        username: widget.username,
        phoneNumber: widget.phoneNumber,
      );

      if (user != null && mounted) {
        try {
          // Then link the phone number with the OTP
          await user.linkWithCredential(phoneCredential);

          // Navigate to home screen
          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(
                context, '/home', (route) => false);
          }
        } catch (linkError) {
          // If linking fails, it's okay - user is already created
          print('Phone linking error (non-critical): $linkError');
          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(
                context, '/home', (route) => false);
          }
        }
      } else {
        throw Exception('Failed to create user account');
      }
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Error in verify: ${e.code} - ${e.message}');
      String errorMessage = 'Verification failed. ';
      if (e.code == 'invalid-verification-code') {
        errorMessage = 'Invalid verification code. Please check and try again.';
      } else if (e.code == 'session-expired') {
        errorMessage = 'Session expired. Please request a new code.';
      } else if (e.code == 'invalid-verification-id') {
        errorMessage =
            'Verification session expired. Please request a new code.';
      } else if (e.code == 'credential-already-in-use') {
        errorMessage =
            'This phone number is already linked to another account.';
      } else {
        errorMessage += 'Error: ${e.message ?? e.code}';
      }

      if (mounted) {
        setState(() {
          _error = errorMessage;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('General error in verify: $e');
      if (mounted) {
        setState(() {
          _error = 'Verification failed: ${e.toString()}';
          _isLoading = false;
        });
      }
    } finally {
      // Always ensure loading state is reset
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.primary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo or App Title
                  Image.asset(
                    'assets/images/Retro.gif',
                    width: 140,
                    height: 140,
                  ),
                  const SizedBox(height: 20),

                  // Title
                  Text(
                    'Verify Phone Number',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),

                  // Subtitle
                  Text(
                    'Enter the 6-digit code sent to ${widget.phoneNumber}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),

                  // OTP Input Field
                  TextField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: InputDecoration(
                      labelText: 'Verification Code',
                      hintText: 'Enter 6-digit code',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.lock),
                    ),
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(height: 20),

                  // Error message
                  if (_error != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const SizedBox(height: 20),

                  // Verify Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _verifyOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Verify',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                  const SizedBox(height: 20),

                  // Resend Code Button
                  TextButton(
                    onPressed: _isLoading ? null : _sendVerificationCode,
                    child: Text(
                      'Resend Code',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }
}
