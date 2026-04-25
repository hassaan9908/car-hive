import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/announcement_banner_model.dart';
import '../../services/announcement_banner_service.dart';
import '../../services/cloudinary_service.dart';
import '../../widgets/announcement_banner_widgets.dart';

class AdminAnnouncementBannersPage extends StatefulWidget {
  const AdminAnnouncementBannersPage({super.key});

  @override
  State<AdminAnnouncementBannersPage> createState() =>
      _AdminAnnouncementBannersPageState();
}

class _AdminAnnouncementBannersPageState
    extends State<AdminAnnouncementBannersPage> {
  final _formKey = GlobalKey<FormState>();
  final _eyebrowController = TextEditingController(text: 'Fresh on CarHive');
  final _headlineController = TextEditingController();
  final _subtitleController = TextEditingController();
  final _ctaController = TextEditingController(text: 'Explore now');
  final AnnouncementBannerService _bannerService = AnnouncementBannerService();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final ImagePicker _imagePicker = ImagePicker();

  File? _selectedImageFile;
  Uint8List? _selectedImageBytes;
  bool _publishImmediately = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _eyebrowController.dispose();
    _headlineController.dispose();
    _subtitleController.dispose();
    _ctaController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );

      if (pickedFile == null) {
        return;
      }

      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
          _selectedImageFile = null;
        });
        return;
      }

      setState(() {
        _selectedImageFile = File(pickedFile.path);
        _selectedImageBytes = null;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to pick image: $e'),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  }

  Future<void> _submitBanner() async {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      String? imageUrl;
      if (_selectedImageBytes != null) {
        imageUrl = await _cloudinaryService.uploadImageBytes(
          imageBytes: _selectedImageBytes!,
        );
      } else if (_selectedImageFile != null) {
        imageUrl = await _cloudinaryService.uploadImage(
          imageFile: _selectedImageFile!,
        );
      }

      final currentUser = FirebaseAuth.instance.currentUser;
      final displayName = currentUser?.displayName?.trim();
      final createdByName = (displayName != null && displayName.isNotEmpty)
          ? displayName
          : currentUser?.email;

      final banner = AnnouncementBannerModel(
        eyebrow: _eyebrowController.text.trim(),
        headline: _headlineController.text.trim(),
        subtitle: _subtitleController.text.trim(),
        ctaLabel: _normalizeOptionalText(_ctaController.text),
        imageUrl: imageUrl,
        isActive: _publishImmediately,
        createdByName: createdByName,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _bannerService.createBanner(banner);
      _resetComposer();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _publishImmediately
                ? 'Announcement banner published on the home page.'
                : 'Announcement banner saved as inactive.',
          ),
          backgroundColor: Colors.green.shade600,
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      final message = e.toString().contains('permission-denied')
          ? 'Failed to create banner. Deploy the updated Firestore rules first, then try again.'
          : 'Failed to create banner: $e';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red.shade600,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _toggleBanner(AnnouncementBannerModel banner) async {
    if (banner.id == null) {
      return;
    }

    try {
      await _bannerService.updateBannerStatus(banner.id!, !banner.isActive);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            banner.isActive
                ? 'Banner hidden from the home page.'
                : 'Banner is now live on the home page.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      final message = e.toString().contains('permission-denied')
          ? 'Could not update the banner. Deploy the updated Firestore rules first.'
          : 'Could not update banner: $e';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  }

  Future<void> _deleteBanner(AnnouncementBannerModel banner) async {
    if (banner.id == null) {
      return;
    }

    final shouldDelete = await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Delete Banner'),
              content: Text(
                'Delete "${banner.headline}"? This will remove it from the admin panel and home page.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                  ),
                  child: const Text('Delete'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!shouldDelete) {
      return;
    }

    try {
      await _bannerService.deleteBanner(banner.id!);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Banner deleted successfully.'),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      final message = e.toString().contains('permission-denied')
          ? 'Could not delete the banner. Deploy the updated Firestore rules first.'
          : 'Could not delete banner: $e';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  }

  void _resetComposer() {
    _headlineController.clear();
    _subtitleController.clear();
    _selectedImageFile = null;
    _selectedImageBytes = null;
    _publishImmediately = true;

    setState(() {});
  }

  String? _normalizeOptionalText(String value) {
    final normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }

  AnnouncementBannerModel _buildPreviewBanner() {
    return AnnouncementBannerModel(
      eyebrow: _eyebrowController.text.trim().isEmpty
          ? 'CarHive Update'
          : _eyebrowController.text.trim(),
      headline: _headlineController.text.trim().isEmpty
          ? 'Put your next launch, event, or special offer here'
          : _headlineController.text.trim(),
      subtitle: _subtitleController.text.trim().isEmpty
          ? 'This banner appears right under the home-page search bar and above Browse by Brand.'
          : _subtitleController.text.trim(),
      ctaLabel: _normalizeOptionalText(_ctaController.text) ?? 'Explore now',
      isActive: _publishImmediately,
    );
  }

  Widget? _buildSelectedImagePreview() {
    if (_selectedImageBytes != null) {
      return Image.memory(
        _selectedImageBytes!,
        fit: BoxFit.contain,
      );
    }

    if (_selectedImageFile != null) {
      return Image.file(
        _selectedImageFile!,
        fit: BoxFit.contain,
      );
    }

    return null;
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return 'Just now';
    }

    final difference = DateTime.now().difference(date);

    if (difference.inDays >= 1) {
      return difference.inDays == 1
          ? '1 day ago'
          : '${difference.inDays} days ago';
    }

    if (difference.inHours >= 1) {
      return difference.inHours == 1
          ? '1 hour ago'
          : '${difference.inHours} hours ago';
    }

    if (difference.inMinutes >= 1) {
      return difference.inMinutes == 1
          ? '1 minute ago'
          : '${difference.inMinutes} minutes ago';
    }

    return 'Just now';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const accent = Color(0xFFF48C25);
    final panelColor =
        isDark ? const Color(0xFF111827) : Colors.white.withValues(alpha: 0.94);
    final pageBackground = isDark
        ? const LinearGradient(
            colors: [Color(0xFF0B1220), Color(0xFF101A2B)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          )
        : LinearGradient(
            colors: [Colors.grey.shade100, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          );
    final borderColor =
        isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade300;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 0,
        title: const Text(
          'Announcements',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: pageBackground,
        ),
        child: StreamBuilder<List<AnnouncementBannerModel>>(
          stream: _bannerService.watchAllBanners(),
          builder: (context, snapshot) {
            final loadError = snapshot.error;
            final banners = snapshot.data ?? const <AnnouncementBannerModel>[];
            final activeCount =
                banners.where((banner) => banner.isActive).length;

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFB85C), Color(0xFFF48C25)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.18),
                          blurRadius: 18,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Wrap(
                      runSpacing: 14,
                      spacing: 18,
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 580),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Home-page announcements',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Create a banner once and it will appear right below the search bar, above Browse by Brand. Keep several active to let users swipe through them.',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.92),
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            _buildTopMetric(
                              label: 'Total banners',
                              value: banners.length.toString(),
                            ),
                            _buildTopMetric(
                              label: 'Active now',
                              value: activeCount.toString(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (loadError != null) ...[
                    _buildRulesWarningCard(loadError),
                    const SizedBox(height: 20),
                  ],
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final useWideLayout = constraints.maxWidth >= 1180;

                      final composer = _buildComposerPanel(
                        panelColor: panelColor,
                        borderColor: borderColor,
                        accent: accent,
                        isDark: isDark,
                      );
                      final manager = _buildManagerPanel(
                        banners: banners,
                        panelColor: panelColor,
                        borderColor: borderColor,
                        accent: accent,
                        isDark: isDark,
                      );

                      if (useWideLayout) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 6, child: composer),
                            const SizedBox(width: 20),
                            Expanded(flex: 5, child: manager),
                          ],
                        );
                      }

                      return Column(
                        children: [
                          composer,
                          const SizedBox(height: 20),
                          manager,
                        ],
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildComposerPanel({
    required Color panelColor,
    required Color borderColor,
    required Color accent,
    required bool isDark,
  }) {
    final previewBanner = _buildPreviewBanner();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.add_photo_alternate_outlined,
                    color: accent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Create a banner',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Write the announcement, upload a car image if you want, and publish it directly to the home page.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                              height: 1.35,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Live preview',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 190,
              child: AnnouncementBannerCard(
                banner: previewBanner,
                imageOverride: _buildSelectedImagePreview(),
              ),
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _eyebrowController,
              label: 'Eyebrow label',
              hint: 'Ex: This week only',
              icon: Icons.campaign_outlined,
              maxLength: 32,
            ),
            const SizedBox(height: 14),
            _buildTextField(
              controller: _headlineController,
              label: 'Headline',
              hint: 'Ex: Zero markup deals on certified SUVs',
              icon: Icons.title,
              maxLength: 72,
              validator: (value) {
                if ((value ?? '').trim().isEmpty) {
                  return 'Headline is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            _buildTextField(
              controller: _subtitleController,
              label: 'Supporting text',
              hint:
                  'Ex: Let buyers know what changed, what is new, or what action to take.',
              icon: Icons.notes_rounded,
              maxLength: 120,
              minLines: 2,
              maxLines: 3,
              validator: (value) {
                if ((value ?? '').trim().isEmpty) {
                  return 'Supporting text is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            _buildTextField(
              controller: _ctaController,
              label: 'CTA label',
              hint: 'Ex: Explore now',
              icon: Icons.ads_click_outlined,
              maxLength: 24,
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.03)
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Banner image',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Optional. If you skip it, CarHive will use a default car illustration in the banner.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      FilledButton.icon(
                        onPressed: _isSubmitting ? null : _pickImage,
                        icon: const Icon(Icons.upload_outlined),
                        label: Text(
                          _selectedImageBytes != null ||
                                  _selectedImageFile != null
                              ? 'Replace image'
                              : 'Upload image',
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: accent,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      if (_selectedImageBytes != null ||
                          _selectedImageFile != null)
                        OutlinedButton.icon(
                          onPressed: _isSubmitting
                              ? null
                              : () {
                                  setState(() {
                                    _selectedImageBytes = null;
                                    _selectedImageFile = null;
                                  });
                                },
                          icon: const Icon(Icons.close),
                          label: const Text('Remove image'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SwitchListTile.adaptive(
              value: _publishImmediately,
              contentPadding: EdgeInsets.zero,
              activeColor: accent,
              title: const Text(
                'Publish immediately',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: const Text(
                'Turn this on to show the banner on the home page as soon as you save it.',
              ),
              onChanged: _isSubmitting
                  ? null
                  : (value) {
                      setState(() {
                        _publishImmediately = value;
                      });
                    },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isSubmitting ? null : _submitBanner,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.publish_rounded),
                label: Text(
                  _isSubmitting ? 'Saving banner...' : 'Save announcement',
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: accent,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRulesWarningCard(Object error) {
    final isPermissionIssue = error.toString().contains('permission-denied');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF59E0B)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Color(0xFFB45309),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Announcement storage is not ready yet',
                  style: TextStyle(
                    color: Color(0xFF92400E),
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isPermissionIssue
                      ? 'The updated Firestore rules for `announcement_banners` are not deployed yet. The home page will show the built-in fallback banner until those rules are live.'
                      : 'There was a problem loading saved banners. The home page will keep showing the built-in fallback banner until Firestore is available again.',
                  style: const TextStyle(
                    color: Color(0xFF92400E),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Current error: $error',
                  style: const TextStyle(
                    color: Color(0xFF92400E),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManagerPanel({
    required List<AnnouncementBannerModel> banners,
    required Color panelColor,
    required Color borderColor,
    required Color accent,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Manage existing banners',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Newest banners appear first. Active banners are the ones the home page shows in the announcement slider.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.35,
                ),
          ),
          const SizedBox(height: 18),
          if (banners.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.03)
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.campaign_outlined,
                    size: 48,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'No announcement banners yet',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Use the composer on the left to create the first banner for the home page.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                  ),
                ],
              ),
            )
          else
            Column(
              children: banners
                  .map(
                    (banner) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildBannerListItem(
                        banner: banner,
                        borderColor: borderColor,
                        accent: accent,
                        isDark: isDark,
                      ),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildBannerListItem({
    required AnnouncementBannerModel banner,
    required Color borderColor,
    required Color accent,
    required bool isDark,
  }) {
    final statusColor = banner.isActive ? accent : Colors.grey.shade500;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            isDark ? Colors.white.withValues(alpha: 0.03) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 172,
            child: AnnouncementBannerCard(
              banner: banner,
              showShadow: false,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildInfoChip(
                label: banner.isActive ? 'Active on home page' : 'Inactive',
                icon: banner.isActive ? Icons.visibility : Icons.visibility_off,
                color: statusColor,
              ),
              _buildInfoChip(
                label: _formatDate(banner.createdAt),
                icon: Icons.schedule_rounded,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              if ((banner.createdByName ?? '').trim().isNotEmpty)
                _buildInfoChip(
                  label: banner.createdByName!,
                  icon: Icons.person_outline_rounded,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: () => _toggleBanner(banner),
                icon: Icon(
                  banner.isActive ? Icons.visibility_off : Icons.visibility,
                ),
                label:
                    Text(banner.isActive ? 'Hide banner' : 'Activate banner'),
              ),
              TextButton.icon(
                onPressed: () => _deleteBanner(banner),
                icon: Icon(Icons.delete_outline, color: Colors.red.shade400),
                label: Text(
                  'Delete',
                  style: TextStyle(color: Colors.red.shade400),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopMetric({
    required String label,
    required String value,
  }) {
    return Container(
      constraints: const BoxConstraints(minWidth: 120),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withValues(alpha: 0.16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.92),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int? maxLength,
    int minLines = 1,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    final borderColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.grey.shade300;

    return TextFormField(
      controller: controller,
      validator: validator,
      maxLength: maxLength,
      minLines: minLines,
      maxLines: maxLines,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        counterText: '',
        filled: true,
        fillColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFF48C25), width: 1.4),
        ),
      ),
    );
  }
}
