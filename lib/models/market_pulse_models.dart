import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum MarketPulsePeriod {
  today,
  week,
  month,
  quarter,
}

extension MarketPulsePeriodX on MarketPulsePeriod {
  String get label {
    switch (this) {
      case MarketPulsePeriod.today:
        return 'Today';
      case MarketPulsePeriod.week:
        return 'This Week';
      case MarketPulsePeriod.month:
        return 'This Month';
      case MarketPulsePeriod.quarter:
        return '3 Months';
    }
  }

  String get cacheKey {
    switch (this) {
      case MarketPulsePeriod.today:
        return 'today';
      case MarketPulsePeriod.week:
        return 'week';
      case MarketPulsePeriod.month:
        return 'month';
      case MarketPulsePeriod.quarter:
        return 'quarter';
    }
  }

  Duration get duration {
    switch (this) {
      case MarketPulsePeriod.today:
        return const Duration(days: 1);
      case MarketPulsePeriod.week:
        return const Duration(days: 7);
      case MarketPulsePeriod.month:
        return const Duration(days: 30);
      case MarketPulsePeriod.quarter:
        return const Duration(days: 90);
    }
  }
}

enum MarketPulseModelMode {
  listed,
  sold,
}

extension MarketPulseModelModeX on MarketPulseModelMode {
  String get label {
    switch (this) {
      case MarketPulseModelMode.listed:
        return 'Most Listed';
      case MarketPulseModelMode.sold:
        return 'Most Sold';
    }
  }

  String get cacheKey {
    switch (this) {
      case MarketPulseModelMode.listed:
        return 'listed';
      case MarketPulseModelMode.sold:
        return 'sold';
    }
  }
}

class MarketPulseSection<T> {
  final T data;
  final DateTime updatedAt;

  const MarketPulseSection({
    required this.data,
    required this.updatedAt,
  });
}

class MarketPulseHomeTeaser {
  final String title;
  final String subtitle;
  final double changePercent;
  final DateTime updatedAt;

  const MarketPulseHomeTeaser({
    required this.title,
    required this.subtitle,
    required this.changePercent,
    required this.updatedAt,
  });

  factory MarketPulseHomeTeaser.fromMap(Map<String, dynamic> map) {
    return MarketPulseHomeTeaser(
      title: (map['title'] ?? 'Toyota Corolla avg price').toString(),
      subtitle: (map['subtitle'] ?? 'up 4% this week').toString(),
      changePercent: (map['changePercent'] is num)
          ? (map['changePercent'] as num).toDouble()
          : double.tryParse((map['changePercent'] ?? '0').toString()) ?? 0,
      updatedAt: _readDate(map['updatedAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'subtitle': subtitle,
      'changePercent': changePercent,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class MarketPulseCityPriceEntry {
  final String city;
  final double avgPrice;
  final int listingCount;

  const MarketPulseCityPriceEntry({
    required this.city,
    required this.avgPrice,
    required this.listingCount,
  });

  factory MarketPulseCityPriceEntry.fromMap(Map<String, dynamic> map) {
    return MarketPulseCityPriceEntry(
      city: (map['city'] ?? 'Unknown').toString(),
      avgPrice: _readDouble(map['avgPrice']),
      listingCount: _readInt(map['listingCount']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'city': city,
      'avgPrice': avgPrice,
      'listingCount': listingCount,
    };
  }
}

class MarketPulseModelEntry {
  final String model;
  final String brand;
  final int count;

  const MarketPulseModelEntry({
    required this.model,
    required this.brand,
    required this.count,
  });

  String get displayName {
    final normalizedBrand = brand.trim();
    final normalizedModel = model.trim();
    if (normalizedBrand.isEmpty) {
      return normalizedModel;
    }
    if (normalizedModel
        .toLowerCase()
        .startsWith(normalizedBrand.toLowerCase())) {
      return normalizedModel;
    }
    return '$normalizedBrand $normalizedModel'.trim();
  }

  factory MarketPulseModelEntry.fromMap(Map<String, dynamic> map) {
    return MarketPulseModelEntry(
      model: (map['model'] ?? '').toString(),
      brand: (map['brand'] ?? '').toString(),
      count: _readInt(map['count']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'model': model,
      'brand': brand,
      'count': count,
    };
  }
}

class MarketPulseBrandEntry {
  final String brand;
  final int searchCount;
  final String trend;
  final String? logoPath;

  const MarketPulseBrandEntry({
    required this.brand,
    required this.searchCount,
    required this.trend,
    this.logoPath,
  });

  factory MarketPulseBrandEntry.fromMap(Map<String, dynamic> map) {
    return MarketPulseBrandEntry(
      brand: (map['brand'] ?? '').toString(),
      searchCount: _readInt(map['searchCount']),
      trend: (map['trend'] ?? 'stable').toString(),
      logoPath: map['logoPath']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'brand': brand,
      'searchCount': searchCount,
      'trend': trend,
      'logoPath': logoPath,
    };
  }
}

class MarketPulseTrendModelOption {
  final String brand;
  final String model;
  final int year;

  const MarketPulseTrendModelOption({
    required this.brand,
    required this.model,
    required this.year,
  });

  String get label => '$brand $model $year'.trim();

  String get key =>
      '${brand.toLowerCase()}_${model.toLowerCase()}_${year.toString()}';

  factory MarketPulseTrendModelOption.fromMap(Map<String, dynamic> map) {
    return MarketPulseTrendModelOption(
      brand: (map['brand'] ?? '').toString(),
      model: (map['model'] ?? '').toString(),
      year: _readInt(map['year']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'brand': brand,
      'model': model,
      'year': year,
    };
  }
}

class MarketPulseTrendPoint {
  final DateTime date;
  final double avgPrice;

  const MarketPulseTrendPoint({
    required this.date,
    required this.avgPrice,
  });

  factory MarketPulseTrendPoint.fromMap(Map<String, dynamic> map) {
    return MarketPulseTrendPoint(
      date: _readDate(map['date']) ?? DateTime.now(),
      avgPrice: _readDouble(map['avgPrice']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'avgPrice': avgPrice,
    };
  }
}

class MarketPulseTrendSeries {
  final MarketPulseTrendModelOption selectedModel;
  final List<MarketPulseTrendModelOption> options;
  final List<MarketPulseTrendPoint> points;

  const MarketPulseTrendSeries({
    required this.selectedModel,
    required this.options,
    required this.points,
  });

  factory MarketPulseTrendSeries.fromMap(Map<String, dynamic> map) {
    final options = ((map['options'] as List?) ?? const <dynamic>[])
        .whereType<Map>()
        .map((item) => MarketPulseTrendModelOption.fromMap(
              Map<String, dynamic>.from(item),
            ))
        .toList();

    final fallbackModel = options.isNotEmpty
        ? options.first
        : const MarketPulseTrendModelOption(
            brand: 'Toyota',
            model: 'Corolla',
            year: 2020,
          );

    return MarketPulseTrendSeries(
      selectedModel: map['selectedModel'] is Map<String, dynamic>
          ? MarketPulseTrendModelOption.fromMap(
              Map<String, dynamic>.from(map['selectedModel'] as Map),
            )
          : fallbackModel,
      options: options,
      points: ((map['points'] as List?) ?? const <dynamic>[])
          .whereType<Map>()
          .map((item) => MarketPulseTrendPoint.fromMap(
                Map<String, dynamic>.from(item),
              ))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'selectedModel': selectedModel.toMap(),
      'options': options.map((item) => item.toMap()).toList(),
      'points': points.map((item) => item.toMap()).toList(),
    };
  }
}

class MarketPulseActivityMetric {
  final String id;
  final String label;
  final int total;
  final int delta;

  const MarketPulseActivityMetric({
    required this.id,
    required this.label,
    required this.total,
    required this.delta,
  });

  factory MarketPulseActivityMetric.fromMap(Map<String, dynamic> map) {
    return MarketPulseActivityMetric(
      id: (map['id'] ?? '').toString(),
      label: (map['label'] ?? '').toString(),
      total: _readInt(map['total']),
      delta: _readInt(map['delta']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'label': label,
      'total': total,
      'delta': delta,
    };
  }
}

class MarketPulseRegionEntry {
  final String city;
  final int activityCount;
  final int listingCount;
  final double avgPrice;
  final double x;
  final double y;

  const MarketPulseRegionEntry({
    required this.city,
    required this.activityCount,
    required this.listingCount,
    required this.avgPrice,
    required this.x,
    required this.y,
  });

  factory MarketPulseRegionEntry.fromMap(Map<String, dynamic> map) {
    return MarketPulseRegionEntry(
      city: (map['city'] ?? '').toString(),
      activityCount: _readInt(map['activityCount']),
      listingCount: _readInt(map['listingCount']),
      avgPrice: _readDouble(map['avgPrice']),
      x: _readDouble(map['x']),
      y: _readDouble(map['y']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'city': city,
      'activityCount': activityCount,
      'listingCount': listingCount,
      'avgPrice': avgPrice,
      'x': x,
      'y': y,
    };
  }
}

class MarketPulseReportedUser {
  final String userLabel;
  final int reportCount;

  const MarketPulseReportedUser({
    required this.userLabel,
    required this.reportCount,
  });

  factory MarketPulseReportedUser.fromMap(Map<String, dynamic> map) {
    return MarketPulseReportedUser(
      userLabel: (map['userLabel'] ?? 'Unknown').toString(),
      reportCount: _readInt(map['reportCount']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userLabel': userLabel,
      'reportCount': reportCount,
    };
  }
}

class MarketPulseAdminExtras {
  final int totalRegisteredUsers;
  final int newUsersToday;
  final int newUsersThisWeek;
  final double featuredRevenue;
  final int reportedAdsCount;
  final List<MarketPulseReportedUser> mostReportedUsers;

  const MarketPulseAdminExtras({
    required this.totalRegisteredUsers,
    required this.newUsersToday,
    required this.newUsersThisWeek,
    required this.featuredRevenue,
    required this.reportedAdsCount,
    required this.mostReportedUsers,
  });

  factory MarketPulseAdminExtras.fromMap(Map<String, dynamic> map) {
    return MarketPulseAdminExtras(
      totalRegisteredUsers: _readInt(map['totalRegisteredUsers']),
      newUsersToday: _readInt(map['newUsersToday']),
      newUsersThisWeek: _readInt(map['newUsersThisWeek']),
      featuredRevenue: _readDouble(map['featuredRevenue']),
      reportedAdsCount: _readInt(map['reportedAdsCount']),
      mostReportedUsers:
          ((map['mostReportedUsers'] as List?) ?? const <dynamic>[])
              .whereType<Map>()
              .map((item) => MarketPulseReportedUser.fromMap(
                    Map<String, dynamic>.from(item),
                  ))
              .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalRegisteredUsers': totalRegisteredUsers,
      'newUsersToday': newUsersToday,
      'newUsersThisWeek': newUsersThisWeek,
      'featuredRevenue': featuredRevenue,
      'reportedAdsCount': reportedAdsCount,
      'mostReportedUsers':
          mostReportedUsers.map((item) => item.toMap()).toList(),
    };
  }
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

DateTime? _readDate(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is DateTime) {
    return value;
  }
  if (value is Timestamp) {
    return value.toDate();
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

const Map<String, Offset> marketPulseCityPositions = {
  'Karachi': Offset(0.30, 0.84),
  'Lahore': Offset(0.64, 0.48),
  'Islamabad': Offset(0.63, 0.29),
  'Rawalpindi': Offset(0.61, 0.33),
  'Peshawar': Offset(0.50, 0.27),
  'Multan': Offset(0.49, 0.58),
  'Faisalabad': Offset(0.57, 0.47),
  'Quetta': Offset(0.27, 0.45),
};
