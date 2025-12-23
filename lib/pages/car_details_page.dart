import 'package:flutter/material.dart';
import '../models/ad_model.dart';
import '../services/review_service.dart';
import '../models/review_model.dart';
import '../widgets/car_360_viewer.dart';
import '../screens/car_360_viewer_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/chat_service.dart';
import 'chat_detail_page.dart';

class CarDetailsPage extends StatefulWidget {
  final AdModel ad;

  const CarDetailsPage({super.key, required this.ad});

  @override
  State<CarDetailsPage> createState() => _CarDetailsPageState();
}

class _CarDetailsPageState extends State<CarDetailsPage> {
  final ReviewService _reviewService = ReviewService();
  final TextEditingController _commentController = TextEditingController();
  int _rating = 0;
  bool _submitting = false;
  int _currentImageIndex = 0; // Track current image index for indicator
  final PageController _pageController = PageController(); // Controller for PageView

  @override
  void dispose() {
    _commentController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    try {
      if (phoneNumber.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Phone number is empty')),
          );
        }
        return;
      }

      // Clean phone number: remove spaces, dashes, parentheses, and other non-digit characters except +
      String cleanedNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      
      if (cleanedNumber.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid phone number format')),
          );
        }
        return;
      }

      // Create URI with tel scheme
      final Uri phoneUri = Uri(scheme: 'tel', path: cleanedNumber);
      
      print('Attempting to call: $cleanedNumber'); // Debug log
      
      // Try to launch the phone dialer
      // Use platformDefault mode which works better on mobile devices
      final launched = await launchUrl(
        phoneUri,
        mode: LaunchMode.platformDefault,
      );
      
      if (!launched) {
        // If platformDefault fails, try externalApplication
        await launchUrl(
          phoneUri,
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      print('Error making phone call: $e'); // Debug log
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not launch phone dialer: ${e.toString()}'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _openChat(String sellerId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to send messages')),
        );
      }
      return;
    }

    if (currentUser.uid == sellerId) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You cannot message yourself')),
        );
      }
      return;
    }

    // Get seller info for display name
    String sellerName = 'User';
    try {
      final sellerDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(sellerId)
          .get();
      if (sellerDoc.exists) {
        final data = sellerDoc.data();
        sellerName = data?['displayName'] ?? 
                     data?['email']?.split('@')[0] ?? 
                     'User';
      }
    } catch (e) {
      print('Error getting seller info: $e');
    }

    // Navigate to chat detail page
    if (mounted) {
      try {
        final chatService = ChatService();
        final conversationId = await chatService.getOrCreateConversation(sellerId);
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatDetailPage(
              conversationId: conversationId,
              otherUserId: sellerId,
              otherUserName: sellerName,
            ),
          ),
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error opening chat: ${e.toString()}')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final ad = widget.ad;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Car Details'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Enhanced Car images display
            Container(
              height: 280,
              width: double.infinity,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Display images from Cloudinary if available
                  if (ad.imageUrls != null && ad.imageUrls!.isNotEmpty)
                    PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() {
                          _currentImageIndex = index;
                        });
                      },
                      itemCount: ad.imageUrls!.length,
                      itemBuilder: (context, index) {
                        return Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(30),
                              bottomRight: Radius.circular(30),
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(30),
                              bottomRight: Radius.circular(30),
                            ),
                            child: Image.network(
                              ad.imageUrls![index],
                              fit: BoxFit.cover,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes !=
                                            null
                                        ? loadingProgress
                                                .cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: colorScheme.surfaceContainerHighest,
                                  child: Center(
                                    child: Icon(
                                      Icons.broken_image,
                                      size: 100,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    )
                  else
                    // Placeholder if no images
                    Container(
                      color: colorScheme.surfaceContainerHighest,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            Icons.car_rental,
                            size: 100,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                  // Trust badge overlay
                  Positioned(
                    top: 20,
                    right: 20,
                    child: _buildTrustBadge(context),
                  ),
                  // Image counter overlay
                  if (ad.imageUrls != null && ad.imageUrls!.length > 1)
                    Positioned(
                      top: 20,
                      left: 20,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '${_currentImageIndex + 1} / ${ad.imageUrls!.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // 360° View Section (if available)
            if (ad.images360Urls != null && ad.images360Urls!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.rotate_right,
                            color: colorScheme.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '360° View',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                colorScheme.primary,
                                colorScheme.primary.withValues(alpha: 0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${ad.images360Urls!.length} angles',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Car360PreviewWidget(
                      imageUrls: ad.images360Urls!,
                      size: 220,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Car360ViewerScreen(
                              imageUrls: ad.images360Urls!,
                              title: ad.title,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

            // Main content with enhanced styling
            Container(
              margin: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Enhanced Title and Price Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          ad.title,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                        ),
                        const SizedBox(height: 12),

                        // Price with enhanced styling
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                colorScheme.primary,
                                colorScheme.primary.withValues(alpha: 0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'PKR ${ad.price}',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Location with enhanced styling
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color:
                                    colorScheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.location_on,
                                color: colorScheme.primary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              ad.location,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Enhanced Car Specifications Section
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color:
                                    colorScheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.info_outline,
                                color: colorScheme.primary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Specifications',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurface,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildEnhancedSpecificationCard(
                          context,
                          'Year',
                          ad.year.isNotEmpty ? ad.year : 'Not specified',
                          Icons.calendar_today,
                        ),
                        const SizedBox(height: 12),
                        _buildEnhancedSpecificationCard(
                          context,
                          'Mileage (KMs Driven)',
                          ad.mileage.isNotEmpty
                              ? '${ad.mileage} km'
                              : 'Not specified',
                          Icons.speed,
                        ),
                        const SizedBox(height: 12),
                        _buildEnhancedSpecificationCard(
                          context,
                          'Fuel Type',
                          ad.fuel.isNotEmpty ? ad.fuel : 'Not specified',
                          Icons.local_gas_station,
                        ),
                        if (ad.carBrand != null && ad.carBrand!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _buildEnhancedSpecificationCard(
                            context,
                            'Brand',
                            ad.carBrand!,
                            Icons.branding_watermark,
                          ),
                        ],
                        if (ad.bodyColor != null &&
                            ad.bodyColor!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _buildEnhancedSpecificationCard(
                            context,
                            'Color',
                            ad.bodyColor!,
                            Icons.palette,
                          ),
                        ],
                        if (ad.registeredIn != null &&
                            ad.registeredIn!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _buildEnhancedSpecificationCard(
                            context,
                            'Registered In',
                            ad.registeredIn!,
                            Icons.location_city,
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Enhanced Description Section
                  if (ad.description != null && ad.description!.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.primary.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.description,
                                  color: colorScheme.primary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Description',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onSurface,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            ad.description!,
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      height: 1.5,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Enhanced Contact Information Section
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color:
                                    colorScheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.contact_phone,
                                color: colorScheme.primary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Contact Information',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurface,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Fetch seller info from user document with real-time updates
                        if (ad.userId != null && ad.userId!.isNotEmpty)
                          StreamBuilder<DocumentSnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('users')
                                .doc(ad.userId)
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const SizedBox(
                                  height: 40,
                                  child: Center(
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2)),
                                );
                              }

                              // Fallback to ad fields if user doc doesn't exist
                              if (!snapshot.hasData || !snapshot.data!.exists) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (ad.name != null &&
                                        ad.name!.isNotEmpty) ...[
                                      _buildEnhancedContactCard(
                                        context,
                                        'Seller Name',
                                        ad.name!,
                                        Icons.person,
                                      ),
                                      const SizedBox(height: 12),
                                    ],
                                    if (ad.phone != null &&
                                        ad.phone!.isNotEmpty)
                                      _buildEnhancedContactCard(
                                        context,
                                        'Phone',
                                        ad.phone!,
                                        Icons.phone,
                                      ),
                                  ],
                                );
                              }

                              final data = snapshot.data!.data()
                                      as Map<String, dynamic>? ??
                                  {};
                              final sellerName = (data['fullName'] ??
                                      data['displayName'] ??
                                      ad.name ??
                                      '')
                                  .toString();
                              final email = (data['email'] ?? '').toString();
                              final phone =
                                  (data['phoneNumber'] ?? ad.phone ?? '')
                                      .toString();

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (sellerName.isNotEmpty) ...[
                                    _buildEnhancedContactCard(
                                      context,
                                      'Seller Name',
                                      sellerName,
                                      Icons.person,
                                    ),
                                    const SizedBox(height: 12),
                                  ],
                                  if (email.isNotEmpty) ...[
                                    _buildEnhancedContactCard(
                                      context,
                                      'Email',
                                      email,
                                      Icons.email,
                                    ),
                                    const SizedBox(height: 12),
                                  ],
                                  if (phone.isNotEmpty)
                                    _buildEnhancedContactCard(
                                      context,
                                      'Phone',
                                      phone,
                                      Icons.phone,
                                    ),
                                ],
                              );
                            },
                          )
                        else ...[
                          // No userId, use ad embedded fields only
                          if (ad.name != null && ad.name!.isNotEmpty) ...[
                            _buildEnhancedContactCard(
                              context,
                              'Seller Name',
                              ad.name!,
                              Icons.person,
                            ),
                            const SizedBox(height: 12),
                          ],
                          if (ad.phone != null && ad.phone!.isNotEmpty)
                            _buildEnhancedContactCard(
                              context,
                              'Phone',
                              ad.phone!,
                              Icons.phone,
                            ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Enhanced Action Buttons
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color(0xFFFF6B35),
                                  Color(0xFFFF8C42),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFF6B35).withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                // Get phone number from user doc or ad
                                String? phoneNumber;
                                if (ad.userId != null &&
                                    ad.userId!.isNotEmpty) {
                                  try {
                                    final userDoc = await FirebaseFirestore
                                        .instance
                                        .collection('users')
                                        .doc(ad.userId)
                                        .get();
                                    if (userDoc.exists) {
                                      final data = userDoc.data()
                                          as Map<String, dynamic>?;
                                      phoneNumber =
                                          data?['phoneNumber']?.toString() ??
                                          data?['phone']?.toString();
                                      print('Phone from user doc: $phoneNumber'); // Debug log
                                    }
                                  } catch (e) {
                                    print('Error fetching phone: $e');
                                  }
                                }
                                phoneNumber ??= ad.phone;
                                print('Final phone number: $phoneNumber'); // Debug log

                                if (phoneNumber != null &&
                                    phoneNumber.trim().isNotEmpty) {
                                  await _makePhoneCall(phoneNumber.trim());
                                } else {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Phone number not available')),
                                    );
                                  }
                                }
                              },
                              icon: const Icon(Icons.phone),
                              label: const Text('Call'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  colorScheme.secondary,
                                  colorScheme.secondary.withValues(alpha: 0.8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ElevatedButton.icon(
                              onPressed: () {
                                if (ad.userId != null &&
                                    ad.userId!.isNotEmpty) {
                                  _openChat(ad.userId!);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Seller information not available')),
                                  );
                                }
                              },
                              icon: const Icon(Icons.message),
                              label: const Text('Message'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Enhanced Reviews Section
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color:
                                    colorScheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.star,
                                color: colorScheme.primary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Reviews',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurface,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Display existing reviews
                        StreamBuilder<List<ReviewModel>>(
                          stream: _reviewService.streamReviews(ad.id ?? ''),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }
                            if (snapshot.hasError) {
                              return Text(
                                  'Error loading reviews: ${snapshot.error}');
                            }
                            if (!snapshot.hasData) {
                              return const Text('No reviews data available');
                            }
                            final reviews = snapshot.data!;

                            if (reviews.isEmpty) {
                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .outline
                                        .withOpacity(0.3),
                                  ),
                                ),
                                child: Text(
                                  'No reviews yet. Be the first to review this car!',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                ),
                              );
                            }

                            return Column(
                              children: reviews
                                  .map((r) => _buildReviewItem(context, r))
                                  .toList(),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildAddReviewCard(context, ad),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecificationCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: colorScheme.primary,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Enhanced specification card with modern styling
  Widget _buildEnhancedSpecificationCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.03),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Enhanced contact card with modern styling
  Widget _buildEnhancedContactCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.03),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: colorScheme.primary,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddReviewCard(BuildContext context, AdModel ad) {
    final colorScheme = Theme.of(context).colorScheme;
    final currentUser = FirebaseAuth.instance.currentUser;
    final isOwner = currentUser != null && ad.userId == currentUser.uid;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add your review',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          if (isOwner)
            Text(
              'You cannot review your own ad.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: colorScheme.error),
            )
          else ...[
            Row(
              children: List.generate(5, (index) {
                final starIndex = index + 1;
                final isSelected = _rating >= starIndex;
                return IconButton(
                  onPressed: () {
                    setState(() {
                      _rating = starIndex;
                    });
                  },
                  icon: Icon(
                    isSelected ? Icons.star : Icons.star_border,
                    color: isSelected
                        ? Colors.amber
                        : Theme.of(context).colorScheme.outline,
                  ),
                );
              }),
            ),
            TextField(
              controller: _commentController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Share your experience...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,

              child: 
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFF6B35), Color(0xFFFF8C42)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF6B35).withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    
                  ),
                onPressed: _submitting
                    ? null
                    : () async {
                        final adId = ad.id;
                        if (adId == null || adId.isEmpty) return;
                        if (_rating == 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Please select a star rating')),
                          );
                          return;
                        }
                        setState(() {
                          _submitting = true;
                        });
                        try {
                          await _reviewService.addReview(
                            adId: adId,
                            rating: _rating,
                            comment: _commentController.text,
                          );
                          _commentController.clear();
                          setState(() {
                            _rating = 0;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Review submitted')),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed: $e')),
                          );
                        } finally {
                          if (mounted) {
                            setState(() {
                              _submitting = false;
                            });
                          }
                        }
                      },
                child: _submitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Submit Review'),
              ),
            ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildReviewItem(BuildContext context, ReviewModel review) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                review.userName ?? 'Anonymous',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Row(
                children: List.generate(5, (index) {
                  final starIndex = index + 1;
                  final filled = review.rating >= starIndex;
                  return Icon(
                    filled ? Icons.star : Icons.star_border,
                    color: filled ? Colors.amber : colorScheme.outline,
                    size: 18,
                  );
                }),
              )
            ],
          ),
          const SizedBox(height: 8),
          Text(
            review.comment,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 8),
          Text(
            _formatDate(review.createdAt),
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // Trust badge widget
  Widget _buildTrustBadge(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.ad.userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text('...'),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const SizedBox.shrink();
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>?;
        final trustLevel = userData?['trustLevel'] as String?;

        if (trustLevel == null ||
            !['Bronze', 'Silver', 'Gold'].contains(trustLevel)) {
          return const SizedBox.shrink();
        }

        Color badgeColor;
        switch (trustLevel) {
          case 'Gold':
            badgeColor = Colors.amber;
            break;
          case 'Silver':
            badgeColor = Colors.grey[400]!;
            break;
          case 'Bronze':
            badgeColor = Colors.brown[400]!;
            break;
          default:
            badgeColor = colorScheme.primary;
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: badgeColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: badgeColor),
          ),
          child: Text(
            trustLevel.toUpperCase(),
            style: TextStyle(
              color: badgeColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        );
      },
    );
  }
}
