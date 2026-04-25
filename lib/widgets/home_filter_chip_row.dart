import 'package:flutter/material.dart';

import '../models/home_quick_filter.dart';

const double _homeFilterPillHeight = 36;
const double _homeFilterPillRadius = 999;
const Color _homeFilterPillBackground = Color(0xFF1E1E1E);
const double _homeFilterFontSize = 13;
const FontWeight _homeFilterFontWeight = FontWeight.w600;

class HomeFilterSection extends StatelessWidget {
  final String selectedQuickFilterId;
  final ValueChanged<String> onQuickFilterSelected;
  final VoidCallback onClearAll;
  final bool hasActiveFilters;
  final String? selectedCity;
  final ValueChanged<String?> onCitySelected;
  final int? selectedYear;
  final ValueChanged<int?> onYearSelected;
  final String? selectedTrustLevelId;
  final ValueChanged<String?> onTrustLevelSelected;

  const HomeFilterSection({
    super.key,
    required this.selectedQuickFilterId,
    required this.onQuickFilterSelected,
    required this.onClearAll,
    required this.hasActiveFilters,
    required this.selectedCity,
    required this.onCitySelected,
    required this.selectedYear,
    required this.onYearSelected,
    required this.selectedTrustLevelId,
    required this.onTrustLevelSelected,
  });

  Future<void> _showSelectionSheet<T>({
    required BuildContext context,
    required String title,
    required T selectedValue,
    required List<_FilterSheetOption<T>> options,
    required ValueChanged<T> onSelected,
  }) async {
    final accentColor = Theme.of(context).colorScheme.primary;
    final result = await showModalBottomSheet<_SelectionSheetResult<T>>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          top: false,
          child: Container(
            constraints: const BoxConstraints(maxHeight: 460),
            decoration: BoxDecoration(
              color: const Color(0xFF111111),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ) ??
                                  const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: options.length,
                    separatorBuilder: (_, __) => Divider(
                      color: Colors.white.withValues(alpha: 0.06),
                      height: 1,
                    ),
                    itemBuilder: (context, index) {
                      final option = options[index];
                      final isSelected = option.value == selectedValue;

                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () {
                            Navigator.of(context).pop(
                              _SelectionSheetResult<T>.selected(option.value),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 14,
                            ),
                            child: Row(
                              children: [
                                if (option.indicatorColor != null) ...[
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: option.indicatorColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                ],
                                Expanded(
                                  child: Text(
                                    option.label,
                                    style: TextStyle(
                                      color: isSelected
                                          ? accentColor
                                          : Colors.white,
                                      fontSize: 15,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                    ),
                                  ),
                                ),
                                _BottomSheetRadio(
                                  isSelected: isSelected,
                                  accentColor: accentColor,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (result != null && result.didSelect) {
      onSelected(result.value);
    }
  }

  String _trustLabel(String? trustLevelId) {
    return HomeTrustLevelOption.byId(trustLevelId)?.label ?? 'Any Trust Level';
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = Theme.of(context).colorScheme.primary;

    Widget itemWithGap(Widget child) {
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: child,
      );
    }

    return SizedBox(
      height: 44,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            for (final filter in HomeQuickFilter.options)
              itemWithGap(
                _FilterChipButton(
                  filter: filter,
                  isSelected: filter.id == selectedQuickFilterId,
                  accentColor: accentColor,
                  onTap: () => onQuickFilterSelected(filter.id),
                ),
              ),
            itemWithGap(
              _FilterDropdownField(
                placeholder: 'City',
                value: selectedCity,
                onTap: () => _showSelectionSheet<String?>(
                  context: context,
                  title: 'City',
                  selectedValue: selectedCity,
                  options: [
                    const _FilterSheetOption<String?>(
                      label: 'Any City',
                      value: null,
                    ),
                    ...HomeFilterCatalog.pakistanCities.map(
                      (city) => _FilterSheetOption<String?>(
                        label: city,
                        value: city,
                      ),
                    ),
                  ],
                  onSelected: onCitySelected,
                ),
              ),
            ),
            itemWithGap(
              _FilterDropdownField(
                placeholder: 'Year',
                value: selectedYear?.toString(),
                onTap: () => _showSelectionSheet<int?>(
                  context: context,
                  title: 'Year',
                  selectedValue: selectedYear,
                  options: [
                    const _FilterSheetOption<int?>(
                      label: 'Any Year',
                      value: null,
                    ),
                    ...HomeFilterCatalog.buildYearOptions().map(
                      (year) => _FilterSheetOption<int?>(
                        label: year.toString(),
                        value: year,
                      ),
                    ),
                  ],
                  onSelected: onYearSelected,
                ),
              ),
            ),
            itemWithGap(
              _FilterDropdownField(
                placeholder: 'Trust',
                value: _trustLabel(selectedTrustLevelId),
                hasSelection: selectedTrustLevelId != null &&
                    selectedTrustLevelId!.trim().isNotEmpty,
                onTap: () => _showSelectionSheet<String?>(
                  context: context,
                  title: 'Trust Level',
                  selectedValue: selectedTrustLevelId,
                  options: [
                    const _FilterSheetOption<String?>(
                      label: 'Any Trust Level',
                      value: null,
                    ),
                    ...HomeTrustLevelOption.options.map(
                      (option) => _FilterSheetOption<String?>(
                        label: option.label,
                        value: option.id,
                        indicatorColor: option.indicatorColor,
                      ),
                    ),
                  ],
                  onSelected: onTrustLevelSelected,
                ),
              ),
            ),
            TextButton(
              onPressed: hasActiveFilters ? onClearAll : null,
              style: TextButton.styleFrom(
                foregroundColor: accentColor,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                minimumSize: const Size(0, _homeFilterPillHeight),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Clear All',
                style: TextStyle(
                  color:
                      hasActiveFilters ? accentColor : const Color(0xFF777777),
                  fontSize: _homeFilterFontSize,
                  fontWeight: _homeFilterFontWeight,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  final HomeQuickFilter filter;
  final bool isSelected;
  final Color accentColor;
  final VoidCallback onTap;

  const _FilterChipButton({
    required this.filter,
    required this.isSelected,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Border? border = isSelected
        ? null
        : Border.all(
            color: Colors.white.withValues(alpha: 0.12),
          );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_homeFilterPillRadius),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          height: _homeFilterPillHeight,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: isSelected ? accentColor : _homeFilterPillBackground,
            borderRadius: BorderRadius.circular(_homeFilterPillRadius),
            border: border,
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.26),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Text(
            filter.label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: _homeFilterFontSize,
              fontWeight: _homeFilterFontWeight,
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterDropdownField extends StatelessWidget {
  final String placeholder;
  final String? value;
  final bool hasSelection;
  final VoidCallback onTap;

  const _FilterDropdownField({
    required this.placeholder,
    required this.value,
    this.hasSelection = true,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = Theme.of(context).colorScheme.primary;
    final displayValue = value?.trim();
    final isSelected =
        hasSelection && displayValue != null && displayValue.isNotEmpty;
    final label = isSelected ? displayValue : placeholder;
    final Border? border = isSelected
        ? null
        : Border.all(
            color: Colors.white.withValues(alpha: 0.12),
          );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_homeFilterPillRadius),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          height: _homeFilterPillHeight,
          constraints: const BoxConstraints(minWidth: 88, maxWidth: 172),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: isSelected ? accentColor : _homeFilterPillBackground,
            borderRadius: BorderRadius.circular(_homeFilterPillRadius),
            border: border,
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.26),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: _homeFilterFontSize,
                    fontWeight: _homeFilterFontWeight,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '\u25BE',
                style: TextStyle(
                  color: isSelected ? Colors.white : accentColor,
                  fontSize: _homeFilterFontSize,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomSheetRadio extends StatelessWidget {
  final bool isSelected;
  final Color accentColor;

  const _BottomSheetRadio({
    required this.isSelected,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? accentColor : const Color(0xFF4A4A4A),
          width: 1.5,
        ),
      ),
      child: isSelected
          ? Center(
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                ),
              ),
            )
          : null,
    );
  }
}

class _FilterSheetOption<T> {
  final String label;
  final T value;
  final Color? indicatorColor;

  const _FilterSheetOption({
    required this.label,
    required this.value,
    this.indicatorColor,
  });
}

class _SelectionSheetResult<T> {
  final bool didSelect;
  final T value;

  const _SelectionSheetResult.selected(this.value) : didSelect = true;
}
