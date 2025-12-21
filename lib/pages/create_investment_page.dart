import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/ad_model.dart';
import '../store/global_ads.dart';
import '../services/investment_vehicle_service.dart';

class CreateInvestmentPage extends StatefulWidget {
  final String? preselectedAdId;

  const CreateInvestmentPage({
    super.key,
    this.preselectedAdId,
  });

  @override
  State<CreateInvestmentPage> createState() => _CreateInvestmentPageState();
}

class _CreateInvestmentPageState extends State<CreateInvestmentPage> {
  final _formKey = GlobalKey<FormState>();
  final _investmentGoalController = TextEditingController();
  final _minimumContributionController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _deadlineController = TextEditingController();

  final InvestmentVehicleService _vehicleService = InvestmentVehicleService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GlobalAdStore _adStore = GlobalAdStore();

  AdModel? _selectedAd;
  DateTime? _selectedDeadline;
  bool _isSubmitting = false;
  double _platformFeePercentage = 5.0;

  @override
  void initState() {
    super.initState();
    if (widget.preselectedAdId != null) {
      _loadPreselectedAd();
    }
  }

  Future<void> _loadPreselectedAd() async {
    try {
      // Get ad from Firestore
      final ads = await _adStore.getAllAds().first;
      final ad = ads.firstWhere(
        (a) => a.id == widget.preselectedAdId,
        orElse: () => ads.first,
      );
      if (mounted) {
        setState(() {
          _selectedAd = ad;
          if (ad.price.isNotEmpty) {
            try {
              final price = double.parse(ad.price.replaceAll(RegExp(r'[^\d.]'), ''));
              _investmentGoalController.text = price.toStringAsFixed(0);
            } catch (e) {
              // Ignore parsing errors
            }
          }
        });
      }
    } catch (e) {
      print('Error loading preselected ad: $e');
    }
  }

  @override
  void dispose() {
    _investmentGoalController.dispose();
    _minimumContributionController.dispose();
    _descriptionController.dispose();
    _deadlineController.dispose();
    super.dispose();
  }

  Future<void> _selectDeadline() async {
    final now = DateTime.now();
    final firstDate = now.add(const Duration(days: 1));
    final lastDate = now.add(const Duration(days: 365));

    final picked = await showDatePicker(
      context: context,
      initialDate: firstDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (picked != null) {
      setState(() {
        _selectedDeadline = picked;
        _deadlineController.text =
            '${picked.day}/${picked.month}/${picked.year}';
      });
    }
  }

  String? _validateInvestmentGoal(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter investment goal';
    }

    final amount = double.tryParse(value.trim());
    if (amount == null || amount <= 0) {
      return 'Please enter a valid amount';
    }

    if (_selectedAd != null && _selectedAd!.price.isNotEmpty) {
      try {
        final adPrice = double.parse(
            _selectedAd!.price.replaceAll(RegExp(r'[^\d.]'), ''));
        if (amount > adPrice * 1.5) {
          return 'Investment goal should not exceed 150% of vehicle price';
        }
      } catch (e) {
        // Ignore parsing errors
      }
    }

    return null;
  }

  String? _validateMinimumContribution(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter minimum contribution';
    }

    final amount = double.tryParse(value.trim());
    if (amount == null || amount <= 0) {
      return 'Please enter a valid amount';
    }

    final goal = double.tryParse(_investmentGoalController.text.trim());
    if (goal != null && amount > goal) {
      return 'Minimum contribution cannot exceed investment goal';
    }

    if (goal != null && amount < goal * 0.01) {
      return 'Minimum contribution should be at least 1% of investment goal';
    }

    return null;
  }

  Future<void> _submitInvestment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedAd == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an ad')),
      );
      return;
    }

    if (_selectedDeadline == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a deadline')),
      );
      return;
    }

    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to create investment')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final investmentGoal =
          double.parse(_investmentGoalController.text.trim());
      final minimumContribution =
          double.parse(_minimumContributionController.text.trim());

      final vehicleId = await _vehicleService.createInvestmentVehicle(
        adId: _selectedAd!.id!,
        totalInvestmentGoal: investmentGoal,
        minimumContribution: minimumContribution,
        expiresAt: _selectedDeadline!,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        platformFeePercentage: _platformFeePercentage,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Investment opportunity created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, vehicleId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating investment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Create Investment'),
          backgroundColor: Colors.transparent,
        ),
        body: const Center(
          child: Text('Please login to create an investment opportunity'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Investment Opportunity'),
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Select Ad Section
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select Vehicle Ad',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_selectedAd == null)
                        _buildAdSelector()
                      else
                        _buildSelectedAdCard(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Investment Details
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Investment Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Investment Goal
                      TextFormField(
                        controller: _investmentGoalController,
                        decoration: InputDecoration(
                          labelText: 'Total Investment Goal (PKR)',
                          hintText: 'Enter total amount needed',
                          prefixIcon: const Icon(Icons.attach_money),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d+\.?\d{0,2}')),
                        ],
                        validator: _validateInvestmentGoal,
                      ),
                      const SizedBox(height: 16),

                      // Minimum Contribution
                      TextFormField(
                        controller: _minimumContributionController,
                        decoration: InputDecoration(
                          labelText: 'Minimum Contribution (PKR)',
                          hintText: 'Minimum investment per investor',
                          prefixIcon: const Icon(Icons.account_balance_wallet),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d+\.?\d{0,2}')),
                        ],
                        validator: _validateMinimumContribution,
                      ),
                      const SizedBox(height: 16),

                      // Deadline
                      TextFormField(
                        controller: _deadlineController,
                        decoration: InputDecoration(
                          labelText: 'Investment Deadline',
                          hintText: 'Select deadline date',
                          prefixIcon: const Icon(Icons.calendar_today),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          suffixIcon: const Icon(Icons.arrow_drop_down),
                        ),
                        readOnly: true,
                        onTap: _selectDeadline,
                        validator: (value) {
                          if (_selectedDeadline == null) {
                            return 'Please select a deadline';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Description
                      TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: 'Description (Optional)',
                          hintText: 'Add investment opportunity description',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        maxLines: 4,
                      ),
                      const SizedBox(height: 16),

                      // Platform Fee Info
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline,
                                size: 16, color: Colors.blue),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Platform Fee: $_platformFeePercentage% (Automatically deducted from profits)',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitInvestment,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: _isSubmitting
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
                          'Create Investment Opportunity',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdSelector() {
    return StreamBuilder<List<AdModel>>(
      stream: _adStore.getUserAdsByStatus(_auth.currentUser!.uid, 'active'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        final ads = snapshot.data ?? [];

        if (ads.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text('No active ads available. Please create an ad first.'),
          );
        }

        return DropdownButtonFormField<AdModel>(
          decoration: InputDecoration(
            labelText: 'Select Ad',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          items: ads.map((ad) {
            return DropdownMenuItem<AdModel>(
              value: ad,
              child: Text('${ad.title} - ${ad.price}'),
            );
          }).toList(),
          onChanged: (ad) {
            setState(() {
              _selectedAd = ad;
              if (ad != null && ad.price.isNotEmpty) {
                try {
                  final price = double.parse(
                      ad.price.replaceAll(RegExp(r'[^\d.]'), ''));
                  _investmentGoalController.text = price.toStringAsFixed(0);
                } catch (e) {
                  // Ignore parsing errors
                }
              }
            });
          },
          validator: (value) {
            if (value == null) {
              return 'Please select an ad';
            }
            return null;
          },
        );
      },
    );
  }

  Widget _buildSelectedAdCard() {
    return Card(
      color: Colors.green[50],
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            if (_selectedAd!.imageUrls != null &&
                _selectedAd!.imageUrls!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  _selectedAd!.imageUrls!.first,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image),
                    );
                  },
                ),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedAd!.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('Price: ${_selectedAd!.price}'),
                  Text('Year: ${_selectedAd!.year}'),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _selectedAd = null;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}

