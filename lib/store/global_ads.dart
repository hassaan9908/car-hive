// import 'package:carhive/models/ad_model.dart';


// class GlobalAdStore {
//   static final GlobalAdStore _instance = GlobalAdStore._internal();
//   factory GlobalAdStore() => _instance;
//   GlobalAdStore._internal();

//   final List<AdModel> ads = [];

//   void addAd(AdModel ad) {
//     ads.add(ad);
//   }

//   List<AdModel> getByStatus(String status) =>
//       ads.where((ad) => ad.status == status).toList();

//   void updateStatus(String id, String s) {}
// }
//  new change 18 aug=-=-=-=-=
import 'package:carhive/models/ad_model.dart';

class GlobalAdStore {
  static final GlobalAdStore _instance = GlobalAdStore._();
  GlobalAdStore._();
  factory GlobalAdStore() => _instance;

  final List<AdModel> _ads = [];

  void addAd(AdModel ad) => _ads.add(ad);

  List<AdModel> getByStatus(String status) =>
      _ads.where((a) => a.status == status).toList();

  // ⟵ Add this:
  void updateStatus(String id, String newStatus) {
    final i = _ads.indexWhere((a) => a.id == id);
    if (i == -1) return;
    final a = _ads[i];
    _ads[i] = AdModel(
      id: a.id,
      photos: a.photos,
      location: a.location,
      carModel: a.carModel,
      brand: a.brand,
      registeredCity: a.registeredCity,
      bodyColor: a.bodyColor,
      kmsDriven: a.kmsDriven,
      price: a.price,
      description: a.description,
      phoneNumber: a.phoneNumber,
      fuel: a.fuel,
      year: a.year,
      status: newStatus,       // ⟵ changed here
      userId: a.userId,
      createdAt: a.createdAt,
    );
  }
}

