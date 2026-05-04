import 'dart:async';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

import '../models/ad_model.dart';
import '../services/fuel_price_service.dart';
import '../services/market_pulse_service.dart';
import 'market_pulse_teaser_card.dart';

class HomeMarketplaceSections extends StatefulWidget {
  final Widget? filterSection;
  final Widget? brandsSection;
  final Widget listings;

  const HomeMarketplaceSections({
    super.key,
    this.filterSection,
    this.brandsSection,
    required this.listings,
  });

  @override
  State<HomeMarketplaceSections> createState() =>
      _HomeMarketplaceSectionsState();
}

class _HomeMarketplaceSectionsState extends State<HomeMarketplaceSections> {
  final _service = _HomeMarketplaceSectionsService();
  final _fuelPriceService = FuelPriceService();
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      _fuelPricesSubscription;

  bool _isLoading = true;
  bool _isRefreshingNearYou = false;

  List<_HomeCarItem> _featuredCars = const <_HomeCarItem>[];
  List<_HomeCarItem> _nearbyCars = const <_HomeCarItem>[];
  List<_HomeCarItem> _newTodayCars = const <_HomeCarItem>[];
  List<FuelPriceEntry> _fuelPrices = const <FuelPriceEntry>[];

  _NearYouStatus _nearYouStatus = _NearYouStatus.loading;
  DateTime? _fuelLastUpdated;

  @override
  void initState() {
    super.initState();
    _loadSections();
    _listenToFuelPriceUpdates();
  }

  @override
  void dispose() {
    _fuelPricesSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadSections() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final futures = await Future.wait<dynamic>([
        _service
            .fetchFeaturedCars(limit: 10)
            .timeout(
              const Duration(seconds: 8),
              onTimeout: () => const <_HomeCarItem>[],
            )
            .catchError((_) => const <_HomeCarItem>[]),
        _service
            .fetchNearYou(limit: 10, requestPermission: true)
            .timeout(
              const Duration(seconds: 8),
              onTimeout: () => const _NearYouResult(
                items: <_HomeCarItem>[],
                status: _NearYouStatus.permissionDenied,
              ),
            )
            .catchError(
              (_) => const _NearYouResult(
                items: <_HomeCarItem>[],
                status: _NearYouStatus.permissionDenied,
              ),
            ),
        _service
            .fetchNewToday(limit: 10)
            .timeout(
              const Duration(seconds: 8),
              onTimeout: () => const <_HomeCarItem>[],
            )
            .catchError((_) => const <_HomeCarItem>[]),
        _fuelPriceService
            .fetchFuelPrices()
            .timeout(
              const Duration(seconds: 8),
              onTimeout: () => FuelPricesPayload(
                entries: _fuelPriceService.defaultFuelPrices(),
                lastUpdated: DateTime.now(),
              ),
            )
            .catchError(
              (_) => FuelPricesPayload(
                entries: _fuelPriceService.defaultFuelPrices(),
                lastUpdated: DateTime.now(),
              ),
            ),
      ]);

      if (!mounted) {
        return;
      }

      final featured = futures[0] as List<_HomeCarItem>;
      final nearYouResult = futures[1] as _NearYouResult;
      final newToday = futures[2] as List<_HomeCarItem>;
      final fuelResult = futures[3] as FuelPricesPayload;

      setState(() {
        _featuredCars = featured;
        _nearbyCars = nearYouResult.items;
        _nearYouStatus = nearYouResult.status;
        _newTodayCars = newToday;
        _fuelPrices = fuelResult.entries;
        _fuelLastUpdated = fuelResult.lastUpdated;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _retryNearYou() async {
    setState(() {
      _isRefreshingNearYou = true;
      _nearYouStatus = _NearYouStatus.loading;
    });

    final result = await _service
        .fetchNearYou(limit: 10, requestPermission: true)
        .timeout(
          const Duration(seconds: 8),
          onTimeout: () => const _NearYouResult(
            items: <_HomeCarItem>[],
            status: _NearYouStatus.permissionDenied,
          ),
        )
        .catchError(
          (_) => const _NearYouResult(
            items: <_HomeCarItem>[],
            status: _NearYouStatus.permissionDenied,
          ),
        );

    if (!mounted) {
      return;
    }

    setState(() {
      _nearbyCars = result.items;
      _nearYouStatus = result.status;
      _isRefreshingNearYou = false;
    });
  }

  void _listenToFuelPriceUpdates() {
    _fuelPricesSubscription = FirebaseFirestore.instance
        .collection('fuel_prices')
        .snapshots()
        .listen((snapshot) {
      final entries = snapshot.docs
          .map((doc) => FuelPriceEntry.fromFirestore(doc.data()))
          .toList();

      if (entries.isEmpty || !mounted) {
        return;
      }

      final sortedEntries = _fuelPriceService.sortEntries(entries);
      DateTime? latest;
      for (final entry in sortedEntries) {
        if (entry.updatedAt == null) {
          continue;
        }

        if (latest == null || entry.updatedAt!.isAfter(latest)) {
          latest = entry.updatedAt;
        }
      }

      setState(() {
        _fuelPrices = sortedEntries;
        _fuelLastUpdated = latest ?? DateTime.now();
      });
    });
  }

  void _openSeeAll(String title, List<_HomeCarItem> items) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _HomeSeeAllPage(
          title: title,
          items: items,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _HorizontalCarSection(
          icon: Icons.local_fire_department,
          iconColor: const Color(0xFFF48C25),
          title: 'Featured',
          actionLabel: 'See All',
          onActionPress: () => _openSeeAll('Featured Cars', _featuredCars),
          isLoading: _isLoading,
          items: _featuredCars,
          badgeAlignment: _BadgeAlignment.topLeft,
        ),
        _HorizontalCarSection(
          icon: Icons.location_on,
          iconColor: const Color(0xFFF48C25),
          title: 'Near You',
          actionLabel: 'See All',
          onActionPress: () => _openSeeAll('Cars Near You', _nearbyCars),
          isLoading: _isLoading || _isRefreshingNearYou,
          items: _nearbyCars,
          showDistanceLabel: true,
          placeholder: _NearYouPermissionBanner(
            onEnablePressed: _retryNearYou,
            status: _nearYouStatus,
          ),
        ),
        _HorizontalCarSection(
          icon: Icons.new_releases,
          iconColor: const Color(0xFF44B35B),
          title: 'New Today',
          actionLabel: 'See All',
          onActionPress: () => _openSeeAll('New Today', _newTodayCars),
          isLoading: _isLoading,
          items: _newTodayCars,
          badgeAlignment: _BadgeAlignment.topRight,
          emptyState: const _SectionEmptyState(
            icon: Icons.directions_car_outlined,
            message: 'No new listings today. Check back soon!',
          ),
        ),
        if (widget.brandsSection != null) ...[
          const SizedBox(height: 12),
          widget.brandsSection!,
        ],
        if (widget.filterSection != null) ...[
          const SizedBox(height: 12),
          widget.filterSection!,
        ],
        widget.listings,
        const MarketPulseTeaserCard(),
        _FuelPricesSection(
          prices: _fuelPrices,
          lastUpdated: _fuelLastUpdated,
          isLoading: _isLoading,
        ),
      ],
    );
  }
}

class _HorizontalCarSection extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String actionLabel;
  final VoidCallback onActionPress;
  final bool isLoading;
  final List<_HomeCarItem> items;
  final bool showDistanceLabel;
  final _BadgeAlignment? badgeAlignment;
  final Widget? emptyState;
  final Widget? placeholder;

  const _HorizontalCarSection({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.actionLabel,
    required this.onActionPress,
    required this.isLoading,
    required this.items,
    this.showDistanceLabel = false,
    this.badgeAlignment,
    this.emptyState,
    this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: icon,
            iconColor: iconColor,
            title: title,
            actionLabel: actionLabel,
            onActionPress: onActionPress,
          ),
          const SizedBox(height: 10),
          if (placeholder != null && !isLoading && items.isEmpty) placeholder!,
          if (isLoading)
            const _HorizontalSkeletonRow()
          else if (items.isNotEmpty)
            SizedBox(
              height: 224,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final item = items[index];

                  return HomeCarCard(
                    image: item.imageUrl,
                    title: item.title,
                    year: item.year,
                    price: item.price,
                    location: item.location,
                    distanceKm: item.distanceKm,
                    showDistanceLabel: showDistanceLabel,
                    badge: badgeAlignment == null ? null : item.badge,
                    badgeAlignment: badgeAlignment ?? _BadgeAlignment.topLeft,
                    rating: item.rating,
                    onTap: () {
                      if (item.ad.id != null && item.ad.id!.isNotEmpty) {
                        MarketPulseService().trackAdClick(
                          adId: item.ad.id!,
                          city: item.location,
                        );
                      }
                      Navigator.pushNamed(
                        context,
                        '/car-details',
                        arguments: item.ad,
                      );
                    },
                  );
                },
              ),
            )
          else
            emptyState ?? const _SectionEmptyState(),
        ],
      ),
    );
  }
}

class _FuelPricesSection extends StatelessWidget {
  final List<FuelPriceEntry> prices;
  final DateTime? lastUpdated;
  final bool isLoading;

  const _FuelPricesSection({
    required this.prices,
    required this.lastUpdated,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formattedDate = lastUpdated == null
        ? 'Last updated: --'
        : 'Last updated: ${DateFormat('dd MMM yyyy').format(lastUpdated!)}';

    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(
                  Icons.local_gas_station,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Fuel Prices',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  formattedDate,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: isLoading
                ? const _FuelListSkeleton()
                : Column(
                    children: [
                      for (int index = 0; index < prices.length; index++) ...[
                        _FuelPriceRow(item: prices[index]),
                        if (index < prices.length - 1)
                          Divider(
                            height: 1,
                            color: theme.colorScheme.outlineVariant,
                          ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _FuelPriceRow extends StatelessWidget {
  final FuelPriceEntry item;

  const _FuelPriceRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color indicatorColor;
    if (item.change < 0) {
      indicatorColor = const Color(0xFF4CAF50);
    } else if (item.change > 0) {
      indicatorColor = const Color(0xFFE14C4C);
    } else {
      indicatorColor = const Color(0xFF909090);
    }

    final priceLabel =
        'PKR ${NumberFormat('#,##0.00').format(item.price)} /${item.unit}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              item.type,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            priceLabel,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            item.arrowSymbol,
            style: TextStyle(
              color: indicatorColor,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _FuelListSkeleton extends StatelessWidget {
  const _FuelListSkeleton();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        for (int index = 0; index < 4; index++) ...[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Expanded(child: _SkeletonLine(width: 140)),
                SizedBox(width: 12),
                _SkeletonLine(width: 100),
                SizedBox(width: 10),
                _SkeletonLine(width: 12),
              ],
            ),
          ),
          if (index < 3)
            Divider(
              height: 1,
              color: theme.colorScheme.outlineVariant,
            ),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String actionLabel;
  final VoidCallback? onActionPress;

  const _SectionHeader({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.actionLabel,
    required this.onActionPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 8),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: onActionPress,
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              minimumSize: const Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              onActionPress == null ? actionLabel : '$actionLabel  >',
              style: TextStyle(
                color: onActionPress == null
                    ? theme.colorScheme.onSurfaceVariant
                    : theme.colorScheme.primary,
                fontSize: 12,
                fontWeight:
                    onActionPress == null ? FontWeight.w500 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HomeCarCard extends StatelessWidget {
  final String? image;
  final String title;
  final String year;
  final String price;
  final String location;
  final double? distanceKm;
  final bool showDistanceLabel;
  final String? badge;
  final _BadgeAlignment badgeAlignment;
  final double? rating;
  final VoidCallback onTap;

  const HomeCarCard({
    super.key,
    required this.image,
    required this.title,
    required this.year,
    required this.price,
    required this.location,
    required this.distanceKm,
    required this.showDistanceLabel,
    required this.badge,
    required this.badgeAlignment,
    required this.rating,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final badgeText = badge?.trim().toUpperCase();
    final hasBadge = badgeText != null && badgeText.isNotEmpty;

    final Color? badgeColor;
    if (badgeText == 'FEATURED') {
      badgeColor = const Color(0xFFF48C25);
    } else if (badgeText == 'NEW') {
      badgeColor = const Color(0xFF44B35B);
    } else {
      badgeColor = null;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
        height: 220,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 122,
              width: double.infinity,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: _CardImage(image: image),
                  ),
                  if (hasBadge && badgeColor != null)
                    Positioned(
                      left:
                          badgeAlignment == _BadgeAlignment.topLeft ? 8 : null,
                      right:
                          badgeAlignment == _BadgeAlignment.topRight ? 8 : null,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: badgeColor,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          badgeText,
                          style: TextStyle(
                            color: theme.colorScheme.onPrimary,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$title $year',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    price,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                  if (showDistanceLabel && distanceKm != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        '${distanceKm!.toStringAsFixed(0)} km away',
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  if (rating != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              color: Color(0xFFF9C75D), size: 14),
                          const SizedBox(width: 3),
                          Text(
                            rating!.toStringAsFixed(1),
                            style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardImage extends StatelessWidget {
  final String? image;

  const _CardImage({required this.image});

  @override
  Widget build(BuildContext context) {
    if (image == null || image!.trim().isEmpty) {
      return Image.asset(
        'assets/images/Retro.gif',
        fit: BoxFit.cover,
      );
    }

    return CachedNetworkImage(
      imageUrl: image!,
      fit: BoxFit.cover,
      fadeInDuration: const Duration(milliseconds: 150),
      placeholder: (context, _) => Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      errorWidget: (_, __, ___) => Image.asset(
        'assets/images/Retro.gif',
        fit: BoxFit.cover,
      ),
    );
  }
}

class _SectionEmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _SectionEmptyState({
    this.icon = Icons.inbox_outlined,
    this.message = 'No listings available in this section right now.',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Row(
          children: [
            Icon(icon, color: theme.colorScheme.onSurfaceVariant, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NearYouPermissionBanner extends StatelessWidget {
  final VoidCallback onEnablePressed;
  final _NearYouStatus status;

  const _NearYouPermissionBanner({
    required this.onEnablePressed,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final needsPermission = status == _NearYouStatus.permissionDenied ||
        status == _NearYouStatus.permissionDeniedForever ||
        status == _NearYouStatus.serviceDisabled;

    if (!needsPermission) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Row(
          children: [
            Icon(Icons.location_on_outlined, color: theme.colorScheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Enable location to see cars near you',
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            TextButton(
              onPressed: onEnablePressed,
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.primary,
              ),
              child: const Text('Enable'),
            ),
          ],
        ),
      ),
    );
  }
}

class _HorizontalSkeletonRow extends StatelessWidget {
  const _HorizontalSkeletonRow();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 224,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) => const _CarSkeletonCard(),
      ),
    );
  }
}

class _CarSkeletonCard extends StatelessWidget {
  const _CarSkeletonCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 200,
      height: 220,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 122,
            color: theme.colorScheme.surfaceContainerHighest,
          ),
          const Padding(
            padding: EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SkeletonLine(width: 120),
                SizedBox(height: 8),
                _SkeletonLine(width: 90),
                SizedBox(height: 8),
                _SkeletonLine(width: 140),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  final double width;

  const _SkeletonLine({required this.width});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: width,
      height: 10,
      decoration: BoxDecoration(
        color: theme.colorScheme.outlineVariant,
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _HomeSeeAllPage extends StatelessWidget {
  final String title;
  final List<_HomeCarItem> items;

  const _HomeSeeAllPage({
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: items.isEmpty
          ? Center(
              child: Text(
                'No listings available right now',
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = items[index];
                return GestureDetector(
                  onTap: () {
                    if (item.ad.id != null && item.ad.id!.isNotEmpty) {
                      MarketPulseService().trackAdClick(
                        adId: item.ad.id!,
                        city: item.location,
                      );
                    }
                    Navigator.pushNamed(
                      context,
                      '/car-details',
                      arguments: item.ad,
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant,
                      ),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            bottomLeft: Radius.circular(12),
                          ),
                          child: SizedBox(
                            width: 128,
                            height: 98,
                            child: _CardImage(image: item.imageUrl),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.price,
                                  style: TextStyle(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.location,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

enum _BadgeAlignment {
  topLeft,
  topRight,
}

enum _NearYouStatus {
  loading,
  ready,
  permissionDenied,
  permissionDeniedForever,
  serviceDisabled,
}

class _NearYouResult {
  final List<_HomeCarItem> items;
  final _NearYouStatus status;

  const _NearYouResult({
    required this.items,
    required this.status,
  });
}

class _HomeCarItem {
  final AdModel ad;
  final String imageUrl;
  final String title;
  final String year;
  final String price;
  final String location;
  final double? distanceKm;
  final String? badge;
  final double? rating;
  final DateTime? createdAt;
  final int clickCount;
  final int viewCount;

  const _HomeCarItem({
    required this.ad,
    required this.imageUrl,
    required this.title,
    required this.year,
    required this.price,
    required this.location,
    required this.distanceKm,
    required this.badge,
    required this.rating,
    required this.createdAt,
    required this.clickCount,
    required this.viewCount,
  });
}

class _HomeMarketplaceSectionsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static List<_HomeCarItem>? _newTodayCache;
  static DateTime? _newTodayCacheTimestamp;

  Future<List<_HomeCarItem>> fetchFeaturedCars({int limit = 10}) async {
    final snapshot = await _firestore.collection('ads').get();

    final items = snapshot.docs
        .where((doc) => _isActiveOrApproved(doc.data()))
        .map((doc) => _toHomeCarItem(doc, badge: 'FEATURED'))
        .toList();

    items.sort((a, b) {
      final clickComparison = b.clickCount.compareTo(a.clickCount);
      if (clickComparison != 0) {
        return clickComparison;
      }

      return b.viewCount.compareTo(a.viewCount);
    });

    return items.take(limit).toList();
  }

  Future<List<_HomeCarItem>> fetchNewToday({int limit = 10}) async {
    final now = DateTime.now();

    if (_newTodayCache != null && _newTodayCacheTimestamp != null) {
      final age = now.difference(_newTodayCacheTimestamp!);
      if (age < const Duration(minutes: 5)) {
        return _newTodayCache!.take(limit).toList();
      }
    }

    final snapshot = await _firestore.collection('ads').get();
    final threshold = now.subtract(const Duration(hours: 24));

    final items = snapshot.docs
        .where((doc) => _isActiveOrApproved(doc.data()))
        .map((doc) => _toHomeCarItem(doc, badge: 'NEW'))
        .where((item) =>
            item.createdAt != null && item.createdAt!.isAfter(threshold))
        .toList();

    items.sort((a, b) {
      final left = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final right = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return right.compareTo(left);
    });

    _newTodayCache = items;
    _newTodayCacheTimestamp = now;

    return items.take(limit).toList();
  }

  Future<_NearYouResult> fetchNearYou({
    required int limit,
    required bool requestPermission,
  }) async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return const _NearYouResult(
        items: <_HomeCarItem>[],
        status: _NearYouStatus.serviceDisabled,
      );
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied && requestPermission) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      return const _NearYouResult(
        items: <_HomeCarItem>[],
        status: _NearYouStatus.permissionDenied,
      );
    }

    if (permission == LocationPermission.deniedForever) {
      return const _NearYouResult(
        items: <_HomeCarItem>[],
        status: _NearYouStatus.permissionDeniedForever,
      );
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    final snapshot = await _firestore.collection('ads').get();

    final items = snapshot.docs
        .where((doc) => _isActiveOrApproved(doc.data()))
        .map((doc) => _toHomeCarItem(doc))
        .where((item) => item.ad.locationCoordinates != null)
        .map((item) {
          final coords = item.ad.locationCoordinates!;
          final distance = _distanceInKm(
            position.latitude,
            position.longitude,
            coords['lat'] ?? 0,
            coords['lng'] ?? 0,
          );

          return _HomeCarItem(
            ad: item.ad,
            imageUrl: item.imageUrl,
            title: item.title,
            year: item.year,
            price: item.price,
            location: item.location,
            distanceKm: distance,
            badge: null,
            rating: item.rating,
            createdAt: item.createdAt,
            clickCount: item.clickCount,
            viewCount: item.viewCount,
          );
        })
        .where((item) => (item.distanceKm ?? 99999) <= 25)
        .toList();

    items.sort(
      (a, b) => (a.distanceKm ?? 99999).compareTo(b.distanceKm ?? 99999),
    );

    return _NearYouResult(
      items: items.take(limit).toList(),
      status: _NearYouStatus.ready,
    );
  }

  bool _isActiveOrApproved(Map<String, dynamic> data) {
    final status = (data['status'] ?? '').toString().toLowerCase();
    return status == 'active' || status == 'approved';
  }

  _HomeCarItem _toHomeCarItem(
    QueryDocumentSnapshot<Map<String, dynamic>> doc, {
    String? badge,
  }) {
    final ad = AdModel.fromFirestore(doc.data(), doc.id);
    final data = doc.data();

    final imageUrl = ad.imageUrls != null && ad.imageUrls!.isNotEmpty
        ? ad.imageUrls!.first
        : '';

    final brand = (ad.carBrand ?? '').trim();
    final model = (ad.carName ?? '').trim();

    String title = ad.title.trim();
    if (title.isEmpty && brand.isNotEmpty && model.isNotEmpty) {
      title = '$brand $model';
    } else if (title.isEmpty && brand.isNotEmpty) {
      title = brand;
    } else if (title.isEmpty) {
      title = 'Car Listing';
    }

    final rating = _toDouble(data['rating']) ??
        _toDouble(data['avg_rating']) ??
        _toDouble(data['averageRating']);

    final clickCount =
        _toInt(data['click_count']) ?? _toInt(data['clicks']) ?? 0;
    final viewCount = _toInt(data['view_count']) ?? _toInt(data['views']) ?? 0;

    return _HomeCarItem(
      ad: ad,
      imageUrl: imageUrl,
      title: title,
      year: ad.year.trim(),
      price: ad.price.trim().isEmpty ? 'Price on request' : ad.price,
      location: ad.location.trim().isEmpty ? 'Location not set' : ad.location,
      distanceKm: null,
      badge: badge,
      rating: rating,
      createdAt: ad.createdAt,
      clickCount: clickCount,
      viewCount: viewCount,
    );
  }

  double _distanceInKm(double lat1, double lng1, double lat2, double lng2) {
    const earthRadiusKm = 6371.0;

    final dLat = _degreesToRadians(lat2 - lat1);
    final dLng = _degreesToRadians(lng2 - lng1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180.0);
  }

  int? _toInt(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    if (value is double) {
      return value.toInt();
    }

    return int.tryParse(value.toString());
  }

  double? _toDouble(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is double) {
      return value;
    }

    if (value is int) {
      return value.toDouble();
    }

    return double.tryParse(value.toString());
  }
}
