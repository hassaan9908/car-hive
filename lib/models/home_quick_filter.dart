import 'package:flutter/material.dart';

class HomeQuickFilter {
  final String id;
  final String label;

  const HomeQuickFilter({
    required this.id,
    required this.label,
  });

  static const String allId = 'all';
  static const String electricId = 'electric';
  static const String under50LId = 'under_50_l';

  static const List<HomeQuickFilter> options = [
    HomeQuickFilter(id: allId, label: 'All'),
    HomeQuickFilter(id: electricId, label: 'Electric'),
    HomeQuickFilter(id: under50LId, label: 'Under PKR 50L'),
  ];
}

class HomeTrustLevelOption {
  final String id;
  final String label;
  final Color indicatorColor;

  const HomeTrustLevelOption({
    required this.id,
    required this.label,
    required this.indicatorColor,
  });

  static const String bronzeId = 'bronze';
  static const String silverId = 'silver';
  static const String goldId = 'gold';

  static const List<HomeTrustLevelOption> options = [
    HomeTrustLevelOption(
      id: bronzeId,
      label: 'Bronze',
      indicatorColor: Color(0xFFB8793E),
    ),
    HomeTrustLevelOption(
      id: silverId,
      label: 'Silver',
      indicatorColor: Color(0xFFC0C6CF),
    ),
    HomeTrustLevelOption(
      id: goldId,
      label: 'Gold',
      indicatorColor: Color(0xFFFFC247),
    ),
  ];

  static HomeTrustLevelOption? byId(String? id) {
    if (id == null || id.trim().isEmpty) {
      return null;
    }

    final normalizedId = id.trim().toLowerCase();
    for (final option in options) {
      if (option.id == normalizedId) {
        return option;
      }
    }

    return null;
  }
}

class HomeFilterCatalog {
  static const List<String> pakistanCities = [
    'Karachi',
    'Lahore',
    'Islamabad',
    'Rawalpindi',
    'Peshawar',
    'Quetta',
    'Multan',
    'Faisalabad',
    'Sialkot',
    'Gujranwala',
    'Attock',
    'Abbottabad',
    'Murree',
    'Hyderabad',
    'Sukkur',
  ];

  static List<int> buildYearOptions() {
    final currentYear = DateTime.now().year;
    return List<int>.generate(
      currentYear - 1969,
      (index) => currentYear - index,
    );
  }
}
