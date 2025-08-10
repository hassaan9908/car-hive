class AdModel {
  final String title;
  final String price;
  final String location;
  final String year;
  final String mileage;
  final String fuel;
  late final String status; // 'active', 'pending', 'removed'

  AdModel({
    required this.title,
    required this.price,
    required this.location,
    required this.year,
    required this.mileage,
    required this.fuel,
    this.status = 'active',
  });
}
