// class AdModel {
//   final String title;
//   final String price;
//   final String location;
//   final String year;
//   final String mileage;
//   final String fuel;
//   late final String status; // 'active', 'pending', 'removed'

//   AdModel({
//     required this.title,
//     required this.price,
//     required this.location,
//     required this.year,
//     required this.mileage,
//     required this.fuel,
//     this.status = 'active',
//   });
// }

class AdModel {
  String id; // <-- make mutable
  final String brand;
  final String carModel;
  final String year;
  final String kmsDriven;
  final String fuel;
  final String price;
  final String description;
  final String phoneNumber;
  final String location;
  final String registeredCity;
  final String bodyColor;
  final List<String> photos;
  final String userId;
  final DateTime createdAt;
  String status;

  AdModel({
    required this.id,
    required this.brand,
    required this.carModel,
    required this.year,
    required this.kmsDriven,
    required this.fuel,
    required this.price,
    required this.description,
    required this.phoneNumber,
    required this.location,
    required this.registeredCity,
    required this.bodyColor,
    required this.photos,
    required this.userId,
    required this.createdAt,
    this.status = 'active',
  });

  Map<String, dynamic> toMap() {
    return {
      'brand': brand,
      'carModel': carModel,
      'year': year,
      'kmsDriven': kmsDriven,
      'fuel': fuel,
      'price': price,
      'description': description,
      'phoneNumber': phoneNumber,
      'location': location,
      'registeredCity': registeredCity,
      'bodyColor': bodyColor,
      'photos': photos,
      'userId': userId,
      'createdAt': createdAt,
      'status': status,
    };
  }
}
