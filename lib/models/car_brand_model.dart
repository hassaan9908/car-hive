/// Car Brand Model
/// Represents a car brand with its logo and display information
class CarBrand {
  final String id; // Unique identifier (e.g., "honda", "toyota")
  final String displayName; // Display name (e.g., "Honda", "Toyota")
  final String logoPath; // Asset path to logo image

  const CarBrand({
    required this.id,
    required this.displayName,
    required this.logoPath,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CarBrand &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

