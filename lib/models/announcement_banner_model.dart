import 'package:cloud_firestore/cloud_firestore.dart';

class AnnouncementBannerModel {
  static const String typeText = 'text';
  static const String typeImage = 'image';

  final String? id;
  final String type;
  final String eyebrow;
  final String headline;
  final String subtitle;
  final String? ctaLabel;
  final String? imageUrl;
  final bool isActive;
  final String? createdBy;
  final String? createdByName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AnnouncementBannerModel({
    this.id,
    this.type = typeText,
    required this.eyebrow,
    required this.headline,
    required this.subtitle,
    this.ctaLabel,
    this.imageUrl,
    this.isActive = true,
    this.createdBy,
    this.createdByName,
    this.createdAt,
    this.updatedAt,
  });

  factory AnnouncementBannerModel.fromFirestore(
    Map<String, dynamic> data,
    String documentId,
  ) {
    final createdAtValue = data['createdAt'];
    final updatedAtValue = data['updatedAt'];

    return AnnouncementBannerModel(
      id: documentId,
      type: _normalizeType(data['type']),
      eyebrow: (data['eyebrow'] ?? '').toString(),
      headline: (data['headline'] ?? '').toString(),
      subtitle: (data['subtitle'] ?? '').toString(),
      ctaLabel: _stringOrNull(data['ctaLabel']),
      imageUrl: _stringOrNull(data['imageUrl']),
      isActive: data['isActive'] != false,
      createdBy: _stringOrNull(data['createdBy']),
      createdByName: _stringOrNull(data['createdByName']),
      createdAt: createdAtValue is Timestamp ? createdAtValue.toDate() : null,
      updatedAt: updatedAtValue is Timestamp ? updatedAtValue.toDate() : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'eyebrow': eyebrow,
      'headline': headline,
      'subtitle': subtitle,
      'type': type,
      'ctaLabel': ctaLabel,
      'imageUrl': imageUrl,
      'isActive': isActive,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': updatedAt != null
          ? Timestamp.fromDate(updatedAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  AnnouncementBannerModel copyWith({
    String? id,
    String? type,
    String? eyebrow,
    String? headline,
    String? subtitle,
    String? ctaLabel,
    String? imageUrl,
    bool? isActive,
    String? createdBy,
    String? createdByName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AnnouncementBannerModel(
      id: id ?? this.id,
      type: type ?? this.type,
      eyebrow: eyebrow ?? this.eyebrow,
      headline: headline ?? this.headline,
      subtitle: subtitle ?? this.subtitle,
      ctaLabel: ctaLabel ?? this.ctaLabel,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get hasImage => imageUrl != null && imageUrl!.trim().isNotEmpty;
  bool get isImageBanner => type == typeImage;
  bool get isTextBanner => !isImageBanner;
  String get typeLabel => isImageBanner ? 'Image' : 'Text';
  String get displayTitle {
    if (headline.trim().isNotEmpty) {
      return headline.trim();
    }
    if (eyebrow.trim().isNotEmpty) {
      return eyebrow.trim();
    }
    return isImageBanner ? 'Image banner' : 'Text banner';
  }

  static String? _stringOrNull(dynamic value) {
    final normalized = value?.toString().trim() ?? '';
    return normalized.isEmpty ? null : normalized;
  }

  static String _normalizeType(dynamic value) {
    final normalized = value?.toString().trim().toLowerCase() ?? typeText;
    return normalized == typeImage ? typeImage : typeText;
  }
}
