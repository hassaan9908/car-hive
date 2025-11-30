import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import '../services/phone_validation_service.dart';
import '../services/trust_rank_service.dart';
import '../services/username_service.dart';
import '../components/searchable_dropdown.dart';
import '../utils/validators.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _fullNameController;
  late TextEditingController _displayNameController;
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _birthdayController;

  String? _selectedGender;
  String? _selectedCity;
  bool _isLoading = false;
  bool _isCheckingUsername = false;
  String? _usernameError;
  String? _originalUsername;

  // Cities used for car searching (you can expand this list)
  final List<String> _cities = [
    'Karachi',
    'Lahore',
    'Islamabad',
    'Rawalpindi',
    'Faisalabad',
    'Multan',
    'Gujranwala',
    'Peshawar',
    'Quetta',
    'Sialkot',
    'Sargodha',
    'Bahawalpur',
    'Sukkur',
    'Jhang',
    'Sheikhupura',
    'Larkana',
    'Gujrat',
    'Mardan',
    'Kasur',
    'Dera Ghazi Khan',
    'Nawabshah',
    'Sahiwal',
    'Mirpur Khas',
    'Chiniot',
    'Kotri',
    'Kamoke',
    'Hafizabad',
    'Kohat',
    'Jacobabad',
    'Shikarpur',
    'Muzaffargarh',
    'Khanpur',
    'Gojra',
    'Bahawalnagar',
    'Muridke',
    'Pakpattan',
    'Abottabad',
    'Tando Adam',
    'Jhelum',
    'Sanghar',
    'Chishtian',
    'Kot Addu',
    'Khanewal'
  ];

  final List<String> _genders = [
    'Male',
    'Female',
    'Other',
    'Prefer not to say'
  ];

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController();
    _displayNameController = TextEditingController();
    _usernameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _birthdayController = TextEditingController();

    // Add listener to phone controller to trigger availability check
    _phoneController.addListener(() {
      setState(() {
        // This will trigger a rebuild and show/hide the availability indicator
      });
    });

    // Add listener for username changes
    _usernameController.addListener(_onUsernameChanged);

    // Load user data and store original username
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = fb_auth.FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          final data = userDoc.data()!;
          _originalUsername = data['username']?.toString();

          setState(() {
            _fullNameController.text = data['fullName'] ?? '';
            _displayNameController.text = data['displayName'] ?? '';
            _usernameController.text = data['username'] ?? '';
            _emailController.text = data['email'] ?? '';
            _phoneController.text = data['phoneNumber'] ?? '';
            _birthdayController.text = data['birthday'] ?? '';
            _selectedGender = data['gender'];
            _selectedCity = data['city'];
          });
        }
      }
    } catch (e) {
      // Handle error silently
    }
  }

  void _onUsernameChanged() {
    final username = _usernameController.text.trim();

    // Only check if username is different from original
    if (username != _originalUsername) {
      if (username.length >= 3) {
        _checkUsernameAvailability(username);
      } else {
        setState(() {
          _usernameError = null;
          _isCheckingUsername = false;
        });
      }
    } else {
      // Username is same as original, clear any errors/loading
      setState(() {
        _usernameError = null;
        _isCheckingUsername = false;
      });
    }
  }

  Future<void> _checkUsernameAvailability(String username) async {
    setState(() {
      _isCheckingUsername = true;
      _usernameError = null;
    });

    try {
      final error =
          await UsernameService.validateUsernameAvailability(username);
      if (mounted) {
        setState(() {
          _usernameError = error;
          _isCheckingUsername = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _usernameError = 'Error checking username availability';
          _isCheckingUsername = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _displayNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _birthdayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = fb_auth.FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Profile')),
        body: const Center(child: Text('Please log in to edit profile')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Colors.transparent,
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() ?? <String, dynamic>{};

            // Initialize controllers with current data if not already set
            if (_fullNameController.text.isEmpty) {
              _fullNameController.text = data['fullName'] ?? '';
              _displayNameController.text = data['displayName'] ?? '';
              _usernameController.text = data['username'] ?? '';
              _emailController.text = data['email'] ?? user.email ?? '';
              _phoneController.text = data['phoneNumber'] ?? '';
              _birthdayController.text = data['birthday'] ?? '';
              _selectedGender = data['gender'];
              _selectedCity = data['city'];
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Personal Information'),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _fullNameController,
                    label: 'Full Name',
                    hint: 'Enter your full name',
                    validator: (value) {
                      if (value?.trim().isEmpty == true) {
                        return 'Full name is required';
                      }
                      final name = value!.trim();

                      // Allow partial input during typing
                      if (name.length < 2) {
                        return null; // Don't show error for very short input
                      }

                      if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(name)) {
                        return 'Full name should contain only alphabets';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _displayNameController,
                    label: 'Display Name',
                    hint: 'How others will see your name',
                    validator: (value) {
                      if (value?.trim().isEmpty == true) {
                        return 'Display name is required';
                      }
                      final name = value!.trim();

                      // Allow partial input during typing
                      if (name.length < 2) {
                        return null; // Don't show error for very short input
                      }

                      if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(name)) {
                        return 'Display name should contain only alphabets';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _usernameController,
                    label: 'Username',
                    hint: 'Choose a unique username',
                    validator: (value) {
                      if (value?.trim().isEmpty == true) {
                        return 'Username is required';
                      }
                      if (_usernameError != null) {
                        return _usernameError;
                      }
                      return Validators.validateUsername(value);
                    },
                    suffixIcon: _isCheckingUsername
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : _usernameController.text.trim() !=
                                    _originalUsername &&
                                _usernameError == null &&
                                _usernameController.text.trim().length >= 3
                            ? const Icon(Icons.check_circle,
                                color: Colors.green)
                            : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _emailController,
                    label: 'Email',
                    hint: 'Your email address',
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value?.trim().isEmpty == true) {
                        return 'Email is required';
                      }
                      final email = value!.trim();

                      // Allow partial input during typing
                      if (email.length < 5) {
                        return null; // Don't show error for very short input
                      }

                      // Check if it looks like an email (has @ and .)
                      if (!email.contains('@') || !email.contains('.')) {
                        if (email.length >= 5) {
                          return 'Enter a valid email address';
                        }
                        return null;
                      }

                      if (!RegExp(
                              r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
                          .hasMatch(email)) {
                        return 'Enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _phoneController,
                    label: 'Phone Number',
                    hint: 'Your contact number',
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value?.trim().isEmpty == true) {
                        return 'Phone number is required';
                      }
                      final phone = value!.trim();

                      // Allow partial input during typing
                      if (phone.length < 3) {
                        return null; // Don't show error for very short input
                      }

                      // Check for Pakistan phone numbers
                      if (phone.startsWith('+92')) {
                        if (phone.length > 13) {
                          return 'Phone number too long';
                        }
                        if (phone.length < 13) {
                          return 'Phone number incomplete';
                        }
                        if (!RegExp(r'^\+92[0-9]{10}$').hasMatch(phone)) {
                          return 'Invalid Pakistan phone number format';
                        }
                      } else if (phone.startsWith('03')) {
                        if (phone.length > 11) {
                          return 'Phone number too long';
                        }
                        if (phone.length < 11) {
                          return 'Phone number incomplete';
                        }
                        if (!RegExp(r'^03[0-9]{9}$').hasMatch(phone)) {
                          return 'Invalid Pakistan phone number format';
                        }
                      } else if (phone.length >= 3) {
                        return 'Phone number must start with +92 or 03';
                      }
                      return null;
                    },
                  ),

                  // Phone availability indicator
                  if (_phoneController.text.trim().isNotEmpty &&
                      ((_phoneController.text.trim().startsWith('+92') &&
                              _phoneController.text.trim().length == 13) ||
                          (_phoneController.text.trim().startsWith('03') &&
                              _phoneController.text.trim().length == 11)))
                    FutureBuilder<bool>(
                      future:
                          PhoneValidationService.isPhoneNumberAvailableForUser(
                        _phoneController.text.trim(),
                        fb_auth.FirebaseAuth.instance.currentUser?.uid ?? '',
                      ),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                ),
                                SizedBox(width: 8),
                                Text('Checking availability...',
                                    style: TextStyle(fontSize: 12)),
                              ],
                            ),
                          );
                        }

                        if (snapshot.hasData) {
                          final isAvailable = snapshot.data!;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              children: [
                                Icon(
                                  isAvailable
                                      ? Icons.check_circle
                                      : Icons.error,
                                  size: 16,
                                  color:
                                      isAvailable ? Colors.green : Colors.red,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  isAvailable
                                      ? 'Phone number is available'
                                      : 'This phone number is already registered',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color:
                                        isAvailable ? Colors.green : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return const SizedBox.shrink();
                      },
                    ),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Location & Details'),
                  const SizedBox(height: 16),
                  SearchableDropdown<String>(
                    labelText: 'City',
                    hintText: 'Search and select your city',
                    value: _selectedCity,
                    items: _cities,
                    itemAsString: (city) => city,
                    onChanged: (value) => setState(() => _selectedCity = value),
                    validator: (value) =>
                        value == null ? 'Please select a city' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildDropdown(
                    label: 'Gender',
                    value: _selectedGender,
                    items: _genders,
                    onChanged: (value) =>
                        setState(() => _selectedGender = value),
                    validator: (value) =>
                        value == null ? 'Please select gender' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildDateField(),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Save Profile',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
    String? Function(String?)? validator,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
      ),
      items: items.map((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: onChanged,
      validator: validator,
    );
  }

  Widget _buildDateField() {
    return TextFormField(
      controller: _birthdayController,
      decoration: InputDecoration(
        labelText: 'Birthday',
        hintText: 'Select your birthday',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        suffixIcon: const Icon(Icons.calendar_today),
      ),
      readOnly: true,
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now().subtract(const Duration(days: 365 * 20)),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
        );
        if (picked != null) {
          _birthdayController.text =
              '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
        }
      },
      validator: (value) =>
          value?.trim().isEmpty == true ? 'Please select your birthday' : null,
    );
  }

  Future<void> _saveProfile() async {
    print('Starting profile save...');

    // Validate form fields manually to handle async validators
    bool isValid = true;

    // Validate phone number availability
    final phone = _phoneController.text.trim();
    if (phone.isNotEmpty &&
        ((phone.startsWith('+92') && phone.length == 13) ||
            (phone.startsWith('03') && phone.length == 11))) {
      final isPhoneAvailable =
          await PhoneValidationService.isPhoneNumberAvailableForUser(
        phone,
        fb_auth.FirebaseAuth.instance.currentUser?.uid ?? '',
      );

      if (!isPhoneAvailable) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('This phone number is already registered by another user'),
            backgroundColor: Colors.red,
          ),
        );
        isValid = false;
      }
    }

    // Validate other fields
    if (!_formKey.currentState!.validate()) {
      print('Form validation failed');
      isValid = false;
    }

    if (!isValid) {
      print('Validation failed');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = fb_auth.FirebaseAuth.instance.currentUser!;

      // Get current user data to check for username changes
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final currentUsername = userDoc.data()?['username']?.toString();
      final newUsername = _usernameController.text.trim().toLowerCase();

      final updates = <String, dynamic>{
        'fullName': _fullNameController.text.trim(),
        'displayName': _displayNameController.text.trim(),
        'username': newUsername,
        'email': _emailController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
        'city': _selectedCity,
        'gender': _selectedGender,
        'birthday': _birthdayController.text.trim(),
        'profileUpdatedAt': FieldValue.serverTimestamp(),
      };

      print('Updating user document with: $updates');

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(updates, SetOptions(merge: true));

      print('User document updated successfully');

      // Update phone number record in dedicated collection
      if (phone.isNotEmpty) {
        await PhoneValidationService.updatePhoneNumberRecord(user.uid, phone);
      }

      // Handle username changes
      if (newUsername != currentUsername && newUsername.isNotEmpty) {
        print('Username changed from $currentUsername to $newUsername');

        // Delete old username document if it exists
        if (currentUsername != null && currentUsername.isNotEmpty) {
          try {
            await FirebaseFirestore.instance
                .collection('usernames')
                .doc(currentUsername)
                .delete();
            print('Deleted old username document: $currentUsername');
          } catch (e) {
            print('Error deleting old username: $e');
          }
        }

        // Create new username document
        try {
          await FirebaseFirestore.instance
              .collection('usernames')
              .doc(newUsername)
              .set({
            'userId': user.uid,
            'username': newUsername,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          print('Created new username document: $newUsername');
        } catch (e) {
          print('Error creating new username document: $e');
          throw Exception('Failed to update username: $e');
        }
      } else {
        print('Username unchanged: $currentUsername');
      }

      // Trigger TrustRank recompute after profile update
      try {
        await TrustRankService().recomputeAndSave(user.uid);
      } catch (_) {}

      print('Profile save completed successfully');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Profile updated successfully! Username: $newUsername'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
