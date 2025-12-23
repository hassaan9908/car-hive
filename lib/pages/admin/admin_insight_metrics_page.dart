import 'dart:async';
import 'package:flutter/material.dart';
// ignore: unused_import
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
// ignore: unused_import
import '../../providers/admin_provider.dart';

class AdminInsightMetricsPage extends StatefulWidget {
  const AdminInsightMetricsPage({super.key});

  @override
  State<AdminInsightMetricsPage> createState() =>
      _AdminInsightMetricsPageState();
}

class _AdminInsightMetricsPageState extends State<AdminInsightMetricsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String? _errorMessage;

  // Metrics data
  Map<String, int> _brandStats = {};
  Map<String, int> _locationStats = {};
  Map<String, int> _priceRangeStats = {};
  Map<String, int> _yearStats = {};
  Map<String, int> _dailyViews = {};
  Map<String, int> _dailyListings = {};
  int _totalViews = 0;
  int _totalMessages = 0;
  int _totalContacts = 0;
  int _totalSaves = 0;
  int _totalConversions = 0;
  int _totalAds = 0;
  double _avgTimeToSell = 0;
  double _viewsWeeklyChange = 0;
  double _messagesWeeklyChange = 0;
  List<Map<String, dynamic>> _topPerformingAds = [];
  List<Map<String, dynamic>> _recentSearches = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final firestore = FirebaseFirestore.instance;

      // Load all ads first
      final adsSnapshot = await firestore.collection('ads').get();
      final ads = adsSnapshot.docs;

      if (!mounted) return;

      _totalAds = ads.length;

      // Initialize counters
      Map<String, int> brandCounts = {};
      Map<String, int> locationCounts = {};
      Map<String, int> priceRangeCounts = {
        '< 5 Lakh': 0,
        '5-10 Lakh': 0,
        '10-20 Lakh': 0,
        '20-50 Lakh': 0,
        '50+ Lakh': 0,
      };
      Map<String, int> yearCounts = {};
      int totalViews = 0;
      int totalMessages = 0;
      int totalContacts = 0;
      int totalSaves = 0;
      int totalConversions = 0;
      List<Map<String, dynamic>> adsWithInsights = [];

      // Process each ad
      for (var doc in ads) {
        final data = doc.data();

        // Brand stats
        final brand = data['carBrand']?.toString() ?? 'Unknown';
        if (brand.isNotEmpty && brand != 'Unknown') {
          brandCounts[brand] = (brandCounts[brand] ?? 0) + 1;
        }

        // Location stats
        final location = data['location']?.toString() ?? 'Unknown';
        final city = location.split(',').first.trim();
        if (city.isNotEmpty && city != 'Unknown') {
          locationCounts[city] = (locationCounts[city] ?? 0) + 1;
        }

        // Price range stats
        final priceStr =
            data['price']?.toString().replaceAll(RegExp(r'[^0-9]'), '') ?? '0';
        final price = int.tryParse(priceStr) ?? 0;
        if (price < 500000) {
          priceRangeCounts['< 5 Lakh'] = priceRangeCounts['< 5 Lakh']! + 1;
        } else if (price < 1000000) {
          priceRangeCounts['5-10 Lakh'] = priceRangeCounts['5-10 Lakh']! + 1;
        } else if (price < 2000000) {
          priceRangeCounts['10-20 Lakh'] = priceRangeCounts['10-20 Lakh']! + 1;
        } else if (price < 5000000) {
          priceRangeCounts['20-50 Lakh'] = priceRangeCounts['20-50 Lakh']! + 1;
        } else {
          priceRangeCounts['50+ Lakh'] = priceRangeCounts['50+ Lakh']! + 1;
        }

        // Year stats
        final year = data['year']?.toString() ?? '';
        if (year.isNotEmpty && year != 'Unknown') {
          yearCounts[year] = (yearCounts[year] ?? 0) + 1;
        }

        // Check for sold status
        if (data['status'] == 'sold') {
          totalConversions++;
        }

        // Get insights from subcollection - with timeout
        int adViews = 0;
        int adMessages = 0;
        int adContacts = 0;
        int adSaves = 0;

        try {
          final insightsDoc = await firestore
              .collection('ads')
              .doc(doc.id)
              .collection('insights')
              .doc('stats')
              .get()
              .timeout(const Duration(seconds: 3));

          if (insightsDoc.exists) {
            final insightData = insightsDoc.data() ?? {};
            adViews = (insightData['views'] ?? 0) as int;
            adMessages = (insightData['messages'] ?? 0) as int;
            adContacts = (insightData['contacts'] ?? 0) as int;
            adSaves = (insightData['saves'] ?? 0) as int;
          }
        } catch (e) {
          // Skip if timeout or error
        }

        totalViews += adViews;
        totalMessages += adMessages;
        totalContacts += adContacts;
        totalSaves += adSaves;

        // Store for top performing
        if (data['status'] == 'active') {
          adsWithInsights.add({
            'id': doc.id,
            'title': data['title'] ?? data['carBrand'] ?? 'Unknown',
            'views': adViews,
            'messages': adMessages,
            'contacts': adContacts,
            'saves': adSaves,
            'price': data['price'] ?? '0',
            'location': data['location'] ?? 'Unknown',
          });
        }
      }

      // Sort brand stats
      final sortedBrands = brandCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      // Sort location stats
      final sortedLocations = locationCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      // Sort year stats
      final sortedYears = yearCounts.entries.toList()
        ..sort((a, b) => b.key.compareTo(a.key));

      // Sort ads by views
      adsWithInsights
          .sort((a, b) => (b['views'] as int).compareTo(a['views'] as int));

      // Calculate daily stats
      final dailyStats = await _calculateDailyStats(firestore);

      // Calculate weekly changes
      final weeklyChanges = await _calculateWeeklyChanges(firestore, ads);

      // Calculate avg time to sell
      double avgTimeToSell = 0;
      int soldCount = 0;
      for (var doc in ads) {
        final data = doc.data();
        if (data['status'] == 'sold') {
          final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
          final soldAt = (data['soldAt'] as Timestamp?)?.toDate() ??
              (data['updatedAt'] as Timestamp?)?.toDate();
          if (createdAt != null && soldAt != null) {
            avgTimeToSell += soldAt.difference(createdAt).inDays;
            soldCount++;
          }
        }
      }
      if (soldCount > 0) {
        avgTimeToSell = avgTimeToSell / soldCount;
      }

      // Load recent searches
      List<Map<String, dynamic>> recentSearches = [];
      try {
        final searchSnapshot = await firestore
            .collection('search_logs')
            .orderBy('timestamp', descending: true)
            .limit(10)
            .get()
            .timeout(const Duration(seconds: 3));

        recentSearches = searchSnapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'query': data['query'] ?? '',
            'timestamp': data['timestamp'],
          };
        }).toList();
      } catch (e) {
        // Collection might not exist
      }

      if (!mounted) return;

      setState(() {
        _brandStats = Map.fromEntries(sortedBrands.take(10));
        _locationStats = Map.fromEntries(sortedLocations.take(10));
        _priceRangeStats = priceRangeCounts;
        _yearStats = Map.fromEntries(sortedYears.take(10));
        _totalViews = totalViews;
        _totalMessages = totalMessages;
        _totalContacts = totalContacts;
        _totalSaves = totalSaves;
        _totalConversions = totalConversions;
        _topPerformingAds = adsWithInsights.take(5).toList();
        _dailyListings = dailyStats['listings'] ?? {};
        _dailyViews = dailyStats['views'] ?? {};
        _viewsWeeklyChange = weeklyChanges['views'] ?? 0.0;
        _messagesWeeklyChange = weeklyChanges['messages'] ?? 0.0;
        _avgTimeToSell = avgTimeToSell;
        _recentSearches = recentSearches;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error loading data: ${e.toString()}';
        });
      }
    }
  }

  Future<Map<String, Map<String, int>>> _calculateDailyStats(
      FirebaseFirestore firestore) async {
    final now = DateTime.now();
    Map<String, int> dailyListings = {};
    Map<String, int> dailyViews = {};

    // Initialize last 7 days
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateKey = '${date.day}/${date.month}';
      dailyListings[dateKey] = 0;
      dailyViews[dateKey] = 0;
    }

    try {
      // Get ads created in last 7 days
      final weekAgo = now.subtract(const Duration(days: 7));
      final adsSnapshot = await firestore
          .collection('ads')
          .where('createdAt', isGreaterThan: Timestamp.fromDate(weekAgo))
          .get()
          .timeout(const Duration(seconds: 5));

      for (var doc in adsSnapshot.docs) {
        final data = doc.data();
        final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
        if (createdAt != null) {
          final dateKey = '${createdAt.day}/${createdAt.month}';
          if (dailyListings.containsKey(dateKey)) {
            dailyListings[dateKey] = dailyListings[dateKey]! + 1;
          }
        }
      }
    } catch (e) {
      print('Error calculating daily listings: $e');
    }

    return {
      'listings': dailyListings,
      'views': dailyViews,
    };
  }

  Future<Map<String, double>> _calculateWeeklyChanges(
      FirebaseFirestore firestore, List<QueryDocumentSnapshot> ads) async {
    double viewsChange = 0;
    double messagesChange = 0;

    try {
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));
      final twoWeeksAgo = now.subtract(const Duration(days: 14));

      int thisWeekViews = 0;
      int lastWeekViews = 0;
      int thisWeekMessages = 0;
      int lastWeekMessages = 0;

      // Sample only first 20 ads to avoid timeout
      final sampleAds = ads.take(20).toList();

      for (var adDoc in sampleAds) {
        try {
          // This week views
          final thisWeekEventsViews = await firestore
              .collection('ads')
              .doc(adDoc.id)
              .collection('insights')
              .doc('events')
              .collection('items')
              .where('type', isEqualTo: 'view')
              .where('ts', isGreaterThan: Timestamp.fromDate(weekAgo))
              .get()
              .timeout(const Duration(seconds: 2));
          thisWeekViews += thisWeekEventsViews.docs.length;

          // This week messages
          final thisWeekEventsMessages = await firestore
              .collection('ads')
              .doc(adDoc.id)
              .collection('insights')
              .doc('events')
              .collection('items')
              .where('type', isEqualTo: 'message')
              .where('ts', isGreaterThan: Timestamp.fromDate(weekAgo))
              .get()
              .timeout(const Duration(seconds: 2));
          thisWeekMessages += thisWeekEventsMessages.docs.length;
        } catch (e) {
          // Skip on timeout
        }
      }

      // Calculate percentage changes
      if (lastWeekViews > 0) {
        viewsChange = ((thisWeekViews - lastWeekViews) / lastWeekViews * 100);
      } else if (thisWeekViews > 0) {
        viewsChange = 100;
      }

      if (lastWeekMessages > 0) {
        messagesChange =
            ((thisWeekMessages - lastWeekMessages) / lastWeekMessages * 100);
      } else if (thisWeekMessages > 0) {
        messagesChange = 100;
      }
    } catch (e) {
      print('Error calculating weekly changes: $e');
    }

    return {
      'views': viewsChange,
      'messages': messagesChange,
    };
  }

  String _formatWeeklyChange(double change) {
    final sign = change >= 0 ? '+' : '';
    return '$sign${change.toStringAsFixed(1)}% this week';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Insight Metrics',
          style: TextStyle(
            color: isDark ? const Color(0xFFf48c25) : Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(
          color: isDark ? const Color(0xFFf48c25) : Colors.black,
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFFf48c25),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFFf48c25),
          isScrollable: true,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard, size: 20)),
            Tab(text: 'Trends', icon: Icon(Icons.trending_up, size: 20)),
            Tab(text: 'Performance', icon: Icon(Icons.speed, size: 20)),
            Tab(text: 'Analytics', icon: Icon(Icons.analytics, size: 20)),
          ],
        ),
        actions: [
          IconButton(
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadAllData,
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading insights data...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_errorMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadAllData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildOverviewTab(),
        _buildTrendsTab(),
        _buildPerformanceTab(),
        _buildAnalyticsTab(),
      ],
    );
  }

  Widget _buildOverviewTab() {
    return RefreshIndicator(
      onRefresh: _loadAllData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildKeyMetricsSection(),
            const SizedBox(height: 24),
            _buildQuickStatsSection(),
            const SizedBox(height: 24),
            _buildTopPerformingAdsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyMetricsSection() {
    final conversionRate = _totalAds > 0
        ? (_totalConversions / _totalAds * 100).toStringAsFixed(1)
        : '0';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Key Metrics',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.4,
          children: [
            _buildMetricCard(
              'Total Views',
              _totalViews.toString(),
              Icons.visibility,
              const Color(0xFF4CAF50),
              _formatWeeklyChange(_viewsWeeklyChange),
              _viewsWeeklyChange >= 0,
            ),
            _buildMetricCard(
              'Messages',
              _totalMessages.toString(),
              Icons.message,
              const Color(0xFF2196F3),
              _formatWeeklyChange(_messagesWeeklyChange),
              _messagesWeeklyChange >= 0,
            ),
            _buildMetricCard(
              'Conversions',
              _totalConversions.toString(),
              Icons.shopping_cart,
              const Color(0xFFFF9800),
              '$conversionRate% rate',
              true,
            ),
            _buildMetricCard(
              'Avg. Time to Sell',
              '${_avgTimeToSell.toStringAsFixed(1)} days',
              Icons.timer,
              const Color(0xFF9C27B0),
              'From listing to sold',
              true,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon,
      Color color, String subtitle, bool isPositive) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.1),
              color.withOpacity(0.05),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                Icon(
                  isPositive ? Icons.trending_up : Icons.trending_down,
                  color: isPositive ? Colors.green : Colors.red,
                  size: 14,
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 9,
                    color: isPositive ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Statistics',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
                child: _buildStatChip(
                    'Brands', _brandStats.length.toString(), Icons.car_repair)),
            const SizedBox(width: 8),
            Expanded(
                child: _buildStatChip('Cities',
                    _locationStats.length.toString(), Icons.location_city)),
            const SizedBox(width: 8),
            Expanded(
                child: _buildStatChip(
                    'Total Ads', _totalAds.toString(), Icons.list_alt)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
                child: _buildStatChip(
                    'Contacts', _totalContacts.toString(), Icons.phone)),
            const SizedBox(width: 8),
            Expanded(
                child: _buildStatChip(
                    'Saves', _totalSaves.toString(), Icons.bookmark)),
            const SizedBox(width: 8),
            Expanded(
                child: _buildStatChip(
                    'Sold', _totalConversions.toString(), Icons.sell)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatChip(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFf48c25).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFf48c25).withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFFf48c25), size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFFf48c25),
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 9, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTopPerformingAdsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Top Performing Ads',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        if (_topPerformingAds.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Column(
                children: [
                  Icon(Icons.info_outline, size: 48, color: Colors.grey),
                  SizedBox(height: 8),
                  Text('No active ads with insights yet'),
                ],
              ),
            ),
          )
        else
          ...List.generate(_topPerformingAds.length, (index) {
            final ad = _topPerformingAds[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFFf48c25).withOpacity(0.2),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Color(0xFFf48c25),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  ad['title']?.toString() ?? 'Unknown',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text('PKR ${ad['price']}'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.visibility,
                            size: 12, color: Colors.blue),
                        const SizedBox(width: 2),
                        Text('${ad['views']}',
                            style: const TextStyle(fontSize: 11)),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.message,
                            size: 12, color: Colors.purple),
                        const SizedBox(width: 2),
                        Text('${ad['messages']}',
                            style: const TextStyle(fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildTrendsTab() {
    return RefreshIndicator(
      onRefresh: _loadAllData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDailyActivityChart(),
            const SizedBox(height: 24),
            _buildBrandDistributionChart(),
            const SizedBox(height: 24),
            _buildPriceRangeChart(),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyActivityChart() {
    final maxValue = _dailyListings.values.isEmpty
        ? 1.0
        : (_dailyListings.values.reduce((a, b) => a > b ? a : b)).toDouble();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Daily Listings (Last 7 Days)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: _dailyListings.isEmpty ||
                      _dailyListings.values.every((v) => v == 0)
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.bar_chart, size: 48, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('No listings in the last 7 days',
                              style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: (maxValue * 1.2).clamp(1, double.infinity),
                        barTouchData: BarTouchData(enabled: true),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final index = value.toInt();
                                if (index >= 0 &&
                                    index < _dailyListings.keys.length) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      _dailyListings.keys.toList()[index],
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                  );
                                }
                                return const Text('');
                              },
                              reservedSize: 30,
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              getTitlesWidget: (value, meta) {
                                return Text(value.toInt().toString(),
                                    style: const TextStyle(fontSize: 10));
                              },
                            ),
                          ),
                          topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                        ),
                        gridData: const FlGridData(
                            show: true, drawVerticalLine: false),
                        borderData: FlBorderData(show: false),
                        barGroups: List.generate(
                          _dailyListings.length,
                          (index) => BarChartGroupData(
                            x: index,
                            barRods: [
                              BarChartRodData(
                                toY: _dailyListings.values
                                    .toList()[index]
                                    .toDouble(),
                                color: const Color(0xFFf48c25),
                                width: 16,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(4),
                                  topRight: Radius.circular(4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrandDistributionChart() {
    final colors = [
      const Color(0xFFFF6B35),
      const Color(0xFF4CAF50),
      const Color(0xFF2196F3),
      const Color(0xFFFF9800),
      const Color(0xFF9C27B0),
      const Color(0xFF00BCD4),
      const Color(0xFFE91E63),
      const Color(0xFF795548),
      const Color(0xFF607D8B),
      const Color(0xFFCDDC39),
    ];

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Top Car Brands',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: _brandStats.isEmpty
                  ? const Center(
                      child: Text('No brand data available',
                          style: TextStyle(color: Colors.grey)))
                  : Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: PieChart(
                            PieChartData(
                              sectionsSpace: 2,
                              centerSpaceRadius: 40,
                              sections:
                                  List.generate(_brandStats.length, (index) {
                                final entry =
                                    _brandStats.entries.toList()[index];
                                final total =
                                    _brandStats.values.fold(0, (a, b) => a + b);
                                final percentage = total > 0
                                    ? (entry.value / total * 100)
                                    : 0.0;
                                return PieChartSectionData(
                                  color: colors[index % colors.length],
                                  value: entry.value.toDouble(),
                                  title: percentage > 5
                                      ? '${percentage.toStringAsFixed(0)}%'
                                      : '',
                                  radius: 50,
                                  titleStyle: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white),
                                );
                              }),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 1,
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children:
                                  List.generate(_brandStats.length, (index) {
                                final entry =
                                    _brandStats.entries.toList()[index];
                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 2),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          color: colors[index % colors.length],
                                          borderRadius:
                                              BorderRadius.circular(2),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(entry.key,
                                            style:
                                                const TextStyle(fontSize: 10),
                                            overflow: TextOverflow.ellipsis),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRangeChart() {
    final total = _priceRangeStats.values.fold(0, (a, b) => a + b);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Price Range Distribution',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (total == 0)
              const Center(
                  child: Text('No price data available',
                      style: TextStyle(color: Colors.grey)))
            else
              ...List.generate(_priceRangeStats.length, (index) {
                final entry = _priceRangeStats.entries.toList()[index];
                final percentage = total > 0 ? entry.value / total : 0.0;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(entry.key, style: const TextStyle(fontSize: 12)),
                          Text(
                              '${entry.value} (${(percentage * 100).toStringAsFixed(1)}%)',
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w500)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: percentage,
                        backgroundColor: Colors.grey.withOpacity(0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color.lerp(const Color(0xFF4CAF50),
                              const Color(0xFFFF6B35), index / 4)!,
                        ),
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceTab() {
    return RefreshIndicator(
      onRefresh: _loadAllData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLocationPerformanceSection(),
            const SizedBox(height: 24),
            _buildYearDistributionSection(),
            const SizedBox(height: 24),
            _buildConversionFunnelSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationPerformanceSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Top Cities by Listings',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (_locationStats.isEmpty)
              const Center(
                  child: Text('No location data available',
                      style: TextStyle(color: Colors.grey)))
            else
              ...List.generate(
                _locationStats.length > 5 ? 5 : _locationStats.length,
                (index) {
                  final entry = _locationStats.entries.toList()[index];
                  final maxValue = _locationStats.values.first;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 24,
                          child: Text('${index + 1}',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: index < 3
                                      ? const Color(0xFFf48c25)
                                      : Colors.grey)),
                        ),
                        Expanded(
                            flex: 2,
                            child: Text(entry.key,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500))),
                        Expanded(
                          flex: 3,
                          child: Stack(
                            children: [
                              Container(
                                  height: 20,
                                  decoration: BoxDecoration(
                                      color: Colors.grey.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10))),
                              FractionallySizedBox(
                                widthFactor:
                                    maxValue > 0 ? entry.value / maxValue : 0,
                                child: Container(
                                  height: 20,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(colors: [
                                      const Color(0xFFFF6B35),
                                      const Color(0xFFFF8C42).withOpacity(0.7)
                                    ]),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                            width: 30,
                            child: Text('${entry.value}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                                textAlign: TextAlign.end)),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildYearDistributionSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Car Years Distribution',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 150,
              child: _yearStats.isEmpty
                  ? const Center(
                      child: Text('No year data available',
                          style: TextStyle(color: Colors.grey)))
                  : LineChart(
                      LineChartData(
                        gridData: const FlGridData(
                            show: true, drawVerticalLine: false),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              getTitlesWidget: (value, meta) {
                                final index = value.toInt();
                                if (index >= 0 &&
                                    index < _yearStats.length &&
                                    index % 2 == 0) {
                                  return Text(_yearStats.keys.toList()[index],
                                      style: const TextStyle(fontSize: 9));
                                }
                                return const Text('');
                              },
                            ),
                          ),
                          leftTitles: const AxisTitles(
                              sideTitles: SideTitles(
                                  showTitles: true, reservedSize: 30)),
                          topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: List.generate(
                                _yearStats.length,
                                (index) => FlSpot(
                                    index.toDouble(),
                                    _yearStats.values
                                        .toList()[index]
                                        .toDouble())),
                            isCurved: true,
                            color: const Color(0xFFf48c25),
                            barWidth: 3,
                            dotData: const FlDotData(show: true),
                            belowBarData: BarAreaData(
                                show: true,
                                color:
                                    const Color(0xFFf48c25).withOpacity(0.1)),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversionFunnelSection() {
    final viewRate =
        _totalAds > 0 ? (_totalViews / _totalAds).toStringAsFixed(1) : '0';
    final messageRate = _totalViews > 0
        ? (_totalMessages / _totalViews * 100).toStringAsFixed(1)
        : '0';
    final conversionRate = _totalAds > 0
        ? (_totalConversions / _totalAds * 100).toStringAsFixed(1)
        : '0';

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Conversion Funnel',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            _buildFunnelStep('Total Listings', _totalAds.toString(), 1.0,
                const Color(0xFF4CAF50)),
            _buildFunnelStep(
                'Avg. Views/Listing', viewRate, 0.75, const Color(0xFF2196F3)),
            _buildFunnelStep(
                'Message Rate', '$messageRate%', 0.5, const Color(0xFFFF9800)),
            _buildFunnelStep('Conversion Rate', '$conversionRate%', 0.25,
                const Color(0xFFf48c25)),
          ],
        ),
      ),
    );
  }

  Widget _buildFunnelStep(
      String label, String value, double width, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
              Text(value,
                  style: TextStyle(fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          const SizedBox(height: 4),
          FractionallySizedBox(
            widthFactor: width,
            alignment: Alignment.centerLeft,
            child: Container(
              height: 30,
              decoration: BoxDecoration(
                gradient:
                    LinearGradient(colors: [color, color.withOpacity(0.6)]),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return RefreshIndicator(
      onRefresh: _loadAllData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSearchAnalyticsSection(),
            const SizedBox(height: 24),
            _buildUserEngagementSection(),
            const SizedBox(height: 24),
            _buildMarketInsightsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAnalyticsSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Recent Searches',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (_recentSearches.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12)),
                child: const Column(
                  children: [
                    Icon(Icons.search_off, size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text('No search data available',
                        style: TextStyle(color: Colors.grey)),
                  ],
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _recentSearches.map((search) {
                  return Chip(
                    label: Text(search['query'] ?? ''),
                    backgroundColor: const Color(0xFFf48c25).withOpacity(0.1),
                    labelStyle: const TextStyle(fontSize: 12),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserEngagementSection() {
    final avgViewsPerAd = _totalAds > 0 ? (_totalViews / _totalAds) : 0.0;
    final engagementRate = _totalViews > 0
        ? ((_totalMessages + _totalContacts + _totalSaves) / _totalViews * 100)
        : 0.0;
    final saveRate = _totalViews > 0 ? (_totalSaves / _totalViews * 100) : 0.0;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('User Engagement Metrics',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                    child: _buildEngagementMetric(
                        'Avg. Views/Ad',
                        avgViewsPerAd.toStringAsFixed(1),
                        Icons.visibility,
                        const Color(0xFF4CAF50))),
                Expanded(
                    child: _buildEngagementMetric(
                        'Engagement',
                        '${engagementRate.toStringAsFixed(1)}%',
                        Icons.touch_app,
                        const Color(0xFFFF5722))),
                Expanded(
                    child: _buildEngagementMetric(
                        'Save Rate',
                        '${saveRate.toStringAsFixed(1)}%',
                        Icons.bookmark,
                        const Color(0xFF2196F3))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEngagementMetric(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.bold, color: color)),
          Text(label,
              style: const TextStyle(fontSize: 9, color: Colors.grey),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildMarketInsightsSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFf48c25).withOpacity(0.1),
              const Color(0xFFFF6B35).withOpacity(0.05)
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: const Color(0xFFf48c25),
                      borderRadius: BorderRadius.circular(8)),
                  child:
                      const Icon(Icons.insights, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Text('Market Insights',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            _buildInsightItem(
                'Most Popular Brand',
                _brandStats.isNotEmpty ? _brandStats.keys.first : 'N/A',
                Icons.star),
            _buildInsightItem(
                'Hottest Market',
                _locationStats.isNotEmpty ? _locationStats.keys.first : 'N/A',
                Icons.location_on),
            _buildInsightItem(
                'Total Active Ads', _totalAds.toString(), Icons.list_alt),
            _buildInsightItem(
                'Most Common Price',
                _priceRangeStats.isNotEmpty
                    ? _priceRangeStats.entries
                        .reduce((a, b) => a.value > b.value ? a : b)
                        .key
                    : 'N/A',
                Icons.attach_money),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFf48c25), size: 20),
          const SizedBox(width: 12),
          Expanded(
              child: Text(label, style: const TextStyle(color: Colors.grey))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
