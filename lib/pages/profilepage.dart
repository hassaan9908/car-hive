import 'package:flutter/material.dart';
import '../components/custom_bottom_nav.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';
import '../auth/loginscreen.dart';
import '../auth/auth_provider.dart';
import 'homepage.dart';
import 'edit_profile_page.dart';
import 'blog_list_page.dart'; // Add this import
import 'video_list_page.dart'; // Add this import
import 'saved_ads_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/cloudinary_service.dart';

class Profilepage extends StatelessWidget {
  const Profilepage({super.key});

  static const int _selectedIndex = 4;
  static const List<String> _navRoutes = [
    '/',
    '/myads',
    '/upload',
    '/investment',
    '/profile'
  ];

  void _onTabSelected(BuildContext context, int index) {
    if (_selectedIndex == index) return;
    if (index == 0) {
      Navigator.pushNamedAndRemoveUntil(
          context, _navRoutes[0], (route) => false);
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
          ),
          backgroundColor: Colors.transparent,
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
                      ? _buildGreetingMessage(
                          context, authProvider, colorScheme)
                      : _buildLoginButton(context, colorScheme),
                ),

                // User engagement score and rank (only for logged in users)
                if (authProvider.isLoggedIn) ...[
                  const SizedBox(height: 16),
                  _buildEngagementScore(
                      context, authProvider.user!.uid, colorScheme),
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
                  _settingsTile(context, Icons.language, 'Choose Language',
                      onTap: () {}),
                  _dividerInset(context),
                ]),

                const SizedBox(height: 16),

                // Products section (Sell/Buy)
                _sectionHeader(context, 'Products'),
                _settingsCard(context, [
                  _settingsTile(context, Icons.directions_car, 'Sell My Car',
                      onTap: () => _navigateToUpload(context)),
                  _dividerInset(context),
                  _settingsTile(
                      context, Icons.directions_car_filled, 'Buy Used Car',
                      onTap: () => _navigateToUsedCars(context)),
                  _dividerInset(context),
                  _settingsTile(context, Icons.car_rental, 'Buy New Car',
                      onTap: () => _navigateToNewCars(context)),
                ]),

                const SizedBox(height: 16),

                // Explore section
                _sectionHeader(context, 'Explore'),
                _settingsCard(context, [
                  if (authProvider.isLoggedIn) ...[
                    _settingsTile(context, Icons.article, 'Blog',
                        onTap: () => _navigateToBlog(context)),
                    _dividerInset(context),
                    _settingsTile(context, Icons.ondemand_video, 'Videos',
                        onTap: () => _navigateToVideos(context)),
                    _dividerInset(context),
                  ],
                  _settingsTile(context, Icons.directions_car, 'Cool Rides',
                      onTap: () {}),
                ]),

                const SizedBox(height: 16),

                // More section
                _sectionHeader(context, 'More'),
                _settingsCard(context, [
                  if (authProvider.isLoggedIn) ...[
                    _settingsTile(context, Icons.bookmark, 'Saved Ads',
                        onTap: () => _navigateToSavedAds(context)),
                    _dividerInset(context),
                  ],
                  _settingsTile(
                      context, Icons.reviews_outlined, 'Rate & Review',
                      onTap: () {}),
                  _dividerInset(context),
                  _settingsTile(context, Icons.help_outline, 'Help',
                      onTap: () => Navigator.pushNamed(context, '/help')),
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
          gradient: const LinearGradient(
            colors: [Color(0xFFFF6B35), Color(0xFFFF8C42)],
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF6B35).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
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

  Widget _buildGreetingMessage(BuildContext context, AuthProvider authProvider,
      ColorScheme colorScheme) {
    final userId = authProvider.user?.uid;

    if (userId == null) return const SizedBox.shrink();

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 17),
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .snapshots(),
          builder: (context, snapshot) {
            String? photoUrl;
            String username = '';

            if (snapshot.hasData && snapshot.data!.exists) {
              final data = snapshot.data!.data() as Map<String, dynamic>?;
              photoUrl = data?['photoUrl'] as String?;
              username = data?['username']?.toString() ?? '';
            }

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Larger User avatar with profile picture
                GestureDetector(
                  onTap: () => _showImagePickerOptions(context, userId),
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: colorScheme.primary.withOpacity(0.12),
                        backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                            ? NetworkImage(photoUrl)
                            : null,
                        child: photoUrl == null || photoUrl.isEmpty
                            ? Text(
                                username.isNotEmpty
                                    ? username[0].toUpperCase()
                                    : 'U',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                ),
                              )
                            : null,
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: colorScheme.surface,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Username (if available)
                if (username.isNotEmpty)
                  Text(
                    '@$username',
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showImagePickerOptions(BuildContext context, String? userId) {
    if (userId == null) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Take Photo'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickAndUploadImage(context, userId, ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Choose from Gallery'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickAndUploadImage(context, userId, ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Remove Photo',
                      style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    _removeProfilePhoto(context, userId);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickAndUploadImage(
      BuildContext context, String userId, ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image == null) return;

      // Show loading indicator
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      // Upload to Cloudinary
      final cloudinaryService = CloudinaryService();
      String downloadUrl;

      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        downloadUrl =
            await cloudinaryService.uploadImageBytes(imageBytes: bytes);
      } else {
        downloadUrl =
            await cloudinaryService.uploadImage(imageFile: File(image.path));
      }

      // Update Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({'photoUrl': downloadUrl});

      // Close loading dialog
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture updated successfully')),
        );
      }
    } catch (e) {
      // Close loading dialog if open
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile picture: $e')),
        );
      }
    }
  }

  Future<void> _removeProfilePhoto(BuildContext context, String userId) async {
    try {
      // Show loading indicator
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      // Update Firestore to remove photoUrl
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({'photoUrl': FieldValue.delete()});

      // Close loading dialog
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture removed')),
        );
      }
    } catch (e) {
      // Close loading dialog if open
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove profile picture: $e')),
        );
      }
    }
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color cardSettings =
        isDark ? const Color.fromARGB(255, 15, 15, 15) : Colors.grey.shade200;

    return Card(
      elevation: 0,
      color: cardSettings,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side:
            BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(children: children),
      ),
    );
  }

  // Single settings tile with trailing chevron
  Widget _settingsTile(BuildContext context, IconData icon, String title,
      {String? subtitle, VoidCallback? onTap}) {
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
      title: Text(title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
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
      child: Divider(
          height: 1, color: Theme.of(context).dividerColor.withOpacity(0.3)),
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

  Widget _buildEngagementScore(
      BuildContext context, String userId, ColorScheme colorScheme) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _calculateEngagementScore(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildEngagementCard(
              context, colorScheme, 0, 'Bronze', 0, 0, 0, true);
        }

        final data = snapshot.data ?? {};
        final score = data['score'] ?? 0;
        final rank = data['rank'] ?? 'Bronze';
        final adsSold = data['adsSold'] ?? 0;
        final positiveRatings = data['positiveRatings'] ?? 0;
        final totalRatings = data['totalRatings'] ?? 0;

        return _buildEngagementCard(context, colorScheme, score, rank, adsSold,
            positiveRatings, totalRatings, false);
      },
    );
  }

  Widget _buildEngagementCard(
      BuildContext context,
      ColorScheme colorScheme,
      int score,
      String rank,
      int adsSold,
      int positiveRatings,
      int totalRatings,
      bool isLoading) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color cardEngagement =
        isDark ? const Color.fromARGB(255, 15, 15, 15) : Colors.grey.shade200;

    return Card(
      elevation: 2,
      color: cardEngagement,
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
            if (!isLoading)
              _buildRankProgress(context, score, rank, colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreItem(BuildContext context, String label, String value,
      IconData icon, ColorScheme colorScheme) {
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

  Widget _buildBreakdownItem(BuildContext context, String label, String value,
      IconData icon, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
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

  Widget _buildRankProgress(BuildContext context, int score, String currentRank,
      ColorScheme colorScheme) {
    final rankThresholds = {
      'Bronze': 0,
      'Silver': 50,
      'Gold': 150,
      'Platinum': 300,
      'Diamond': 500,
    };

    final ranks = ['Bronze', 'Silver', 'Gold', 'Platinum', 'Diamond'];
    final currentIndex = ranks.indexOf(currentRank);
    final nextRank =
        currentIndex < ranks.length - 1 ? ranks[currentIndex + 1] : null;

    if (nextRank == null) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.amber.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            const Icon(Icons.emoji_events, color: Colors.amber, size: 16),
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
    final progress =
        (score - currentThreshold) / (nextThreshold - currentThreshold);
    final remaining = nextThreshold - score;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
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
            backgroundColor: colorScheme.surfaceContainerHighest,
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
            if (rating >= 4) {
              // Consider 4+ as positive
              positiveRatings++;
            }
          }
        }
      }

      // Calculate score: 10 points per sold ad + 5 points per positive rating
      final score = (adsSold * 10) + (positiveRatings * 5);

      // Determine rank based on score
      String rank = 'Bronze';
      if (score >= 500) {
        rank = 'Diamond';
      } else if (score >= 300)
        rank = 'Platinum';
      else if (score >= 150)
        rank = 'Gold';
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

  void _navigateToBlog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BlogListPage()),
    );
  }

  void _navigateToVideos(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const VideoListPage()),
    );
  }

  void _navigateToSavedAds(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SavedAdsPage()),
    );
  }
}
