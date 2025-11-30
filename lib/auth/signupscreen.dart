import 'package:carhive/pages/homepage.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carhive/auth/auth_provider.dart';
import 'package:carhive/components/custom_textfield.dart';
import 'package:carhive/utils/validators.dart';
import 'package:carhive/services/username_service.dart';
import 'package:carhive/services/phone_validation_service.dart';
import 'package:carhive/services/email_validation_service.dart';
import 'package:carhive/auth/phone_verification_screen.dart';

class Signupscreen extends StatefulWidget {
  const Signupscreen({super.key});

  @override
  State<Signupscreen> createState() => _SignupscreenState();
}

class _SignupscreenState extends State<Signupscreen> {
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  String? _nameError;
  String? _usernameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;
  String? _phoneError;
  PasswordStrength? _passwordStrength;
  bool _isCheckingUsername = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_onPasswordChanged);
    _usernameController.addListener(_onUsernameChanged);
  }

  @override
  void dispose() {
    super.dispose();
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
  }

  void _onPasswordChanged() {
    setState(() {
      _passwordStrength =
          Validators.calculatePasswordStrength(_passwordController.text);
    });
  }

  void _onUsernameChanged() {
    if (_usernameController.text.length >= 3) {
      setState(() {
        _isCheckingUsername = true;
      });
      _checkUsernameAvailability();
    }
  }

  Future<void> _checkUsernameAvailability() async {
    final username = _usernameController.text.trim();
    if (username.isEmpty) return;

    final error = await UsernameService.validateUsernameAvailability(username);
    setState(() {
      _usernameError = error;
      _isCheckingUsername = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final authProvider = Provider.of<AuthProvider>(context);

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
                    'Create Account',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Join us today',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.secondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),

                  // Name Field
                  CustomTextField(
                    controller: _nameController,
                    hintText: 'Full Name',
                    keyboardType: TextInputType.name,
                    prefixIcon: const Icon(Icons.person),
                    errorText: _nameError,
                  ),
                  const SizedBox(height: 16),

                  // Username Field
                  CustomTextField(
                    controller: _usernameController,
                    hintText: 'Username',
                    keyboardType: TextInputType.text,
                    prefixIcon: const Icon(Icons.alternate_email),
                    errorText: _usernameError,
                    suffixIcon: _isCheckingUsername
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // Email Field
                  CustomTextField(
                    controller: _emailController,
                    hintText: 'Email',
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: const Icon(Icons.email),
                    errorText: _emailError,
                  ),
                  const SizedBox(height: 16),

                  // Phone Number Field
                  CustomTextField(
                    controller: _phoneController,
                    hintText: 'Phone Number (03XXXXXXXXX)',
                    keyboardType: TextInputType.phone,
                    prefixIcon: const Icon(Icons.phone),
                    errorText: _phoneError,
                  ),
                  const SizedBox(height: 16),

                  // Password Field
                  CustomTextField(
                    controller: _passwordController,
                    hintText: 'Password',
                    obscureText: !_isPasswordVisible,
                    prefixIcon: const Icon(Icons.lock),
                    errorText: _passwordError,
                    suffixIcon: IconButton(
                      icon: Icon(_isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Confirm Password Field
                  CustomTextField(
                    controller: _confirmPasswordController,
                    hintText: 'Confirm Password',
                    obscureText: !_isConfirmPasswordVisible,
                    prefixIcon: const Icon(Icons.lock_outline),
                    errorText: _confirmPasswordError,
                    suffixIcon: IconButton(
                      icon: Icon(_isConfirmPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off),
                      onPressed: () {
                        setState(() {
                          _isConfirmPasswordVisible =
                              !_isConfirmPasswordVisible;
                        });
                      },
                    ),
                  ),

                  // Password Strength Indicator
                  if (_passwordStrength != null &&
                      _passwordController.text.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Password Strength: ',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.secondary,
                                ),
                              ),
                              Text(
                                _passwordStrength!.strength,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: _passwordStrength!.color,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: _passwordStrength!.score / 6,
                            backgroundColor:
                                colorScheme.surfaceContainerHighest,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                _passwordStrength!.color),
                          ),
                          if (_passwordStrength!.feedback.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Missing: ${_passwordStrength!.feedback.join(', ')}',
                              style: TextStyle(
                                fontSize: 10,
                                color: colorScheme.secondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Signup Button
                  ElevatedButton(
                    onPressed: authProvider.isLoading ? null : _signup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: authProvider.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Sign Up',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                  const SizedBox(height: 24),

                  // Login Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.secondary,
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Login',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  goToHome(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const Homepage()),
    );
  }

  _signup() async {
    // Clear previous errors
    setState(() {
      _nameError = null;
      _usernameError = null;
      _emailError = null;
      _passwordError = null;
      _confirmPasswordError = null;
      _phoneError = null;
    });

    // Validate name
    final nameError = Validators.validateName(_nameController.text);
    if (nameError != null) {
      setState(() {
        _nameError = nameError;
      });
      return;
    }

    // Validate username
    final usernameError = Validators.validateUsername(_usernameController.text);
    if (usernameError != null) {
      setState(() {
        _usernameError = usernameError;
      });
      return;
    }

    // Check username availability
    final usernameAvailabilityError =
        await UsernameService.validateUsernameAvailability(
            _usernameController.text);
    if (usernameAvailabilityError != null) {
      setState(() {
        _usernameError = usernameAvailabilityError;
      });
      return;
    }

    // Validate email format and check for duplication
    String? emailError;
    try {
      emailError =
          await EmailValidationService.validateEmail(_emailController.text);
    } catch (e) {
      print("Error validating email: $e");
      // Even if we can't validate due to permissions, we still check format
      emailError = Validators.validateEmail(_emailController.text);
    }

    if (emailError != null) {
      setState(() {
        _emailError = emailError;
      });
      return;
    }

    // Validate phone number format and check for duplication
    String? phoneError;
    try {
      phoneError = await PhoneValidationService.validatePhoneNumber(
          _phoneController.text);
    } catch (e) {
      print("Error validating phone number: $e");
      // Even if we can't validate due to permissions, we still check format
      phoneError = Validators.validatePakistanPhone(_phoneController.text);
    }

    if (phoneError != null) {
      setState(() {
        _phoneError = phoneError;
      });
      return;
    }

    // Validate password
    final passwordError = Validators.validatePassword(_passwordController.text);
    if (passwordError != null) {
      setState(() {
        _passwordError = passwordError;
      });
      return;
    }

    // Validate confirm password
    final confirmPasswordError = Validators.validateConfirmPassword(
        _confirmPasswordController.text, _passwordController.text);
    if (confirmPasswordError != null) {
      setState(() {
        _confirmPasswordError = confirmPasswordError;
      });
      return;
    }

    // Format phone number for Firebase
    final formattedPhoneNumber =
        _formatPhoneNumberForFirebase(_phoneController.text);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Navigate to phone verification screen instead of directly creating user
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PhoneVerificationScreen(
          phoneNumber: formattedPhoneNumber,
          email: _emailController.text,
          password: _passwordController.text,
          fullName: _nameController.text,
          username: _usernameController.text,
        ),
      ),
    );
  }

  /// Format phone number for Firebase authentication
  String _formatPhoneNumberForFirebase(String phoneNumber) {
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

    // If format is not recognized, return as is
    return phoneNumber;
  }
}
