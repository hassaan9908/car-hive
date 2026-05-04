import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/ad_model.dart';
import '../models/market_pulse_models.dart';
import 'car_brand_service.dart';

class MarketPulseService {
  MarketPulseService._();

  static final MarketPulseService _instance = MarketPulseService._();
  factory MarketPulseService() => _instance;

  static const Duration _cacheTtl = Duration(hours: 1);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CarBrandService _brandService = CarBrandService();

  static final Map<String, _MemorySectionEntry> _sectionCache =
      <String, _MemorySectionEntry>{};
  static final Map<String, _MemoryCollectionEntry> _collectionCache =
      <String, _MemoryCollectionEntry>{};

  static const List<String> _featuredCities = <String>[
    'Karachi',
    'Lahore',
    'Islamabad',
    'Rawalpindi',
    'Peshawar',
    'Multan',
    'Faisalabad',
    'Quetta',
  ];

  Future<MarketPulseSection<MarketPulseHomeTeaser>> getHomeTeaser({
    bool forceRefresh = false,
  }) {
    return _resolveSection<MarketPulseHomeTeaser>(
      key: 'home_teaser_week',
      forceRefresh: forceRefresh,
      fromCache: (raw) => MarketPulseHomeTeaser.fromMap(
        Map<String, dynamic>.from(raw as Map),
      ),
      toCache: (value) => value.toMap(),
      compute: () async {
        final range = _resolveRange(
          period: MarketPulsePeriod.week,
          customRange: null,
        );
        final current = await _averagePriceForModel(
          brand: 'Toyota',
          model: 'Corolla',
          year: 2020,
          range: range,
        );
        final previous = await _averagePriceForModel(
          brand: 'Toyota',
          model: 'Corolla',
          year: 2020,
          range: _DateWindow(
            start: range.start.subtract(range.duration),
            end: range.start,
          ),
        );

        final changePercent = previous > 0
            ? ((current - previous) / previous) * 100
            : (current > 0 ? 4.0 : 0.0);

        return MarketPulseSection<MarketPulseHomeTeaser>(
          data: MarketPulseHomeTeaser(
            title: 'Toyota Corolla avg price',
            subtitle:
                '${changePercent >= 0 ? 'up' : 'down'} ${changePercent.abs().toStringAsFixed(0)}% this week',
            changePercent: changePercent,
            updatedAt: DateTime.now(),
          ),
          updatedAt: DateTime.now(),
        );
      },
    );
  }

  Future<MarketPulseSection<List<MarketPulseCityPriceEntry>>> getAvgPriceByCity(
    MarketPulsePeriod period, {
    DateTimeRange? customRange,
    bool forceRefresh = false,
  }) {
    final window = _resolveRange(period: period, customRange: customRange);

    return _resolveSection<List<MarketPulseCityPriceEntry>>(
      key: 'avg_price_by_city_${_rangeCacheKey(period, customRange)}',
      forceRefresh: forceRefresh,
      fromCache: (raw) => ((raw as List?) ?? const <dynamic>[])
          .whereType<Map>()
          .map((item) => MarketPulseCityPriceEntry.fromMap(
                Map<String, dynamic>.from(item),
              ))
          .toList(),
      toCache: (value) => value.map((item) => item.toMap()).toList(),
      compute: () async {
        final ads = await _loadAds(forceRefresh: forceRefresh);
        final grouped = <String, List<double>>{};
        final counts = <String, int>{};

        for (final ad in ads) {
          if (!_isActiveAd(ad)) {
            continue;
          }
          final createdAt = ad.createdAt;
          if (createdAt != null &&
              createdAt
                  .isBefore(window.start.subtract(const Duration(days: 90)))) {
            continue;
          }
          final city = _normalizeCity(ad.location);
          if (!_featuredCities.contains(city)) {
            continue;
          }
          final price = _parsePrice(ad.price);
          if (price <= 0) {
            continue;
          }
          grouped.putIfAbsent(city, () => <double>[]).add(price);
          counts[city] = (counts[city] ?? 0) + 1;
        }

        final entries = _featuredCities
            .where((city) => grouped.containsKey(city))
            .map((city) {
          final prices = grouped[city]!;
          final avg = prices.reduce((a, b) => a + b) / prices.length;
          return MarketPulseCityPriceEntry(
            city: city,
            avgPrice: avg,
            listingCount: counts[city] ?? prices.length,
          );
        }).toList()
          ..sort((a, b) => b.avgPrice.compareTo(a.avgPrice));

        return MarketPulseSection<List<MarketPulseCityPriceEntry>>(
          data: entries.take(8).toList(),
          updatedAt: DateTime.now(),
        );
      },
    );
  }

  Future<MarketPulseSection<List<MarketPulseModelEntry>>> getTopModels(
    MarketPulsePeriod period, {
    required MarketPulseModelMode mode,
    DateTimeRange? customRange,
    bool forceRefresh = false,
  }) {
    final window = _resolveRange(period: period, customRange: customRange);

    return _resolveSection<List<MarketPulseModelEntry>>(
      key: 'top_models_${mode.cacheKey}_${_rangeCacheKey(period, customRange)}',
      forceRefresh: forceRefresh,
      fromCache: (raw) => ((raw as List?) ?? const <dynamic>[])
          .whereType<Map>()
          .map((item) => MarketPulseModelEntry.fromMap(
                Map<String, dynamic>.from(item),
              ))
          .toList(),
      toCache: (value) => value.map((item) => item.toMap()).toList(),
      compute: () async {
        final ads = await _loadAds(forceRefresh: forceRefresh);
        final counts = <String, int>{};
        final metadata = <String, MarketPulseModelEntry>{};

        for (final ad in ads) {
          final brand = (ad.carBrand ?? '').trim();
          final model = (ad.carName ?? '').trim();
          if (brand.isEmpty || model.isEmpty) {
            continue;
          }

          final targetDate = mode == MarketPulseModelMode.sold
              ? await _soldAtForAd(ad.id)
              : ad.createdAt;

          final qualifies = mode == MarketPulseModelMode.sold
              ? ad.status.toLowerCase() == 'sold'
              : _isActiveAd(ad);

          if (!qualifies ||
              targetDate == null ||
              !_inWindow(targetDate, window)) {
            continue;
          }

          final key = '${brand.toLowerCase()}::${model.toLowerCase()}';
          counts[key] = (counts[key] ?? 0) + 1;
          metadata[key] = MarketPulseModelEntry(
            brand: brand,
            model: model,
            count: counts[key] ?? 0,
          );
        }

        final results = metadata.entries
            .map((entry) => MarketPulseModelEntry(
                  brand: entry.value.brand,
                  model: entry.value.model,
                  count: counts[entry.key] ?? entry.value.count,
                ))
            .toList()
          ..sort((a, b) => b.count.compareTo(a.count));

        return MarketPulseSection<List<MarketPulseModelEntry>>(
          data: results.take(10).toList(),
          updatedAt: DateTime.now(),
        );
      },
    );
  }

  Future<MarketPulseSection<List<MarketPulseBrandEntry>>> getTrendingBrands(
    MarketPulsePeriod period, {
    DateTimeRange? customRange,
    bool forceRefresh = false,
  }) {
    final window = _resolveRange(period: period, customRange: customRange);
    final previousWindow = _DateWindow(
      start: window.start.subtract(window.duration),
      end: window.start,
    );

    return _resolveSection<List<MarketPulseBrandEntry>>(
      key: 'trending_brands_${_rangeCacheKey(period, customRange)}',
      forceRefresh: forceRefresh,
      fromCache: (raw) => ((raw as List?) ?? const <dynamic>[])
          .whereType<Map>()
          .map((item) => MarketPulseBrandEntry.fromMap(
                Map<String, dynamic>.from(item),
              ))
          .toList(),
      toCache: (value) => value.map((item) => item.toMap()).toList(),
      compute: () async {
        final logs = await _loadSearchLogs(forceRefresh: forceRefresh);
        final current = <String, int>{};
        final previous = <String, int>{};

        for (final log in logs) {
          final createdAt =
              _readDate(log['timestamp']) ?? _readDate(log['createdAt']);
          if (createdAt == null) {
            continue;
          }
          final brand = _extractBrandFromSearch(log);
          if (brand.isEmpty) {
            continue;
          }
          if (_inWindow(createdAt, window)) {
            current[brand] = (current[brand] ?? 0) + 1;
          } else if (_inWindow(createdAt, previousWindow)) {
            previous[brand] = (previous[brand] ?? 0) + 1;
          }
        }

        if (current.isEmpty) {
          final ads = await _loadAds(forceRefresh: forceRefresh);
          for (final ad in ads) {
            final brand = (ad.carBrand ?? '').trim();
            if (brand.isEmpty) {
              continue;
            }
            current[brand] = (current[brand] ?? 0) + 1;
          }
        }

        final sorted = current.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        final topBrands = sorted.take(8).toList();
        final results = <MarketPulseBrandEntry>[];

        for (var i = 0; i < topBrands.length; i++) {
          final entry = topBrands[i];
          final prevValue = previous[entry.key] ?? 0;
          String trend = 'stable';
          if (i < 3) {
            trend = 'hot';
          } else if (entry.value > math.max(2, prevValue * 1.2)) {
            trend = 'rising';
          } else if (prevValue > 0 && entry.value < prevValue) {
            trend = 'dropping';
          }

          results.add(
            MarketPulseBrandEntry(
              brand: entry.key,
              searchCount: entry.value,
              trend: trend,
              logoPath: _brandService.getBrandByName(entry.key)?.logoPath,
            ),
          );
        }

        return MarketPulseSection<List<MarketPulseBrandEntry>>(
          data: results,
          updatedAt: DateTime.now(),
        );
      },
    );
  }

  Future<MarketPulseSection<MarketPulseTrendSeries>> getPriceTrend(
    MarketPulsePeriod period, {
    MarketPulseTrendModelOption? selectedModel,
    DateTimeRange? customRange,
    bool forceRefresh = false,
  }) async {
    final optionsSection =
        await getTrendModelOptions(forceRefresh: forceRefresh);
    final options = optionsSection.data;
    final selected = selectedModel ??
        (options.isNotEmpty
            ? options.first
            : const MarketPulseTrendModelOption(
                brand: 'Toyota',
                model: 'Corolla',
                year: 2020,
              ));
    final window = _resolveRange(period: period, customRange: customRange);

    return _resolveSection<MarketPulseTrendSeries>(
      key: 'price_trend_${selected.key}_${_rangeCacheKey(period, customRange)}',
      forceRefresh: forceRefresh,
      fromCache: (raw) => MarketPulseTrendSeries.fromMap(
        Map<String, dynamic>.from(raw as Map),
      ),
      toCache: (value) => value.toMap(),
      compute: () async {
        final ads = await _loadAds(forceRefresh: forceRefresh);
        final buckets = <DateTime, List<double>>{};

        for (final ad in ads) {
          final matchesBrand = (ad.carBrand ?? '').trim().toLowerCase() ==
              selected.brand.toLowerCase();
          final matchesModel = (ad.carName ?? '').trim().toLowerCase() ==
              selected.model.toLowerCase();
          final matchesYear = int.tryParse(ad.year) == selected.year;
          final createdAt = ad.createdAt;
          if (!matchesBrand ||
              !matchesModel ||
              !matchesYear ||
              createdAt == null ||
              !_inWindow(createdAt, window)) {
            continue;
          }
          final price = _parsePrice(ad.price);
          if (price <= 0) {
            continue;
          }
          final bucket = _bucketDate(createdAt, period, window.start);
          buckets.putIfAbsent(bucket, () => <double>[]).add(price);
        }

        final points = buckets.entries
            .map((entry) => MarketPulseTrendPoint(
                  date: entry.key,
                  avgPrice:
                      entry.value.reduce((a, b) => a + b) / entry.value.length,
                ))
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));

        final series = points.isNotEmpty
            ? points
            : _buildFallbackTrend(selected, period, window.start);

        return MarketPulseSection<MarketPulseTrendSeries>(
          data: MarketPulseTrendSeries(
            selectedModel: selected,
            options: options,
            points: series,
          ),
          updatedAt: DateTime.now(),
        );
      },
    );
  }

  Future<MarketPulseSection<List<MarketPulseTrendModelOption>>>
      getTrendModelOptions({
    bool forceRefresh = false,
  }) {
    return _resolveSection<List<MarketPulseTrendModelOption>>(
      key: 'trend_model_options',
      forceRefresh: forceRefresh,
      fromCache: (raw) => ((raw as List?) ?? const <dynamic>[])
          .whereType<Map>()
          .map((item) => MarketPulseTrendModelOption.fromMap(
                Map<String, dynamic>.from(item),
              ))
          .toList(),
      toCache: (value) => value.map((item) => item.toMap()).toList(),
      compute: () async {
        final ads = await _loadAds(forceRefresh: forceRefresh);
        final counts = <String, int>{};
        final options = <String, MarketPulseTrendModelOption>{};

        for (final ad in ads) {
          final brand = (ad.carBrand ?? '').trim();
          final model = (ad.carName ?? '').trim();
          final year = int.tryParse(ad.year);
          if (brand.isEmpty || model.isEmpty || year == null) {
            continue;
          }
          final option = MarketPulseTrendModelOption(
            brand: brand,
            model: model,
            year: year,
          );
          counts[option.key] = (counts[option.key] ?? 0) + 1;
          options[option.key] = option;
        }

        final sortedKeys = counts.keys.toList()
          ..sort((a, b) => (counts[b] ?? 0).compareTo(counts[a] ?? 0));

        final resolved =
            sortedKeys.map((key) => options[key]!).take(8).toList();

        if (resolved.isEmpty) {
          resolved.add(
            const MarketPulseTrendModelOption(
              brand: 'Toyota',
              model: 'Corolla',
              year: 2020,
            ),
          );
        }

        return MarketPulseSection<List<MarketPulseTrendModelOption>>(
          data: resolved,
          updatedAt: DateTime.now(),
        );
      },
    );
  }

  Future<MarketPulseSection<List<MarketPulseActivityMetric>>> getActivityStats(
    MarketPulsePeriod period, {
    DateTimeRange? customRange,
    bool forceRefresh = false,
  }) {
    final window = _resolveRange(period: period, customRange: customRange);
    final previousWindow = _DateWindow(
      start: window.start.subtract(window.duration),
      end: window.start,
    );

    return _resolveSection<List<MarketPulseActivityMetric>>(
      key: 'activity_stats_${_rangeCacheKey(period, customRange)}',
      forceRefresh: forceRefresh,
      fromCache: (raw) => ((raw as List?) ?? const <dynamic>[])
          .whereType<Map>()
          .map((item) => MarketPulseActivityMetric.fromMap(
                Map<String, dynamic>.from(item),
              ))
          .toList(),
      toCache: (value) => value.map((item) => item.toMap()).toList(),
      compute: () async {
        final ads = await _loadAds(forceRefresh: forceRefresh);
        final searchLogs = await _loadSearchLogs(forceRefresh: forceRefresh);
        final viewLogs = await _loadAnalyticsCollection(
          'analytics_views',
          forceRefresh: forceRefresh,
        );
        final dealLogs = await _loadAnalyticsCollection(
          'analytics_deals',
          forceRefresh: forceRefresh,
        );

        int currentViews = 0;
        int previousViews = 0;
        for (final item in viewLogs) {
          final createdAt =
              _readDate(item['timestamp']) ?? _readDate(item['createdAt']);
          if (createdAt == null) {
            continue;
          }
          final type = (item['eventType'] ?? 'view').toString();
          if (type != 'view') {
            continue;
          }
          if (_inWindow(createdAt, window)) {
            currentViews++;
          } else if (_inWindow(createdAt, previousWindow)) {
            previousViews++;
          }
        }

        if (currentViews == 0 && previousViews == 0) {
          currentViews =
              await _sumInsightField('views', forceRefresh: forceRefresh);
        }

        int activeAds = 0;
        int activeAdsDelta = 0;
        for (final ad in ads) {
          if (_isActiveAd(ad)) {
            activeAds++;
          }
          if (_isActiveAd(ad) &&
              ad.createdAt != null &&
              _inWindow(ad.createdAt!, window)) {
            activeAdsDelta++;
          }
        }

        int currentSearches = 0;
        int previousSearches = 0;
        for (final item in searchLogs) {
          final createdAt =
              _readDate(item['timestamp']) ?? _readDate(item['createdAt']);
          if (createdAt == null) {
            continue;
          }
          if (_inWindow(createdAt, window)) {
            currentSearches++;
          } else if (_inWindow(createdAt, previousWindow)) {
            previousSearches++;
          }
        }

        int currentDeals = 0;
        int previousDeals = 0;
        for (final item in dealLogs) {
          final createdAt =
              _readDate(item['timestamp']) ?? _readDate(item['createdAt']);
          if (createdAt == null) {
            continue;
          }
          if (_inWindow(createdAt, window)) {
            currentDeals++;
          } else if (_inWindow(createdAt, previousWindow)) {
            previousDeals++;
          }
        }

        if (currentDeals == 0 && previousDeals == 0) {
          for (final ad in ads) {
            if (ad.status.toLowerCase() != 'sold') {
              continue;
            }
            final soldAt = await _soldAtForAd(ad.id);
            if (soldAt == null) {
              continue;
            }
            if (_inWindow(soldAt, window)) {
              currentDeals++;
            } else if (_inWindow(soldAt, previousWindow)) {
              previousDeals++;
            }
          }
        }

        return MarketPulseSection<List<MarketPulseActivityMetric>>(
          data: <MarketPulseActivityMetric>[
            MarketPulseActivityMetric(
              id: 'views',
              label: 'Total Views',
              total: currentViews,
              delta: currentViews - previousViews,
            ),
            MarketPulseActivityMetric(
              id: 'active_ads',
              label: 'Active Ads',
              total: activeAds,
              delta: activeAdsDelta,
            ),
            MarketPulseActivityMetric(
              id: 'searches',
              label: 'Searches',
              total: currentSearches,
              delta: currentSearches - previousSearches,
            ),
            MarketPulseActivityMetric(
              id: 'deals',
              label: 'Deals Done',
              total: currentDeals,
              delta: currentDeals - previousDeals,
            ),
          ],
          updatedAt: DateTime.now(),
        );
      },
    );
  }

  Future<MarketPulseSection<List<MarketPulseRegionEntry>>> getRegionActivity(
    MarketPulsePeriod period, {
    DateTimeRange? customRange,
    bool forceRefresh = false,
  }) {
    final window = _resolveRange(period: period, customRange: customRange);

    return _resolveSection<List<MarketPulseRegionEntry>>(
      key: 'region_activity_${_rangeCacheKey(period, customRange)}',
      forceRefresh: forceRefresh,
      fromCache: (raw) => ((raw as List?) ?? const <dynamic>[])
          .whereType<Map>()
          .map((item) => MarketPulseRegionEntry.fromMap(
                Map<String, dynamic>.from(item),
              ))
          .toList(),
      toCache: (value) => value.map((item) => item.toMap()).toList(),
      compute: () async {
        final citySection = await getAvgPriceByCity(
          period,
          customRange: customRange,
          forceRefresh: forceRefresh,
        );
        final searchLogs = await _loadSearchLogs(forceRefresh: forceRefresh);
        final searchCounts = <String, int>{};

        for (final item in searchLogs) {
          final createdAt =
              _readDate(item['timestamp']) ?? _readDate(item['createdAt']);
          if (createdAt == null || !_inWindow(createdAt, window)) {
            continue;
          }
          final city = _normalizeCity((item['city'] ?? '').toString());
          if (city.isEmpty) {
            continue;
          }
          searchCounts[city] = (searchCounts[city] ?? 0) + 1;
        }

        final results = citySection.data
            .where((entry) => marketPulseCityPositions.containsKey(entry.city))
            .map((entry) {
          final position = marketPulseCityPositions[entry.city]!;
          final searches = searchCounts[entry.city] ?? 0;
          return MarketPulseRegionEntry(
            city: entry.city,
            activityCount: entry.listingCount + searches,
            listingCount: entry.listingCount,
            avgPrice: entry.avgPrice,
            x: position.dx,
            y: position.dy,
          );
        }).toList()
          ..sort((a, b) => b.activityCount.compareTo(a.activityCount));

        return MarketPulseSection<List<MarketPulseRegionEntry>>(
          data: results,
          updatedAt: DateTime.now(),
        );
      },
    );
  }

  Future<MarketPulseSection<MarketPulseAdminExtras>> getAdminExtras(
    MarketPulsePeriod period, {
    DateTimeRange? customRange,
    bool forceRefresh = false,
  }) {
    final window = _resolveRange(period: period, customRange: customRange);

    return _resolveSection<MarketPulseAdminExtras>(
      key: 'admin_extras_${_rangeCacheKey(period, customRange)}',
      forceRefresh: forceRefresh,
      fromCache: (raw) => MarketPulseAdminExtras.fromMap(
        Map<String, dynamic>.from(raw as Map),
      ),
      toCache: (value) => value.toMap(),
      compute: () async {
        final users = await _loadCollectionDocs(
          'users',
          forceRefresh: forceRefresh,
        );
        final promotions = await _loadAnalyticsCollection(
          'ad_promotions',
          forceRefresh: forceRefresh,
        );
        final ads = await _loadAds(forceRefresh: forceRefresh);

        int newUsersToday = 0;
        int newUsersThisWeek = 0;
        for (final user in users) {
          final createdAt = _readDate(user.data()['createdAt']) ??
              _readDate(user.data()['updatedAt']);
          if (createdAt == null) {
            continue;
          }
          if (_inWindow(
            createdAt,
            _DateWindow(
              start: DateTime.now().subtract(const Duration(days: 1)),
              end: DateTime.now(),
            ),
          )) {
            newUsersToday++;
          }
          if (_inWindow(
            createdAt,
            _DateWindow(
              start: DateTime.now().subtract(const Duration(days: 7)),
              end: DateTime.now(),
            ),
          )) {
            newUsersThisWeek++;
          }
        }

        double revenue = 0;
        for (final promotion in promotions) {
          final createdAt = _readDate(promotion['timestamp']) ??
              _readDate(promotion['createdAt']);
          if (createdAt == null || !_inWindow(createdAt, window)) {
            continue;
          }
          revenue += _readDouble(promotion['amount']);
        }

        int reportedAdsCount = 0;
        final reportedUsers = <String, int>{};
        for (final ad in ads) {
          final data = ad.toFirestore();
          final reportCount = _readInt(data['reportCount']);
          if (reportCount > 0) {
            reportedAdsCount++;
            final ownerLabel = ad.userId ?? 'Unknown user';
            reportedUsers[ownerLabel] =
                (reportedUsers[ownerLabel] ?? 0) + reportCount;
          }
        }

        final mostReportedUsers = reportedUsers.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        return MarketPulseSection<MarketPulseAdminExtras>(
          data: MarketPulseAdminExtras(
            totalRegisteredUsers: users.length,
            newUsersToday: newUsersToday,
            newUsersThisWeek: newUsersThisWeek,
            featuredRevenue: revenue,
            reportedAdsCount: reportedAdsCount,
            mostReportedUsers: mostReportedUsers
                .take(5)
                .map(
                  (entry) => MarketPulseReportedUser(
                    userLabel: entry.key,
                    reportCount: entry.value,
                  ),
                )
                .toList(),
          ),
          updatedAt: DateTime.now(),
        );
      },
    );
  }

  Future<String> buildCsvReport(
    MarketPulsePeriod period, {
    DateTimeRange? customRange,
  }) async {
    final avgCity = await getAvgPriceByCity(
      period,
      customRange: customRange,
      forceRefresh: true,
    );
    final topModels = await getTopModels(
      period,
      mode: MarketPulseModelMode.sold,
      customRange: customRange,
      forceRefresh: true,
    );
    final brands = await getTrendingBrands(
      period,
      customRange: customRange,
      forceRefresh: true,
    );
    final activity = await getActivityStats(
      period,
      customRange: customRange,
      forceRefresh: true,
    );
    final admin = await getAdminExtras(
      period,
      customRange: customRange,
      forceRefresh: true,
    );

    final buffer = StringBuffer();
    buffer.writeln('section,name,value,extra');
    for (final item in avgCity.data) {
      buffer.writeln(
        'avg_price_by_city,${item.city},${item.avgPrice.toStringAsFixed(0)},${item.listingCount} listings',
      );
    }
    for (final item in topModels.data) {
      buffer.writeln('top_models,${item.displayName},${item.count},');
    }
    for (final item in brands.data) {
      buffer.writeln(
        'trending_brands,${item.brand},${item.searchCount},${item.trend}',
      );
    }
    for (final item in activity.data) {
      buffer.writeln('activity,${item.label},${item.total},${item.delta}');
    }
    buffer.writeln(
      'admin,total_registered_users,${admin.data.totalRegisteredUsers},',
    );
    buffer.writeln('admin,new_users_today,${admin.data.newUsersToday},');
    buffer.writeln('admin,new_users_this_week,${admin.data.newUsersThisWeek},');
    buffer.writeln(
      'admin,featured_revenue,${admin.data.featuredRevenue.toStringAsFixed(0)},',
    );
    buffer.writeln('admin,reported_ads,${admin.data.reportedAdsCount},');
    for (final item in admin.data.mostReportedUsers) {
      buffer.writeln(
        'admin_reported_users,${item.userLabel},${item.reportCount},',
      );
    }
    return buffer.toString();
  }

  Future<void> trackSearchQuery({
    required String query,
    String? brand,
    String? model,
    String? city,
  }) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) {
      return;
    }
    final user = _auth.currentUser;
    final data = <String, dynamic>{
      'query': trimmed,
      'brand': brand ?? _extractBrandFromQuery(trimmed),
      'model': model,
      'city': city,
      'userId': user?.uid,
      'timestamp': FieldValue.serverTimestamp(),
    };
    await _firestore.collection('analytics_searches').add(data);
    await _firestore.collection('search_logs').add(data);
    _invalidateCaches();
  }

  Future<void> trackFilterUsed({
    required String filterType,
    required String value,
  }) async {
    if (value.trim().isEmpty) {
      return;
    }
    final user = _auth.currentUser;
    await _firestore.collection('analytics_filters').add({
      'filterType': filterType,
      'value': value,
      'userId': user?.uid,
      'timestamp': FieldValue.serverTimestamp(),
    });
    _invalidateCaches();
  }

  Future<void> trackAdView({
    required String adId,
    String? city,
  }) async {
    final user = _auth.currentUser;
    await _firestore.collection('analytics_views').add({
      'adId': adId,
      'eventType': 'view',
      'userId': user?.uid,
      'city': city,
      'timestamp': FieldValue.serverTimestamp(),
    });
    _invalidateCaches();
  }

  Future<void> trackAdClick({
    required String adId,
    String? city,
  }) async {
    final user = _auth.currentUser;
    await _firestore.collection('analytics_views').add({
      'adId': adId,
      'eventType': 'click',
      'userId': user?.uid,
      'city': city,
      'timestamp': FieldValue.serverTimestamp(),
    });
    _invalidateCaches();
  }

  Future<void> trackDealCompleted({
    required String adId,
    required double price,
    String? city,
  }) async {
    final user = _auth.currentUser;
    await _firestore.collection('analytics_deals').add({
      'adId': adId,
      'price': price,
      'city': city,
      'userId': user?.uid,
      'timestamp': FieldValue.serverTimestamp(),
    });
    _invalidateCaches();
  }

  Future<void> trackPromotionPurchase({
    required String adId,
    required int amount,
    required String packageId,
  }) async {
    final user = _auth.currentUser;
    await _firestore.collection('ad_promotions').add({
      'adId': adId,
      'amount': amount,
      'packageId': packageId,
      'userId': user?.uid,
      'timestamp': FieldValue.serverTimestamp(),
    });
    _invalidateCaches();
  }

  Future<MarketPulseSection<T>> _resolveSection<T>({
    required String key,
    required bool forceRefresh,
    required T Function(dynamic raw) fromCache,
    required dynamic Function(T value) toCache,
    required Future<MarketPulseSection<T>> Function() compute,
  }) async {
    final now = DateTime.now();
    final memoryEntry = _sectionCache[key];
    if (!forceRefresh &&
        memoryEntry != null &&
        now.difference(memoryEntry.updatedAt) < _cacheTtl) {
      return memoryEntry.section as MarketPulseSection<T>;
    }

    if (!forceRefresh) {
      final doc =
          await _firestore.collection('marketpulse_cache').doc(key).get();
      if (doc.exists) {
        final data = doc.data() ?? <String, dynamic>{};
        final updatedAt = _readDate(data['updatedAt']);
        if (updatedAt != null && now.difference(updatedAt) < _cacheTtl) {
          final section = MarketPulseSection<T>(
            data: fromCache(data['data']),
            updatedAt: updatedAt,
          );
          _sectionCache[key] = _MemorySectionEntry(
            section: section,
            updatedAt: updatedAt,
          );
          return section;
        }
      }
    }

    final computed = await compute();
    _sectionCache[key] = _MemorySectionEntry(
      section: computed,
      updatedAt: computed.updatedAt,
    );
    unawaited(
      _firestore.collection('marketpulse_cache').doc(key).set(
        <String, dynamic>{
          'updatedAt': Timestamp.fromDate(computed.updatedAt),
          'data': toCache(computed.data),
        },
        SetOptions(merge: true),
      ),
    );
    return computed;
  }

  Future<List<AdModel>> _loadAds({required bool forceRefresh}) async {
    const key = 'ads';
    final cached = _collectionCache[key];
    final now = DateTime.now();
    if (!forceRefresh &&
        cached != null &&
        now.difference(cached.updatedAt) < _cacheTtl) {
      return (cached.data as List<AdModel>);
    }

    final snapshot = await _firestore.collection('ads').get();
    final ads = snapshot.docs
        .map((doc) => AdModel.fromFirestore(doc.data(), doc.id))
        .toList();

    _collectionCache[key] = _MemoryCollectionEntry(
      data: ads,
      updatedAt: now,
    );
    return ads;
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _loadCollectionDocs(
    String collection, {
    required bool forceRefresh,
  }) async {
    final key = 'collection::$collection';
    final cached = _collectionCache[key];
    final now = DateTime.now();
    if (!forceRefresh &&
        cached != null &&
        now.difference(cached.updatedAt) < _cacheTtl) {
      return (cached.data as List<QueryDocumentSnapshot<Map<String, dynamic>>>);
    }

    final snapshot = await _firestore.collection(collection).get();
    _collectionCache[key] = _MemoryCollectionEntry(
      data: snapshot.docs,
      updatedAt: now,
    );
    return snapshot.docs;
  }

  Future<List<Map<String, dynamic>>> _loadAnalyticsCollection(
    String collection, {
    required bool forceRefresh,
  }) async {
    final docs =
        await _loadCollectionDocs(collection, forceRefresh: forceRefresh);
    return docs.map((doc) => doc.data()).toList();
  }

  Future<List<Map<String, dynamic>>> _loadSearchLogs({
    required bool forceRefresh,
  }) async {
    final analytics = await _loadAnalyticsCollection(
      'analytics_searches',
      forceRefresh: forceRefresh,
    );
    final rawLogs = await _loadAnalyticsCollection(
      'search_logs',
      forceRefresh: forceRefresh,
    );
    return <Map<String, dynamic>>[
      ...analytics,
      ...rawLogs,
    ];
  }

  Future<int> _sumInsightField(
    String field, {
    required bool forceRefresh,
  }) async {
    final ads = await _loadCollectionDocs('ads', forceRefresh: forceRefresh);
    int total = 0;
    for (final doc in ads) {
      final statsDoc = await _firestore
          .collection('ads')
          .doc(doc.id)
          .collection('insights')
          .doc('stats')
          .get();
      total += _readInt(statsDoc.data()?[field]);
    }
    return total;
  }

  Future<double> _averagePriceForModel({
    required String brand,
    required String model,
    required int year,
    required _DateWindow range,
  }) async {
    final ads = await _loadAds(forceRefresh: false);
    final prices = ads
        .where((ad) {
          return (ad.carBrand ?? '').trim().toLowerCase() ==
                  brand.toLowerCase() &&
              (ad.carName ?? '').trim().toLowerCase() == model.toLowerCase() &&
              int.tryParse(ad.year) == year &&
              ad.createdAt != null &&
              _inWindow(ad.createdAt!, range);
        })
        .map((ad) => _parsePrice(ad.price))
        .where((price) => price > 0)
        .toList();

    if (prices.isEmpty) {
      return 0;
    }
    return prices.reduce((a, b) => a + b) / prices.length;
  }

  Future<DateTime?> _soldAtForAd(String? adId) async {
    if (adId == null || adId.isEmpty) {
      return null;
    }
    final doc = await _firestore.collection('ads').doc(adId).get();
    return _readDate(doc.data()?['soldAt']) ??
        _readDate(doc.data()?['updatedAt']);
  }

  List<MarketPulseTrendPoint> _buildFallbackTrend(
    MarketPulseTrendModelOption model,
    MarketPulsePeriod period,
    DateTime start,
  ) {
    final seed = math.max(18, model.year - 1995).toDouble();
    final points = <MarketPulseTrendPoint>[];
    final count = switch (period) {
      MarketPulsePeriod.today => 6,
      MarketPulsePeriod.week => 7,
      MarketPulsePeriod.month => 5,
      MarketPulsePeriod.quarter => 3,
    };

    for (var i = 0; i < count; i++) {
      final date = switch (period) {
        MarketPulsePeriod.today => start.add(Duration(hours: i * 4)),
        MarketPulsePeriod.week => start.add(Duration(days: i)),
        MarketPulsePeriod.month => start.add(Duration(days: i * 6)),
        MarketPulsePeriod.quarter => DateTime(start.year, start.month + i, 1),
      };
      points.add(
        MarketPulseTrendPoint(
          date: date,
          avgPrice: (22 + seed / 8 + (i * 0.4)) * 100000,
        ),
      );
    }
    return points;
  }

  _DateWindow _resolveRange({
    required MarketPulsePeriod period,
    required DateTimeRange? customRange,
  }) {
    if (customRange != null) {
      return _DateWindow(
        start: DateTime(
          customRange.start.year,
          customRange.start.month,
          customRange.start.day,
        ),
        end: DateTime(
          customRange.end.year,
          customRange.end.month,
          customRange.end.day,
          23,
          59,
          59,
        ),
      );
    }

    final now = DateTime.now();
    return _DateWindow(
      start: now.subtract(period.duration),
      end: now,
    );
  }

  DateTime _bucketDate(
    DateTime date,
    MarketPulsePeriod period,
    DateTime rangeStart,
  ) {
    switch (period) {
      case MarketPulsePeriod.today:
        final hourBucket = (date.hour / 4).floor() * 4;
        return DateTime(date.year, date.month, date.day, hourBucket);
      case MarketPulsePeriod.week:
        return DateTime(date.year, date.month, date.day);
      case MarketPulsePeriod.month:
        final normalized = date.difference(rangeStart).inDays ~/ 6;
        return DateTime(rangeStart.year, rangeStart.month, rangeStart.day)
            .add(Duration(days: normalized * 6));
      case MarketPulsePeriod.quarter:
        return DateTime(date.year, date.month, 1);
    }
  }

  bool _inWindow(DateTime value, _DateWindow window) {
    return !value.isBefore(window.start) && value.isBefore(window.end);
  }

  bool _isActiveAd(AdModel ad) {
    final status = ad.status.toLowerCase();
    return status == 'active' || status == 'approved';
  }

  String _normalizeCity(String? raw) {
    final value = (raw ?? '').trim();
    if (value.isEmpty) {
      return '';
    }
    final city = value.split(',').first.trim();
    return _featuredCities.firstWhere(
      (known) => known.toLowerCase() == city.toLowerCase(),
      orElse: () => city,
    );
  }

  String _extractBrandFromSearch(Map<String, dynamic> data) {
    final explicitBrand = (data['brand'] ?? '').toString().trim();
    if (explicitBrand.isNotEmpty) {
      return explicitBrand;
    }
    return _extractBrandFromQuery((data['query'] ?? '').toString());
  }

  String _extractBrandFromQuery(String query) {
    final normalized = query.toLowerCase();
    for (final brand in _brandService.getAllBrands()) {
      if (normalized.contains(brand.displayName.toLowerCase())) {
        return brand.displayName;
      }
    }
    return '';
  }

  double _parsePrice(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[^0-9.]'), '');
    if (cleaned.isEmpty) {
      return 0;
    }
    return double.tryParse(cleaned) ?? 0;
  }

  String _rangeCacheKey(MarketPulsePeriod period, DateTimeRange? range) {
    if (range == null) {
      return period.cacheKey;
    }
    return '${range.start.toIso8601String()}_${range.end.toIso8601String()}';
  }

  void _invalidateCaches() {
    _sectionCache.clear();
    _collectionCache.clear();
  }

  DateTime? _readDate(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value.trim());
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    if (value is num) {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    }
    return null;
  }

  int _readInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse((value ?? '0').toString()) ?? 0;
  }

  double _readDouble(dynamic value) {
    if (value is double) {
      return value;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse((value ?? '0').toString()) ?? 0;
  }
}

class _MemorySectionEntry {
  final dynamic section;
  final DateTime updatedAt;

  const _MemorySectionEntry({
    required this.section,
    required this.updatedAt,
  });
}

class _MemoryCollectionEntry {
  final dynamic data;
  final DateTime updatedAt;

  const _MemoryCollectionEntry({
    required this.data,
    required this.updatedAt,
  });
}

class _DateWindow {
  final DateTime start;
  final DateTime end;

  const _DateWindow({
    required this.start,
    required this.end,
  });

  Duration get duration => end.difference(start);
}
