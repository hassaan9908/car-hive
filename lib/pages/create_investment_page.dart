import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/ad_model.dart';
import '../services/investment_vehicle_service.dart';
import '../store/global_ads.dart';

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
  final NumberFormat _currencyFormatter = NumberFormat.decimalPattern();

  AdModel? _selectedAd;
  DateTime? _selectedDeadline;
  bool _isSubmitting = false;
  final double _platformFeePercentage = 5.0;

  @override
  void initState() {
    super.initState();
    if (widget.preselectedAdId != null) {
      _loadPreselectedAd();
    }
  }

  Future<void> _loadPreselectedAd() async {
    try {
      final ads = await _adStore.getAllAds().first;
      if (ads.isEmpty || widget.preselectedAdId == null) {
        return;
      }

      AdModel? matchedAd;
      for (final ad in ads) {
        if (ad.id == widget.preselectedAdId) {
          matchedAd = ad;
          break;
        }
      }

      if (!mounted || matchedAd == null) {
        return;
      }

      setState(() {
        _selectedAd = matchedAd;
        _syncInvestmentFieldsFromAd(matchedAd);
      });
    } catch (e) {
      debugPrint('Error loading preselected ad: $e');
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

  double? _extractAdPrice(AdModel ad) {
    final cleaned = ad.price.replaceAll(RegExp(r'[^\d.]'), '');
    if (cleaned.isEmpty) {
      return null;
    }

    return double.tryParse(cleaned);
  }

  void _syncInvestmentFieldsFromAd(AdModel? ad) {
    if (ad == null) {
      _investmentGoalController.clear();
      _minimumContributionController.clear();
      return;
    }

    final adPrice = _extractAdPrice(ad);
    if (adPrice == null || adPrice <= 0) {
      _investmentGoalController.clear();
      _minimumContributionController.clear();
      return;
    }

    _investmentGoalController.text = adPrice.toStringAsFixed(0);
    _minimumContributionController.text = (adPrice * 0.25).toStringAsFixed(0);
  }

  String _formatPkr(double amount) {
    return 'PKR ${_currencyFormatter.format(amount.round())}';
  }

  String _buildCarName(AdModel ad) {
    if (ad.title.trim().isNotEmpty) {
      return ad.title.trim();
    }

    final composed =
        '${ad.carBrand ?? ''} ${ad.carName ?? ''} ${ad.year}'.trim();
    return composed.isEmpty ? 'Unnamed Vehicle' : composed;
  }

  InputDecoration _buildInputDecoration({
    required String labelText,
    required String hintText,
    IconData? prefixIcon,
    IconData? suffixIcon,
    bool readOnly = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final inputTheme = theme.inputDecorationTheme;
    final defaultBorderRadius = BorderRadius.circular(10);
    final inputFillColor =
        inputTheme.fillColor ?? colorScheme.surfaceContainerHighest;
    final readOnlyFillColor = colorScheme.surfaceContainerHighest;

    return InputDecoration(
      labelText: labelText,
      labelStyle: theme.textTheme.labelMedium?.copyWith(
        color: colorScheme.onSurfaceVariant,
        fontSize: 13,
      ),
      hintText: hintText,
      hintStyle: theme.textTheme.bodyMedium?.copyWith(
        color: colorScheme.onSurfaceVariant,
        fontSize: 14,
      ),
      filled: true,
      fillColor: readOnly ? readOnlyFillColor : inputFillColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      prefixIcon: prefixIcon == null
          ? null
          : Icon(
              prefixIcon,
              size: 20,
              color: colorScheme.onSurfaceVariant,
            ),
      suffixIcon: suffixIcon == null
          ? null
          : Icon(
              suffixIcon,
              size: 20,
              color: colorScheme.onSurfaceVariant,
            ),
      enabledBorder: OutlineInputBorder(
        borderRadius: defaultBorderRadius,
        borderSide: BorderSide(
          color: colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: defaultBorderRadius,
        borderSide: BorderSide(
          color: colorScheme.primary,
          width: 1.2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: defaultBorderRadius,
        borderSide: BorderSide(
          color: colorScheme.error,
          width: 1,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: defaultBorderRadius,
        borderSide: BorderSide(
          color: colorScheme.error,
          width: 1.2,
        ),
      ),
      errorStyle: TextStyle(
        color: colorScheme.error,
        fontSize: 12,
      ),
    );
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
    if (_selectedAd == null) {
      return 'Please select an ad first';
    }

    if (value == null || value.trim().isEmpty) {
      return 'Investment goal is auto-filled from selected ad';
    }

    final goalAmount = double.tryParse(value.trim());
    if (goalAmount == null || goalAmount <= 0) {
      return 'Please enter a valid amount';
    }

    final adPrice = _extractAdPrice(_selectedAd!);
    if (adPrice == null || adPrice <= 0) {
      return 'Selected ad has an invalid price';
    }

    if ((goalAmount - adPrice).abs() > 0.5) {
      return 'Investment goal must match the selected vehicle price';
    }

    return null;
  }

  String? _validateMinimumContribution(String? value) {
    if (_selectedAd == null) {
      return 'Please select an ad first';
    }

    if (value == null || value.trim().isEmpty) {
      return 'Minimum contribution is auto-calculated from selected ad';
    }

    final amount = double.tryParse(value.trim());
    if (amount == null || amount <= 0) {
      return 'Please enter a valid amount';
    }

    final goal = double.tryParse(_investmentGoalController.text.trim());
    if (goal != null && amount > goal) {
      return 'Minimum contribution cannot exceed investment goal';
    }

    final adPrice = _extractAdPrice(_selectedAd!);
    if (adPrice == null || adPrice <= 0) {
      return 'Selected ad has an invalid price';
    }

    final requiredMinimum = adPrice * 0.25;
    if (amount + 0.001 < requiredMinimum) {
      return 'Minimum contribution must be at least 25% of vehicle price';
    }

    return null;
  }

  void _showSnackBar(
    String message, {
    Color? backgroundColor,
  }) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
      ),
    );
  }

  Future<void> _submitInvestment() async {
    final colorScheme = Theme.of(context).colorScheme;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedAd == null) {
      _showSnackBar('Please select an ad');
      return;
    }

    if (_selectedDeadline == null) {
      _showSnackBar('Please select a deadline');
      return;
    }

    final user = _auth.currentUser;
    if (user == null) {
      _showSnackBar('Please login to create investment');
      return;
    }

    final adPrice = _extractAdPrice(_selectedAd!);
    if (adPrice == null || adPrice <= 0) {
      _showSnackBar('Selected ad has an invalid price');
      return;
    }

    final investmentGoal =
        double.tryParse(_investmentGoalController.text.trim());
    final minimumContribution =
        double.tryParse(_minimumContributionController.text.trim());

    if (investmentGoal == null || minimumContribution == null) {
      _showSnackBar('Unable to read investment values');
      return;
    }

    final requiredMinimum = adPrice * 0.25;
    if (minimumContribution + 0.001 < requiredMinimum) {
      _showSnackBar(
          'Minimum contribution cannot be below 25% of vehicle price');
      return;
    }

    if ((investmentGoal - adPrice).abs() > 0.5) {
      _showSnackBar('Total investment goal must match selected vehicle price');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
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

      _showSnackBar(
        'Investment opportunity created successfully!',
        backgroundColor: colorScheme.primary,
      );

      if (mounted) {
        Navigator.pop(context, vehicleId);
      }
    } catch (e) {
      _showSnackBar(
        'Error creating investment: $e',
        backgroundColor: colorScheme.error,
      );
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final user = _auth.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          centerTitle: true,
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: 0,
          iconTheme: IconThemeData(color: colorScheme.primary),
          title: Text(
            'Create Investment',
            style: TextStyle(
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: Center(
          child: Text(
            'Please login to create an investment opportunity',
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: colorScheme.primary),
        title: Text(
          'Create Investment',
          style: TextStyle(
            color: colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildSectionCard(
                title: 'Select Ad',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAdSelector(),
                    if (_selectedAd != null) ...[
                      const SizedBox(height: 12),
                      _buildSelectedAdCard(),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildSectionCard(
                title: 'Investment Details',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _investmentGoalController,
                      readOnly: true,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 14,
                      ),
                      decoration: _buildInputDecoration(
                        labelText: 'Total Investment Goal (PKR)',
                        hintText: 'Auto-filled from selected ad',
                        prefixIcon: Icons.payments_outlined,
                        readOnly: true,
                      ),
                      validator: _validateInvestmentGoal,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _minimumContributionController,
                      readOnly: true,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 14,
                      ),
                      decoration: _buildInputDecoration(
                        labelText: 'Minimum Contribution (PKR)',
                        hintText: 'Auto-calculated (25% of price)',
                        prefixIcon: Icons.account_balance_wallet_outlined,
                        readOnly: true,
                      ),
                      validator: _validateMinimumContribution,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Minimum contribution is set to 25% of vehicle price',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _deadlineController,
                      readOnly: true,
                      onTap: _selectDeadline,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 14,
                      ),
                      decoration: _buildInputDecoration(
                        labelText: 'Investment Deadline',
                        hintText: 'Select deadline date',
                        prefixIcon: Icons.calendar_today_outlined,
                        suffixIcon: Icons.arrow_drop_down,
                      ),
                      validator: (_) {
                        if (_selectedDeadline == null) {
                          return 'Please select a deadline';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 4,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 14,
                      ),
                      decoration: _buildInputDecoration(
                        labelText: 'Description (Optional)',
                        hintText: 'Add investment opportunity description',
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoNoteBox(),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitInvestment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    disabledBackgroundColor:
                        colorScheme.onSurface.withValues(alpha: 0.12),
                    foregroundColor: colorScheme.onPrimary,
                    elevation: 4,
                    shadowColor: colorScheme.primary.withValues(alpha: 0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: _isSubmitting
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                colorScheme.onPrimary),
                          ),
                        )
                      : const Text('Create Investment Opportunity'),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoNoteBox() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: colorScheme.primary,
            width: 3,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: colorScheme.primary,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Investment opportunities are visible to all CarHive users. Funds are held securely until the goal is reached.',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdSelector() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return StreamBuilder<List<AdModel>>(
      stream: _adStore.getUserAdsByStatus(_auth.currentUser!.uid, 'active'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: CircularProgressIndicator(color: colorScheme.primary),
            ),
          );
        }

        if (snapshot.hasError) {
          return Text(
            'Error loading ads: ${snapshot.error}',
            style: TextStyle(color: colorScheme.error),
          );
        }

        final ads = snapshot.data ?? [];
        if (ads.isEmpty) {
          return Text(
            'No active ads available. Please create an ad first.',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 13,
            ),
          );
        }

        AdModel? selectedValue;
        if (_selectedAd != null) {
          for (final ad in ads) {
            if (ad.id == _selectedAd!.id) {
              selectedValue = ad;
              break;
            }
          }

          if (selectedValue == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) {
                return;
              }
              setState(() {
                _selectedAd = null;
                _syncInvestmentFieldsFromAd(null);
              });
            });
          }
        }

        return DropdownButtonFormField<AdModel>(
          value: selectedValue,
          isExpanded: true,
          dropdownColor: theme.cardColor,
          iconEnabledColor: colorScheme.onSurfaceVariant,
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 14,
          ),
          decoration: _buildInputDecoration(
            labelText: 'Select Ad',
            hintText: 'Choose one of your active ads',
          ),
          items: ads.map((ad) {
            final adPrice = _extractAdPrice(ad);
            final priceLabel = adPrice == null ? ad.price : _formatPkr(adPrice);

            return DropdownMenuItem<AdModel>(
              value: ad,
              child: Text(
                '${_buildCarName(ad)} - $priceLabel',
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            );
          }).toList(),
          onChanged: (ad) {
            setState(() {
              _selectedAd = ad;
              _syncInvestmentFieldsFromAd(ad);
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
    if (_selectedAd == null) {
      return const SizedBox.shrink();
    }

    final ad = _selectedAd!;
    final adPrice = _extractAdPrice(ad);
    final priceText = adPrice == null
        ? (ad.price.trim().isEmpty ? 'PKR -' : ad.price.trim())
        : _formatPkr(adPrice);
    final locationText =
        ad.location.trim().isEmpty ? 'Unknown location' : ad.location.trim();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          _buildAdImage(ad),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _buildCarName(ad),
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  priceText,
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$locationText  •  Silver Seller',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Clear selection',
            onPressed: () {
              setState(() {
                _selectedAd = null;
                _syncInvestmentFieldsFromAd(null);
              });
            },
            icon: Icon(
              Icons.close,
              color: colorScheme.onSurfaceVariant,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdImage(AdModel ad) {
    final hasImage = ad.imageUrls != null && ad.imageUrls!.isNotEmpty;
    if (!hasImage) {
      return _buildImagePlaceholder();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        ad.imageUrls!.first,
        width: 80,
        height: 80,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildImagePlaceholder(),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    final theme = Theme.of(context);

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.directions_car,
        color: theme.colorScheme.onSurfaceVariant,
        size: 28,
      ),
    );
  }
}
