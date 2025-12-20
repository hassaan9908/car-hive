import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminSystemAnalyticsPage extends StatefulWidget {
  const AdminSystemAnalyticsPage({super.key});

  @override
  State<AdminSystemAnalyticsPage> createState() =>
      _AdminSystemAnalyticsPageState();
}

class _AdminSystemAnalyticsPageState extends State<AdminSystemAnalyticsPage> {
  late Future<_AnalyticsData> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadData();
  }

  Future<_AnalyticsData> _loadData() async {
    final usersSnap =
        await FirebaseFirestore.instance.collection('users').get();
    final adsSnap = await FirebaseFirestore.instance.collection('ads').get();

    int pending = 0;
    int active = 0;
    int rejected = 0;
    double totalPrice = 0;

    for (final doc in adsSnap.docs) {
      final data = doc.data();
      final status = (data['status'] ?? 'active').toString();
      switch (status) {
        case 'pending':
          pending++;
          break;
        case 'rejected':
          rejected++;
          break;
        default:
          active++;
      }
      final price = (data['price'] is num)
          ? (data['price'] as num).toDouble()
          : double.tryParse(data['price']?.toString() ?? '0') ?? 0;
      totalPrice += price;
    }

    final avgPrice =
        adsSnap.docs.isEmpty ? 0.0 : totalPrice / adsSnap.docs.length;

    return _AnalyticsData(
      userCount: usersSnap.docs.length,
      adCount: adsSnap.docs.length,
      pendingAds: pending,
      activeAds: active,
      rejectedAds: rejected,
      averagePrice: avgPrice,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'System Analytics',
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFFf48c25)
                : Colors.black,
          ),
        ),
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFFf48c25)
              : Colors.black,
        ),
      ),
      body: FutureBuilder<_AnalyticsData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final data = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _future = _loadData();
              });
              await _future;
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _statTile('Total Users', data.userCount.toString(),
                        Icons.people, Colors.blue),
                    _statTile('Total Ads', data.adCount.toString(),
                        Icons.directions_car, Colors.green),
                    _statTile('Pending Ads', data.pendingAds.toString(),
                        Icons.pending_actions, Colors.orange),
                    _statTile('Active Ads', data.activeAds.toString(),
                        Icons.check_circle, Colors.teal),
                    _statTile('Rejected Ads', data.rejectedAds.toString(),
                        Icons.cancel, Colors.red),
                    _statTile('Avg Price', data.averagePrice.toStringAsFixed(0),
                        Icons.price_change, Colors.purple),
                  ],
                ),
                const SizedBox(height: 24),
                const Text('Distribution',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                _buildBarChart(data),
                const SizedBox(height: 32),
                const Text('Notes',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                const Text(
                    'These analytics aggregate live Firestore data. More granular charts (daily trends, category breakdowns) can be added later.'),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _statTile(String label, String value, IconData icon, Color color) {
    return SizedBox(
      width: 180,
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(value,
                  style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold, color: color)),
              const SizedBox(height: 4),
              Text(label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBarChart(_AnalyticsData data) {
    final items = [
      _BarData('Pending', data.pendingAds, Colors.orange),
      _BarData('Active', data.activeAds, Colors.teal),
      _BarData('Rejected', data.rejectedAds, Colors.red),
    ];
    final maxValue = (items
        .map((e) => e.value)
        .fold<int>(0, (p, c) => c > p ? c : p)).clamp(1, 999999);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: items.map((e) {
            final heightFactor = e.value / maxValue;
            return Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(e.value.toString(),
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Container(
                  width: 40,
                  height: 160 * heightFactor,
                  decoration: BoxDecoration(
                    color: e.color.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 6),
                Text(e.label, style: const TextStyle(fontSize: 12)),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _AnalyticsData {
  final int userCount;
  final int adCount;
  final int pendingAds;
  final int activeAds;
  final int rejectedAds;
  final double averagePrice;

  _AnalyticsData({
    required this.userCount,
    required this.adCount,
    required this.pendingAds,
    required this.activeAds,
    required this.rejectedAds,
    required this.averagePrice,
  });
}

class _BarData {
  final String label;
  final int value;
  final Color color;
  _BarData(this.label, this.value, this.color);
}
