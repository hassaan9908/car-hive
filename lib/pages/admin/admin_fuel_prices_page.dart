import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../services/fuel_price_service.dart';
import 'admin_theme.dart';

class AdminFuelPricesPage extends StatefulWidget {
  const AdminFuelPricesPage({super.key});

  @override
  State<AdminFuelPricesPage> createState() => _AdminFuelPricesPageState();
}

class _AdminFuelPricesPageState extends State<AdminFuelPricesPage> {
  final FuelPriceService _fuelPriceService = FuelPriceService();

  bool _isLoading = true;
  bool _isSavingAll = false;
  String? _savingRowId;

  DateTime? _lastUpdated;
  List<_EditableFuelRow> _rows = <_EditableFuelRow>[];

  @override
  void initState() {
    super.initState();
    _loadFuelPrices();
  }

  @override
  void dispose() {
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  Future<void> _loadFuelPrices() async {
    setState(() {
      _isLoading = true;
    });

    final payload = await _fuelPriceService.fetchFuelPrices(useCache: false);

    if (!mounted) {
      return;
    }

    for (final row in _rows) {
      row.dispose();
    }

    setState(() {
      _rows = payload.entries.map((entry) => _EditableFuelRow(entry)).toList();
      _lastUpdated = payload.lastUpdated;
      _isLoading = false;
    });
  }

  Future<void> _saveRow(_EditableFuelRow row) async {
    final parsed = row.toEntry();
    if (parsed == null) {
      _showError('Please enter valid values for ${row.type}.');
      return;
    }

    if (parsed.price <= 0) {
      _showError('Price must be a positive number for ${row.type}.');
      return;
    }

    setState(() {
      _savingRowId = row.id;
    });

    try {
      await _fuelPriceService.updateFuelPrice(parsed);
      if (!mounted) {
        return;
      }

      setState(() {
        _lastUpdated = DateTime.now();
      });
      _showSuccess('Fuel prices updated successfully');
    } catch (e) {
      _showError('Failed to update fuel price: $e');
    } finally {
      if (mounted) {
        setState(() {
          _savingRowId = null;
        });
      }
    }
  }

  Future<void> _saveAll() async {
    final parsedEntries = <FuelPriceEntry>[];

    for (final row in _rows) {
      final parsed = row.toEntry();
      if (parsed == null) {
        _showError('All fields are required and must be valid numbers.');
        return;
      }
      if (parsed.price <= 0) {
        _showError('Price must be a positive number for ${row.type}.');
        return;
      }
      parsedEntries.add(parsed);
    }

    setState(() {
      _isSavingAll = true;
    });

    try {
      await _fuelPriceService.updateAllFuelPrices(parsedEntries);
      if (!mounted) {
        return;
      }

      setState(() {
        _lastUpdated = DateTime.now();
      });

      _showSuccess('Fuel prices updated successfully');
    } catch (e) {
      _showError('Failed to update fuel prices: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSavingAll = false;
        });
      }
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF2E7D32),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFC62828),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final pageBackground = AdminThemeTokens.pageBackground(context);
    final tableBackground = theme.cardColor;
    final borderColor = colorScheme.outlineVariant.withValues(alpha: 0.55);
    final primaryTextColor =
        textTheme.bodyLarge?.color ?? colorScheme.onSurface;
    final secondaryTextColor =
        textTheme.bodyMedium?.color ?? colorScheme.onSurfaceVariant;
    final mutedTextColor = colorScheme.onSurfaceVariant;
    final inputFillColor = theme.inputDecorationTheme.fillColor ??
        (theme.brightness == Brightness.dark
            ? colorScheme.surfaceContainerHighest
            : colorScheme.surface);

    final updatedLabel = _lastUpdated == null
        ? 'Last updated: --'
        : 'Last updated: ${DateFormat('dd MMM yyyy, hh:mm a').format(_lastUpdated!)}';

    return Scaffold(
      backgroundColor: pageBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          'Manage Fuel Prices',
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: textTheme.titleLarge?.color ?? colorScheme.onSurface,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadFuelPrices,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    'Changes reflect immediately on the home screen',
                    style: textTheme.bodyMedium?.copyWith(
                      color: mutedTextColor,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    decoration: BoxDecoration(
                      color: tableBackground,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      children: [
                        _buildHeaderRow(
                          textColor: mutedTextColor,
                        ),
                        Divider(height: 1, color: borderColor),
                        for (int i = 0; i < _rows.length; i++) ...[
                          _buildFuelRow(
                            _rows[i],
                            textColor: primaryTextColor,
                            mutedTextColor: secondaryTextColor,
                            borderColor: borderColor,
                            inputFillColor: inputFillColor,
                          ),
                          if (i < _rows.length - 1)
                            Divider(height: 1, color: borderColor),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: _isSavingAll ? null : _saveAll,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6B00),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _isSavingAll
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Save All'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    updatedLabel,
                    textAlign: TextAlign.right,
                    style: textTheme.bodySmall?.copyWith(
                      color: mutedTextColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildHeaderRow({
    required Color textColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              'Fuel Type',
              style: TextStyle(
                color: textColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Price/L',
              style: TextStyle(
                color: textColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Change',
              style: TextStyle(
                color: textColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(
            width: 90,
            child: Text(
              'Action',
              style: TextStyle(
                color: textColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFuelRow(
    _EditableFuelRow row, {
    required Color textColor,
    required Color mutedTextColor,
    required Color borderColor,
    required Color inputFillColor,
  }) {
    final isRowSaving = _savingRowId == row.id;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              row.type,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: _buildInput(
              controller: row.priceController,
              hintText: '0.00',
              borderColor: borderColor,
              fillColor: inputFillColor,
              textColor: textColor,
              hintColor: mutedTextColor,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: _buildInput(
              controller: row.changeController,
              hintText: '0.00',
              borderColor: borderColor,
              fillColor: inputFillColor,
              textColor: textColor,
              hintColor: mutedTextColor,
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 80,
            child: ElevatedButton(
              onPressed: isRowSaving ? null : () => _saveRow(row),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B00),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: isRowSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Save'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String hintText,
    required Color borderColor,
    required Color fillColor,
    required Color textColor,
    required Color hintColor,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType:
          const TextInputType.numberWithOptions(decimal: true, signed: true),
      style: TextStyle(color: textColor),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: hintColor),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFFF6B00)),
        ),
      ),
    );
  }
}

class _EditableFuelRow {
  final String id;
  final String type;
  final String unit;

  final TextEditingController priceController;
  final TextEditingController changeController;

  _EditableFuelRow(FuelPriceEntry entry)
      : id = entry.id,
        type = entry.type,
        unit = entry.unit,
        priceController = TextEditingController(
          text: entry.price.toStringAsFixed(2),
        ),
        changeController = TextEditingController(
          text: entry.change.toStringAsFixed(2),
        );

  FuelPriceEntry? toEntry() {
    final parsedPrice = double.tryParse(priceController.text.trim());
    final parsedChange = double.tryParse(changeController.text.trim());

    if (parsedPrice == null || parsedChange == null) {
      return null;
    }

    return FuelPriceEntry(
      type: type,
      price: parsedPrice,
      unit: unit,
      change: parsedChange,
      updatedAt: DateTime.now(),
    );
  }

  void dispose() {
    priceController.dispose();
    changeController.dispose();
  }
}
