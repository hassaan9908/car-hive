import '../models/car_brand_model.dart';

/// Service for managing car brands and their logos
class CarBrandService {
  static final CarBrandService _instance = CarBrandService._internal();
  factory CarBrandService() => _instance;
  CarBrandService._internal();

  /// List of all available car brands with their logos
  static const List<CarBrand> _brands = [
    CarBrand(
      id: 'audi',
      displayName: 'Audi',
      logoPath: 'assets/car-log/audi-logo-2016-download.png',
    ),
    CarBrand(
      id: 'bmw',
      displayName: 'BMW',
      logoPath: 'assets/car-log/bmw-logo-2020-gray-download.png',
    ),
    CarBrand(
      id: 'byd',
      displayName: 'BYD',
      logoPath: 'assets/car-log/BYD-logo-2007-2560x1440.png',
    ),
    CarBrand(
      id: 'chevrolet',
      displayName: 'Chevrolet',
      logoPath: 'assets/car-log/Chevrolet-logo-2013-2560x1440.png',
    ),
    CarBrand(
      id: 'dodge',
      displayName: 'Dodge',
      logoPath: 'assets/car-log/dodge-logo-2010-download.png',
    ),
    CarBrand(
      id: 'ford',
      displayName: 'Ford',
      logoPath: 'assets/car-log/ford-logo-2017-download.png',
    ),
    CarBrand(
      id: 'honda',
      displayName: 'Honda',
      logoPath: 'assets/car-log/honda-logo-2000-full-download.png',
    ),
    CarBrand(
      id: 'hyundai',
      displayName: 'Hyundai',
      logoPath: 'assets/car-log/hyundai-logo-2011-download.png',
    ),
    CarBrand(
      id: 'isuzu',
      displayName: 'Isuzu',
      logoPath: 'assets/car-log/Isuzu-logo-1991-3840x2160.png',
    ),
    CarBrand(
      id: 'kia',
      displayName: 'Kia',
      logoPath: 'assets/car-log/Kia-logo-2560x1440.png',
    ),
    CarBrand(
      id: 'land_rover',
      displayName: 'Land Rover',
      logoPath: 'assets/car-log/Land-Rover-logo-2011-1920x1080.png',
    ),
    CarBrand(
      id: 'lexus',
      displayName: 'Lexus',
      logoPath: 'assets/car-log/Lexus-logo-1988-1920x1080.png',
    ),
    CarBrand(
      id: 'mazda',
      displayName: 'Mazda',
      logoPath: 'assets/car-log/mazda-logo-2018-vertical-download.png',
    ),
    CarBrand(
      id: 'mercedes_benz',
      displayName: 'Mercedes-Benz',
      logoPath: 'assets/car-log/Mercedes-Benz-logo-2011-1920x1080.png',
    ),
    CarBrand(
      id: 'mg',
      displayName: 'MG',
      logoPath: 'assets/car-log/MG-logo-red-2010-1920x1080.png',
    ),
    CarBrand(
      id: 'mini',
      displayName: 'Mini',
      logoPath: 'assets/car-log/Mini-logo-2001-1920x1080.png',
    ),
    CarBrand(
      id: 'mitsubishi',
      displayName: 'Mitsubishi',
      logoPath: 'assets/car-log/Mitsubishi-logo-2000x2500.png',
    ),
    CarBrand(
      id: 'nissan',
      displayName: 'Nissan',
      logoPath: 'assets/car-log/nissan-logo-2020-black.png',
    ),
    CarBrand(
      id: 'peugeot',
      displayName: 'Peugeot',
      logoPath: 'assets/car-log/Peugeot-logo-2010-1920x1080.png',
    ),
    CarBrand(
      id: 'porsche',
      displayName: 'Porsche',
      logoPath: 'assets/car-log/porsche-logo-2014-full-download.png',
    ),
    CarBrand(
      id: 'subaru',
      displayName: 'Subaru',
      logoPath: 'assets/car-log/subaru-logo-2019-download.png',
    ),
    CarBrand(
      id: 'suzuki',
      displayName: 'Suzuki',
      logoPath: 'assets/car-log/Suzuki-logo-5000x2500.png',
    ),
    CarBrand(
      id: 'tesla',
      displayName: 'Tesla',
      logoPath: 'assets/car-log/tesla-logo-2007-full-download.png',
    ),
    CarBrand(
      id: 'toyota',
      displayName: 'Toyota',
      logoPath: 'assets/car-log/toyota-logo-2020-europe-download.png',
    ),
  ];

  /// Get all car brands
  List<CarBrand> getAllBrands() {
    return List.unmodifiable(_brands);
  }

  /// Get brand by ID
  CarBrand? getBrandById(String id) {
    try {
      return _brands.firstWhere((brand) => brand.id == id.toLowerCase());
    } catch (e) {
      return null;
    }
  }

  /// Get brand by display name (case-insensitive)
  CarBrand? getBrandByName(String name) {
    try {
      return _brands.firstWhere(
        (brand) => brand.displayName.toLowerCase() == name.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  /// Search brands by name (partial match)
  List<CarBrand> searchBrands(String query) {
    if (query.isEmpty) return getAllBrands();
    
    final lowerQuery = query.toLowerCase();
    return _brands.where((brand) {
      return brand.displayName.toLowerCase().contains(lowerQuery) ||
          brand.id.toLowerCase().contains(lowerQuery);
    }).toList();
  }
}

