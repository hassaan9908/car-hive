import 'dart:math' as math;

import 'package:carhive/models/market_pulse_models.dart';
import 'package:carhive/pages/homepage.dart';
import 'package:carhive/services/market_pulse_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../components/custom_bottom_nav.dart';

class _MarketPulseColors {
  final bool isDark;
  final Color accent;
  final Color background;
  final Color card;
  final Color tile;
  final Color subtleFill;
  final Color border;
  final Color text;
  final Color muted;
  final Color faint;
  final Color skeleton;
  final Color success;
  final Color danger;

  const _MarketPulseColors({
    required this.isDark,
    required this.accent,
    required this.background,
    required this.card,
    required this.tile,
    required this.subtleFill,
    required this.border,
    required this.text,
    required this.muted,
    required this.faint,
    required this.skeleton,
    required this.success,
    required this.danger,
  });

  factory _MarketPulseColors.of(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    return _MarketPulseColors(
      isDark: isDark,
      accent: scheme.primary,
      background: theme.scaffoldBackgroundColor,
      card: scheme.surface,
      tile: isDark ? const Color(0xFF202020) : const Color(0xFFF8FAFC),
      subtleFill: isDark
          ? Colors.white.withValues(alpha: 0.04)
          : Colors.black.withValues(alpha: 0.035),
      border: isDark
          ? Colors.white.withValues(alpha: 0.07)
          : Colors.black.withValues(alpha: 0.08),
      text: scheme.onSurface,
      muted: scheme.onSurfaceVariant,
      faint: scheme.onSurfaceVariant.withValues(alpha: isDark ? 0.70 : 0.78),
      skeleton: isDark
          ? Colors.white.withValues(alpha: 0.08)
          : Colors.black.withValues(alpha: 0.07),
      success: const Color(0xFF4CAF50),
      danger: const Color(0xFFF44336),
    );
  }

  Color get accentSoft => accent.withValues(alpha: isDark ? 0.12 : 0.10);

  Color get accentBorder => accent.withValues(alpha: isDark ? 0.24 : 0.22);

  Color get mapBase => isDark
      ? Colors.white.withValues(alpha: 0.04)
      : Colors.black.withValues(alpha: 0.035);

  Color statusSoft(Color color) =>
      color.withValues(alpha: isDark ? 0.12 : 0.10);
}

class MarketPulsePage extends StatefulWidget {
  final bool isAdmin;

  const MarketPulsePage({
    super.key,
    this.isAdmin = false,
  });

  @override
  State<MarketPulsePage> createState() => _MarketPulsePageState();
}

class _MarketPulsePageState extends State<MarketPulsePage>
    with SingleTickerProviderStateMixin {
  static const List<String> _navRoutes = <String>[
    '/',
    '/myads',
    '/upload',
    '/investment',
    '/profile',
  ];

  final MarketPulseService _service = MarketPulseService();
  late final AnimationController _pulseController;

  MarketPulsePeriod _selectedPeriod = MarketPulsePeriod.week;
  MarketPulseModelMode _selectedModelMode = MarketPulseModelMode.listed;
  DateTimeRange? _customRange;
  int _reloadToken = 0;
  int _forceRefreshToken = 0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    if (!mounted) {
      return;
    }
    setState(() {
      _reloadToken++;
      _forceRefreshToken++;
    });
  }

  void _onTabSelected(int index) {
    if (index == 4) {
      return;
    }
    if (index == 0) {
      Navigator.pushNamedAndRemoveUntil(
          context, _navRoutes[0], (route) => false);
      return;
    }
    Navigator.pushReplacementNamed(context, _navRoutes[index]);
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024, 1, 1),
      lastDate: DateTime.now(),
      initialDateRange: _customRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: const Color(0xFFFF6B00),
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) {
      return;
    }

    setState(() {
      _customRange = picked;
      _reloadToken++;
    });
  }

  Future<void> _exportCsv() async {
    final csv = await _service.buildCsvReport(
      _selectedPeriod,
      customRange: _customRange,
    );
    await Clipboard.setData(ClipboardData(text: csv));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('MarketPulse CSV copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = _MarketPulseColors.of(context);
    final body = RefreshIndicator(
      color: colors.accent,
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: <Widget>[
          _buildHeader(),
          const SizedBox(height: 16),
          _buildPeriodFilters(),
          if (widget.isAdmin) ...<Widget>[
            const SizedBox(height: 12),
            _buildAdminToolbar(),
          ],
          const SizedBox(height: 20),
          _AsyncMarketPulseSection<List<MarketPulseCityPriceEntry>>(
            reloadToken: _reloadToken,
            forceRefreshToken: _forceRefreshToken,
            load: (force) => _service.getAvgPriceByCity(
              _selectedPeriod,
              customRange: _customRange,
              forceRefresh: force,
            ),
            isEmpty: (data) => data.isEmpty,
            skeleton: const _SectionSkeleton(height: 260),
            emptyBuilder: (context) => const _EmptyStateCard(
              title: 'No city pricing yet',
              subtitle:
                  'Average listing prices will appear once listings are indexed.',
            ),
            builder: (context, section) =>
                _AvgPriceByCityCard(section: section),
          ),
          const SizedBox(height: 16),
          _AsyncMarketPulseSection<List<MarketPulseModelEntry>>(
            reloadToken: _reloadToken,
            forceRefreshToken: _forceRefreshToken,
            load: (force) => _service.getTopModels(
              _selectedPeriod,
              mode: _selectedModelMode,
              customRange: _customRange,
              forceRefresh: force,
            ),
            isEmpty: (data) => data.isEmpty,
            skeleton: const _SectionSkeleton(height: 320),
            emptyBuilder: (context) => const _EmptyStateCard(
              title: 'No model leaderboard yet',
              subtitle:
                  'Model rankings will appear once listing activity is available.',
            ),
            builder: (context, section) => _TopModelsCard(
              section: section,
              mode: _selectedModelMode,
              onModeChanged: (mode) {
                setState(() {
                  _selectedModelMode = mode;
                  _reloadToken++;
                });
              },
            ),
          ),
          const SizedBox(height: 16),
          _AsyncMarketPulseSection<List<MarketPulseBrandEntry>>(
            reloadToken: _reloadToken,
            forceRefreshToken: _forceRefreshToken,
            load: (force) => _service.getTrendingBrands(
              _selectedPeriod,
              customRange: _customRange,
              forceRefresh: force,
            ),
            isEmpty: (data) => data.isEmpty,
            skeleton: const _SectionSkeleton(height: 290),
            emptyBuilder: (context) => const _EmptyStateCard(
              title: 'No brand trends yet',
              subtitle:
                  'Brand search heat will appear after search traffic arrives.',
            ),
            builder: (context, section) =>
                _TrendingBrandsCard(section: section),
          ),
          const SizedBox(height: 16),
          _PriceTrendSection(
            service: _service,
            period: _selectedPeriod,
            customRange: _customRange,
            reloadToken: _reloadToken,
            forceRefreshToken: _forceRefreshToken,
          ),
          const SizedBox(height: 16),
          _AsyncMarketPulseSection<List<MarketPulseActivityMetric>>(
            reloadToken: _reloadToken,
            forceRefreshToken: _forceRefreshToken,
            load: (force) => _service.getActivityStats(
              _selectedPeriod,
              customRange: _customRange,
              forceRefresh: force,
            ),
            isEmpty: (data) => data.isEmpty,
            skeleton: const _SectionSkeleton(height: 260),
            emptyBuilder: (context) => const _EmptyStateCard(
              title: 'No activity metrics yet',
              subtitle:
                  'Views, searches, and deals will populate here once events are tracked.',
            ),
            builder: (context, section) => _ActivityStatsCard(section: section),
          ),
          const SizedBox(height: 16),
          _AsyncMarketPulseSection<List<MarketPulseRegionEntry>>(
            reloadToken: _reloadToken,
            forceRefreshToken: _forceRefreshToken,
            load: (force) => _service.getRegionActivity(
              _selectedPeriod,
              customRange: _customRange,
              forceRefresh: force,
            ),
            isEmpty: (data) => data.isEmpty,
            skeleton: const _SectionSkeleton(height: 270),
            emptyBuilder: (context) => const _EmptyStateCard(
              title: 'No regional activity yet',
              subtitle:
                  'Region hotspots will show once listings and searches are mapped.',
            ),
            builder: (context, section) => _RegionHeatMapCard(section: section),
          ),
          if (widget.isAdmin) ...<Widget>[
            const SizedBox(height: 16),
            _AsyncMarketPulseSection<MarketPulseAdminExtras>(
              reloadToken: _reloadToken,
              forceRefreshToken: _forceRefreshToken,
              load: (force) => _service.getAdminExtras(
                _selectedPeriod,
                customRange: _customRange,
                forceRefresh: force,
              ),
              isEmpty: (data) => false,
              skeleton: const _SectionSkeleton(height: 250),
              builder: (context, section) => _AdminExtrasCard(section: section),
            ),
          ],
        ],
      ),
    );

    return Scaffold(
      backgroundColor: colors.background,
      appBar: widget.isAdmin
          ? null
          : AppBar(
              title: Text(
                'MarketPulse',
                style: TextStyle(
                  color: colors.accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
              centerTitle: true,
              automaticallyImplyLeading: false,
              backgroundColor: colors.background,
            ),
      body: body,
      bottomNavigationBar: widget.isAdmin
          ? null
          : CustomBottomNav(
              selectedIndex: -1,
              onTabSelected: _onTabSelected,
              onFabPressed: () {
                Navigator.pushReplacementNamed(context, '/upload');
              },
            ),
    );
  }

  Widget _buildHeader() {
    final colors = _MarketPulseColors.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                'MarketPulse',
                style: TextStyle(
                  color: colors.accent,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Opacity(
                    opacity: 0.4 + (_pulseController.value * 0.6),
                    child: child,
                  );
                },
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Color(0xFF4CAF50),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Live',
                style: TextStyle(
                  color: colors.text,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Live market insights - updated every hour',
            style: TextStyle(
              color: colors.muted,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodFilters() {
    final colors = _MarketPulseColors.of(context);
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: MarketPulsePeriod.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final period = MarketPulsePeriod.values[index];
          final isSelected = period == _selectedPeriod;
          return InkWell(
            onTap: () {
              setState(() {
                _selectedPeriod = period;
                _reloadToken++;
              });
            },
            borderRadius: BorderRadius.circular(999),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? colors.accent : colors.card,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: isSelected ? Colors.transparent : colors.border,
                ),
              ),
              child: Text(
                period.label,
                style: TextStyle(
                  color: isSelected ? Colors.white : colors.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAdminToolbar() {
    final colors = _MarketPulseColors.of(context);
    final rangeLabel = _customRange == null
        ? 'Custom Range'
        : '${DateFormat('dd MMM').format(_customRange!.start)} - ${DateFormat('dd MMM').format(_customRange!.end)}';

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 430;

        final rangeButton = OutlinedButton.icon(
          onPressed: _selectDateRange,
          icon: const Icon(Icons.date_range),
          label: Text(
            rangeLabel,
            overflow: TextOverflow.ellipsis,
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: colors.text,
            side: BorderSide(color: colors.border),
            backgroundColor: colors.card,
          ),
        );

        final exportButton = FilledButton.icon(
          onPressed: _exportCsv,
          icon: const Icon(Icons.download_rounded),
          label: const Text('Export CSV'),
          style: FilledButton.styleFrom(
            backgroundColor: colors.accent,
            foregroundColor: Colors.white,
          ),
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              rangeButton,
              const SizedBox(height: 10),
              exportButton,
            ],
          );
        }

        return Row(
          children: <Widget>[
            Expanded(child: rangeButton),
            const SizedBox(width: 10),
            exportButton,
          ],
        );
      },
    );
  }
}

class _AsyncMarketPulseSection<T> extends StatefulWidget {
  final int reloadToken;
  final int forceRefreshToken;
  final Future<MarketPulseSection<T>> Function(bool forceRefresh) load;
  final bool Function(T data) isEmpty;
  final Widget skeleton;
  final Widget Function(BuildContext context)? emptyBuilder;
  final Widget Function(BuildContext context, MarketPulseSection<T> section)
      builder;

  const _AsyncMarketPulseSection({
    required this.reloadToken,
    required this.forceRefreshToken,
    required this.load,
    required this.isEmpty,
    required this.skeleton,
    required this.builder,
    this.emptyBuilder,
  });

  @override
  State<_AsyncMarketPulseSection<T>> createState() =>
      _AsyncMarketPulseSectionState<T>();
}

class _AsyncMarketPulseSectionState<T>
    extends State<_AsyncMarketPulseSection<T>> {
  late Future<MarketPulseSection<T>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.load(false);
  }

  @override
  void didUpdateWidget(covariant _AsyncMarketPulseSection<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reloadToken != widget.reloadToken ||
        oldWidget.forceRefreshToken != widget.forceRefreshToken) {
      final shouldForceRefresh =
          oldWidget.forceRefreshToken != widget.forceRefreshToken;
      _future = widget.load(shouldForceRefresh);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<MarketPulseSection<T>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return widget.skeleton;
        }
        if (snapshot.hasError) {
          return _ErrorStateCard(
            message: snapshot.error.toString(),
            onRetry: () {
              setState(() {
                _future = widget.load(true);
              });
            },
          );
        }

        final section = snapshot.data;
        if (section == null) {
          return widget.emptyBuilder?.call(context) ??
              const _EmptyStateCard(
                title: 'No data available',
                subtitle:
                    'This section will populate after analytics data is available.',
              );
        }

        if (widget.isEmpty(section.data)) {
          return widget.emptyBuilder?.call(context) ??
              const _EmptyStateCard(
                title: 'No data available',
                subtitle:
                    'This section will populate after analytics data is available.',
              );
        }

        return widget.builder(context, section);
      },
    );
  }
}

class _AvgPriceByCityCard extends StatelessWidget {
  final MarketPulseSection<List<MarketPulseCityPriceEntry>> section;

  const _AvgPriceByCityCard({required this.section});

  @override
  Widget build(BuildContext context) {
    final colors = _MarketPulseColors.of(context);
    final maxPrice = section.data
        .map((item) => item.avgPrice)
        .fold<double>(0, (prev, value) => value > prev ? value : prev);

    return _MarketPulseCard(
      title: 'Avg Price by City',
      subtitle: 'Based on active listings',
      updatedAt: section.updatedAt,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 360;
          final cityWidth = math.min(92.0, constraints.maxWidth * 0.26);
          final valueWidth = math.min(104.0, constraints.maxWidth * 0.30);

          return Column(
            children: section.data.asMap().entries.map((entry) {
              final item = entry.value;
              final ratio = maxPrice <= 0 ? 0.0 : item.avgPrice / maxPrice;
              final opacity = 0.35 + (ratio * 0.65);
              final progressBar = ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 12,
                  backgroundColor: colors.skeleton,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    colors.accent.withValues(alpha: opacity),
                  ),
                ),
              );

              return Padding(
                padding: EdgeInsets.only(
                  bottom: entry.key == section.data.length - 1 ? 0 : 14,
                ),
                child: compact
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  item.city,
                                  style: TextStyle(
                                    color: colors.text,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                '${_formatLakh(item.avgPrice)} avg',
                                style: TextStyle(
                                  color: colors.muted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          progressBar,
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          SizedBox(
                            width: cityWidth,
                            child: Text(
                              item.city,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: colors.text,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          Expanded(child: progressBar),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: valueWidth,
                            child: Text(
                              '${_formatLakh(item.avgPrice)} avg',
                              textAlign: TextAlign.end,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: colors.muted,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class _TopModelsCard extends StatelessWidget {
  final MarketPulseSection<List<MarketPulseModelEntry>> section;
  final MarketPulseModelMode mode;
  final ValueChanged<MarketPulseModelMode> onModeChanged;

  const _TopModelsCard({
    required this.section,
    required this.mode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _MarketPulseColors.of(context);
    final maxCount = section.data
        .map((item) => item.count)
        .fold<int>(0, (prev, value) => value > prev ? value : prev);

    return _MarketPulseCard(
      title: 'Top Models',
      subtitle: 'Tap a model to open filtered search results',
      updatedAt: section.updatedAt,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: MarketPulseModelMode.values.map((entry) {
          final isSelected = mode == entry;
          return Padding(
            padding: const EdgeInsets.only(left: 6),
            child: InkWell(
              onTap: () => onModeChanged(entry),
              borderRadius: BorderRadius.circular(999),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? colors.accent : colors.subtleFill,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  entry.label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : colors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 360;
          final countSuffix =
              mode == MarketPulseModelMode.sold ? 'sold' : 'listings';

          return Column(
            children: section.data.asMap().entries.map((entry) {
              final item = entry.value;
              final ratio = maxCount <= 0 ? 0.0 : item.count / maxCount;
              final progressBar = ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 10,
                  backgroundColor: colors.skeleton,
                  valueColor: AlwaysStoppedAnimation<Color>(colors.accent),
                ),
              );

              return InkWell(
                onTap: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          Homepage(initialSearchQuery: item.displayName),
                    ),
                    (route) => false,
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: entry.key == section.data.length - 1 ? 0 : 14,
                  ),
                  child: compact
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                Text(
                                  '#${entry.key + 1}',
                                  style: TextStyle(
                                    color: colors.accent,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    item.displayName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: colors.text,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  '${item.count} $countSuffix',
                                  style: TextStyle(
                                    color: colors.muted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            progressBar,
                          ],
                        )
                      : Row(
                          children: <Widget>[
                            Text(
                              '#${entry.key + 1}',
                              style: TextStyle(
                                color: colors.accent,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    item.displayName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: colors.text,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  progressBar,
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 86,
                              child: Text(
                                '${item.count} $countSuffix',
                                textAlign: TextAlign.end,
                                style: TextStyle(
                                  color: colors.muted,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class _TrendingBrandsCard extends StatelessWidget {
  final MarketPulseSection<List<MarketPulseBrandEntry>> section;

  const _TrendingBrandsCard({required this.section});

  @override
  Widget build(BuildContext context) {
    final colors = _MarketPulseColors.of(context);
    return _MarketPulseCard(
      title: 'Trending Brands',
      subtitle: 'Search demand ranked by heat',
      updatedAt: section.updatedAt,
      child: GridView.builder(
        itemCount: section.data.length,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 116,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.80,
        ),
        itemBuilder: (context, index) {
          final item = section.data[index];
          return Column(
            children: <Widget>[
              Expanded(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      color: colors.subtleFill,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color:
                            _brandBadgeColor(item.trend).withValues(alpha: 0.4),
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: <Widget>[
                        if (item.logoPath != null)
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Image.asset(
                              item.logoPath!,
                              fit: BoxFit.contain,
                            ),
                          )
                        else
                          Text(
                            item.brand.isNotEmpty ? item.brand[0] : '?',
                            style: TextStyle(
                              color: colors.text,
                              fontWeight: FontWeight.w800,
                              fontSize: 22,
                            ),
                          ),
                        if (item.trend != 'stable')
                          Positioned(
                            top: 6,
                            right: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: _brandBadgeColor(item.trend),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                item.trend == 'hot' ? 'HOT' : 'RISING',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item.brand,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.text,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${NumberFormat.compact().format(item.searchCount)} searches',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.muted,
                  fontSize: 10,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PriceTrendSection extends StatefulWidget {
  final MarketPulseService service;
  final MarketPulsePeriod period;
  final DateTimeRange? customRange;
  final int reloadToken;
  final int forceRefreshToken;

  const _PriceTrendSection({
    required this.service,
    required this.period,
    required this.customRange,
    required this.reloadToken,
    required this.forceRefreshToken,
  });

  @override
  State<_PriceTrendSection> createState() => _PriceTrendSectionState();
}

class _PriceTrendSectionState extends State<_PriceTrendSection> {
  Future<MarketPulseSection<MarketPulseTrendSeries>>? _future;
  MarketPulseTrendModelOption? _selectedModel;

  List<MarketPulseTrendModelOption> _dropdownOptionsFor(
    MarketPulseTrendSeries series,
  ) {
    final options = <MarketPulseTrendModelOption>[];
    final seenKeys = <String>{};

    void addOption(MarketPulseTrendModelOption option) {
      if (seenKeys.add(option.key)) {
        options.add(option);
      }
    }

    addOption(_selectedModel ?? series.selectedModel);
    for (final option in series.options) {
      addOption(option);
    }

    return options;
  }

  MarketPulseTrendModelOption _selectedOptionFor(
    MarketPulseTrendSeries series,
    List<MarketPulseTrendModelOption> options,
  ) {
    final selectedKey = (_selectedModel ?? series.selectedModel).key;
    return options.firstWhere(
      (option) => option.key == selectedKey,
      orElse: () => options.first,
    );
  }

  @override
  void initState() {
    super.initState();
    _future = widget.service.getPriceTrend(
      widget.period,
      selectedModel: _selectedModel,
      customRange: widget.customRange,
      forceRefresh: false,
    );
  }

  @override
  void didUpdateWidget(covariant _PriceTrendSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reloadToken != widget.reloadToken ||
        oldWidget.forceRefreshToken != widget.forceRefreshToken) {
      final forceRefresh =
          oldWidget.forceRefreshToken != widget.forceRefreshToken;
      _future = widget.service.getPriceTrend(
        widget.period,
        selectedModel: _selectedModel,
        customRange: widget.customRange,
        forceRefresh: forceRefresh,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = _MarketPulseColors.of(context);
    return FutureBuilder<MarketPulseSection<MarketPulseTrendSeries>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _SectionSkeleton(height: 320);
        }
        if (snapshot.hasError) {
          return _ErrorStateCard(
            message: snapshot.error.toString(),
            onRetry: () {
              setState(() {
                _future = widget.service.getPriceTrend(
                  widget.period,
                  selectedModel: _selectedModel,
                  customRange: widget.customRange,
                  forceRefresh: true,
                );
              });
            },
          );
        }

        final section = snapshot.data;
        if (section == null || section.data.points.isEmpty) {
          return const _EmptyStateCard(
            title: 'No price trend yet',
            subtitle:
                'Model pricing history will appear once listing data is available.',
          );
        }

        final series = section.data;
        final dropdownOptions = _dropdownOptionsFor(series);
        final selectedOption = _selectedOptionFor(series, dropdownOptions);
        _selectedModel ??= selectedOption;
        final points = series.points;
        final firstValue = points.first.avgPrice;
        final lastValue = points.last.avgPrice;
        final delta = lastValue - firstValue;
        final minValue = points.map((item) => item.avgPrice).reduce(math.min);
        final maxValue = points.map((item) => item.avgPrice).reduce(math.max);
        final yPadding = math.max((maxValue - minValue) * 0.10, 10000.0);

        return _MarketPulseCard(
          title: 'Price Trend',
          subtitle: 'Average model price over time',
          updatedAt: section.updatedAt,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: colors.subtleFill,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedOption.key,
                    dropdownColor: colors.card,
                    isExpanded: true,
                    iconEnabledColor: colors.muted,
                    style: TextStyle(color: colors.text),
                    items: dropdownOptions
                        .map(
                          (item) => DropdownMenuItem<String>(
                            value: item.key,
                            child: Text(item.label),
                          ),
                        )
                        .toList(),
                    onChanged: (selectedKey) {
                      if (selectedKey == null) {
                        return;
                      }
                      final value = dropdownOptions.firstWhere(
                        (option) => option.key == selectedKey,
                        orElse: () => selectedOption,
                      );
                      setState(() {
                        _selectedModel = value;
                        _future = widget.service.getPriceTrend(
                          widget.period,
                          selectedModel: value,
                          customRange: widget.customRange,
                          forceRefresh: true,
                        );
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: <Widget>[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: delta >= 0
                          ? colors.success.withValues(alpha: 0.14)
                          : colors.danger.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      delta.abs() < 1
                          ? 'Flat'
                          : '${delta >= 0 ? 'Up' : 'Down'} ${_formatLakh(delta.abs())}',
                      style: TextStyle(
                        color: delta >= 0 ? colors.success : colors.danger,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 360;
                  final labelStep = compact && points.length > 4 ? 2 : 1;

                  return SizedBox(
                    height: compact ? 188 : 210,
                    child: LineChart(
                      LineChartData(
                        minY: math.max(0, minValue - yPadding),
                        maxY: maxValue + yPadding,
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: null,
                          getDrawingHorizontalLine: (_) => FlLine(
                            color: colors.border,
                            strokeWidth: 1,
                          ),
                        ),
                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: compact ? 40 : 48,
                              getTitlesWidget: (value, meta) => Text(
                                '${(value / 100000).toStringAsFixed(0)}L',
                                style: TextStyle(
                                  color: colors.muted,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: compact ? 24 : 28,
                              getTitlesWidget: (value, meta) {
                                final index = value.toInt();
                                if (index < 0 || index >= points.length) {
                                  return const SizedBox.shrink();
                                }
                                final showLabel = !compact ||
                                    index == 0 ||
                                    index == points.length - 1 ||
                                    index % labelStep == 0;
                                if (!showLabel) {
                                  return const SizedBox.shrink();
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    _axisLabel(
                                        points[index].date, widget.period),
                                    style: TextStyle(
                                      color: colors.muted,
                                      fontSize: 10,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        lineTouchData: LineTouchData(
                          handleBuiltInTouches: true,
                          touchTooltipData: LineTouchTooltipData(
                            getTooltipItems: (spots) => spots.map((spot) {
                              final index = spot.x.toInt();
                              final point = points[index];
                              return LineTooltipItem(
                                '${DateFormat('MMM d').format(point.date)}\nPKR ${_formatLakh(point.avgPrice)} avg',
                                const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        lineBarsData: <LineChartBarData>[
                          LineChartBarData(
                            spots: points
                                .asMap()
                                .entries
                                .map(
                                  (entry) => FlSpot(
                                    entry.key.toDouble(),
                                    entry.value.avgPrice,
                                  ),
                                )
                                .toList(),
                            isCurved: true,
                            color: colors.accent,
                            barWidth: 3,
                            dotData: FlDotData(show: !compact),
                            belowBarData: BarAreaData(
                              show: true,
                              color: colors.accent.withValues(alpha: 0.18),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ActivityStatsCard extends StatelessWidget {
  final MarketPulseSection<List<MarketPulseActivityMetric>> section;

  const _ActivityStatsCard({required this.section});

  @override
  Widget build(BuildContext context) {
    final colors = _MarketPulseColors.of(context);
    return _MarketPulseCard(
      title: 'User Traffic & Activity',
      subtitle: 'Platform pulse for the selected period',
      updatedAt: section.updatedAt,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 360;
          final crossAxisCount = constraints.maxWidth < 300 ? 1 : 2;
          final tileHeight = compact ? 132.0 : 118.0;

          return GridView.builder(
            itemCount: section.data.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              mainAxisExtent: tileHeight,
            ),
            itemBuilder: (context, index) {
              final metric = section.data[index];
              final positive = metric.delta >= 0;
              final trendText =
                  '${positive ? 'Up' : 'Down'} ${NumberFormat.compact().format(metric.delta.abs())} ${widgetLabel(metric.id)}';

              return Container(
                padding: EdgeInsets.all(compact ? 14 : 16),
                decoration: BoxDecoration(
                  color: colors.tile,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: colors.accentSoft,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: colors.accentBorder,
                            ),
                          ),
                          child: Icon(
                            _metricIcon(metric.id),
                            color: colors.accent,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            metric.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.text,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.bottomLeft,
                            child: Text(
                              NumberFormat.compact().format(metric.total),
                              style: TextStyle(
                                color: colors.text,
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Align(
                            alignment: Alignment.bottomRight,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    (positive ? colors.success : colors.danger)
                                        .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                trendText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color:
                                      positive ? colors.success : colors.danger,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  String widgetLabel(String id) {
    switch (id) {
      case 'views':
      case 'searches':
        return 'today';
      default:
        return 'change';
    }
  }
}

class _RegionHeatMapCard extends StatelessWidget {
  final MarketPulseSection<List<MarketPulseRegionEntry>> section;

  const _RegionHeatMapCard({required this.section});

  @override
  Widget build(BuildContext context) {
    final colors = _MarketPulseColors.of(context);
    final maxActivity = section.data
        .map((item) => item.activityCount)
        .fold<int>(0, (prev, value) => value > prev ? value : prev);

    return _MarketPulseCard(
      title: 'Activity by Region',
      subtitle: 'Premium preview of regional listing and search demand',
      updatedAt: section.updatedAt,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = width < 360 ? 200.0 : 220.0;

          return Container(
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  colors.subtleFill,
                  colors.card,
                ],
              ),
            ),
            child: Stack(
              children: <Widget>[
                Positioned.fill(
                  child: CustomPaint(
                    painter: _PakistanHeatBackgroundPainter(colors.mapBase),
                  ),
                ),
                ...section.data.map((entry) {
                  final ratio = maxActivity <= 0
                      ? 0.0
                      : entry.activityCount / maxActivity;
                  final color = Color.lerp(
                    const Color(0xFF44210A),
                    const Color(0xFFFF6B00),
                    ratio,
                  )!;
                  final bubbleSize = 16 + (ratio * 20);
                  final left = (entry.x * (width - bubbleSize))
                      .clamp(0.0, width - bubbleSize);
                  final top = (entry.y * (height - 42)).clamp(0.0, height - 42);

                  return Positioned(
                    left: left,
                    top: top,
                    child: Tooltip(
                      message:
                          '${entry.city}: ${entry.listingCount} active listings - ${_formatLakh(entry.avgPrice)} avg',
                      child: Column(
                        children: <Widget>[
                          Container(
                            width: bubbleSize,
                            height: bubbleSize,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.82),
                              shape: BoxShape.circle,
                              boxShadow: <BoxShadow>[
                                BoxShadow(
                                  color: color.withValues(alpha: 0.45),
                                  blurRadius: 18,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          SizedBox(
                            width: 56,
                            child: Text(
                              entry.city,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: colors.text,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AdminExtrasCard extends StatelessWidget {
  final MarketPulseSection<MarketPulseAdminExtras> section;

  const _AdminExtrasCard({required this.section});

  @override
  Widget build(BuildContext context) {
    final data = section.data;
    return _MarketPulseCard(
      title: 'Admin Overview',
      subtitle: 'Admin-only platform health signals',
      updatedAt: section.updatedAt,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final crossAxisCount = width >= 920
                  ? 4
                  : width >= 520
                      ? 2
                      : 1;

              return GridView.builder(
                itemCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  mainAxisExtent: 112,
                ),
                itemBuilder: (context, index) {
                  final tiles = <Widget>[
                    _adminStatTile(
                      context,
                      'Total Users',
                      NumberFormat.compact().format(data.totalRegisteredUsers),
                      Icons.people_outline,
                    ),
                    _adminStatTile(
                      context,
                      'New Today',
                      NumberFormat.compact().format(data.newUsersToday),
                      Icons.person_add_alt_1_outlined,
                    ),
                    _adminStatTile(
                      context,
                      'New This Week',
                      NumberFormat.compact().format(data.newUsersThisWeek),
                      Icons.calendar_today_outlined,
                    ),
                    _adminStatTile(
                      context,
                      'Featured Revenue',
                      'PKR ${NumberFormat.compact().format(data.featuredRevenue)}',
                      Icons.payments_outlined,
                    ),
                  ];
                  return tiles[index];
                },
              );
            },
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final stackPanels = constraints.maxWidth < 720;
              final reportPanel = _reportedAdsPanel(
                context,
                data.reportedAdsCount,
              );
              final usersPanel = _reportedUsersPanel(
                context,
                data.mostReportedUsers,
              );

              if (stackPanels) {
                return Column(
                  children: <Widget>[
                    reportPanel,
                    const SizedBox(height: 12),
                    usersPanel,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SizedBox(width: 260, child: reportPanel),
                  const SizedBox(width: 12),
                  Expanded(child: usersPanel),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _adminStatTile(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    final colors = _MarketPulseColors.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.tile,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: colors.accentSoft,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color: colors.accentBorder,
                  ),
                ),
                child: Icon(
                  icon,
                  color: colors.accent,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                color: colors.text,
                fontWeight: FontWeight.w800,
                fontSize: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _reportedAdsPanel(BuildContext context, int reportedAdsCount) {
    final colors = _MarketPulseColors.of(context);
    final hasReports = reportedAdsCount > 0;

    return Container(
      height: 116,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: hasReports ? colors.accent.withValues(alpha: 0.08) : colors.tile,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasReports ? colors.accentBorder : colors.border,
        ),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: colors.accentSoft,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              Icons.report_problem_outlined,
              color: colors.accent,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  'Reported Ads',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  NumberFormat.compact().format(reportedAdsCount),
                  style: TextStyle(
                    color: colors.text,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _reportedUsersPanel(
    BuildContext context,
    List<MarketPulseReportedUser> users,
  ) {
    final colors = _MarketPulseColors.of(context);
    return Container(
      constraints: const BoxConstraints(minHeight: 116),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.tile,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                Icons.flag_outlined,
                color: colors.accent,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Most Reported Users',
                style: TextStyle(
                  color: colors.text,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (users.isEmpty)
            SizedBox(
              height: 46,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'No reported users yet.',
                  style: TextStyle(color: colors.muted, fontSize: 12),
                ),
              ),
            )
          else
            Column(
              children: users.take(4).map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          entry.userLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.text,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colors.accent.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${entry.reportCount} reports',
                          style: TextStyle(
                            color: colors.accent,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

class _MarketPulseCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final DateTime updatedAt;
  final Widget child;
  final Widget? trailing;

  const _MarketPulseCard({
    required this.title,
    required this.subtitle,
    required this.updatedAt,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _MarketPulseColors.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final stackHeader = trailing != null && constraints.maxWidth < 420;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (stackHeader) ...<Widget>[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: TextStyle(
                        color: colors.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: colors.muted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 12),
                    trailing!,
                  ],
                ),
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            title,
                            style: TextStyle(
                              color: colors.text,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: TextStyle(
                              color: colors.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (trailing != null) ...<Widget>[
                      const SizedBox(width: 12),
                      Flexible(child: trailing!),
                    ],
                  ],
                ),
              const SizedBox(height: 10),
              Text(
                'Last updated ${_relativeUpdatedAt(updatedAt)}',
                style: TextStyle(
                  color: colors.faint,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 16),
              child,
            ],
          ),
        );
      },
    );
  }
}

class _SectionSkeleton extends StatelessWidget {
  final double height;

  const _SectionSkeleton({required this.height});

  @override
  Widget build(BuildContext context) {
    final colors = _MarketPulseColors.of(context);
    return Container(
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _SkeletonLine(width: 150),
          SizedBox(height: 10),
          _SkeletonLine(width: 110),
          SizedBox(height: 18),
          Expanded(child: _SkeletonBlock()),
        ],
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  final String title;
  final String subtitle;

  const _EmptyStateCard({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _MarketPulseColors.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: <Widget>[
          const Icon(Icons.bar_chart_rounded,
              color: Color(0xFFFF6B00), size: 36),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: colors.text,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.muted),
          ),
        ],
      ),
    );
  }
}

class _ErrorStateCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorStateCard({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _MarketPulseColors.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.withValues(alpha: 0.18)),
      ),
      child: Column(
        children: <Widget>[
          const Icon(Icons.error_outline, color: Color(0xFFF44336), size: 36),
          const SizedBox(height: 12),
          Text(
            'Could not load this section',
            style: TextStyle(color: colors.text, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.muted, fontSize: 12),
          ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: onRetry,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B00),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  final double width;

  const _SkeletonLine({required this.width});

  @override
  Widget build(BuildContext context) {
    final colors = _MarketPulseColors.of(context);
    return Container(
      width: width,
      height: 10,
      decoration: BoxDecoration(
        color: colors.skeleton,
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _SkeletonBlock extends StatelessWidget {
  const _SkeletonBlock();

  @override
  Widget build(BuildContext context) {
    final colors = _MarketPulseColors.of(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.skeleton.withValues(alpha: colors.isDark ? 0.70 : 0.85),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}

class _PakistanHeatBackgroundPainter extends CustomPainter {
  final Color color;

  const _PakistanHeatBackgroundPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width * 0.34, size.height * 0.10)
      ..lineTo(size.width * 0.56, size.height * 0.06)
      ..lineTo(size.width * 0.68, size.height * 0.18)
      ..lineTo(size.width * 0.72, size.height * 0.34)
      ..lineTo(size.width * 0.66, size.height * 0.52)
      ..lineTo(size.width * 0.60, size.height * 0.68)
      ..lineTo(size.width * 0.48, size.height * 0.88)
      ..lineTo(size.width * 0.34, size.height * 0.92)
      ..lineTo(size.width * 0.22, size.height * 0.74)
      ..lineTo(size.width * 0.18, size.height * 0.48)
      ..lineTo(size.width * 0.24, size.height * 0.24)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

Color _brandBadgeColor(String trend) {
  switch (trend) {
    case 'hot':
      return const Color(0xFFF44336);
    case 'rising':
      return const Color(0xFF4CAF50);
    default:
      return const Color(0xFFFF6B00);
  }
}

IconData _metricIcon(String id) {
  switch (id) {
    case 'views':
      return Icons.visibility_outlined;
    case 'active_ads':
      return Icons.view_list_outlined;
    case 'searches':
      return Icons.search_rounded;
    case 'deals':
      return Icons.handshake_outlined;
    default:
      return Icons.analytics_outlined;
  }
}

String _formatLakh(double amount) {
  if (amount <= 0) {
    return '0L';
  }
  return '${(amount / 100000).toStringAsFixed(1)}L';
}

String _axisLabel(DateTime date, MarketPulsePeriod period) {
  switch (period) {
    case MarketPulsePeriod.today:
      return DateFormat('ha').format(date);
    case MarketPulsePeriod.week:
      return DateFormat('E').format(date);
    case MarketPulsePeriod.month:
      return DateFormat('d MMM').format(date);
    case MarketPulsePeriod.quarter:
      return DateFormat('MMM').format(date);
  }
}

String _relativeUpdatedAt(DateTime updatedAt) {
  final diff = DateTime.now().difference(updatedAt);
  if (diff.inMinutes < 1) {
    return 'just now';
  }
  if (diff.inMinutes < 60) {
    return '${diff.inMinutes} mins ago';
  }
  if (diff.inHours < 24) {
    return '${diff.inHours} hrs ago';
  }
  return '${diff.inDays} days ago';
}
