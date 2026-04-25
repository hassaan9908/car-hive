import 'package:flutter/material.dart';

import '../models/car_brand_model.dart';
import '../services/car_brand_service.dart';

class CarBrandGrid extends StatelessWidget {
  final ValueChanged<CarBrand>? onBrandSelected;
  final String? selectedBrandId;

  const CarBrandGrid({
    super.key,
    this.onBrandSelected,
    this.selectedBrandId,
  });

  static const List<_FeaturedBrandConfig> _featuredBrandConfigs = [
    _FeaturedBrandConfig(id: 'mercedes_benz', label: 'Mercedes'),
    _FeaturedBrandConfig(id: 'audi', label: 'Audi'),
    _FeaturedBrandConfig(id: 'tesla', label: 'Tesla'),
    _FeaturedBrandConfig(id: 'bmw', label: 'BMW'),
    _FeaturedBrandConfig(
      id: 'ferrari',
      label: 'Ferrari',
      fallbackText: 'F',
      fallbackBackground: Color(0xFFFFECE8),
      fallbackForeground: Color(0xFFB71C1C),
    ),
    _FeaturedBrandConfig(id: 'toyota', label: 'Toyota'),
    _FeaturedBrandConfig(id: 'honda', label: 'Honda'),
    _FeaturedBrandConfig(id: 'suzuki', label: 'Suzuki'),
    _FeaturedBrandConfig(id: 'chevrolet', label: 'Chevrolet'),
    _FeaturedBrandConfig(id: 'byd', label: 'BYD'),
  ];

  List<_BrandPresentation> _buildFeaturedBrands() {
    final brandService = CarBrandService();
    final allBrands = {
      for (final brand in brandService.getAllBrands()) brand.id: brand,
    };

    return _featuredBrandConfigs.map((config) {
      final serviceBrand = allBrands[config.id];
      final brand = serviceBrand ??
          CarBrand(
            id: config.id,
            displayName: config.label,
            logoPath: '',
          );

      return _BrandPresentation(
        brand: brand,
        label: config.label,
        logoPath: serviceBrand?.logoPath ?? '',
        fallbackText: config.fallbackText,
        fallbackBackground:
            config.fallbackBackground ?? const Color(0xFFF2F2F2),
        fallbackForeground: config.fallbackForeground ?? const Color(0xFF5A5A5A),
      );
    }).toList(growable: false);
  }

  List<_BrandPresentation> _buildAllBrands() {
    final brandService = CarBrandService();
    final brands = brandService
        .getAllBrands()
        .map(
          (brand) => _BrandPresentation(
            brand: brand,
            label: brand.displayName,
            logoPath: brand.logoPath,
            fallbackBackground: const Color(0xFFF2F2F2),
            fallbackForeground: const Color(0xFF5A5A5A),
          ),
        )
        .toList();

    final hasFerrari = brands.any((brand) => brand.brand.id == 'ferrari');
    if (!hasFerrari) {
      brands.add(
        const _BrandPresentation(
          brand: CarBrand(
            id: 'ferrari',
            displayName: 'Ferrari',
            logoPath: '',
          ),
          label: 'Ferrari',
          logoPath: '',
          fallbackText: 'F',
          fallbackBackground: Color(0xFFFFECE8),
          fallbackForeground: Color(0xFFB71C1C),
        ),
      );
    }

    brands.sort(
      (first, second) =>
          first.label.toLowerCase().compareTo(second.label.toLowerCase()),
    );

    return brands;
  }

  Future<void> _showAllBrandsSheet(BuildContext context) async {
    final theme = Theme.of(context);
    final allBrands = _buildAllBrands();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF121212),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Text(
                        'All Brands',
                        style: theme.textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ) ??
                            const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 16,
                    runSpacing: 18,
                    children: [
                      for (final brand in allBrands)
                        _BrandCircleCard(
                          brand: brand,
                          isSelected: selectedBrandId == brand.brand.id,
                          onTap: () {
                            Navigator.of(context).pop();
                            onBrandSelected?.call(brand.brand);
                          },
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final featuredBrands = _buildFeaturedBrands();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              Text(
                'All Brands',
                style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ) ??
                    const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => _showAllBrandsSheet(context),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.primary,
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'View All',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              for (int index = 0; index < featuredBrands.length; index++)
                Padding(
                  padding: EdgeInsets.only(
                    right: index == featuredBrands.length - 1 ? 0 : 14,
                  ),
                  child: _BrandCircleCard(
                    brand: featuredBrands[index],
                    isSelected:
                        selectedBrandId == featuredBrands[index].brand.id,
                    onTap: () => onBrandSelected?.call(featuredBrands[index].brand),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BrandCircleCard extends StatelessWidget {
  final _BrandPresentation brand;
  final bool isSelected;
  final VoidCallback onTap;

  const _BrandCircleCard({
    required this.brand,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final circleBorderColor =
        isSelected ? theme.colorScheme.primary : const Color(0xFFE4E4E4);

    return SizedBox(
      width: 78,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: circleBorderColor,
                      width: isSelected ? 2.4 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.22),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                      if (isSelected)
                        BoxShadow(
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.2),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                    ],
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: _BrandLogo(brand: brand),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  brand.label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    height: 1.15,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandLogo extends StatelessWidget {
  final _BrandPresentation brand;

  const _BrandLogo({
    required this.brand,
  });

  @override
  Widget build(BuildContext context) {
    if (brand.logoPath.isNotEmpty) {
      return Image.asset(
        brand.logoPath,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (context, error, stackTrace) => _BrandFallbackIcon(
          text: brand.fallbackText,
          backgroundColor: brand.fallbackBackground,
          foregroundColor: brand.fallbackForeground,
        ),
      );
    }

    return _BrandFallbackIcon(
      text: brand.fallbackText,
      backgroundColor: brand.fallbackBackground,
      foregroundColor: brand.fallbackForeground,
    );
  }
}

class _BrandFallbackIcon extends StatelessWidget {
  final String? text;
  final Color backgroundColor;
  final Color foregroundColor;

  const _BrandFallbackIcon({
    required this.text,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    if (text != null && text!.isNotEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: Text(
          text!,
          style: TextStyle(
            color: foregroundColor,
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }

    return Icon(
      Icons.directions_car_filled_rounded,
      size: 28,
      color: foregroundColor,
    );
  }
}

class _FeaturedBrandConfig {
  final String id;
  final String label;
  final String? fallbackText;
  final Color? fallbackBackground;
  final Color? fallbackForeground;

  const _FeaturedBrandConfig({
    required this.id,
    required this.label,
    this.fallbackText,
    this.fallbackBackground,
    this.fallbackForeground,
  });
}

class _BrandPresentation {
  final CarBrand brand;
  final String label;
  final String logoPath;
  final String? fallbackText;
  final Color fallbackBackground;
  final Color fallbackForeground;

  const _BrandPresentation({
    required this.brand,
    required this.label,
    required this.logoPath,
    this.fallbackText,
    required this.fallbackBackground,
    required this.fallbackForeground,
  });
}
