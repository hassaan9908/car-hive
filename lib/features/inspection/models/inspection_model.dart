import 'inspection_section_model.dart';
import 'inspection_item_model.dart';

class InspectionModel {
  String? id;
  final String carId;
  final String carTitle;
  final String buyerId;
  String sellerId;
  final DateTime createdAt;
  DateTime updatedAt;
  final List<InspectionSection> sections;
  String status; // 'draft' or 'completed'

  InspectionModel({
    this.id,
    required this.carId,
    required this.carTitle,
    required this.buyerId,
    this.sellerId = '',
    required this.createdAt,
    required this.updatedAt,
    required this.sections,
    this.status = 'draft',
  });

  double get overallScore {
    if (sections.isEmpty) return 0;
    final completedSections =
        sections.where((s) => s.completedCount > 0).toList();
    if (completedSections.isEmpty) return 0;

    final sum = completedSections.fold<double>(
        0, (sum, section) => sum + section.sectionScore);
    return sum / completedSections.length;
  }

  int get totalItems =>
      sections.fold<int>(0, (sum, section) => sum + section.totalCount);
  int get completedItems =>
      sections.fold<int>(0, (sum, section) => sum + section.completedCount);

  double get progress => totalItems > 0 ? completedItems / totalItems : 0;

  String get scoreText {
    final score = overallScore;
    if (score >= 85) return 'Excellent';
    if (score >= 70) return 'Good';
    if (score >= 50) return 'Fair';
    if (score >= 30) return 'Poor';
    return 'Critical';
  }

  List<String> get recommendations {
    final List<String> recs = [];

    for (var section in sections) {
      for (var item in section.items) {
        if (item.isCompleted && item.rating < 60) {
          recs.add('⚠️ ${section.name}: ${item.question} needs attention');
        }
      }
    }

    return recs;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'carId': carId,
        'carTitle': carTitle,
        'buyerId': buyerId,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'sections': sections.map((s) => s.toJson()).toList(),
        'status': status,
        'overallScore': overallScore,
      };

  factory InspectionModel.fromJson(Map<String, dynamic> json) =>
      InspectionModel(
        id: json['id'] ?? '',
        carId: json['carId'] ?? '',
        carTitle: json['carTitle'] ?? '',
        buyerId: json['buyerId'] ?? '',
        createdAt: DateTime.parse(json['createdAt']),
        updatedAt: DateTime.parse(json['updatedAt']),
        sections: (json['sections'] as List?)
                ?.map((s) => InspectionSection.fromJson(s))
                .toList() ??
            [],
        status: json['status'] ?? 'draft',
      );

  // Factory to create a new inspection with default questions
  factory InspectionModel.createNew({
    required String carId,
    required String carTitle,
    required String buyerId,
    String sellerId = '',
  }) {
    final now = DateTime.now();
    return InspectionModel(
      id: '${carId}_${now.millisecondsSinceEpoch}',
      carId: carId,
      carTitle: carTitle,
      buyerId: buyerId,
      sellerId: sellerId,
      createdAt: now,
      updatedAt: now,
      status: 'draft',
      sections: [
        InspectionSection(
          id: 'exterior',
          name: 'Exterior',
          icon: '🚗',
          items: [
            InspectionItem(
                id: 'ext_1',
                question: 'Body condition (dents, scratches)',
                category: 'exterior'),
            InspectionItem(
                id: 'ext_2',
                question: 'Paint quality and color match',
                category: 'exterior'),
            InspectionItem(
                id: 'ext_3',
                question: 'Windshield and windows',
                category: 'exterior'),
            InspectionItem(
                id: 'ext_4',
                question: 'Headlights and taillights',
                category: 'exterior'),
            InspectionItem(
                id: 'ext_5',
                question: 'Bumpers and grille',
                category: 'exterior'),
            InspectionItem(
                id: 'ext_6',
                question: 'Doors and trunk alignment',
                category: 'exterior'),
          ],
        ),
        InspectionSection(
          id: 'interior',
          name: 'Interior',
          icon: '🪑',
          items: [
            InspectionItem(
                id: 'int_1',
                question: 'Seats condition and comfort',
                category: 'interior'),
            InspectionItem(
                id: 'int_2',
                question: 'Dashboard and controls',
                category: 'interior'),
            InspectionItem(
                id: 'int_3',
                question: 'Carpet and floor mats',
                category: 'interior'),
            InspectionItem(
                id: 'int_4',
                question: 'Air conditioning system',
                category: 'interior'),
            InspectionItem(
                id: 'int_5',
                question: 'Audio and infotainment',
                category: 'interior'),
            InspectionItem(
                id: 'int_6',
                question: 'Odor and cleanliness',
                category: 'interior'),
          ],
        ),
        InspectionSection(
          id: 'engine',
          name: 'Engine & Mechanical',
          icon: '🔧',
          items: [
            InspectionItem(
                id: 'eng_1',
                question: 'Engine condition and sounds',
                category: 'engine'),
            InspectionItem(
                id: 'eng_2',
                question: 'Oil level and quality',
                category: 'engine'),
            InspectionItem(
                id: 'eng_3',
                question: 'Coolant and fluid levels',
                category: 'engine'),
            InspectionItem(
                id: 'eng_4', question: 'Battery condition', category: 'engine'),
            InspectionItem(
                id: 'eng_5', question: 'Belts and hoses', category: 'engine'),
            InspectionItem(
                id: 'eng_6',
                question: 'Transmission operation',
                category: 'engine'),
          ],
        ),
        InspectionSection(
          id: 'tires',
          name: 'Tires & Suspension',
          icon: '🛞',
          items: [
            InspectionItem(
                id: 'tire_1', question: 'Tire tread depth', category: 'tires'),
            InspectionItem(
                id: 'tire_2', question: 'Tire wear pattern', category: 'tires'),
            InspectionItem(
                id: 'tire_3',
                question: 'Brake pad thickness',
                category: 'tires'),
            InspectionItem(
                id: 'tire_4',
                question: 'Suspension and shocks',
                category: 'tires'),
            InspectionItem(
                id: 'tire_5', question: 'Wheel alignment', category: 'tires'),
          ],
        ),
        InspectionSection(
          id: 'paperwork',
          name: 'Paperwork & History',
          icon: '📄',
          items: [
            InspectionItem(
                id: 'paper_1',
                question: 'Registration documents',
                category: 'paperwork'),
            InspectionItem(
                id: 'paper_2',
                question: 'Service history records',
                category: 'paperwork'),
            InspectionItem(
                id: 'paper_3',
                question: 'Insurance status',
                category: 'paperwork'),
            InspectionItem(
                id: 'paper_4',
                question: 'Owner manual availability',
                category: 'paperwork'),
          ],
        ),
      ],
    );
  }
}
