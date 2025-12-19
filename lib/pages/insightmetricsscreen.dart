// lib/screens/insight_metrics_screen.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../models/ad_model.dart';

class InsightMetricsScreen extends StatefulWidget {
  final AdModel ad;
  const InsightMetricsScreen({super.key, required this.ad});

  @override
  State<InsightMetricsScreen> createState() => _InsightMetricsScreenState();
}

class _InsightMetricsScreenState extends State<InsightMetricsScreen> {
  int views = 0;
  int saves = 0;
  int contacts = 0;

  Map<String, int> _dailyViews = {};
  StreamSubscription<DocumentSnapshot>? _statsSub;
  StreamSubscription<QuerySnapshot>? _eventsSub;

  @override
  void initState() {
    super.initState();
    _listenStats();
    _listenEvents();
  }

  void _listenStats() {
    final ref = FirebaseFirestore.instance
        .collection('ads')
        .doc(widget.ad.id)
        .collection('insights')
        .doc('stats');

    _statsSub = ref.snapshots().listen((snap) {
      if (snap.exists) {
        final d = snap.data()!;
        setState(() {
          views = d['views'] ?? 0;
          saves = d['saves'] ?? 0;
          contacts = d['contacts'] ?? 0;
        });
      }
    });
  }

  void _listenEvents() {
    final ref = FirebaseFirestore.instance
        .collection('ads')
        .doc(widget.ad.id)
        .collection('insights')
        .doc('events')
        .collection('items');

    final since =
        Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 14)));

    _eventsSub =
        ref.where('ts', isGreaterThan: since).snapshots().listen((snap) {
      Map<String, int> temp = {};
      for (var doc in snap.docs) {
        final ts = (doc['ts'] as Timestamp).toDate();
        final key =
            "${ts.year}-${ts.month.toString().padLeft(2, '0')}-${ts.day.toString().padLeft(2, '0')}";

        temp[key] = (temp[key] ?? 0) + 1;
      }
      setState(() => _dailyViews = temp);
    });
  }

  @override
  void dispose() {
    _statsSub?.cancel();
    _eventsSub?.cancel();
    super.dispose();
  }

  List<FlSpot> _spots() {
    final today = DateTime.now();
    List<FlSpot> list = [];

    for (int i = 13; i >= 0; i--) {
      final d = today.subtract(Duration(days: i));
      final key =
          "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
      final count = _dailyViews[key] ?? 0;
      list.add(FlSpot((13 - i).toDouble(), count.toDouble()));
    }
    return list;
  }

  Widget _chart() {
    final spots = _spots();
    final zero = spots.every((e) => e.y == 0);

    if (zero) {
      return const SizedBox(
          height: 160, child: Center(child: Text("No data for last 14 days")));
    }

    return SizedBox(
      height: 260,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: true),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: true),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 3,
                getTitlesWidget: (value, _) {
                  if (value < 0 || value > 13) return Container();
                  final date = DateTime.now()
                      .subtract(Duration(days: 13 - value.toInt()));
                  return Text("${date.month}/${date.day}",
                      style: const TextStyle(fontSize: 10));
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              barWidth: 3,
              color: Colors.blue,
              belowBarData:
                  BarAreaData(show: true, color: Colors.blue.withOpacity(0.2)),
            )
          ],
        ),
      ),
    );
  }

  Widget _card(String label, int value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.2),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text("$value",
                  style: TextStyle(
                      fontSize: 20, color: color, fontWeight: FontWeight.bold)),
            ])
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ad = widget.ad;

    return Scaffold(
      appBar: AppBar(title: const Text("Ad Insights")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(ad.title,
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _card("Views", views, Icons.remove_red_eye, Colors.blue),
          _card("Saves", saves, Icons.bookmark, Colors.green),
          _card("Contact Clicks", contacts, Icons.phone, Colors.red),
          const SizedBox(height: 20),
          const Text("Last 14 Days (Views)",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Card(
              child:
                  Padding(padding: const EdgeInsets.all(12), child: _chart())),
        ]),
      ),
    );
  }
}
