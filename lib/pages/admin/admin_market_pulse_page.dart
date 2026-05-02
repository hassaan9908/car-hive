import 'package:flutter/material.dart';

import '../market_pulse_page.dart';

class AdminMarketPulsePage extends StatelessWidget {
  const AdminMarketPulsePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const MarketPulsePage(isAdmin: true);
  }
}
