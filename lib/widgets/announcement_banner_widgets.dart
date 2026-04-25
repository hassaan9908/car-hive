import 'package:flutter/material.dart';

import '../models/announcement_banner_model.dart';

class AnnouncementBannerSection extends StatefulWidget {
  final List<AnnouncementBannerModel> banners;
  final double height;

  const AnnouncementBannerSection({
    super.key,
    required this.banners,
    this.height = 182,
  });

  @override
  State<AnnouncementBannerSection> createState() =>
      _AnnouncementBannerSectionState();
}

class _AnnouncementBannerSectionState extends State<AnnouncementBannerSection> {
  late PageController _pageController;
  int _currentIndex = 0;
  double _viewportFraction = 1;

  static const double _bannerGap = 12;
  static const double _horizontalPeekInset = 20;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: _viewportFraction);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final screenWidth = MediaQuery.sizeOf(context).width;
    final nextViewportFraction =
        ((screenWidth - _horizontalPeekInset) / screenWidth)
            .clamp(0.88, 1.0)
            .toDouble();

    if ((_viewportFraction - nextViewportFraction).abs() < 0.0001) {
      return;
    }

    final previousIndex = _pageController.hasClients
        ? (_pageController.page?.round() ?? _currentIndex)
        : _currentIndex;

    _pageController.dispose();
    _viewportFraction = nextViewportFraction;
    _pageController = PageController(
      initialPage: previousIndex,
      viewportFraction: _viewportFraction,
    );
  }

  @override
  void didUpdateWidget(covariant AnnouncementBannerSection oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.banners.isEmpty) {
      _currentIndex = 0;
      return;
    }

    if (_currentIndex >= widget.banners.length) {
      _currentIndex = widget.banners.length - 1;
      if (_pageController.hasClients) {
        _pageController.jumpToPage(_currentIndex);
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.banners.isEmpty) {
      return const SizedBox.shrink();
    }

    final hasMultiple = widget.banners.length > 1;

    return Column(
      children: [
        SizedBox(
          height: widget.height,
          child: hasMultiple
              ? PageView.builder(
                  controller: _pageController,
                  clipBehavior: Clip.none,
                  itemCount: widget.banners.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    final screenWidth = MediaQuery.sizeOf(context).width;

                    return Align(
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                        width: screenWidth - _horizontalPeekInset,
                        child: Row(
                          children: [
                            Expanded(
                              child: AnnouncementBannerCard(
                                banner: widget.banners[index],
                              ),
                            ),
                            const SizedBox(width: _bannerGap),
                          ],
                        ),
                      ),
                    );
                  },
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: AnnouncementBannerCard(
                    banner: widget.banners.first,
                  ),
                ),
        ),
        if (hasMultiple) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.banners.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 8,
                width: _currentIndex == index ? 22 : 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: _currentIndex == index
                      ? const Color(0xFFF48C25)
                      : Theme.of(
                          context,
                        ).colorScheme.outline.withValues(alpha: 0.35),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class AnnouncementBannerCard extends StatelessWidget {
  final AnnouncementBannerModel banner;
  final Widget? imageOverride;
  final VoidCallback? onTap;
  final bool showShadow;

  const AnnouncementBannerCard({
    super.key,
    required this.banner,
    this.imageOverride,
    this.onTap,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bannerEyebrow = banner.eyebrow.trim().isEmpty
        ? 'CarHive Update'
        : banner.eyebrow.trim();
    final ctaLabel = banner.ctaLabel?.trim();
    final borderRadius = BorderRadius.circular(16);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 430;
        final isShort = constraints.maxHeight <= 182;
        final useTightLayout = isNarrow || isShort;
        final headlineSize = isNarrow
            ? 20.0
            : isShort
                ? 22.0
                : 26.0;
        final subtitleSize = isNarrow
            ? 11.5
            : isShort
                ? 12.0
                : 13.5;
        final horizontalPadding = useTightLayout ? 14.0 : 18.0;
        final verticalPadding = isShort ? 14.0 : 18.0;
        final gapAfterEyebrow = useTightLayout ? 8.0 : 12.0;
        final gapAfterHeadline = useTightLayout ? 6.0 : 8.0;
        final showCta = ctaLabel != null &&
            ctaLabel.isNotEmpty &&
            constraints.maxHeight > 186;

        return Material(
          color: Colors.transparent,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              boxShadow: showShadow
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.22),
                        blurRadius: 22,
                        offset: const Offset(0, 14),
                      ),
                    ]
                  : null,
            ),
            child: ClipRRect(
              borderRadius: borderRadius,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: borderRadius,
                  onTap: onTap,
                  child: Ink(
                    decoration: BoxDecoration(
                      borderRadius: borderRadius,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark
                            ? const [
                                Color(0xFFF6A445),
                                Color(0xFFE57B1B),
                                Color(0xFF1D2432),
                              ]
                            : const [
                                Color(0xFFFFC671),
                                Color(0xFFF48C25),
                                Color(0xFF263447),
                              ],
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          top: -48,
                          right: -24,
                          child: Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.10),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: -56,
                          left: -10,
                          child: Container(
                            width: 160,
                            height: 160,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black.withValues(alpha: 0.12),
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            horizontalPadding,
                            verticalPadding,
                            horizontalPadding,
                            verticalPadding,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: useTightLayout ? 4 : 3,
                                child: _BannerArt(
                                  imageUrl: banner.imageUrl,
                                  imageOverride: imageOverride,
                                ),
                              ),
                              SizedBox(width: useTightLayout ? 12 : 18),
                              Expanded(
                                flex: useTightLayout ? 6 : 7,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white
                                            .withValues(alpha: 0.18),
                                        borderRadius:
                                            BorderRadius.circular(999),
                                        border: Border.all(
                                          color: Colors.white
                                              .withValues(alpha: 0.14),
                                        ),
                                      ),
                                      child: Text(
                                        bannerEyebrow.toUpperCase(),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: gapAfterEyebrow),
                                    Flexible(
                                      child: Text(
                                        banner.headline,
                                        maxLines: useTightLayout ? 2 : 3,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: headlineSize,
                                          height: 1.04,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: gapAfterHeadline),
                                    Flexible(
                                      child: Text(
                                        banner.subtitle,
                                        maxLines: useTightLayout ? 2 : 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.white
                                              .withValues(alpha: 0.88),
                                          fontSize: subtitleSize,
                                          height: 1.35,
                                        ),
                                      ),
                                    ),
                                    if (showCta) ...[
                                      const SizedBox(height: 10),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 7,
                                        ),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(999),
                                          color: Colors.black
                                              .withValues(alpha: 0.18),
                                          border: Border.all(
                                            color: Colors.white
                                                .withValues(alpha: 0.12),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              ctaLabel,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            const Icon(
                                              Icons.arrow_forward_rounded,
                                              size: 16,
                                              color: Colors.white,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BannerArt extends StatelessWidget {
  final String? imageUrl;
  final Widget? imageOverride;

  const _BannerArt({
    required this.imageUrl,
    this.imageOverride,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.40),
                  Colors.white.withValues(alpha: 0.12),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Transform.translate(
              offset: const Offset(-4, 0),
              child: imageOverride ??
                  _NetworkOrAssetImage(
                    imageUrl: imageUrl,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NetworkOrAssetImage extends StatelessWidget {
  final String? imageUrl;

  const _NetworkOrAssetImage({
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final normalizedUrl = imageUrl?.trim() ?? '';

    if (normalizedUrl.isNotEmpty) {
      return Image.network(
        normalizedUrl,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Image.asset(
            'assets/images/orange_car.png',
            fit: BoxFit.contain,
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            return child;
          }
          return const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          );
        },
      );
    }

    return Image.asset(
      'assets/images/orange_car.png',
      fit: BoxFit.contain,
    );
  }
}
