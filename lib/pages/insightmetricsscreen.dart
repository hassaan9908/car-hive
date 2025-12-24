// lib/screens/insight_metrics_screen.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
// ignore: depend_on_referenced_packages
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../models/ad_model.dart';
import '../services/insight_service.dart';

class InsightMetricsScreen extends StatefulWidget {
  final AdModel ad;
  const InsightMetricsScreen({super.key, required this.ad});

  @override
  State<InsightMetricsScreen> createState() => _InsightMetricsScreenState();
}

class _InsightMetricsScreenState extends State<InsightMetricsScreen>
    with SingleTickerProviderStateMixin {
  final InsightService _insightService = InsightService();

  int views = 0;
  int saves = 0;
  int contacts = 0;
  int messages = 0;
  DateTime? lastViewedAt;
  DateTime? lastContactAt;
  DateTime? lastMessageAt;
  DateTime? lastSavedAt;

  Map<String, Map<String, int>> _dailyData = {};
  StreamSubscription<Map<String, dynamic>>? _statsSub;
  StreamSubscription<Map<String, Map<String, int>>>? _eventsSub;

  late TabController _tabController;
  String _selectedMetric = 'view';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadInitialData();
    _listenStats();
    _listenEvents();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);

    // Initial fetch to ensure we have data immediately
    if (widget.ad.id != null && widget.ad.id!.isNotEmpty) {
      try {
        final statsDoc = await FirebaseFirestore.instance
            .collection('ads')
            .doc(widget.ad.id)
            .collection('insights')
            .doc('stats')
            .get();

        if (statsDoc.exists && mounted) {
          final data = statsDoc.data() ?? {};
          setState(() {
            views = (data['views'] ?? 0) as int;
            saves = (data['saves'] ?? 0) as int;
            contacts = (data['contacts'] ?? 0) as int;
            messages = (data['messages'] ?? 0) as int;
            lastViewedAt = (data['lastViewedAt'] as Timestamp?)?.toDate();
            lastContactAt = (data['lastContactAt'] as Timestamp?)?.toDate();
            lastMessageAt = (data['lastMessageAt'] as Timestamp?)?.toDate();
            lastSavedAt = (data['lastSavedAt'] as Timestamp?)?.toDate();
          });
        }
      } catch (e) {
        print('Error loading initial stats: $e');
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _listenStats() {
    if (widget.ad.id == null || widget.ad.id!.isEmpty) return;

    _statsSub = _insightService.getAdInsights(widget.ad.id!).listen((data) {
      if (mounted) {
        setState(() {
          views = (data['views'] ?? 0) as int;
          saves = (data['saves'] ?? 0) as int;
          contacts = (data['contacts'] ?? 0) as int;
          messages = (data['messages'] ?? 0) as int;
          lastViewedAt = (data['lastViewedAt'] as Timestamp?)?.toDate();
          lastContactAt = (data['lastContactAt'] as Timestamp?)?.toDate();
          lastMessageAt = (data['lastMessageAt'] as Timestamp?)?.toDate();
          lastSavedAt = (data['lastSavedAt'] as Timestamp?)?.toDate();
        });
      }
    });
  }

  void _listenEvents() {
    if (widget.ad.id == null || widget.ad.id!.isEmpty) return;

    _eventsSub =
        _insightService.getDailyEvents(widget.ad.id!, days: 14).listen((data) {
      if (mounted) {
        setState(() => _dailyData = data);
      }
    });
  }

  @override
  void dispose() {
    _statsSub?.cancel();
    _eventsSub?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  List<FlSpot> _getSpots(String metric) {
    final today = DateTime.now();
    List<FlSpot> list = [];

    for (int i = 13; i >= 0; i--) {
      final d = today.subtract(Duration(days: i));
      final key =
          "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
      final dayData = _dailyData[key] ?? {};
      final count = dayData[metric] ?? 0;
      list.add(FlSpot((13 - i).toDouble(), count.toDouble()));
    }
    return list;
  }

  Color _getMetricColor(String metric) {
    switch (metric) {
      case 'view':
        return Colors.blue;
      case 'contact':
        return Colors.red;
      case 'message':
        return Colors.purple;
      case 'save':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  Widget _buildChart() {
    final spots = _getSpots(_selectedMetric);
    final zero = spots.every((e) => e.y == 0);
    final color = _getMetricColor(_selectedMetric);

    if (zero) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.analytics_outlined, size: 48, color: Colors.grey),
              SizedBox(height: 12),
              Text("No data for last 14 days",
                  style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    return Container(
      height: 280,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 1,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey.withOpacity(0.2),
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 35,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 3,
                getTitlesWidget: (value, _) {
                  if (value < 0 || value > 13) return const SizedBox();
                  final date = DateTime.now()
                      .subtract(Duration(days: 13 - value.toInt()));
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      "${date.month}/${date.day}",
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.3,
              barWidth: 3,
              color: color,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, bar, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: color,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [color.withOpacity(0.3), color.withOpacity(0.05)],
                ),
              ),
            )
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final date = DateTime.now()
                      .subtract(Duration(days: 13 - spot.x.toInt()));
                  return LineTooltipItem(
                    '${date.month}/${date.day}\n${spot.y.toInt()} ${_selectedMetric}s',
                    const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String label, int value, IconData icon, Color color, String metric,
      {DateTime? lastActivity}) {
    final isSelected = _selectedMetric == metric;
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => setState(() => _selectedMetric = metric),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(0.15)
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: color.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4))
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const Spacer(),
                if (isSelected)
                  Icon(Icons.check_circle, color: color, size: 16),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              "$value",
              style: TextStyle(
                fontSize: 28,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (lastActivity != null) ...[
              const SizedBox(height: 4),
              Text(
                'Last: ${_formatLastActivity(lastActivity)}',
                style: TextStyle(
                  fontSize: 10,
                  color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatLastActivity(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    return '${dt.day}/${dt.month}';
  }

  Widget _buildOverviewTab() {
    final colorScheme = Theme.of(context).colorScheme;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadInitialData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ad Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary,
                    colorScheme.primary.withOpacity(0.8)
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.directions_car,
                        color: Colors.white, size: 30),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.ad.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'PKR ${widget.ad.price}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.ad.status.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Real-time indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Real-time data',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Stats Grid
            Text(
              'Performance Metrics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap a metric to see its trend in the chart',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.1,
              children: [
                _buildStatCard(
                    'Views', views, Icons.remove_red_eye, Colors.blue, 'view',
                    lastActivity: lastViewedAt),
                _buildStatCard(
                    'Saves', saves, Icons.bookmark, Colors.green, 'save',
                    lastActivity: lastSavedAt),
                _buildStatCard(
                    'Contacts', contacts, Icons.phone, Colors.red, 'contact',
                    lastActivity: lastContactAt),
                _buildStatCard('Messages', messages, Icons.message,
                    Colors.purple, 'message',
                    lastActivity: lastMessageAt),
              ],
            ),

            const SizedBox(height: 24),

            // Chart Section
            Row(
              children: [
                Text(
                  'Last 14 Days',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getMetricColor(_selectedMetric).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _selectedMetric.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _getMetricColor(_selectedMetric),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildChart(),

            const SizedBox(height: 24),

            // Conversion Rate Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.trending_up, color: colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Engagement Rate',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildEngagementMetric(
                          'Contact Rate',
                          views > 0
                              ? ((contacts / views) * 100).toStringAsFixed(1)
                              : '0',
                          '%',
                          Colors.red,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildEngagementMetric(
                          'Save Rate',
                          views > 0
                              ? ((saves / views) * 100).toStringAsFixed(1)
                              : '0',
                          '%',
                          Colors.green,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildEngagementMetric(
                          'Message Rate',
                          views > 0
                              ? ((messages / views) * 100).toStringAsFixed(1)
                              : '0',
                          '%',
                          Colors.purple,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEngagementMetric(
      String label, String value, String suffix, Color color) {
    return Column(
      children: [
        Text(
          '$value$suffix',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildActivityTab() {
    final colorScheme = Theme.of(context).colorScheme;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('ads')
          .doc(widget.ad.id)
          .collection('insights')
          .doc('events')
          .collection('items')
          .orderBy('ts', descending: true)
          .limit(50)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No activity yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        final events = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: events.length,
          itemBuilder: (context, index) {
            final event = events[index].data() as Map<String, dynamic>;
            final type = event['type'] as String? ?? 'view';
            final ts = (event['ts'] as Timestamp?)?.toDate() ?? DateTime.now();

            IconData icon;
            Color color;
            String label;

            switch (type) {
              case 'view':
                icon = Icons.remove_red_eye;
                color = Colors.blue;
                label = 'Someone viewed your ad';
                break;
              case 'contact':
                icon = Icons.phone;
                color = Colors.red;
                label = 'Someone clicked to call';
                break;
              case 'message':
                icon = Icons.message;
                color = Colors.purple;
                label = 'Someone sent a message';
                break;
              case 'save':
                icon = Icons.bookmark;
                color = Colors.green;
                label = 'Someone saved your ad';
                break;
              default:
                icon = Icons.info;
                color = Colors.grey;
                label = 'Activity';
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatDateTime(ts),
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ad Insights'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInitialData,
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: colorScheme.primary,
          labelColor: colorScheme.primary,
          unselectedLabelColor: colorScheme.onSurfaceVariant,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.analytics, size: 20)),
            Tab(text: 'Activity', icon: Icon(Icons.history, size: 20)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildActivityTab(),
        ],
      ),
    );
  }
}
