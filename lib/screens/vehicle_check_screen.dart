import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:carhive/services/vehicle_service.dart';
import 'package:carhive/utils/html_parser.dart';

/// Screen for checking vehicle registration information
/// 
/// This screen provides a modern Material 3 UI for:
/// - Entering vehicle registration number and date
/// - Fetching vehicle data from the API
/// - Displaying results in a user-friendly format
class VehicleCheckScreen extends StatefulWidget {
  const VehicleCheckScreen({super.key});

  @override
  State<VehicleCheckScreen> createState() => _VehicleCheckScreenState();
}

class _VehicleCheckScreenState extends State<VehicleCheckScreen> {
  // Form key for validation
  final _formKey = GlobalKey<FormState>();

  // Text editing controllers
  final _registrationNoController = TextEditingController();
  final _registrationDateController = TextEditingController();

  // State variables
  bool _isLoading = false;
  String? _htmlResponse;
  Map<String, String>? _extractedFields;

  @override
  void initState() {
    super.initState();
    // Set initial focus on registration number field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(FocusNode());
    });
  }

  @override
  void dispose() {
    _registrationNoController.dispose();
    _registrationDateController.dispose();
    super.dispose();
  }

  /// Validates the registration number field
  String? _validateRegistrationNo(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter registration number';
    }
    if (value.trim().length < 3) {
      return 'Registration number is too short';
    }
    return null;
  }

  /// Validates the registration date field
  String? _validateRegistrationDate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please select registration date';
    }
    // Validate date format (MM/DD/YYYY)
    final datePattern = RegExp(r'^\d{2}/\d{2}/\d{4}$');
    if (!datePattern.hasMatch(value.trim())) {
      return 'Please enter date in MM/DD/YYYY format';
    }
    return null;
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

  /// Shows date picker and updates the date field
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      helpText: 'Select Registration Date',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        // Format as MM/DD/YYYY
        _registrationDateController.text =
            '${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
  }

  /// Handles the form submission and API call
  Future<void> _handleCheck() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    // Set loading state
    setState(() {
      _isLoading = true;
      _htmlResponse = null;
      _extractedFields = null;
    });

    try {
      // Convert date from MM/DD/YYYY to YYYY-MM-DD for API
      final dateForApi = _convertDateToApiFormat(_registrationDateController.text.trim());
      
      // Call the API
      final htmlResponse = await VehicleService.fetchVehicleData(
        registrationNo: _registrationNoController.text.trim(),
        registrationDate: dateForApi,
      );

      // Update state with response
      setState(() {
        _htmlResponse = htmlResponse;
        _isLoading = false;

        // Extract fields if record is found
        if (!HtmlParser.isNoRecord(htmlResponse)) {
          _extractedFields = HtmlParser.extractAllFields(htmlResponse);
        }
      });
    } catch (e) {
      // Handle errors
      setState(() {
        _isLoading = false;
        _htmlResponse = null;
        _extractedFields = null;
      });

      // Show error snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehicle Information Checker'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Web CORS Warning Banner
                if (kIsWeb)
                  Card(
                    color: colorScheme.errorContainer.withOpacity(0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: colorScheme.error,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Note: This feature may not work on web browsers due to CORS restrictions. For best results, use the mobile app.',
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (kIsWeb) const SizedBox(height: 16),
                
                // Registration Number Label with examples
                Text(
                  'REGISTRATION NO: (IDN-9830, AAD-018)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Registration Number Field
                TextFormField(
                  controller: _registrationNoController,
                  decoration: InputDecoration(
                    labelText: 'Registration No',
                    hintText: 'Enter registration number',
                    prefixIcon: const Icon(Icons.confirmation_number),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest,
                  ),
                  textCapitalization: TextCapitalization.characters,
                  autofocus: true,
                  validator: _validateRegistrationNo,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) {
                    FocusScope.of(context).nextFocus();
                  },
                ),
                const SizedBox(height: 16),

                // Registration Date Field
                TextFormField(
                  controller: _registrationDateController,
                  decoration: InputDecoration(
                    labelText: 'Registration Date',
                    hintText: 'MM/DD/YYYY',
                    prefixIcon: const Icon(Icons.calendar_today),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest,
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.date_range),
                      onPressed: _selectDate,
                      tooltip: 'Pick Date',
                    ),
                  ),
                  readOnly: true,
                  onTap: _selectDate,
                  validator: _validateRegistrationDate,
                  keyboardType: TextInputType.datetime,
                ),
                const SizedBox(height: 24),

                // Check Button
                FilledButton.icon(
                  onPressed: _isLoading ? null : _handleCheck,
                  icon: _isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              colorScheme.onPrimary,
                            ),
                          ),
                        )
                      : const Icon(Icons.search),
                  label: Text(_isLoading ? 'Checking...' : 'CHECK'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Results Section
                if (_htmlResponse != null) ...[
                  // No Record Found Card
                  if (HtmlParser.isNoRecord(_htmlResponse!))
                    Card(
                      color: colorScheme.errorContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: colorScheme.onErrorContainer,
                              size: 32,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                'NO RECORD FOUND. PLEASE CONTACT EXCISE & TAXATION DEPARTMENT FOR THIS RECORD.',
                                style: TextStyle(
                                  color: colorScheme.onErrorContainer,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Extracted Fields (Future-proof)
                  if (!HtmlParser.isNoRecord(_htmlResponse!) &&
                      _extractedFields != null &&
                      _extractedFields!.isNotEmpty) ...[
                    Text(
                      'Vehicle Information',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._extractedFields!.entries.map((entry) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(
                            entry.key,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: colorScheme.primary,
                            ),
                          ),
                          subtitle: Text(
                            entry.value,
                            style: theme.textTheme.bodyLarge,
                          ),
                          leading: Icon(
                            Icons.info_outline,
                            color: colorScheme.primary,
                          ),
                        ),
                      );
                    }),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

