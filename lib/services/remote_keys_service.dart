import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RemoteKeys {
  final String stripeKey;
  final String mapsKey;

  const RemoteKeys({
    required this.stripeKey,
    required this.mapsKey,
  });
}

class RemoteKeysService {
  static const String _stripeKeyNode = 'stripe_key';
  static const String _mapsKeyNode = 'maps_key';

  static const String _cacheStripeKey = 'remote_stripe_key';
  static const String _cacheMapsKey = 'remote_maps_key';

  static Future<RemoteKeys> loadKeys() async {
    final prefs = await SharedPreferences.getInstance();

    String stripeKey = (prefs.getString(_cacheStripeKey) ?? '').trim();
    String mapsKey = (prefs.getString(_cacheMapsKey) ?? '').trim();

    try {
      final rootRef = FirebaseDatabase.instance.ref();

      final results = await Future.wait([
        rootRef.child(_stripeKeyNode).get(),
        rootRef.child(_mapsKeyNode).get(),
      ]);

      final fetchedStripe = _toTrimmedString(results[0].value);
      final fetchedMaps = _toTrimmedString(results[1].value);

      if (fetchedStripe.isNotEmpty) {
        stripeKey = fetchedStripe;
        await prefs.setString(_cacheStripeKey, stripeKey);
      }

      if (fetchedMaps.isNotEmpty) {
        mapsKey = fetchedMaps;
        await prefs.setString(_cacheMapsKey, mapsKey);
      }
    } catch (e) {
      debugPrint('RemoteKeysService: failed to fetch keys from Realtime Database: $e');
      // Keep using cached values if network/database fetch fails.
    }

    return RemoteKeys(
      stripeKey: stripeKey,
      mapsKey: mapsKey,
    );
  }

  static String _toTrimmedString(Object? value) {
    if (value == null) return '';
    return value.toString().trim();
  }
}
