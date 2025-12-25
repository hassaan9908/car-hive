import 'package:flutter/material.dart';
import '../models/car_brand_model.dart';
import '../services/car_brand_service.dart';

class CarBrandGrid extends StatefulWidget {
  final Function(CarBrand)? onBrandSelected;
  final String? selectedBrandId;

  const CarBrandGrid({
    super.key,
    this.onBrandSelected,
    this.selectedBrandId,
  });

  @override
  State<CarBrandGrid> createState() => _CarBrandGridState();
}

class _CarBrandGridState extends State<CarBrandGrid> {
  final CarBrandService _brandService = CarBrandService();
  final PageController _pageController = PageController();
  int _currentPage = 0;
  static const int _brandsPerPage = 8; // 2 rows × 4 columns

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brands = _brandService.getAllBrands();
    final pageCount = (brands.length / _brandsPerPage).ceil();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Browse by Brand',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 240, // Fixed height for 2 rows with proper spacing
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: pageCount,
            itemBuilder: (context, pageIndex) {
              final startIndex = pageIndex * _brandsPerPage;
              final endIndex = (startIndex + _brandsPerPage).clamp(0, brands.length);
              final pageBrands = brands.sublist(startIndex, endIndex);

              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: pageBrands.length,
                  itemBuilder: (context, index) {
                    final brand = pageBrands[index];
                    final isSelected = widget.selectedBrandId == brand.id;

                    return _BrandCard(
                      brand: brand,
                      isSelected: isSelected,
                      onTap: () {
                        widget.onBrandSelected?.call(brand);
                      },
                    );
                  },
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 3),
        // Page indicators (dots)
        if (pageCount > 1)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  pageCount,
                  (index) => _buildDotIndicator(index == _currentPage, theme),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDotIndicator(bool isActive, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: isActive
            ? theme.colorScheme.primary
            : theme.colorScheme.primary.withOpacity(0.3),
      ),
    );
  }
}

class _BrandCard extends StatelessWidget {
  final CarBrand brand;
  final bool isSelected;
  final VoidCallback onTap;

  const _BrandCard({
    required this.brand,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withOpacity(0.1)
              : (isDark ? Colors.grey[900] : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Image.asset(
                  brand.logoPath,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.directions_car,
                      size: 32,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                brand.displayName,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : (isDark ? Colors.white70 : Colors.black87),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
    
  }
}

