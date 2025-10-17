import 'package:flutter/material.dart';
import '../components/custom_bottom_nav.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';
import '../auth/loginscreen.dart';
import '../auth/auth_provider.dart';
import 'homepage.dart';
import 'edit_profile_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';



class Profilepage extends StatelessWidget {
  const Profilepage({super.key});

  static const int _selectedIndex = 4;
  static const List<String> _navRoutes = [
    '/', '/myads', '/upload', '/investment', '/profile'
  ];

  void _onTabSelected(BuildContext context, int index) {
    if (_selectedIndex == index) return;
    if (index == 0) {
      Navigator.pushNamedAndRemoveUntil(context, _navRoutes[0], (route) => false);
    } else {
      Navigator.pushReplacementNamed(context, _navRoutes[index]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return WillPopScope(
      onWillPop: () async {
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Profile',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                // Header: user info or login CTA
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: authProvider.isLoggedIn
                      ? _buildGreetingMessage(context, authProvider, colorScheme)
                      : _buildLoginButton(context, colorScheme),
                ),

                // User engagement score and rank (only for logged in users)
                if (authProvider.isLoggedIn) ...[
                  const SizedBox(height: 16),
                  _buildEngagementScore(context, authProvider.user!.uid, colorScheme),
                  const SizedBox(height: 16),
                ],

                // Settings section
                _sectionHeader(context, 'Settings'),
                _settingsCard(context, [
                  // Edit Profile (only for logged in users)
                  if (authProvider.isLoggedIn) ...[
                    _settingsTile(
                      context,
                      Icons.person,
                      'Edit Profile',
                      subtitle: 'Update your personal information',
                      onTap: () => _navigateToEditProfile(context),
                    ),
                    _dividerInset(context),
                  ],
                  // Theme with current mode subtitle
                  Builder(builder: (context) {
                    final themeProvider = Provider.of<ThemeProvider>(context);
                    String subtitle;
                    switch (themeProvider.themeMode) {
                      case ThemeMode.light:
                        subtitle = 'Light';
                        break;
                      case ThemeMode.dark:
                        subtitle = 'Dark';
                        break;
                      default:
                        subtitle = 'System Default';
                    }
                    return _settingsTile(
                      context,
                      Icons.settings,
                      'Theme',
                      subtitle: subtitle,
                      onTap: () => _showThemeBottomSheet(context),
                    );
                  }),
                  _dividerInset(context),
                  _settingsTile(context, Icons.language, 'Choose Language', onTap: () {}),
                  _dividerInset(context),
                ]),

                const SizedBox(height: 16),

                // Products section (Sell/Buy)
                _sectionHeader(context, 'Products'),
                _settingsCard(context, [
                  _settingsTile(context, Icons.directions_car, 'Sell My Car', onTap: () => _navigateToUpload(context)),
                  _dividerInset(context),
                  _settingsTile(context, Icons.directions_car_filled, 'Buy Used Car', onTap: () => _navigateToUsedCars(context)),
                  _dividerInset(context),
                  _settingsTile(context, Icons.car_rental, 'Buy New Car', onTap: () => _navigateToNewCars(context)),
                ]),

                const SizedBox(height: 16),

                // Explore section
                _sectionHeader(context, 'Explore'),
                _settingsCard(context, [
                  _settingsTile(context, Icons.article, 'Blog', onTap: () {}),
                  _dividerInset(context),
                  _settingsTile(context, Icons.ondemand_video, 'Videos', onTap: () {}),
                  _dividerInset(context),
                  _settingsTile(context, Icons.directions_car, 'Cool Rides', onTap: () {}),
                ]),

                const SizedBox(height: 16),

                // More section
                _sectionHeader(context, 'More'),
                _settingsCard(context, [
                  _settingsTile(context, Icons.reviews_outlined, 'Rate & Review', onTap: () {}),
                  _dividerInset(context),
                  _settingsTile(context, Icons.help_outline, 'Help', onTap: () {}),
                ]),

                const SizedBox(height: 20),

                    if (authProvider.isLoggedIn)
                  Center(
                    child: TextButton.icon(
                          onPressed: () => _showLogoutDialog(context, authProvider),
                      icon: const Icon(Icons.logout, size: 18),
                      label: const Text('Log out'),
                      style: TextButton.styleFrom(
                        foregroundColor: colorScheme.error,
                        textStyle: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    
                const SizedBox(height: 12),
                  ],
                ),
          ),
        ),
        bottomNavigationBar: CustomBottomNav(
          selectedIndex: _selectedIndex,
          onTabSelected: (index) => _onTabSelected(context, index),
          onFabPressed: () {
            if (_selectedIndex != 2) {
              Navigator.pushReplacementNamed(context, _navRoutes[2]);
            }
          },
        ),
      ),
    );
  }

  Widget _buildLoginButton(BuildContext context, ColorScheme colorScheme) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const Loginscreen()),
        );
      },
      child: Container(
        height: 45,
        margin: const EdgeInsets.symmetric(horizontal: 17),
        decoration: BoxDecoration(
          color: colorScheme.primary,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text(
            'Log in / Sign up',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGreetingMessage(BuildContext context, AuthProvider authProvider, ColorScheme colorScheme) {
    final displayName = authProvider.getDisplayName();
    
    return Center(
      child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 17),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // User avatar
          CircleAvatar(
            radius: 26,
            backgroundColor: colorScheme.primary.withOpacity(0.12),
            child: Text(
              displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
          ),
            const SizedBox(height: 10),
          
          // Greeting message
          Text(
            'Welcome',
              style: TextStyle(
                color: colorScheme.onSurface.withOpacity(0.6),
              fontSize: 14,
                fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          
          // Display Name
          Text(
            displayName.isNotEmpty ? displayName : 'User',
              style: TextStyle(
                color: colorScheme.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          // Username (if different from display name)
          FutureBuilder<String>(
            future: authProvider.getUsername(),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data!.isNotEmpty && snapshot.data != displayName) {
                return Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    '@${snapshot.data}',
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await authProvider.signOut();
              },
              child: const Text(
                'Logout',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _sectionHeader(BuildContext context, String title) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 0, 6),
        child: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.primary,
            fontSize: 16,
          ),
        ),
      );

  // Modern card container for grouped settings
  Widget _settingsCard(BuildContext context, List<Widget> children) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(children: children),
      ),
    );
  }

  // Single settings tile with trailing chevron
  Widget _settingsTile(BuildContext context, IconData icon, String title, {String? subtitle, VoidCallback? onTap}) {
      return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Theme.of(context).colorScheme.primary),
      ),
      title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
        dense: true,
      visualDensity: const VisualDensity(vertical: -1),
    );
  }

  // Thin divider with left inset to align with text
  Widget _dividerInset(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 68),
      child: Divider(height: 1, color: Theme.of(context).dividerColor.withOpacity(0.3)),
    );
  }

  // Premium banner like the screenshot
  

  void _showThemeBottomSheet(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        final currentMode = themeProvider.themeMode;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              value: ThemeMode.system,
              groupValue: currentMode,
              title: const Text('System Default'),
              onChanged: (mode) {
                themeProvider.setThemeMode(mode!);
                Navigator.pop(ctx);
              },
            ),
            RadioListTile<ThemeMode>(
              value: ThemeMode.light,
              groupValue: currentMode,
              title: const Text('Light'),
              onChanged: (mode) {
                themeProvider.setThemeMode(mode!);
                Navigator.pop(ctx);
              },
            ),
            RadioListTile<ThemeMode>(
              value: ThemeMode.dark,
              groupValue: currentMode,
              title: const Text('Dark'),
              onChanged: (mode) {
                themeProvider.setThemeMode(mode!);
                Navigator.pop(ctx);
              },
            ),
          ],
        );
      },
    );
  }

  void _navigateToUpload(BuildContext context) {
    Navigator.pushNamed(context, '/upload');
  }

  void _navigateToUsedCars(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const Homepage(initialTab: 0),
      ),
      (route) => false,
    );
  }

  void _navigateToNewCars(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const Homepage(initialTab: 1),
      ),
      (route) => false,
    );
  }

  void _navigateToEditProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EditProfilePage(),
      ),
    );
  }

  Widget _buildEngagementScore(BuildContext context, String userId, ColorScheme colorScheme) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _calculateEngagementScore(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildEngagementCard(context, colorScheme, 0, 'Bronze', 0, 0, 0, true);
        }
        
        final data = snapshot.data ?? {};
        final score = data['score'] ?? 0;
        final rank = data['rank'] ?? 'Bronze';
        final adsSold = data['adsSold'] ?? 0;
        final positiveRatings = data['positiveRatings'] ?? 0;
        final totalRatings = data['totalRatings'] ?? 0;
        
        return _buildEngagementCard(context, colorScheme, score, rank, adsSold, positiveRatings, totalRatings, false);
      },
    );
  }

  Widget _buildEngagementCard(BuildContext context, ColorScheme colorScheme, int score, String rank, 
      int adsSold, int positiveRatings, int totalRatings, bool isLoading) {
    return Card(
      elevation: 2,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.primary.withOpacity(0.2)),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.emoji_events,
                    color: colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Engagement Score',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Your activity and reputation',
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
            const SizedBox(height: 16),
            
            // Score and Rank Row
            Row(
              children: [
                Expanded(
                  child: _buildScoreItem(
                    context,
                    'Score',
                    isLoading ? '...' : score.toString(),
                    Icons.star,
                    colorScheme,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildScoreItem(
                    context,
                    'Rank',
                    isLoading ? '...' : rank,
                    Icons.military_tech,
                    colorScheme,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Breakdown
            Text(
              'Score Breakdown',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            
            Row(
              children: [
                Expanded(
                  child: _buildBreakdownItem(
                    context,
                    'Ads Sold',
                    isLoading ? '...' : adsSold.toString(),
                    Icons.check_circle,
                    colorScheme,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildBreakdownItem(
                    context,
                    'Positive Ratings',
                    isLoading ? '...' : '$positiveRatings/$totalRatings',
                    Icons.thumb_up,
                    colorScheme,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Progress bar for next rank
            if (!isLoading) _buildRankProgress(context, score, rank, colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreItem(BuildContext context, String label, String value, IconData icon, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.primary.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Icon(icon, color: colorScheme.primary, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownItem(BuildContext context, String label, String value, IconData icon, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(icon, color: colorScheme.onSurfaceVariant, size: 16),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankProgress(BuildContext context, int score, String currentRank, ColorScheme colorScheme) {
    final rankThresholds = {
      'Bronze': 0,
      'Silver': 50,
      'Gold': 150,
      'Platinum': 300,
      'Diamond': 500,
    };
    
    final ranks = ['Bronze', 'Silver', 'Gold', 'Platinum', 'Diamond'];
    final currentIndex = ranks.indexOf(currentRank);
    final nextRank = currentIndex < ranks.length - 1 ? ranks[currentIndex + 1] : null;
    
    if (nextRank == null) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.amber.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Icon(Icons.emoji_events, color: Colors.amber, size: 16),
            const SizedBox(width: 6),
            Text(
              'Max Rank Achieved!',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.amber[800],
              ),
            ),
          ],
        ),
      );
    }
    
    final currentThreshold = rankThresholds[currentRank] ?? 0;
    final nextThreshold = rankThresholds[nextRank] ?? 0;
    final progress = (score - currentThreshold) / (nextThreshold - currentThreshold);
    final remaining = nextThreshold - score;
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Next: $nextRank',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              Text(
                '$remaining points',
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: colorScheme.surfaceVariant,
            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>> _calculateEngagementScore(String userId) async {
    try {
      // Get user's ads
      final adsSnapshot = await FirebaseFirestore.instance
          .collection('ads')
          .where('userId', isEqualTo: userId)
          .get();
      
      int adsSold = 0;
      int totalRatings = 0;
      int positiveRatings = 0;
      
      // Count sold ads and get ratings
      for (final adDoc in adsSnapshot.docs) {
        final adData = adDoc.data();
        if (adData['status'] == 'sold' || adData['isSold'] == true) {
          adsSold++;
        }
        
        // Get ratings for this ad
        final reviewsSnapshot = await FirebaseFirestore.instance
            .collection('reviews')
            .where('adId', isEqualTo: adDoc.id)
            .get();
        
        for (final reviewDoc in reviewsSnapshot.docs) {
          final rating = reviewDoc.data()['rating'];
          if (rating is num) {
            totalRatings++;
            if (rating >= 4) { // Consider 4+ as positive
              positiveRatings++;
            }
          }
        }
      }
      
      // Calculate score: 10 points per sold ad + 5 points per positive rating
      final score = (adsSold * 10) + (positiveRatings * 5);
      
      // Determine rank based on score
      String rank = 'Bronze';
      if (score >= 500) rank = 'Diamond';
      else if (score >= 300) rank = 'Platinum';
      else if (score >= 150) rank = 'Gold';
      else if (score >= 50) rank = 'Silver';
      
      return {
        'score': score,
        'rank': rank,
        'adsSold': adsSold,
        'positiveRatings': positiveRatings,
        'totalRatings': totalRatings,
      };
    } catch (e) {
      return {
        'score': 0,
        'rank': 'Bronze',
        'adsSold': 0,
        'positiveRatings': 0,
        'totalRatings': 0,
      };
    }
  }
}