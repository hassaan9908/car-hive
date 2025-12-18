import 'package:carhive/models/ad_model.dart' show AdModel;
import 'package:carhive/store/global_ads.dart' show GlobalAdStore;
import 'package:carhive/services/cloudinary_service.dart';
import 'package:carhive/services/car_360_service.dart';
import 'package:carhive/services/vehicle_service.dart';
import 'package:carhive/utils/html_parser.dart';
import 'package:carhive/utils/encryption_service.dart';
import 'package:carhive/screens/capture_360_screen.dart';
import 'package:carhive/screens/video_capture_360_screen.dart';
import 'package:carhive/models/car_360_set.dart';
import 'package:carhive/widgets/location_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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
  LatLng? selectedLocationCoords;
  String selectedLocationAddress = '';

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
  
  // Vehicle verification fields (encrypted)
  final TextEditingController _registrationNoController = TextEditingController();
  final TextEditingController _registrationDateController = TextEditingController();
  final TextEditingController _chassisNoController = TextEditingController();
  final TextEditingController _ownerNameController = TextEditingController();
  
  // Vehicle verification state
  bool _isVerifying = false;

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
  
  // 360° capture state (16 angles)
  final Car360Service _car360Service = Car360Service();
  Car360Set? _captured360Set;
  List<Uint8List?> _360PreviewImages = [];
  bool _isUploading360 = false;


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
        content: Column(
          children: [
            // Map-based location picker
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 4,
                child: InkWell(
                  onTap: () async {
                    Navigator.pop(context); // Close the bottom sheet first
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LocationPicker(
                          initialLocation: selectedLocationCoords,
                          onLocationSelected: (location, address) {
                            setState(() {
                              selectedLocationCoords = location;
                              selectedLocationAddress = address;
                              selectedLocation = address.split(',')[0]; // Use first part as city
                            });
                          },
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFf48c25).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.map,
                            color: const Color(0xFFf48c25),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Use Map to Select Location',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: const Color(0xFFf48c25),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Get precise location using Google Maps',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                              if (selectedLocationAddress.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade100,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Selected: ${selectedLocationAddress}',
                                    style: TextStyle(
                                      color: Colors.green.shade800,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.grey[400],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text('OR'),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
            ),
            
            // City list
            Expanded(
              child: ListView(
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
                        setState(() {
                          selectedLocation = city;
                          selectedLocationCoords = null; // Clear precise coords when using city
                          selectedLocationAddress = city;
                        });
                  Navigator.pop(context);
                },
                    ),
                  ),
                ],
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
                    TextStyle(color: const Color(0xFFf48c25), fontWeight: FontWeight.bold)),
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
                    TextStyle(color: const Color(0xFFf48c25), fontWeight: FontWeight.bold)),
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
                    TextStyle(color: const Color(0xFFf48c25), fontWeight: FontWeight.bold)),
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
                    TextStyle(color: const Color(0xFFf48c25), fontWeight: FontWeight.bold)),
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

  /// Select registration date
  Future<void> _selectRegistrationDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      helpText: 'Select Registration Date',
    );

    if (picked != null) {
      setState(() {
        // Format as MM/DD/YYYY
        _registrationDateController.text =
            '${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
  }

  /// Converts MM/DD/YYYY to YYYY-MM-DD for API
  String _convertDateToApiFormat(String date) {
    try {
      final parts = date.split('/');
      if (parts.length == 3) {
        final month = parts[0].padLeft(2, '0');
        final day = parts[1].padLeft(2, '0');
        final year = parts[2];
        return '$year-$month-$day';
      }
    } catch (e) {
      // If conversion fails, return as is
    }
    return date;
  }

  /// Verifies vehicle details against the API
  /// Returns true if all 4 fields match exactly, false otherwise
  Future<bool> _verifyVehicleDetails() async {
    try {
      setState(() => _isVerifying = true);

      // Convert date from MM/DD/YYYY to YYYY-MM-DD for API
      final dateForApi = _convertDateToApiFormat(_registrationDateController.text.trim());

      // Call the API
      final htmlResponse = await VehicleService.fetchVehicleData(
        registrationNo: _registrationNoController.text.trim(),
        registrationDate: dateForApi,
      );

      // Check if record found
      if (HtmlParser.isNoRecord(htmlResponse)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No record found in the database. Please verify the registration number and date.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 4),
            ),
          );
        }
        return false;
      }

      // Extract fields from HTML
      final extractedFields = HtmlParser.extractAllFields(htmlResponse);

      // Debug: Print extracted fields
      print('=== VERIFICATION DEBUG ===');
      print('Extracted fields: $extractedFields');
      print('All field keys: ${extractedFields.keys.toList()}');

      // Normalize values for comparison (case-insensitive, trim whitespace, handle asterisk)
      final normalize = (String value, {bool isRegistrationNo = false}) {
        var normalized = value
            .trim()
            .toUpperCase();
        
        // For registration numbers, handle asterisk - remove it for comparison
        // API returns format like "LEN-310*" but user enters "LEN-310"
        if (isRegistrationNo) {
          normalized = normalized.replaceAll('*', ''); // Remove asterisk
          normalized = normalized.trim(); // Trim again after removing asterisk
        } else {
          // For other fields, normalize spaces
          normalized = normalized.replaceAll(RegExp(r'\s+'), ' '); // Normalize multiple spaces to single space
        }
        
        return normalized;
      };

      // Get user input values
      final userRegNo = normalize(_registrationNoController.text.trim(), isRegistrationNo: true);
      final userChassisNo = normalize(_chassisNoController.text.trim());
      final userOwnerName = normalize(_ownerNameController.text.trim());

      // Get API values - try multiple field name variations
      String apiRegNo = '';
      String apiChassisNo = '';
      String apiOwnerName = '';

      // Try different field name variations
      final rawApiRegNo = extractedFields['Registration No'] ?? 
                         extractedFields['REGISTRATION NO'] ?? 
                         extractedFields['Reg No'] ?? 
                         extractedFields['Registration Number'] ?? '';
      
      apiRegNo = normalize(rawApiRegNo, isRegistrationNo: true); // Remove asterisk from API response

      apiChassisNo = normalize(extractedFields['Chassis No'] ?? 
                               extractedFields['CHASSIS NO'] ?? 
                               extractedFields['Chassis Number'] ?? 
                               extractedFields['CHASSIS NUMBER'] ?? '');

      apiOwnerName = normalize(extractedFields['Owner Name'] ?? 
                               extractedFields['OWNER NAME'] ?? 
                               extractedFields['Owner'] ?? 
                               extractedFields['OWNER'] ?? '');

      // Debug: Print comparison values
      print('User Reg No: "$userRegNo" | API Reg No: "$apiRegNo" | Match: ${userRegNo == apiRegNo}');
      print('User Chassis: "$userChassisNo" | API Chassis: "$apiChassisNo" | Match: ${userChassisNo == apiChassisNo}');
      print('User Owner: "$userOwnerName" | API Owner: "$apiOwnerName" | Match: ${userOwnerName == apiOwnerName}');

      // Check if any field is empty
      if (apiRegNo.isEmpty || apiChassisNo.isEmpty || apiOwnerName.isEmpty) {
        print('ERROR: Some fields could not be extracted from API response');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not extract all required fields from API. Missing: ${apiRegNo.isEmpty ? "Registration No " : ""}${apiChassisNo.isEmpty ? "Chassis No " : ""}${apiOwnerName.isEmpty ? "Owner Name" : ""}'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 4),
            ),
          );
        }
        return false;
      }

      // Compare all 3 fields (Registration No, Chassis No, Owner Name)
      // Note: Registration Date is already used to fetch the data, so we verify the other 3
      final regNoMatches = userRegNo == apiRegNo;
      final chassisNoMatches = userChassisNo == apiChassisNo;
      final ownerNameMatches = userOwnerName == apiOwnerName;

      // Debug: Print final result
      print('Reg No Match: $regNoMatches, Chassis Match: $chassisNoMatches, Owner Match: $ownerNameMatches');
      print('=== END VERIFICATION DEBUG ===');

      // All fields must match exactly
      if (!regNoMatches || !chassisNoMatches || !ownerNameMatches) {
        if (mounted) {
          final mismatches = <String>[];
          if (!regNoMatches) mismatches.add('Registration No');
          if (!chassisNoMatches) mismatches.add('Chassis No');
          if (!ownerNameMatches) mismatches.add('Owner Name');
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Verification failed. Mismatched fields: ${mismatches.join(", ")}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
        return false;
      }

      return true;
    } catch (e) {
      print('Verification error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verification error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      return false;
    } finally {
      setState(() => _isVerifying = false);
    }
  }

  // Open 360° capture screen (16 angles)
  Future<void> _open360CaptureScreen() async {
    final result = await Navigator.push<Car360Set>(
      context,
      MaterialPageRoute(
        builder: (context) => Capture360Screen(
          existingSet: _captured360Set,
          onCaptureComplete: (set) {
            // Called when capture is complete
          },
        ),
      ),
    );

    if (result != null && result.capturedCount > 0) {
      setState(() {
        _captured360Set = result;
        _car360Service.setCurrentSet(result);
        _360PreviewImages = result.imageBytes;
      });
    }
  }

  // Open video-based 360 capture
  Future<void> _openVideo360CaptureScreen() async {
    final result = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
        builder: (context) => VideoCapture360Screen(
          onComplete: (frameUrls) {
            // Video processing complete
            // Note: Video capture returns frame URLs, not Car360Set
            // You may need to handle this differently based on your needs
          },
        ),
      ),
    );

    if (result != null && result.isNotEmpty) {
      // Handle video-based 360 frames
      // For now, just show a message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Generated ${result.length} frames from video!'),
            backgroundColor: Colors.green,
          ),
        );
      }
      // TODO: Integrate video frames with your upload flow
    }
  }

  // Clear 360° images
  void _clear360Images() {
    setState(() {
      _car360Service.clearAll();
      _captured360Set = null;
      _360PreviewImages = [];
    });
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


  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Sell Your Car"),
          leading: const BackButton(),
          backgroundColor: Colors.transparent,
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
        backgroundColor: Colors.transparent,
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
                      border: Border.all(color: const Color(0xFFf48c25)),
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
                                    size: 30, color: const Color(0xFFf48c25)),
                                SizedBox(height: 8),
                                Text("Add Photo",
                                    style: TextStyle(color: const Color(0xFFf48c25))),
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

              // 360° Photo Capture Section
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.rotate_right, color: const Color(0xFFf48c25)),
                            const SizedBox(width: 8),
                            const Text(
                              '360° View Photos',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        if (_360PreviewImages.isNotEmpty)
                          TextButton.icon(
                            onPressed: _clear360Images,
                            icon: const Icon(Icons.clear, size: 18),
                            label: const Text('Clear'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Capture 16 angles of your car for a smooth 360° drag-to-rotate experience',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_360PreviewImages.isEmpty || _360PreviewImages.every((img) => img == null))
                      // Capture options: Photo or Video
                      Column(
                        children: [
                          // Photo-based capture (existing)
                      GestureDetector(
                        onTap: _open360CaptureScreen,
                        child: Container(
                          width: double.infinity,
                              height: 100,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFFf48c25).withOpacity(0.1),
                                const Color(0xFFf48c25).withOpacity(0.2),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFf48c25).withOpacity(0.5),
                              width: 2,
                              style: BorderStyle.solid,
                            ),
                          ),
                              child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFf48c25),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                      size: 24,
                                ),
                              ),
                                  const SizedBox(width: 12),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                              Text(
                                        'Photo Capture (16 angles)',
                                style: TextStyle(
                                  color: const Color(0xFFf48c25),
                                  fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                ),
                              ),
                              Text(
                                        'Take 16 photos around car',
                                style: TextStyle(
                                  color: const Color(0xFFf48c25).withOpacity(0.8),
                                          fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                                ],
                        ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Video-based capture (new)
                          GestureDetector(
                            onTap: _openVideo360CaptureScreen,
                            child: Container(
                              width: double.infinity,
                              height: 100,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.blue.withOpacity(0.1),
                                    Colors.blue.withOpacity(0.2),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.blue.withOpacity(0.5),
                                  width: 2,
                                  style: BorderStyle.solid,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.blue,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.videocam,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            'Video Capture (90 frames)',
                                            style: TextStyle(
                                              color: Colors.blue,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.green,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Text(
                                              'NEW',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        'Record 15-20 sec video',
                                        style: TextStyle(
                                          color: Colors.blue.withOpacity(0.8),
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      // Preview captured images (16 angles)
                      Builder(
                        builder: (context) {
                          final capturedImages = _360PreviewImages.where((img) => img != null).toList();
                          final capturedCount = capturedImages.length;
                          
                          return Column(
                            children: [
                              Container(
                                height: 100,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: Colors.grey.shade100,
                                ),
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.all(8),
                                  itemCount: capturedCount + 1,
                                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                                  itemBuilder: (context, index) {
                                    if (index == capturedCount) {
                                      // Add more button
                                      return GestureDetector(
                                        onTap: _open360CaptureScreen,
                                        child: Container(
                                          width: 80,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFf48c25).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: const Color(0xFFf48c25).withOpacity(0.5)),
                                          ),
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.edit, color: const Color(0xFFf48c25)),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Edit',
                                                style: TextStyle(
                                                  color: const Color(0xFFf48c25),
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }
                                    return ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Stack(
                                        children: [
                                          Image.memory(
                                            capturedImages[index]!,
                                            width: 80,
                                            height: 84,
                                            fit: BoxFit.cover,
                                          ),
                                          Positioned(
                                            top: 4,
                                            left: 4,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.black54,
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Text(
                                                '${index + 1}',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.green.shade300),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      color: Colors.green.shade700,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '$capturedCount/16 angles captured',
                                      style: TextStyle(
                                        color: Colors.green.shade700,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const Spacer(),
                                    if (capturedCount == 16)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade700,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Text(
                                          '360° Ready',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                  ],
                ),
              ),

              const Divider(height: 32),

              // Location selector
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Location *',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _openLocationSelector,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              selectedLocationCoords != null 
                                  ? Icons.location_on 
                                  : Icons.location_city,
                              color: selectedLocation != null 
                                  ? const Color(0xFFf48c25) 
                                  : Colors.grey,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    selectedLocation ?? 'Select Location',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: selectedLocation != null 
                                          ? Colors.black87 
                                          : Colors.grey,
                                    ),
                                  ),
                                  if (selectedLocationAddress.isNotEmpty && 
                                      selectedLocationAddress != selectedLocation) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      selectedLocationAddress,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                  if (selectedLocationCoords != null) ...[
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade100,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'Precise Location',
                                        style: TextStyle(
                                          color: Colors.green.shade800,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_drop_down,
                              color: Colors.grey[600],
                ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
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
              
              // Vehicle Verification Section
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Card(
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.verified_user, color: Colors.blue.shade700),
                            const SizedBox(width: 8),
                            Text(
                              'Vehicle Verification',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Please provide vehicle details for automatic verification. This information will be encrypted and kept secure.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildTextFieldTile(
                          label: "Registration No",
                          icon: Icons.confirmation_number,
                          controller: _registrationNoController,
                          hint: "ABC-123",
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Registration number is required';
                            }
                            return null;
                          },
                        ),
                        _buildTextFieldTile(
                          label: "Registration Date",
                          icon: Icons.calendar_today,
                          controller: _registrationDateController,
                          hint: "MM/DD/YYYY",
                          readOnly: true,
                          onTap: () => _selectRegistrationDate(),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Registration date is required';
                            }
                            final datePattern = RegExp(r'^\d{2}/\d{2}/\d{4}$');
                            if (!datePattern.hasMatch(value.trim())) {
                              return 'Please enter date in MM/DD/YYYY format';
                            }
                            return null;
                          },
                        ),
                        _buildTextFieldTile(
                          label: "Chassis No",
                          icon: Icons.vpn_key,
                          controller: _chassisNoController,
                          hint: "Enter chassis number",
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Chassis number is required';
                            }
                            return null;
                          },
                        ),
                        _buildTextFieldTile(
                          label: "Owner Name",
                          icon: Icons.person,
                          controller: _ownerNameController,
                          hint: "Enter owner name",
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Owner name is required';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
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
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFFF6B35),
                          Color(0xFFFF8C42),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF6B35).withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: (_isUploadingImages || _isUploading360 || _isVerifying) ? null : () async {
                      if (_formKey.currentState!.validate()) {
                        // Verify vehicle details first
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Verifying vehicle details...'),
                            duration: Duration(seconds: 2),
                          ),
                        );

                        final isVerified = await _verifyVehicleDetails();

                        if (!isVerified) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Vehicle verification failed. Please ensure all details match the official records.'),
                              backgroundColor: Colors.red,
                              duration: Duration(seconds: 4),
                            ),
                          );
                          return;
                        }

                        // Verification successful, proceed with upload
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

                        // Upload 360° images if captured (16 angles)
                        List<String>? images360Urls;
                        if (_captured360Set != null && _captured360Set!.capturedCount > 0) {
                          try {
                            setState(() => _isUploading360 = true);
                            images360Urls = await _car360Service.uploadCar360Set(
                              _captured360Set!,
                              onProgress: (current, total) {
                                // Optional: show progress
                              },
                            );
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to upload 360° images: $e')),
                            );
                            // Continue without 360 images
                          } finally {
                            if (mounted) setState(() => _isUploading360 = false);
                          }
                        }

                        // Use selected location coordinates or get current location
                        Map<String, double>? locationCoords;
                        if (selectedLocationCoords != null) {
                          // Use the precise location selected by user
                          locationCoords = {
                            'lat': selectedLocationCoords!.latitude,
                            'lng': selectedLocationCoords!.longitude,
                          };
                        } else {
                          // Fallback to current location if no precise location selected
                          try {
                          LocationPermission permission = await Geolocator.checkPermission();
                          if (permission == LocationPermission.denied) {
                            permission = await Geolocator.requestPermission();
                          }
                          
                          if (permission == LocationPermission.whileInUse ||
                              permission == LocationPermission.always) {
                            Position position = await Geolocator.getCurrentPosition(
                              desiredAccuracy: LocationAccuracy.medium,
                            );
                            locationCoords = {
                              'lat': position.latitude,
                              'lng': position.longitude,
                            };
                          }
                        } catch (e) {
                          print('Error getting location: $e');
                          // Continue without location coordinates
                          }
                        }

                        // Prepare vehicle verification data
                        // Normalize registration number for consistent duplicate checking
                        final plainRegistrationNo = _registrationNoController.text
                            .trim()
                            .toUpperCase()
                            .replaceAll('*', '')
                            .replaceAll(' ', '')
                            .replaceAll(RegExp(r'[^\w\-]'), '');
                        final vehicleData = {
                          'registrationNo': plainRegistrationNo,
                          'registrationDate': _registrationDateController.text.trim(),
                          'chassisNo': _chassisNoController.text.trim(),
                          'ownerName': _ownerNameController.text.trim(),
                        };

                        // Encrypt sensitive vehicle data
                        final encryptedVehicleData = EncryptionService.encryptFields(vehicleData);
                        
                        // Add plain registration number temporarily for duplicate checking
                        // This will be removed before storing in Firestore
                        encryptedVehicleData['_plainRegistrationNo'] = plainRegistrationNo;

                        // Create ad with image URLs and encrypted vehicle data
                        final newAd = AdModel(
                          title: _titleController.text,
                          price: _priceController.text,
                          location: selectedLocationAddress.isNotEmpty 
                              ? selectedLocationAddress 
                              : selectedLocation ?? _locationController.text,
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
                          locationCoordinates: locationCoords,
                          images360Urls: images360Urls != null && images360Urls.isNotEmpty
                              ? images360Urls
                              : null,
                        );

                        try {
                          // Add ad with encrypted vehicle data and auto-approve (status = 'active')
                          await GlobalAdStore().addAdWithVerification(newAd, encryptedVehicleData);

                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                  'Vehicle verified successfully! Your ad has been posted.'),
                              backgroundColor: Colors.green,
                            ),
                          );

                          await Future.delayed(const Duration(seconds: 1));
                          if (!mounted) return;
                          Navigator.pushReplacementNamed(context, '/myads');
                        } catch (e) {
                          if (!mounted) return;
                          final errorMessage = e.toString().replaceAll('Exception: ', '').replaceAll('Failed to add verified ad: ', '');
                          final isDuplicateError = errorMessage.contains('already exists');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(errorMessage),
                              backgroundColor: isDuplicateError ? Colors.orange : Colors.red,
                              duration: const Duration(seconds: 5),
                            ),
                          );
                        }
                      }
                    },
                    child: (_isUploadingImages || _isUploading360)
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                _isUploading360 ? "Uploading 360° images..." : "Uploading...",
                                style: const TextStyle(fontSize: 16, color: Colors.white),
                              ),
                            ],
                          )
                        : const Text(
                            "Post Ad",
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                  ),
                  )
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
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final Color fill_color = isDark 
        ? const Color.fromARGB(255, 15, 15, 15) 
        : Colors.grey.shade200;

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
          fillColor: fill_color,
        ),
      ),
    );
  }

  Widget _buildFormTile(
    String title,
    IconData icon,
    VoidCallback onTap, {
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