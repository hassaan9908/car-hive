import 'package:carhive/pages/homepage.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carhive/auth/auth_provider.dart';
import 'package:carhive/components/custom_textfield.dart';
import 'package:carhive/utils/validators.dart';
import 'package:carhive/services/username_service.dart';

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
  final _birthdayController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  String? _nameError;
  String? _usernameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;
  String? _birthdayError;
  String? _genderError;
  String? _selectedGender;
  PasswordStrength? _passwordStrength;
  bool _isCheckingUsername = false;

  final List<String> _genders = [
    'Male',
    'Female',
    'Other',
    'Prefer not to say'
  ];

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
    _birthdayController.dispose();
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
                  const SizedBox(height: 16),

                  // Birthday Field
                  CustomTextField(
                    controller: _birthdayController,
                    hintText: 'Birthday',
                    keyboardType: TextInputType.none,
                    prefixIcon: const Icon(Icons.calendar_today),
                    errorText: _birthdayError,
                    readOnly: true,
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now()
                            .subtract(const Duration(days: 365 * 20)),
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        _birthdayController.text =
                            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // Gender Dropdown
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: _genderError != null
                              ? Colors.red
                              : colorScheme.outline),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonFormField<String>(
                      value: _selectedGender,
                      decoration: InputDecoration(
                        labelText: 'Gender',
                        hintText: 'Select your gender',
                        prefixIcon: const Icon(Icons.person_outline),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                        errorText: _genderError,
                      ),
                      items: _genders.map((String gender) {
                        return DropdownMenuItem<String>(
                          value: gender,
                          child: Text(gender),
                        );
                      }).toList(),
                      onChanged: (String? value) {
                        setState(() {
                          _selectedGender = value;
                          _genderError = null;
                        });
                      },
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
      _birthdayError = null;
      _genderError = null;
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

    // Validate email
    final emailError = Validators.validateEmail(_emailController.text);
    if (emailError != null) {
      setState(() {
        _emailError = emailError;
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

    // Validate birthday
    if (_birthdayController.text.isEmpty) {
      setState(() {
        _birthdayError = 'Birthday is required';
      });
      return;
    }

    // Validate gender
    if (_selectedGender == null) {
      setState(() {
        _genderError = 'Gender is required';
      });
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      print("Creating user with data:");
      print("Email: ${_emailController.text}");
      print("Full Name: ${_nameController.text}");
      print("Username: ${_usernameController.text}");
      print("Birthday: ${_birthdayController.text}");
      print("Gender: $_selectedGender");

      final user = await authProvider.createUserWithEmailAndPassword(
        _emailController.text,
        _passwordController.text,
        fullName: _nameController.text,
        username: _usernameController.text,
        birthday: _birthdayController.text,
        gender: _selectedGender!,
      );

      if (user != null) {
        print("User created successfully with UID: ${user.uid}");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        goToHome(context);
      }
    } catch (e) {
      print("Signup error: $e");
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Signup failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
