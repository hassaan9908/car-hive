import 'package:flutter/material.dart';

class SearchableDropdown<T> extends StatefulWidget {
  final List<T> items;
  final T? value;
  final String Function(T) itemAsString;
  final void Function(T?) onChanged;
  final String? hintText;
  final String? labelText;
  final String? Function(T?)? validator;
  final bool enabled;
  final Widget? prefixIcon;

  const SearchableDropdown({
    super.key,
    required this.items,
    required this.itemAsString,
    required this.onChanged,
    this.value,
    this.hintText,
    this.labelText,
    this.validator,
    this.enabled = true,
    this.prefixIcon,
  });

  @override
  State<SearchableDropdown<T>> createState() => _SearchableDropdownState<T>();
}

class _SearchableDropdownState<T> extends State<SearchableDropdown<T>> {
  late TextEditingController _searchController;
  List<T> _filteredItems = [];
  bool _isDropdownOpen = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _filteredItems = widget.items;
    if (widget.value != null) {
      _searchController.text = widget.itemAsString(widget.value!);
    }
  }

  @override
  void didUpdateWidget(SearchableDropdown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      // Defer the text update to avoid setState during build
      // Use addPostFrameCallback to update after the current build phase
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (widget.value != null) {
          final newText = widget.itemAsString(widget.value!);
          // Only update if the text is different to avoid unnecessary notifications
          if (_searchController.text != newText) {
            _searchController.text = newText;
          }
        } else {
          if (_searchController.text.isNotEmpty) {
            _searchController.clear();
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterItems(String query) {
    setState(() {
      _filteredItems = widget.items
          .where((item) => widget
              .itemAsString(item)
              .toLowerCase()
              .contains(query.toLowerCase()))
          .toList();
    });
  }

  void _selectItem(T item) {
    setState(() {
      _searchController.text = widget.itemAsString(item);
      _isDropdownOpen = false;
    });
    widget.onChanged(item);
  }

  void _clearSelection() {
    setState(() {
      _searchController.clear();
      _isDropdownOpen = false;
    });
    widget.onChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.labelText != null) ...[
          Text(
            widget.labelText!,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isDropdownOpen
                  ? colorScheme.primary
                  : colorScheme.outline.withOpacity(0.5),
            ),
            color: colorScheme.surfaceContainerHighest,
          ),
          child: Column(
            children: [
              TextFormField(
                controller: _searchController,
                enabled: widget.enabled,
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  prefixIcon: widget.prefixIcon,
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_searchController.text.isNotEmpty)
                        IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          onPressed: widget.enabled ? _clearSelection : null,
                        ),
                      IconButton(
                        icon: Icon(
                          _isDropdownOpen
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        onPressed: widget.enabled
                            ? () {
                                setState(() {
                                  _isDropdownOpen = !_isDropdownOpen;
                                  if (_isDropdownOpen) {
                                    _filteredItems = widget.items;
                                  }
                                });
                              }
                            : null,
                      ),
                    ],
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                onChanged: (value) {
                  _filterItems(value);
                  if (!_isDropdownOpen) {
                    setState(() {
                      _isDropdownOpen = true;
                    });
                  }
                },
                onTap: () {
                  if (widget.enabled) {
                    setState(() {
                      _isDropdownOpen = true;
                      _filteredItems = widget.items;
                    });
                  }
                },
                validator: (value) {
                  try {
                    if (widget.validator != null) {
                      return widget.validator!(widget.value);
                    }
                    return null;
                  } catch (e) {
                    return 'Validation error';
                  }
                },
              ),
              if (_isDropdownOpen && _filteredItems.isNotEmpty)
                Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: colorScheme.outline.withOpacity(0.2),
                      ),
                    ),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = _filteredItems[index];
                      final isSelected = widget.value == item;

                      return InkWell(
                        onTap: () => _selectItem(item),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? colorScheme.primaryContainer.withOpacity(0.3)
                                : null,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  widget.itemAsString(item),
                                  style: TextStyle(
                                    color: isSelected
                                        ? colorScheme.primary
                                        : colorScheme.onSurface,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                Icon(
                                  Icons.check,
                                  color: colorScheme.primary,
                                  size: 20,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
