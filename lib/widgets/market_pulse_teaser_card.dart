import 'package:flutter/material.dart';

import '../services/market_pulse_service.dart';

class MarketPulseTeaserCard extends StatelessWidget {
  const MarketPulseTeaserCard({super.key});

  @override
  Widget build(BuildContext context) {
    final service = MarketPulseService();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF101010) : Colors.white;
    final titleColor = isDark ? Colors.white : Colors.black;
    final bodyColor = isDark
        ? Colors.white.withValues(alpha: 0.72)
        : Colors.black.withValues(alpha: 0.62);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.08);

    return FutureBuilder(
      future: service.getHomeTeaser(),
      builder: (context, snapshot) {
        final teaser = snapshot.data?.data;

        return Padding(
          padding: const EdgeInsets.only(top: 18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: InkWell(
              onTap: () => Navigator.pushNamed(context, '/marketpulse'),
              borderRadius: BorderRadius.circular(16),
              child: Ink(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.24 : 0.06,
                      ),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: snapshot.connectionState != ConnectionState.done
                    ? const SizedBox(
                        height: 82,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            _TeaserLine(width: 110),
                            SizedBox(height: 14),
                            _TeaserLine(width: double.infinity),
                            SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: _TeaserLine(width: 120),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Icon(
                                Icons.bar_chart_rounded,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'MarketPulse',
                                style: TextStyle(
                                  color: titleColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '${teaser?.title ?? 'Toyota Corolla avg price'} ${teaser?.subtitle ?? 'up 4% this week'}',
                            style: TextStyle(
                              color: bodyColor,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              'Explore Trends ->',
                              style: TextStyle(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TeaserLine extends StatelessWidget {
  final double width;

  const _TeaserLine({required this.width});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: width,
      height: 10,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}
