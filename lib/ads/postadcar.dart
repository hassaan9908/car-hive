import 'package:carhive/models/ad_model.dart' show AdModel;
import 'package:carhive/store/global_ads.dart' show GlobalAdStore;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';



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

// cont4oeller of ads
  final formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  // final TextEditingController _priceadController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
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
  final TextEditingController _kmsController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _carbrandController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

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
    _yearController.dispose();
    _mileageController.dispose();
    _fuelController.dispose();

    _bodyColorController.dispose();
    _kmsController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _carbrandController.dispose();

    super.dispose();
  }

  // ignore: unused_element
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
        const SnackBar(content: Text("Please select all dropdown options.")),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      // Form is valid and dropdowns/images are selected
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Posting Ad...")),
      );
      // Your submission logic here
    }
  }

  @override
  Widget build(BuildContext context) {
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

              _buildFormTile(
                  "Location${selectedLocation != null ? " ($selectedLocation)" : ""}",
                  Icons.location_city,
                  _openLocationSelector),
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
              ),
              _buildTextFieldTile(
                label: "KMs Driven",
                icon: Icons.speed,
                controller: _kmsController,
              ),
              _buildTextFieldTile(
                label: "Price (PKR)",
                icon: Icons.local_offer,
                controller: _priceController,
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
              _buildTextFieldTile(
                label: "Name",
                icon: Icons.person,
                controller: _nameController,
              ),
              _buildTextFieldTile(
                label: "Phone Number",
                icon: Icons.phone,
                controller: _phoneController,
              ),
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
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        final newAd = AdModel(
                          title: _titleController.text,
                          price: _priceController.text,
                          location: _locationController.text,
                          year: _yearController.text,
                          mileage: _mileageController.text,
                          fuel: _fuelController.text,
                        );

                        GlobalAdStore().addAd(newAd);

                        try {
                          await FirebaseFirestore.instance
                              .collection('ads')
                              .add({
                            'title': newAd.title,
                            'price': newAd.price,
                            'location': newAd.location,
                            'year': newAd.year,
                            'mileage': newAd.mileage,
                            'fuel': newAd.fuel,
                            'createdAt': Timestamp.now(),
                            'userId': FirebaseAuth.instance.currentUser?.uid ??
                                'anonymous',
                          });

                          // ignore: use_build_context_synchronously
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('Your ad is live within 1 minute')),
                          );

                          await Future.delayed(const Duration(seconds: 1));
                          // ignore: use_build_context_synchronously
                          Navigator.pushReplacementNamed(context, '/myads');
                        }
                         catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to post ad: $e')),
                          );
                        }
                      }
                    },
                    child: const Text(
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
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey.shade700),
      title: TextFormField(
        controller: controller,
        validator: (value) =>
            value == null || value.trim().isEmpty ? 'Required' : null,
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
    // ignore: unused_element_parameter
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
