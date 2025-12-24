import 'package:carhive/store/global_ads.dart';
import 'package:flutter/material.dart';

class PostAdCar extends StatefulWidget {
  const PostAdCar({super.key});

  @override
  State<PostAdCar> createState() => _PostAdCarState();
}

class _PostAdCarState extends State<PostAdCar> {
  // Add these variables
  bool _isEditing = false;
  String? _editingAdId;

  // ...existing code for controllers and form fields...

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadEditData();
  }

  void _loadEditData() {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (args != null && args['isEditing'] == true && !_isEditing) {
      _isEditing = true;
      _editingAdId = args['adId'];
      final adData = args['adData'] as Map<String, dynamic>;

      // Pre-fill form fields with existing ad data
      setState(() {
        // Example: Update your controllers/variables with ad data
        // titleController.text = adData['title'] ?? '';
        // selectedBrand = adData['carBrand'];
        // selectedModel = adData['carModel'];
        // yearController.text = adData['year']?.toString() ?? '';
        // priceController.text = adData['price']?.toString() ?? '';
        // mileageController.text = adData['mileage']?.toString() ?? '';
        // selectedFuelType = adData['fuelType'];
        // selectedTransmission = adData['transmission'];
        // engineCapacityController.text = adData['engineCapacity']?.toString() ?? '';
        // selectedColor = adData['color'];
        // descriptionController.text = adData['description'] ?? '';
        // selectedLocation = adData['location'];
        // selectedCity = adData['city'];
        // existingImages = List<String>.from(adData['images'] ?? []);
        // selectedRegisteredIn = adData['registeredIn'];
        // selectedAssembly = adData['assembly'];
        // selectedBodyType = adData['bodyType'];
        // selectedFeatures = List<String>.from(adData['features'] ?? []);
      });
    }
  }

  // Update your submit method to handle both create and update
  Future<void> _submitAd() async {
    // ...existing validation code...

    if (_isEditing && _editingAdId != null) {
      // Update existing ad
      await GlobalAdStore().updateAd(_editingAdId!, {
        // your ad data fields
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ad updated successfully!')),
      );
    } else {
      // Create new ad
      // ...existing create logic...
    }

    Navigator.pop(context);
  }

  // ...existing code...

  // Update AppBar title based on mode
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Ad' : 'Post Ad'),
        // ...existing code...
      ),
      // ...existing code...
    );
  }
}