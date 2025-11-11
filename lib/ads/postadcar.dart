import 'package:carhive/models/ad_model.dart' show AdModel;
import 'package:carhive/store/global_ads.dart' show GlobalAdStore;
import 'package:carhive/components/searchable_dropdown.dart';
import 'package:carhive/services/cloudinary_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PostAdCar extends StatefulWidget {
  const PostAdCar({super.key});

  @override
  State<PostAdCar> createState() => _PostAdCarState();
}

class _PostAdCarState extends State<PostAdCar> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String? selectedLocation;
  String? selectedCarModel;
  String? selectedRegisteredIn;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          final data = userDoc.data()!;
          setState(() {
            _userName = data['fullName'] ?? data['displayName'] ?? '';
            _userPhone = data['phoneNumber'] ?? '';
            _userEmail = data['email'] ?? '';
            _userCity = data['city'] ?? '';
            _userUsername = data['username'] ?? '';
            _isLoadingProfile = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _isLoadingProfile = false;
      });
    }
  }

// Controllers for ads

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _priceadController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _mileageController = TextEditingController();
  final TextEditingController _fuelController = TextEditingController();

// @override
// void dispose () {
//   _titleController.dispose();
//   _priceController.dispose();
//   _locationController.dispose();
//   _yearController.dispose();
//   _mileageController.dispose();
//   _fuelController.dispose();
//   super.dispose();

// }
// // relted to postinf add to prevent memory leaks

  final List<File> _images = [];
  final List<Uint8List> _webImages = [];

  final TextEditingController _bodyColorController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _carbrandController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  // User profile data
  String? _userName;
  String? _userPhone;
  String? _userEmail;
  String? _userCity;
  String? _userUsername;
  bool _isLoadingProfile = true;
  
  // Image upload state
  bool _isUploadingImages = false;
  double _uploadProgress = 0.0;
  final CloudinaryService _cloudinaryService = CloudinaryService();

  // Cities list for location selection
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

  final List<String> chipOptions = [
    "Alloy Rims",
    "Army Officer Car",
    "Urgent Sale",
    "Like New",
    "Bumper to Bumper original",
    "Complete Original File",
    "Engine Repaired",
    "Engine Swapped",
    "Exchange Possible",
    "Price Negotiable",
    "Auction Sheet Available",
  ];

  // this image picker is both for web and mobile
  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null && (_images.length + _webImages.length) < 20) {
      setState(() {
        if (kIsWeb) {
          picked.readAsBytes().then((value) {
            _webImages.add(value);
          });
        } else {
          _images.add(File(picked.path));
        }
      });
    }
  }

  // Upload images to Cloudinary and return URLs
  Future<List<String>> _uploadImages() async {
    final List<String> imageUrls = [];
    
    setState(() {
      _isUploadingImages = true;
      _uploadProgress = 0.0;
    });

    try {
      if (kIsWeb) {
        // Upload web images (Uint8List)
        imageUrls.addAll(await _cloudinaryService.uploadMultipleImagesBytes(
          imageBytesList: _webImages,
          onProgress: (current, total) {
            setState(() {
              _uploadProgress = current / total;
            });
          },
        ));
      } else {
        // Upload mobile images (File)
        imageUrls.addAll(await _cloudinaryService.uploadMultipleImages(
          imageFiles: _images,
          onProgress: (current, total) {
            setState(() {
              _uploadProgress = current / total;
            });
          },
        ));
      }
    } catch (e) {
      throw Exception('Failed to upload images: $e');
    } finally {
      setState(() {
        _isUploadingImages = false;
        _uploadProgress = 0.0;
      });
    }

    return imageUrls;
  }

  // this is for mobiel image picker ==========

  // Future<void> _pickImage() async {
  //   final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
  //   if (picked != null && _images.length < 20) {
  //     setState(() {
  //       _images.add(File(picked.path));
  //     });
  //   }
  // }

//  this is added to test on both web and mobile =-=--=-=-=-=-=-=-=-=-=-=-=-==-=-=

  void _openLocationSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _FullScreenPopup(
        title: "Select Location",
        content: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ...[
              "Abbottabad",
              "Bahawalpur",
              "Chiniot",
              "Dera Ghazi Khan",
              "Faisalabad",
              "Gujranwala",
              "Gujrat",
              "Hyderabad",
              "Islamabad",
              "Jacobabad",
              "Jhang",
              "Jhelum",
              "Karachi",
              "Kasur",
              "Kohat",
              "Lahore",
              "Larkana",
              "Mardan",
              "Mirpur",
              "Multan",
              "Muzaffarabad",
              "Muzaffargarh",
              "Nawabshah",
              "Okara",
              "Peshawar",
              "Quetta",
              "Rahim Yar Khan",
              "Rawalpindi",
              "Sahiwal",
              "Sargodha",
              "Sheikhupura",
              "Sialkot",
              "Sukkur",
              "Swat",
              "Toba Tek Singh",
              "Vehari",
              "Burewala",
              "Gujrawnala",
              "Zhob"
            ].map(
              (city) => ListTile(
                title: Text(city),
                onTap: () {
                  setState(() => selectedLocation = city);
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openModelYearSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _FullScreenPopup(
        title: "Select Model Year",
        content: ListView.builder(
          itemCount: 2025 - 1970 + 1,
          itemBuilder: (context, index) {
            final year = 1970 + index;
            return ListTile(
              title: Text(year.toString()),
              onTap: () {
                setState(() {
                  selectedCarModel = year.toString();
                });
                Navigator.pop(context);
              },
            );
          },
        ),
      ),
    );
  }

  void _openRegisteredCitySelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _FullScreenPopup(
        title: "Select Location",
        content: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text("Unregistered",
                style:
                    TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
            ListTile(
              title: const Text("Unregistered"),
              onTap: () {
                setState(() => selectedRegisteredIn = "Unregistered");
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 8),
            const Text("Provinces",
                style:
                    TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
            ...["Punjab", "Sindh", "Balochistan", "KPK"]
                .map((province) => ListTile(
                      title: Text(province),
                      onTap: () {
                        setState(() => selectedRegisteredIn = province);
                        Navigator.pop(context);
                      },
                    )),
            const SizedBox(height: 8),
            const Text("Popular Cities",
                style:
                    TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
            ...["Lahore", "Karachi", "Islamabad", "Multan", "Quetta"]
                .map((city) => ListTile(
                      title: Text(city),
                      onTap: () {
                        setState(() => selectedRegisteredIn = city);
                        Navigator.pop(context);
                      },
                    )),
            const SizedBox(height: 8),
            const Text("Other Cities",
                style:
                    TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
            ...[
              "Rawalpindi",
              "Faisalabad",
              "Hyderabad",
              "Peshawar",
              "Sialkot",
              "Gujranwala",
              "Bahawalpur"
            ].map((city) => ListTile(
                  title: Text(city),
                  onTap: () {
                    setState(() => selectedRegisteredIn = city);
                    Navigator.pop(context);
                  },
                )),
          ],
        ),
      ),
    );
  }

  void _appendToDescription(String value) {
    final text = _descriptionController.text;
    if (!text.contains(value)) {
      _descriptionController.text = text.isEmpty ? value : "$text, $value";
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _mileageController.dispose();
    _fuelController.dispose();

    _bodyColorController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _carbrandController.dispose();

    super.dispose();
  }

  void _submitForm() {
    if ((_images.isEmpty && _webImages.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please add at least one image.")),
      );
      return;
    }

    if (selectedLocation == null ||
        selectedCarModel == null ||
        selectedRegisteredIn == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                "Please select location, car model year, and registration city.")),
      );
      return;
    }

    // Check if form key and current state are valid before validating
    if (_formKey.currentState != null && _formKey.currentState!.validate()) {
      // Form is valid and dropdowns/images are selected
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Posting Ad...")),
      );
      // Your submission logic here
    } else {
      // Form validation failed
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fix the validation errors.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Sell Your Car"),
          leading: const BackButton(),
          backgroundColor: Colors.blue.shade800,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.login, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('Please login to post an ad',
                  style: TextStyle(fontSize: 18)),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, 'loginscreen');
                },
                child: Text('Login'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Sell Your Car"),
        leading: const BackButton(),
        backgroundColor: Colors.blue.shade800,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ========== Image Picker (commented code preserved) ==========
              Padding(
                padding: const EdgeInsets.all(12),
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: double.infinity,
                    height: 150,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.blue),
                      borderRadius: BorderRadius.circular(8),
                    ),

                    // --==== this is for mobile code of image picker
                    // child: _images.isEmpty
                    //     ? const Center(
                    //         child: Column(
                    //           mainAxisAlignment: MainAxisAlignment.center,
                    //           children: [
                    //             Icon(Icons.camera_alt_outlined,
                    //                 size: 30, color: Colors.blue),
                    //             SizedBox(height: 8),
                    //             Text("Add Photo",
                    //                 style: TextStyle(color: Colors.blue)),
                    //           ],
                    //         ),
                    //       )
                    //     : ListView.separated(
                    //         scrollDirection: Axis.horizontal,
                    //         padding: const EdgeInsets.all(8),
                    //         itemCount: _images.length + 1,
                    //         itemBuilder: (context, index) {
                    //           if (index == _images.length &&
                    //               _images.length < 20) {
                    //             return GestureDetector(
                    //               onTap: _pickImage,
                    //               child: Container(
                    //                 width: 100,
                    //                 color: Colors.grey.shade200,
                    //                 child: const Icon(Icons.add),
                    //               ),
                    //             );
                    //           }
                    //           if (index >= _images.length) return Container();
                    //           return Image.file(_images[index],
                    //               width: 100, fit: BoxFit.cover);
                    //         },
                    //         separatorBuilder: (_, __) =>
                    //             const SizedBox(width: 8),
                    //       ),

                    child: _images.isEmpty && _webImages.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.camera_alt_outlined,
                                    size: 30, color: Colors.blue),
                                SizedBox(height: 8),
                                Text("Add Photo",
                                    style: TextStyle(color: Colors.blue)),
                              ],
                            ),
                          )
                        : ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.all(8),
                            itemCount: (_images.length + _webImages.length) + 1,
                            itemBuilder: (context, index) {
                              final total = _images.length + _webImages.length;
                              if (index == total && total < 20) {
                                return GestureDetector(
                                  onTap: _pickImage,
                                  child: Container(
                                    width: 100,
                                    color: Colors.grey.shade200,
                                    child: const Icon(Icons.add),
                                  ),
                                );
                              }
                              if (index < _webImages.length) {
                                return Image.memory(_webImages[index],
                                    width: 100, fit: BoxFit.cover);
                              } else {
                                return Image.memory(
                                  _images[index - _webImages.length]
                                      .readAsBytesSync(),
                                  width: 100,
                                  fit: BoxFit.cover,
                                );
                              }
                            },
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 8),
                          ),
                  ),
                ),
              ),

              // Location searchable dropdown
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: SearchableDropdown<String>(
                  labelText: 'Location',
                  hintText: 'Search and select your location',
                  value: selectedLocation,
                  items: _cities,
                  itemAsString: (city) => city,
                  onChanged: (value) =>
                      setState(() => selectedLocation = value),
                  validator: (value) =>
                      value == null ? 'Please select a location' : null,
                ),
              ),
              _buildFormTile(
                  "Car model${selectedCarModel != null ? " ($selectedCarModel)" : ""}",
                  Icons.directions_car,
                  _openModelYearSelector),
              _buildTextFieldTile(
                  label: "Car Brand",
                  icon: Icons.directions_car,
                  controller: _carbrandController,
                  hint: "Honda Civic 1.8-VTEC CVT"),
              _buildFormTile(
                  "Registered${selectedRegisteredIn != null ? " ($selectedRegisteredIn)" : ""}",
                  Icons.how_to_reg,
                  _openRegisteredCitySelector),
              _buildTextFieldTile(
                label: "Body Color",
                icon: Icons.color_lens,
                controller: _bodyColorController,
                validator: (value) {
                  try {
                    if (value == null || value.trim().isEmpty) {
                      return 'Body color is required';
                    }
                    final trimmedValue = value.trim();
                    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(trimmedValue)) {
                      return 'Body color should contain only alphabets';
                    }
                    return null;
                  } catch (e) {
                    return 'Body color validation error';
                  }
                },
              ),
              _buildTextFieldTile(
                label: "Mileage (KMs)",
                icon: Icons.speed,
                controller: _mileageController,
                hint: "50000",
                validator: (value) {
                  try {
                    if (value == null || value.trim().isEmpty) {
                      return 'Mileage is required';
                    }
                    final trimmedValue = value.trim();
                    if (!RegExp(r'^[0-9]+$').hasMatch(trimmedValue)) {
                      return 'Mileage should contain only numbers';
                    }
                    return null;
                  } catch (e) {
                    return 'Mileage validation error';
                  }
                },
              ),
              _buildTextFieldTile(
                label: "Fuel Type",
                icon: Icons.local_gas_station,
                controller: _fuelController,
                hint: "Petrol",
                validator: (value) {
                  try {
                    if (value == null || value.trim().isEmpty) {
                      return 'Fuel type is required';
                    }
                    final trimmedValue = value.trim();
                    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(trimmedValue)) {
                      return 'Fuel type should contain only alphabets';
                    }
                    return null;
                  } catch (e) {
                    return 'Fuel type validation error';
                  }
                },
              ),
              _buildTextFieldTile(
                label: "Price (PKR)",
                icon: Icons.local_offer,
                controller: _priceController,
                validator: (value) {
                  try {
                    if (value == null || value.trim().isEmpty) {
                      return 'Price is required';
                    }
                    final trimmedValue = value.trim();
                    if (!RegExp(r'^[0-9]+$').hasMatch(trimmedValue)) {
                      return 'Price should contain only numbers';
                    }
                    return null;
                  } catch (e) {
                    return 'Price validation error';
                  }
                },
              ),
              _buildTextFieldTile(
                label: "Description",
                icon: Icons.notes,
                controller: _descriptionController,
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: chipOptions
                        .map((option) => ActionChip(
                              label: Text(option),
                              onPressed: () => _appendToDescription(option),
                            ))
                        .toList(),
                  ),
                ),
              ),
              // Image upload progress
              if (_isUploadingImages)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      CircularProgressIndicator(value: _uploadProgress),
                      const SizedBox(height: 8),
                      Text(
                        'Uploading images... ${(_uploadProgress * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              // User profile information display
              if (_isLoadingProfile)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                )
              else ...[
                _buildProfileInfoTile(
                    "Name", Icons.person, _userName ?? 'Not set'),
                _buildProfileInfoTile(
                    "Phone Number", Icons.phone, _userPhone ?? 'Not set'),
                _buildProfileInfoTile(
                    "Email", Icons.email, _userEmail ?? 'Not set'),
                _buildProfileInfoTile(
                    "City", Icons.location_city, _userCity ?? 'Not set'),
                _buildProfileInfoTile("Username", Icons.alternate_email,
                    _userUsername ?? 'Not set'),
              ],
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade800,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: (_isUploadingImages) ? null : () async {
                      if (_formKey.currentState!.validate()) {
                        List<String> imageUrls = [];
                        
                        // Upload images to Cloudinary
                        if (_images.isNotEmpty || _webImages.isNotEmpty) {
                          try {
                            imageUrls = await _uploadImages();
                            if (imageUrls.isEmpty) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('No images were uploaded. Please try again.'),
                                ),
                              );
                              return;
                            }
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to upload images: $e'),
                              ),
                            );
                            return;
                          }
                        }

                        // Create ad with image URLs
                        final newAd = AdModel(
                          title: _titleController.text,
                          price: _priceController.text,
                          location:
                              selectedLocation ?? _locationController.text,
                          year: selectedCarModel ?? '',
                          mileage: _mileageController.text,
                          fuel: _fuelController.text,
                          description: _descriptionController.text,
                          carBrand: _carbrandController.text,
                          bodyColor: _bodyColorController.text,
                          kmsDriven: _mileageController
                              .text, // Use mileage for kmsDriven
                          registeredIn: selectedRegisteredIn,
                          name: _nameController.text,
                          phone: _phoneController.text,
                          imageUrls: imageUrls.isNotEmpty ? imageUrls : null,
                        );

                        try {
                          await GlobalAdStore().addAd(newAd);

                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Your ad has been submitted for review. You will be notified once it\'s approved.')),
                          );

                          await Future.delayed(const Duration(seconds: 1));
                          if (!mounted) return;
                          Navigator.pushReplacementNamed(context, '/myads');
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to post ad: $e')),
                          );
                        }
                      }
                    },
                    child: _isUploadingImages
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                "Uploading...",
                                style: TextStyle(fontSize: 16, color: Colors.white),
                              ),
                            ],
                          )
                        : const Text(
                            "Post Ad",
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextFieldTile({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    String? hint,
    String? Function(String?)? validator,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey.shade700),
      title: TextFormField(
        controller: controller,
        validator: validator ??
            ((value) {
              try {
                if (value == null || value.trim().isEmpty) {
                  return 'Required';
                }
                return null;
              } catch (e) {
                return 'Validation error';
              }
            }),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildFormTile(
    String title,
    IconData icon,
    VoidCallback onTap, {
    String? selectedValue,
    String? subtitle,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey.shade700),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: const Icon(Icons.keyboard_arrow_right),
      onTap: onTap,
    );
  }

  Widget _buildProfileInfoTile(String label, IconData icon, String value) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey.shade700),
      title: Text(label),
      subtitle: Text(
        value,
        style: TextStyle(
          color: value == 'Not set' ? Colors.grey : null,
          fontStyle: value == 'Not set' ? FontStyle.italic : null,
        ),
      ),
      trailing: value == 'Not set'
          ? const Icon(Icons.warning, color: Colors.orange)
          : const Icon(Icons.check_circle, color: Colors.green),
    );
  }
}

class _FullScreenPopup extends StatelessWidget {
  final String title;
  final Widget? content;

  const _FullScreenPopup({required this.title, this.content});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.95,
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          actions: [
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            )
          ],
        ),
        body: content ??
            const Center(child: Text("Search and list view can go here")),
      ),
    );
  }
}


// i added these code twice 

// import 'package:flutter/material.dart';

// // ignore: unused_element
// class _FullScreenPopup extends StatelessWidget {
//   final String title;
//   final Widget? content;

//   // ignore: unused_element_parameter
//   const _FullScreenPopup({required this.title, this.content});

//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       height: MediaQuery.of(context).size.height * 0.95,
//       child: Scaffold(
//         appBar: AppBar(
//           automaticallyImplyLeading: false,
//           title: Text(title),
//           actions: [
//             IconButton(
//               icon: const Icon(Icons.close),
//               onPressed: () => Navigator.pop(context),
//             )
//           ],
//         ),
//         body: content ??
//             const Center(
//               child: Text("Custom List or Search will go here."),
//             ),
//       ),
//     );
//   }
// }