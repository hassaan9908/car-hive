import 'package:carhive/models/ad_model.dart';
import 'package:carhive/pages/insightmetricsscreen.dart';
import 'package:carhive/pages/promote_ad_page.dart';
import 'package:carhive/store/global_ads.dart';
import 'package:flutter/material.dart';
import '../components/custom_bottom_nav.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:carhive/ads/postadcar.dart';
import 'package:cached_network_image/cached_network_image.dart';

class Myads extends StatefulWidget {
  const Myads({super.key});

  static const List<String> _navRoutes = [
    '/',
    '/myads',
    '/upload',
    '/investment',
    '/profile'
  ];

  @override
  State<Myads> createState() => _MyadsState();
}

class _MyadsState extends State<Myads> {
  int _selectedTabIndex = 0; // 0 = Active, 1 = Sold, 2 = Removed
  final int _selectedIndex = 1;

  final List<String> _tabs = ['Ads', 'Sold', 'Removed'];

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return WillPopScope(
        onWillPop: () async {
          Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
          return false;
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text(
              'My Ads',
            ),
            backgroundColor: Colors.transparent,
            centerTitle: true,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[800]
                    : Colors.grey[400],
                height: 1,
              ),
            ),
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.login, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('Please login to view your ads',
                    style: TextStyle(fontSize: 18)),
                const SizedBox(height: 32),
                Container(
                  width: 130,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF6B35), Color(0xFFFF8C42)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF6B35).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pushNamed(context, 'loginscreen');
                    },
                    child: const Text('Login'),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: CustomBottomNav(
            selectedIndex: _selectedIndex,
            onTabSelected: (index) => _onTabSelected(context, index),
            onFabPressed: () {
              if (_selectedIndex != 2) {
                Navigator.pushReplacementNamed(context, Myads._navRoutes[2]);
              }
            },
          ),
        ),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'My Ads',
          ),
          backgroundColor: Colors.transparent,
          centerTitle: true,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[800]
                  : Colors.grey[400],
              height: 1,
            ),
          ),
        ),
        body: Column(
          children: [
            _buildTopTabs(),
            Expanded(child: _buildTabContent(currentUser.uid)),
          ],
        ),
        bottomNavigationBar: CustomBottomNav(
          selectedIndex: _selectedIndex,
          onTabSelected: (index) => _onTabSelected(context, index),
          onFabPressed: () {
            if (_selectedIndex != 2) {
              Navigator.pushReplacementNamed(context, Myads._navRoutes[2]);
            }
          },
        ),
      ),
    );
  }

  void _onTabSelected(BuildContext context, int index) {
    if (_selectedIndex == index) return;
    if (index == 0) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        Myads._navRoutes[0],
        (route) => false,
      );
    } else {
      Navigator.pushReplacementNamed(context, Myads._navRoutes[index]);
    }
  }

  void _onTopTabChanged(int index) {
    setState(() {
      _selectedTabIndex = index;
    });
  }

  Widget _buildTopTabs() {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.brightness == Brightness.dark
                ? Colors.grey[800]!
                : Colors.grey[400]!,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(_tabs.length, (index) {
          final isSelected = _selectedTabIndex == index;
          return GestureDetector(
            onTap: () => _onTopTabChanged(index),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12.0,
                    horizontal: 10,
                  ),
                  child: Text(
                    _tabs[index],
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 2,
                  width: 60,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTabContent(String userId) {
    switch (_selectedTabIndex) {
      case 0:
        // Active tab shows both active and pending ads
        return _buildActiveTabContent(userId);
      case 1:
        // Sold tab shows sold ads
        return _buildSoldTabContent(userId);
      case 2:
        // Removed tab shows removed ads
        return _buildRemovedTabContent(userId);
      default:
        return _buildActiveTabContent(userId);
    }
  }

  Widget _buildActiveTabContent(String userId) {
    return StreamBuilder<List<AdModel>>(
      stream: GlobalAdStore().getUserAdsByStatus(userId, 'active'),
      builder: (context, activeSnapshot) {
        return StreamBuilder<List<AdModel>>(
          stream: GlobalAdStore().getUserAdsByStatus(userId, 'pending'),
          builder: (context, pendingSnapshot) {
            if (activeSnapshot.connectionState == ConnectionState.waiting ||
                pendingSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (activeSnapshot.hasError || pendingSnapshot.hasError) {
              return _buildErrorWidget(
                  activeSnapshot.error ?? pendingSnapshot.error);
            }

            final activeAds = activeSnapshot.data ?? [];
            final pendingAds = pendingSnapshot.data ?? [];
            final allAds = [...activeAds, ...pendingAds];

            if (allAds.isEmpty) {
              return _buildAdPlaceholder(
                'No Active Ads',
                'You don\'t have any active or pending ads.',
              );
            }

            return ListView.builder(
              itemCount: allAds.length,
              itemBuilder: (context, index) {
                final ad = allAds[index];
                return _buildAdCard(ad);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildSoldTabContent(String userId) {
    return StreamBuilder<List<AdModel>>(
      stream: GlobalAdStore().getUserAdsByStatus(userId, 'sold'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildErrorWidget(snapshot.error);
        }

        final ads = snapshot.data ?? [];

        if (ads.isEmpty) {
          return _buildAdPlaceholder(
            'No Sold Ads',
            'You haven\'t sold any cars yet.',
          );
        }

        return ListView.builder(
          itemCount: ads.length,
          itemBuilder: (context, index) {
            final ad = ads[index];
            return _buildAdCard(ad);
          },
        );
      },
    );
  }

  Widget _buildRemovedTabContent(String userId) {
    return StreamBuilder<List<AdModel>>(
      stream: GlobalAdStore().getUserAdsByStatus(userId, 'removed'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildErrorWidget(snapshot.error);
        }

        final ads = snapshot.data ?? [];

        if (ads.isEmpty) {
          return _buildAdPlaceholder(
            'No Removed Ads',
            'You don\'t have any removed ads.',
          );
        }

        return ListView.builder(
          itemCount: ads.length,
          itemBuilder: (context, index) {
            final ad = ads[index];
            return _buildAdCard(ad);
          },
        );
      },
    );
  }

  Widget _buildErrorWidget(dynamic error) {
    String errorMessage = 'Error loading ads';
    String errorDetails = '';

    if (error.toString().contains('failed-precondition')) {
      errorMessage = 'Database configuration required';
      errorDetails = 'Please contact support to set up the database properly.';
    } else if (error.toString().contains('permission-denied')) {
      errorMessage = 'Access denied';
      errorDetails = 'You may not have permission to view ads.';
    } else {
      errorDetails = error.toString();
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          Text(errorMessage,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (errorDetails.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                errorDetails,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAdCard(AdModel ad) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    Color statusColor;
    String statusLabel;
    switch (ad.status) {
      case 'active':
        statusColor = const Color(0xFF2ECC71);
        statusLabel = 'Active';
        break;
      case 'pending':
        statusColor = const Color(0xFFF5B041);
        statusLabel = 'Pending';
        break;
      case 'sold':
        statusColor = const Color(0xFF5DADE2);
        statusLabel = 'Sold';
        break;
      case 'removed':
        statusColor = colorScheme.error;
        statusLabel = 'Expired';
        break;
      default:
        statusColor = colorScheme.onSurfaceVariant;
        statusLabel = ad.status;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant, width: 1),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      (ad.imageUrls != null && ad.imageUrls!.isNotEmpty)
                          ? Image.network(
                              ad.imageUrls!.first,
                              width: 92,
                              height: 92,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 92,
                                  height: 92,
                                  color: colorScheme.surfaceContainerHighest,
                                  alignment: Alignment.center,
                                  child: Icon(
                                    Icons.directions_car_filled,
                                    color: colorScheme.onSurfaceVariant,
                                    size: 30,
                                  ),
                                );
                              },
                            )
                          : Container(
                              width: 92,
                              height: 92,
                              color: colorScheme.surfaceContainerHighest,
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.directions_car_filled,
                                color: colorScheme.onSurfaceVariant,
                                size: 30,
                              ),
                            ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(
                          height: 30,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Color(0x99000000),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              ad.title.isNotEmpty
                                  ? ad.title
                                  : (ad.carBrand ?? 'Car'),
                              style: TextStyle(
                                color: colorScheme.onSurface,
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (ad.status != 'sold') ...[
                            const SizedBox(width: 8),
                            _hoverActionIcon(
                              icon: Icons.edit_outlined,
                              color: colorScheme.onSurfaceVariant,
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const PostAdCar(),
                                    settings: RouteSettings(
                                      arguments: {
                                        'isEditing': true,
                                        'adId': ad.id,
                                        'adData': {
                                          'title': ad.title,
                                          'carBrand': ad.carBrand,
                                          'carName': ad.carName,
                                          'year': ad.year,
                                          'price': ad.price,
                                          'mileage': ad.mileage,
                                          'fuel': ad.fuel,
                                          'description': ad.description,
                                          'location': ad.location,
                                          'locationCoordinates':
                                              ad.locationCoordinates,
                                          'imageUrls': ad.imageUrls,
                                          'images360Urls': ad.images360Urls,
                                          'registeredIn': ad.registeredIn,
                                          'bodyColor': ad.bodyColor,
                                          'kmsDriven': ad.kmsDriven,
                                          'name': ad.name,
                                          'phone': ad.phone,
                                        },
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 6),
                          ],
                          _hoverActionIcon(
                            icon: ad.status == 'removed'
                                ? Icons.delete_forever_outlined
                                : Icons.delete_outline,
                            color: colorScheme.error,
                            onPressed: () async {
                              if (ad.status == 'sold' ||
                                  ad.status == 'removed') {
                                try {
                                  await GlobalAdStore().deleteAd(ad.id!);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content:
                                            Text('Ad deleted permanently')),
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content:
                                            Text('Failed to delete ad: $e')),
                                  );
                                }
                              } else if (ad.status == 'active') {
                                _showDeleteActiveAdDialog(ad);
                              } else if (ad.status == 'pending') {
                                try {
                                  await GlobalAdStore()
                                      .updateAdStatus(ad.id!, 'removed');
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Ad moved to removed')),
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content:
                                            Text('Failed to remove ad: $e')),
                                  );
                                }
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${ad.year.isNotEmpty ? ad.year : 'Model'}  •  ${ad.mileage} km',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'PKR ${ad.price}',
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: statusColor.withValues(alpha: 0.7),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: statusColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              statusLabel,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(
              color: colorScheme.outlineVariant,
              height: 1,
              thickness: 1,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 38,
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => InsightMetricsScreen(ad: ad),
                          ),
                        );
                      },
                      icon: const Icon(Icons.analytics_outlined, size: 15),
                      label: const Text('Insights'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF9B59B6),
                        side: const BorderSide(
                          color: Color(0xFF9B59B6),
                          width: 1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                      ),
                    ),
                  ),
                  if (ad.status != 'sold') ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          if (ad.status == 'removed') {
                            try {
                              final previousStatus =
                                  ad.previousStatus ?? 'active';
                              await GlobalAdStore().reactivateAd(ad.id!,
                                  previousStatus: previousStatus);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Ad relisted')),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text('Failed to relist ad: $e')),
                              );
                            }
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PromoteAdPage(ad: ad),
                              ),
                            );
                          }
                        },
                        icon: Icon(
                          ad.status == 'removed'
                              ? Icons.refresh_rounded
                              : Icons.rocket_launch_outlined,
                          size: 15,
                        ),
                        label:
                            Text(ad.status == 'removed' ? 'Relist' : 'Promote'),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: colorScheme.onPrimary,
                          backgroundColor: colorScheme.primary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hoverActionIcon({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      splashRadius: 18,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          final isHovered = states.contains(WidgetState.hovered);
          return color.withValues(alpha: isHovered ? 1 : 0.7);
        }),
        overlayColor: WidgetStateProperty.all(Colors.transparent),
      ),
    );
  }

  Widget _buildAdPlaceholder(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.car_rental, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(title,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(subtitle, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  void _showDeleteActiveAdDialog(AdModel ad) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Remove Ad'),
          content: const Text('What would you like to do with this ad?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  // Use markSold method which handles sales count and trust rank updates
                  await GlobalAdStore().markSold(ad.id!);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ad marked as sold')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to mark as sold: $e')),
                  );
                }
              },
              child: const Text(
                'Mark as Sold',
                style: TextStyle(color: Colors.blue),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  // Use markRemoved method which handles previousStatus properly
                  await GlobalAdStore()
                      .markRemoved(ad.id!, previousStatus: ad.status);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ad moved to removed')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to remove ad: $e')),
                  );
                }
              },
              child: const Text(
                'Remove',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoColumn(
      BuildContext context, IconData icon, String label, String value) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Icon(icon, size: 16, color: cs.primary),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: cs.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            color: cs.onSurface,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
