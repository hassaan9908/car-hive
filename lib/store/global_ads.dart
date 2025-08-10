import 'package:carhive/models/ad_model.dart';


class GlobalAdStore {
  static final GlobalAdStore _instance = GlobalAdStore._internal();
  factory GlobalAdStore() => _instance;
  GlobalAdStore._internal();

  final List<AdModel> ads = [];

  void addAd(AdModel ad) {
    ads.add(ad);
  }

  List<AdModel> getByStatus(String status) =>
      ads.where((ad) => ad.status == status).toList();
}
