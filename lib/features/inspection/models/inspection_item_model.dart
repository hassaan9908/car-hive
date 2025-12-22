class InspectionItem {
  final String id;
  final String question;
  final String category;
  int rating; // 0-100 (0=Critical, 40=Poor, 60=Fair, 80=Good, 100=Excellent)
  String notes;
  List<String> photoUrls;

  InspectionItem({
    required this.id,
    required this.question,
    required this.category,
    this.rating = -1, // -1 = not rated yet
    this.notes = '',
    List<String>? photoUrls,
  }) : photoUrls = photoUrls ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'question': question,
        'category': category,
        'rating': rating,
        'notes': notes,
        'photoUrls': photoUrls,
      };

  factory InspectionItem.fromJson(Map<String, dynamic> json) => InspectionItem(
        id: json['id'] ?? '',
        question: json['question'] ?? '',
        category: json['category'] ?? '',
        rating: json['rating'] ?? -1,
        notes: json['notes'] ?? '',
        photoUrls: List<String>.from(json['photoUrls'] ?? []),
      );

  bool get isCompleted => rating >= 0;

  String get ratingText {
    if (rating < 0) return 'Not Rated';
    if (rating >= 90) return 'Excellent';
    if (rating >= 70) return 'Good';
    if (rating >= 50) return 'Fair';
    if (rating >= 30) return 'Poor';
    return 'Critical';
  }
}
