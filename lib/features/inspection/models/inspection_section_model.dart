import 'inspection_item_model.dart';

class InspectionSection {
  final String id;
  final String name;
  final String icon;
  final List<InspectionItem> items;

  InspectionSection({
    required this.id,
    required this.name,
    required this.icon,
    required this.items,
  });

  double get sectionScore {
    if (items.isEmpty) return 0;
    final completedItems = items.where((item) => item.isCompleted).toList();
    if (completedItems.isEmpty) return 0;

    final sum = completedItems.fold<int>(0, (sum, item) => sum + item.rating);
    return sum / completedItems.length;
  }

  int get completedCount => items.where((item) => item.isCompleted).length;
  int get totalCount => items.length;

  double get progress => totalCount > 0 ? completedCount / totalCount : 0;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'icon': icon,
        'items': items.map((item) => item.toJson()).toList(),
      };

  factory InspectionSection.fromJson(Map<String, dynamic> json) =>
      InspectionSection(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        icon: json['icon'] ?? '',
        items: (json['items'] as List?)
                ?.map((item) => InspectionItem.fromJson(item))
                .toList() ??
            [],
      );
}
