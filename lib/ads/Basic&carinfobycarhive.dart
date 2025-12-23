
import 'package:carhive/ads/Bookcarvisit.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CombinedInfoScreen extends StatefulWidget {
  const CombinedInfoScreen({super.key});

  @override
  _CombinedInfoScreenState createState() => _CombinedInfoScreenState();
}

class _CombinedInfoScreenState extends State<CombinedInfoScreen> {
  final _formKey = GlobalKey<FormState>();

  String? name, phone, city, carModel, carYear, registeredCity, engine;
  bool isLocal = false;
  bool isImported = false;
  final TextEditingController _carModelController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = true;

  final List<String> pakistaniCities = [
    'Karachi',
    'Lahore',
    'Islamabad',
    'Rawalpindi',
    'Faisalabad',
    'Multan',
    'Peshawar',
    'Quetta',
    'Sialkot',
    'Gujranwala',
    'Hyderabad',
    'Abbottabad',
    'Mardan',
    'Sukkur',
    'Bahawalpur',
    'Other'
  ];

  final List<String> registrationCities = [
    'Punjab',
    'Sindh',
    'Islamabad',
    'KPK',
    'Balochistan',
    'Unregistered'
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          final data = doc.data();
          setState(() {
            _nameController.text =
                (data?['fullName'] ?? data?['name'] ?? '').toString();
            _phoneController.text = data?['phoneNumber'] ?? '';
            phone = data?['phoneNumber'];
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error loading user data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor:
            isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
        body: const Center(
            child: CircularProgressIndicator(color: Color(0xFFFF6B35))),
      );
    }

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: isDark ? Colors.white : Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'CarHive Assisted',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFFf48c25),
              ),
            ),
            Text(
              'We\'ll help you sell',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white70 : Colors.black54,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Progress Stepper
                  _buildModernStepper(),

                  const SizedBox(height: 32),

                  // Basic Information Section
                  _buildModernSection(
                    title: "Basic Information",
                    subtitle: "Tell us about yourself",
                    icon: Icons.person_outline_rounded,
                    iconColor: const Color(0xFFf48c25),
                    children: [
                      _buildModernTextField(
                        label: 'Full Name',
                        hint: 'Enter your name',
                        icon: Icons.badge_outlined,
                        controller: _nameController,
                        onSaved: (val) => name = val,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Please enter your name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildModernTextField(
                        label: 'Phone Number',
                        hint: 'Phone number from your account',
                        icon: Icons.phone_outlined,
                        controller: _phoneController,
                        readOnly: true,
                        keyboardType: TextInputType.phone,
                        onSaved: (val) => phone = val,
                      ),
                      const SizedBox(height: 16),
                      _buildCityDropdown(isDark: isDark),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Car Information Section
                  _buildModernSection(
                    title: "Car Information",
                    subtitle: "Details about your vehicle",
                    icon: Icons.directions_car_outlined,
                    iconColor: const Color(0xFFf48c25),
                    children: [
                      _buildModernTextField(
                        label: 'Car Model',
                        hint: 'e.g., Honda Civic',
                        icon: Icons.car_rental_outlined,
                        controller: _carModelController,
                        onSaved: (val) => carModel = val,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Please enter car model';
                          }
                          // Allow letters, numbers, spaces, and common special chars
                          final validPattern =
                              RegExp(r'^[a-zA-Z0-9\s\-\_\.\/\(\)]+$');
                          if (!validPattern.hasMatch(val)) {
                            return 'Only letters, numbers, and common symbols allowed';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildYearDropdown(isDark: isDark),
                      const SizedBox(height: 16),
                      _buildModernTextField(
                        label: 'Engine Capacity',
                        hint: 'e.g., 1.8L or 1800cc',
                        icon: Icons.speed_outlined,
                        onSaved: (val) => engine = val,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Please enter engine capacity';
                          }
                          // Allow letters, numbers, and common special chars
                          final validPattern =
                              RegExp(r'^[a-zA-Z0-9\s\.\-\_\/cc]+$');
                          if (!validPattern.hasMatch(val)) {
                            return 'Only letters, numbers, and common symbols allowed';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Assembly Type
                      Text(
                        "Car Assembly",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildCheckCard(
                              label: "Local",
                              icon: Icons.factory_outlined,
                              isSelected: isLocal,
                              onTap: () => setState(() {
                                if (isLocal) {
                                  isLocal = false;
                                } else {
                                  isLocal = true;
                                  isImported = false;
                                }
                              }),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildCheckCard(
                              label: "Imported",
                              icon: Icons.flight_outlined,
                              isSelected: isImported,
                              onTap: () => setState(() {
                                if (isImported) {
                                  isImported = false;
                                } else {
                                  isImported = true;
                                  isLocal = false;
                                }
                              }),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Registered City
                      Text(
                        "Registered In",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color:
                              isDark ? const Color(0xFF1E1E1E) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? Colors.white12 : Colors.black12,
                          ),
                          boxShadow: isDark
                              ? []
                              : [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                        ),
                        child: DropdownButtonFormField<String>(
                          value: registeredCity,
                          decoration: InputDecoration(
                            prefixIcon: Icon(
                              Icons.location_on_outlined,
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            hintText: 'Select province/region',
                            hintStyle: TextStyle(
                              color: isDark ? Colors.white38 : Colors.black38,
                            ),
                          ),
                          dropdownColor:
                              isDark ? const Color(0xFF1E1E1E) : Colors.white,
                          items: registrationCities.map((cityName) {
                            return DropdownMenuItem(
                              value: cityName,
                              child: Text(
                                cityName,
                                style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) =>
                              setState(() => registeredCity = val),
                          validator: (val) {
                            if (val == null || val.isEmpty) {
                              return 'Please select registration province';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Fixed Bottom Button
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: _buildModernButton(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCityDropdown({required bool isDark}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'City',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.white12 : Colors.black12,
            ),
          ),
          child: DropdownButtonFormField<String>(
            value: city,
            decoration: InputDecoration(
              prefixIcon: Icon(
                Icons.location_city_outlined,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
              hintText: 'Select your city',
              hintStyle: TextStyle(
                color: isDark ? Colors.white38 : Colors.black38,
              ),
              filled: true,
              fillColor: Colors.transparent,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            dropdownColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            style: TextStyle(
              fontSize: 15,
              color: isDark ? Colors.white : Colors.black87,
            ),
            items: pakistaniCities.map((cityName) {
              return DropdownMenuItem(
                value: cityName,
                child: Text(cityName),
              );
            }).toList(),
            onChanged: (val) => setState(() => city = val),
            onSaved: (val) => city = val,
            validator: (val) {
              if (val == null || val.isEmpty) {
                return 'Please select your city';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildYearDropdown({required bool isDark}) {
    final currentYear = DateTime.now().year;
    final years = List.generate(
        currentYear - 1975 + 1, (i) => (currentYear - i).toString());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Model Year',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.white12 : Colors.black12,
            ),
          ),
          child: DropdownButtonFormField<String>(
            value: carYear,
            decoration: InputDecoration(
              prefixIcon: Icon(
                Icons.calendar_today_outlined,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
              hintText: 'Select model year',
              hintStyle: TextStyle(
                color: isDark ? Colors.white38 : Colors.black38,
              ),
              filled: true,
              fillColor: Colors.transparent,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            dropdownColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            style: TextStyle(
              fontSize: 15,
              color: isDark ? Colors.white : Colors.black87,
            ),
            items: years.map((year) {
              return DropdownMenuItem(
                value: year,
                child: Text(year),
              );
            }).toList(),
            onChanged: (val) => setState(() => carYear = val),
            onSaved: (val) => carYear = val,
            validator: (val) {
              if (val == null || val.isEmpty) {
                return 'Please select model year';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildModernStepper() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Row(
        children: [
          _buildStep(
            number: "1",
            label: "Basic & Car",
            isActive: true,
            isCompleted: false,
          ),
          _buildStepConnector(isCompleted: false),
          _buildStep(
            number: "2",
            label: "Book Visit",
            isActive: false,
            isCompleted: false,
          ),
          _buildStepConnector(isCompleted: false),
          _buildStep(
            number: "3",
            label: "Checkout",
            isActive: false,
            isCompleted: false,
          ),
        ],
      ),
    );
  }

  Widget _buildStep({
    required String number,
    required String label,
    required bool isActive,
    required bool isCompleted,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: isActive
                  ? const LinearGradient(
                      colors: [Color(0xFFf48c25), Color(0xFFd97706)],
                    )
                  : null,
              color: isActive
                  ? null
                  : (isCompleted
                      ? const Color(0xFFf48c25)
                      : isDark
                          ? Colors.white12
                          : Colors.grey.shade200),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: isCompleted
                  ? const Icon(Icons.check_rounded,
                      color: Colors.white, size: 20)
                  : Text(
                      number,
                      style: TextStyle(
                        color: isActive
                            ? Colors.white
                            : (isDark ? Colors.white38 : Colors.grey),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              color: isActive
                  ? const Color(0xFFf48c25)
                  : (isDark ? Colors.white54 : Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepConnector({required bool isCompleted}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 24,
      height: 2,
      margin: const EdgeInsets.only(bottom: 30),
      decoration: BoxDecoration(
        color: isCompleted
            ? const Color(0xFFf48c25)
            : (isDark ? Colors.white12 : Colors.grey.shade300),
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }

  Widget _buildModernSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildModernTextField({
    required String label,
    required String hint,
    required IconData icon,
    TextEditingController? controller,
    bool readOnly = false,
    TextInputType keyboardType = TextInputType.text,
    FormFieldSetter<String>? onSaved,
    FormFieldValidator<String>? validator,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          keyboardType: keyboardType,
          onSaved: onSaved,
          validator: validator,
          style: TextStyle(
            fontSize: 15,
            color: isDark ? Colors.white : Colors.black87,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: isDark ? Colors.white38 : Colors.black38,
            ),
            prefixIcon:
                Icon(icon, color: isDark ? Colors.white54 : Colors.black54),
            filled: true,
            fillColor: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: isDark ? Colors.white12 : Colors.black12,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Color(0xFFf48c25),
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCheckCard({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFf48c25).withOpacity(0.1)
              : (isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade50),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFf48c25)
                : (isDark ? Colors.white12 : Colors.black12),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFf48c25)
                    : (isDark ? Colors.white12 : Colors.grey.shade200),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white54 : Colors.black54),
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? const Color(0xFFf48c25)
                    : (isDark ? Colors.white70 : Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFf48c25), Color(0xFFd97706)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFf48c25).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              // Check assembly selection
              if (!isLocal && !isImported) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content:
                        Text('Please select car assembly (Local or Imported)'),
                    backgroundColor: Color(0xFFf48c25),
                  ),
                );
                return;
              }
              _formKey.currentState!.save();
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => BookVisitScreen(
                          carModel: carModel ?? '',
                          carYear: carYear ?? '',
                          engine: engine ?? '',
                          registeredCity: registeredCity ?? '',
                          assembly: isLocal ? 'Local' : 'Imported',
                        )),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Continue to Book Visit",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
              SizedBox(width: 8),
              Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
