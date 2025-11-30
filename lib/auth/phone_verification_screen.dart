import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carhive/auth/auth_provider.dart' as carhive_auth;
import 'package:carhive/services/phone_auth_service.dart';
import 'package:carhive/pages/homepage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PhoneVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final String email;
  final String password;
  final String fullName;
  final String username;

  const PhoneVerificationScreen({
    Key? key,
    required this.phoneNumber,
    required this.email,
    required this.password,
    required this.fullName,
    required this.username,
  }) : super(key: key);

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
  bool _codeSent = false;

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
        _codeSent = true;
        _isLoading = false;
      });
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Failed to send verification code. ';
      if (e.code == 'invalid-phone-number') {
        errorMessage += 'The phone number is invalid.';
      } else if (e.code == 'too-many-requests') {
        errorMessage += 'Too many requests. Please try again later.';
      } else if (e.code == 'quota-exceeded') {
        errorMessage += 'Quota exceeded. Please try again later.';
      } else {
        errorMessage += 'Please try again.';
      }

      setState(() {
        _error = errorMessage;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to send verification code. Please try again.';
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
      // First create the user with email and password
      final authProvider =
          Provider.of<carhive_auth.AuthProvider>(context, listen: false);
      final user = await authProvider.createUserWithEmailAndPassword(
        widget.email,
        widget.password,
        fullName: widget.fullName,
        username: widget.username,
        phoneNumber: widget.phoneNumber,
      );

      if (user != null) {
        // Then link the phone number with the OTP
        await _phoneAuthService.linkPhoneNumberToUser(
          _verificationId!,
          _otpController.text,
        );

        // Navigate to home screen
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Verification failed. ';
      if (e.code == 'invalid-verification-code') {
        errorMessage = 'Invalid verification code. Please try again.';
      } else if (e.code == 'session-expired') {
        errorMessage = 'Session expired. Please request a new code.';
      } else {
        errorMessage += 'Please try again.';
      }

      setState(() {
        _error = errorMessage;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Verification failed. Please try again.';
        _isLoading = false;
      });
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
