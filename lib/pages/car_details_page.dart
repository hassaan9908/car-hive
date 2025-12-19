// import 'package:flutter/material.dart';
// import 'package:url_launcher/url_launcher.dart';
// import '../models/ad_model.dart';
// import '../services/review_service.dart';
// import '../models/review_model.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// class CarDetailsPage extends StatefulWidget {
//   final AdModel ad;

//   const CarDetailsPage({super.key, required this.ad});

//   @override
//   State<CarDetailsPage> createState() => _CarDetailsPageState();
// }

// class _CarDetailsPageState extends State<CarDetailsPage> {
//   final ReviewService _reviewService = ReviewService();
//   final TextEditingController _commentController = TextEditingController();
//   int _rating = 0;
//   bool _submitting = false;

//   // image page controller & index
//   final PageController _pageController = PageController();
//   final int _currentImageIndex = 0;

//   // Save/Bookmark state
//   bool _isSaved = false;
//   bool _loadingSavedState = true;

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _trackView(); // adds 1 view when user opens the ad (after build)
//       _loadSavedState();
//     });
//   }

//   @override
//   void dispose() {
//     _commentController.dispose();
//     _pageController.dispose();
//     super.dispose();
//   }

//   Future<void> _loadSavedState() async {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user == null || widget.ad.id == null) {
//       setState(() {
//         _isSaved = false;
//         _loadingSavedState = false;
//       });
//       return;
//     }

//     try {
//       final favDoc = await FirebaseFirestore.instance
//           .collection('users')
//           .doc(user.uid)
//           .collection('favorites')
//           .doc(widget.ad.id)
//           .get();

//       setState(() {
//         _isSaved = favDoc.exists;
//         _loadingSavedState = false;
//       });
//     } catch (e) {
//       setState(() {
//         _isSaved = false;
//         _loadingSavedState = false;
//       });
//     }
//   }

//   // --------- Tracking methods (Option 1)
//   // also writes event entries under ads/{adId}/insights/events so we can draw charts
//   Future<void> _trackView() async {
//     final adId = widget.ad.id;
//     if (adId == null || adId.isEmpty) return;

//     final statsRef = FirebaseFirestore.instance
//         .collection('ads')
//         .doc(adId)
//         .collection('insights')
//         .doc('stats');

//     final eventsRef = FirebaseFirestore.instance
//         .collection('ads')
//         .doc(adId)
//         .collection('insights')
//         .doc('events') // doc container (we'll use subcollection 'items')
//         .collection('items');

//     await statsRef.set({
//       'views': FieldValue.increment(1),
//       'lastViewed': FieldValue.serverTimestamp(),
//     }, SetOptions(merge: true));

//     // write event doc for timeseries
//     await eventsRef.add({
//       'type': 'view',
//       'ts': FieldValue.serverTimestamp(),
//     });
//   }

//   Future<void> _trackContactClick() async {
//     final adId = widget.ad.id;
//     if (adId == null || adId.isEmpty) return;

//     final statsRef = FirebaseFirestore.instance
//         .collection('ads')
//         .doc(adId)
//         .collection('insights')
//         .doc('stats');

//     final eventsRef = FirebaseFirestore.instance
//         .collection('ads')
//         .doc(adId)
//         .collection('insights')
//         .doc('events')
//         .collection('items');

//     await statsRef.set({
//       'contacts': FieldValue.increment(1),
//     }, SetOptions(merge: true));

//     await eventsRef.add({
//       'type': 'contact',
//       'ts': FieldValue.serverTimestamp(),
//     });
//   }

//   Future<void> _trackSaveClick() async {
//     final adId = widget.ad.id;
//     if (adId == null || adId.isEmpty) return;

//     final statsRef = FirebaseFirestore.instance
//         .collection('ads')
//         .doc(adId)
//         .collection('insights')
//         .doc('stats');

//     final eventsRef = FirebaseFirestore.instance
//         .collection('ads')
//         .doc(adId)
//         .collection('insights')
//         .doc('events')
//         .collection('items');

//     await statsRef.set({
//       'saves': FieldValue.increment(1),
//     }, SetOptions(merge: true));

//     await eventsRef.add({
//       'type': 'save',
//       'ts': FieldValue.serverTimestamp(),
//     });
//   }

//   // --------- Save / Unsave handling
//   Future<void> _toggleSave() async {
//     final user = FirebaseAuth.instance.currentUser;
//     final adId = widget.ad.id;
//     if (user == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please log in to save this ad.')),
//       );
//       return;
//     }
//     if (adId == null || adId.isEmpty) return;

//     setState(() {
//       _loadingSavedState = true;
//     });

//     final favRef = FirebaseFirestore.instance
//         .collection('users')
//         .doc(user.uid)
//         .collection('favorites')
//         .doc(adId);

//     try {
//       final snapshot = await favRef.get();
//       if (snapshot.exists) {
//         // Unsave
//         await favRef.delete();
//         setState(() => _isSaved = false);
//         // Optionally decrement - not doing to keep simple
//       } else {
//         // Save
//         await favRef.set({
//           'adId': adId,
//           'savedAt': FieldValue.serverTimestamp(),
//           'title': widget.ad.title,
//           'image':
//               widget.ad.imageUrls != null && widget.ad.imageUrls!.isNotEmpty
//                   ? widget.ad.imageUrls!.first
//                   : null,
//         });
//         setState(() => _isSaved = true);
//         // increment saves counter in ad insights
//         await _trackSaveClick();
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to update favorites: $e')),
//       );
//     } finally {
//       if (mounted) {
//         setState(() {
//           _loadingSavedState = false;
//         });
//       }
//     }
//   }

//   // --------- Call handling (opens dialer and tracks)
//   Future<void> _onCallPressed() async {
//     final phone = widget.ad.phone;
//     if (phone == null || phone.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Phone number not available')),
//       );
//       return;
//     }

//     // Track contact click first
//     await _trackContactClick();

//     final Uri telUri = Uri(scheme: 'tel', path: phone);
//     try {
//       if (await canLaunchUrl(telUri)) {
//         await launchUrl(telUri);
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Could not open dialer')),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error opening dialer: $e')),
//       );
//     }
//   }

//   // --------- SMS message (opens SMS app and tracks)
//   Future<void> _onSmsPressed() async {
//     final phone = widget.ad.phone;
//     if (phone == null || phone.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Phone number not available')),
//       );
//       return;
//     }

//     await _trackContactClick();

//     // Use sms: scheme
//     final Uri smsUri = Uri(scheme: 'sms', path: phone);
//     try {
//       if (await canLaunchUrl(smsUri)) {
//         await launchUrl(smsUri);
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Could not open SMS app')),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error opening SMS app: $e')),
//       );
//     }
//   }

//   // --------- WhatsApp (open native app if available, else web)
//   // ignore: unused_element
//   Future<void> _onWhatsappPressed() async {
//     final phoneRaw = widget.ad.phone;
//     if (phoneRaw == null || phoneRaw.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Phone number not available')),
//       );
//       return;
//     }

//     await _trackContactClick();

//     // Normalize number: remove non-digit characters
//     final phone = phoneRaw.replaceAll(RegExp(r'\D'), '');
//     // Try whatsapp:// scheme
//     final uriApp = Uri.parse(
//         'whatsapp://send?phone=$phone&text=${Uri.encodeComponent("Hi, I saw your ad on the app.")}');
//     final uriWeb = Uri.parse(
//         'https://wa.me/$phone?text=${Uri.encodeComponent("Hi, I saw your ad on the app.")}');

//     try {
//       if (await canLaunchUrl(uriApp)) {
//         await launchUrl(uriApp);
//       } else if (await canLaunchUrl(uriWeb)) {
//         await launchUrl(uriWeb, mode: LaunchMode.externalApplication);
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Could not open WhatsApp')),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error opening WhatsApp: $e')),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final colorScheme = Theme.of(context).colorScheme;
//     final ad = widget.ad;

//     return Scaffold(
//       backgroundColor: colorScheme.surface,
//       appBar: AppBar(
//         title: const Text('Car Details'),
//         backgroundColor: colorScheme.primary,
//         foregroundColor: Colors.white,
//         elevation: 0,
//         flexibleSpace: Container(
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//               colors: [
//                 colorScheme.primary,
//                 colorScheme.primary.withValues(alpha: 0.8),
//               ],
//             ),
//           ),
//         ),
//       ),
//       body: SingleChildScrollView(
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Enhanced Car images display
//             Container(
//               height: 280,
//               width: double.infinity,
//               decoration: BoxDecoration(
//                 color: colorScheme.surfaceContainerHighest,
//                 borderRadius: const BorderRadius.only(
//                   bottomLeft: Radius.circular(30),
//                   bottomRight: Radius.circular(30),
//                 ),
//                 boxShadow: [
//                   BoxShadow(
//                     color: colorScheme.primary.withValues(alpha: 0.1),
//                     blurRadius: 20,
//                     offset: const Offset(0, 10),
//                   ),
//                 ],
//               ),
//               child: Stack(
//                 children: [
//                   // Display images from Cloudinary if available
//                   if (ad.imageUrls != null && ad.imageUrls!.isNotEmpty)
//                     PageView.builder(
//                       itemCount: ad.imageUrls!.length,
//                       itemBuilder: (context, index) {
//                         return Container(
//                           width: double.infinity,
//                           decoration: const BoxDecoration(
//                             borderRadius: BorderRadius.only(
//                               bottomLeft: Radius.circular(30),
//                               bottomRight: Radius.circular(30),
//                             ),
//                           ),
//                           child: ClipRRect(
//                             borderRadius: const BorderRadius.only(
//                               bottomLeft: Radius.circular(30),
//                               bottomRight: Radius.circular(30),
//                             ),
//                             child: Image.network(
//                               ad.imageUrls![index],
//                               fit: BoxFit.cover,
//                               loadingBuilder:
//                                   (context, child, loadingProgress) {
//                                 if (loadingProgress == null) return child;
//                                 return Center(
//                                   child: CircularProgressIndicator(
//                                     value: loadingProgress.expectedTotalBytes !=
//                                             null
//                                         ? loadingProgress
//                                                 .cumulativeBytesLoaded /
//                                             loadingProgress.expectedTotalBytes!
//                                         : null,
//                                   ),
//                                 );
//                               },
//                               errorBuilder: (context, error, stackTrace) {
//                                 return Container(
//                                   color: colorScheme.surfaceContainerHighest,
//                                   child: Center(
//                                     child: Icon(
//                                       Icons.broken_image,
//                                       size: 100,
//                                       color: colorScheme.onSurfaceVariant,
//                                     ),
//                                   ),
//                                 );
//                               },
//                             ),
//                           ),
//                         );
//                       },
//                     )
//                   else
//                     // Placeholder if no images
//                     Container(
//                       color: colorScheme.surfaceContainerHighest,
//                       child: Center(
//                         child: Container(
//                           padding: const EdgeInsets.all(20),
//                           decoration: BoxDecoration(
//                             color: colorScheme.primary.withValues(alpha: 0.1),
//                             borderRadius: BorderRadius.circular(20),
//                           ),
//                           child: Icon(
//                             Icons.car_rental,
//                             size: 100,
//                             color: colorScheme.primary,
//                           ),
//                         ),
//                       ),
//                     ),
//                   // Trust badge overlay
//                   Positioned(
//                     top: 20,
//                     right: 20,
//                     child: _buildTrustBadge(context),
//                   ),
//                   // Image counter overlay
//                   if (ad.imageUrls != null && ad.imageUrls!.length > 1)
//                     Positioned(
//                       top: 20,
//                       left: 20,
//                       child: Container(
//                         padding: const EdgeInsets.symmetric(
//                           horizontal: 12,
//                           vertical: 6,
//                         ),
//                         decoration: BoxDecoration(
//                           color: Colors.black.withValues(alpha: 0.6),
//                           borderRadius: BorderRadius.circular(16),
//                         ),
//                         child: Text(
//                           '1 / ${ad.imageUrls!.length}',
//                           style: const TextStyle(
//                             color: Colors.white,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ),
//                     ),
//                 ],
//               ),
//             ),

//             // Main content with enhanced styling
//             Container(
//               margin: const EdgeInsets.all(16),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Enhanced Title and Price Card
//                   Container(
//                     padding: const EdgeInsets.all(20),
//                     decoration: BoxDecoration(
//                       color: colorScheme.surfaceContainerHighest,
//                       borderRadius: BorderRadius.circular(16),
//                       boxShadow: [
//                         BoxShadow(
//                           color: colorScheme.primary.withValues(alpha: 0.05),
//                           blurRadius: 10,
//                           offset: const Offset(0, 5),
//                         ),
//                       ],
//                     ),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         // Title
//                         Text(
//                           ad.title,
//                           style: Theme.of(context)
//                               .textTheme
//                               .headlineSmall
//                               ?.copyWith(
//                                 fontWeight: FontWeight.bold,
//                                 color: colorScheme.onSurface,
//                               ),
//                         ),
//                         const SizedBox(height: 12),

//                         // Price with enhanced styling
//                         Container(
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 16,
//                             vertical: 8,
//                           ),
//                           decoration: BoxDecoration(
//                             gradient: LinearGradient(
//                               colors: [
//                                 colorScheme.primary,
//                                 colorScheme.primary.withValues(alpha: 0.8),
//                               ],
//                             ),
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                           child: Text(
//                             'PKR ${ad.price}',
//                             style: Theme.of(context)
//                                 .textTheme
//                                 .headlineSmall
//                                 ?.copyWith(
//                                   color: Colors.white,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                           ),
//                         ),
//                         const SizedBox(height: 16),

//                         // Location with enhanced styling
//                         Row(
//                           children: [
//                             Container(
//                               padding: const EdgeInsets.all(8),
//                               decoration: BoxDecoration(
//                                 color:
//                                     colorScheme.primary.withValues(alpha: 0.1),
//                                 borderRadius: BorderRadius.circular(8),
//                               ),
//                               child: Icon(
//                                 Icons.location_on,
//                                 color: colorScheme.primary,
//                                 size: 20,
//                               ),
//                             ),
//                             const SizedBox(width: 12),
//                             Text(
//                               ad.location,
//                               style: Theme.of(context)
//                                   .textTheme
//                                   .titleMedium
//                                   ?.copyWith(
//                                     color: colorScheme.onSurfaceVariant,
//                                     fontWeight: FontWeight.w500,
//                                   ),
//                             ),
//                           ],
//                         ),
//                       ],
//                     ),
//                   ),

//                   const SizedBox(height: 24),

//                   // Enhanced Car Specifications Section
//                   Container(
//                     padding: const EdgeInsets.all(20),
//                     decoration: BoxDecoration(
//                       color: colorScheme.surfaceContainerHighest,
//                       borderRadius: BorderRadius.circular(16),
//                       boxShadow: [
//                         BoxShadow(
//                           color: colorScheme.primary.withValues(alpha: 0.05),
//                           blurRadius: 10,
//                           offset: const Offset(0, 5),
//                         ),
//                       ],
//                     ),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Row(
//                           children: [
//                             Container(
//                               padding: const EdgeInsets.all(8),
//                               decoration: BoxDecoration(
//                                 color:
//                                     colorScheme.primary.withValues(alpha: 0.1),
//                                 borderRadius: BorderRadius.circular(8),
//                               ),
//                               child: Icon(
//                                 Icons.info_outline,
//                                 color: colorScheme.primary,
//                                 size: 20,
//                               ),
//                             ),
//                             const SizedBox(width: 12),
//                             Text(
//                               'Specifications',
//                               style: Theme.of(context)
//                                   .textTheme
//                                   .titleLarge
//                                   ?.copyWith(
//                                     fontWeight: FontWeight.bold,
//                                     color: colorScheme.onSurface,
//                                   ),
//                             ),
//                           ],
//                         ),
//                         const SizedBox(height: 20),
//                         _buildEnhancedSpecificationCard(
//                           context,
//                           'Year',
//                           ad.year.isNotEmpty ? ad.year : 'Not specified',
//                           Icons.calendar_today,
//                         ),
//                         const SizedBox(height: 12),
//                         _buildEnhancedSpecificationCard(
//                           context,
//                           'Mileage (KMs Driven)',
//                           ad.mileage.isNotEmpty
//                               ? '${ad.mileage} km'
//                               : 'Not specified',
//                           Icons.speed,
//                         ),
//                         const SizedBox(height: 12),
//                         _buildEnhancedSpecificationCard(
//                           context,
//                           'Fuel Type',
//                           ad.fuel.isNotEmpty ? ad.fuel : 'Not specified',
//                           Icons.local_gas_station,
//                         ),
//                         if (ad.carBrand != null && ad.carBrand!.isNotEmpty) ...[
//                           const SizedBox(height: 12),
//                           _buildEnhancedSpecificationCard(
//                             context,
//                             'Brand',
//                             ad.carBrand!,
//                             Icons.branding_watermark,
//                           ),
//                         ],
//                         if (ad.bodyColor != null &&
//                             ad.bodyColor!.isNotEmpty) ...[
//                           const SizedBox(height: 12),
//                           _buildEnhancedSpecificationCard(
//                             context,
//                             'Color',
//                             ad.bodyColor!,
//                             Icons.palette,
//                           ),
//                         ],
//                         if (ad.registeredIn != null &&
//                             ad.registeredIn!.isNotEmpty) ...[
//                           const SizedBox(height: 12),
//                           _buildEnhancedSpecificationCard(
//                             context,
//                             'Registered In',
//                             ad.registeredIn!,
//                             Icons.location_city,
//                           ),
//                         ],
//                       ],
//                     ),
//                   ),

//                   const SizedBox(height: 24),

//                   // Enhanced Description Section
//                   if (ad.description != null && ad.description!.isNotEmpty) ...[
//                     Container(
//                       padding: const EdgeInsets.all(20),
//                       decoration: BoxDecoration(
//                         color: colorScheme.surfaceContainerHighest,
//                         borderRadius: BorderRadius.circular(16),
//                         boxShadow: [
//                           BoxShadow(
//                             color: colorScheme.primary.withValues(alpha: 0.05),
//                             blurRadius: 10,
//                             offset: const Offset(0, 5),
//                           ),
//                         ],
//                       ),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Row(
//                             children: [
//                               Container(
//                                 padding: const EdgeInsets.all(8),
//                                 decoration: BoxDecoration(
//                                   color: colorScheme.primary
//                                       .withValues(alpha: 0.1),
//                                   borderRadius: BorderRadius.circular(8),
//                                 ),
//                                 child: Icon(
//                                   Icons.description,
//                                   color: colorScheme.primary,
//                                   size: 20,
//                                 ),
//                               ),
//                               const SizedBox(width: 12),
//                               Text(
//                                 'Description',
//                                 style: Theme.of(context)
//                                     .textTheme
//                                     .titleLarge
//                                     ?.copyWith(
//                                       fontWeight: FontWeight.bold,
//                                       color: colorScheme.onSurface,
//                                     ),
//                               ),
//                             ],
//                           ),
//                           const SizedBox(height: 16),
//                           Text(
//                             ad.description!,
//                             style:
//                                 Theme.of(context).textTheme.bodyLarge?.copyWith(
//                                       height: 1.5,
//                                       color: colorScheme.onSurfaceVariant,
//                                     ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     const SizedBox(height: 24),
//                   ],

//                   // Enhanced Contact Information Section
//                   Container(
//                     padding: const EdgeInsets.all(20),
//                     decoration: BoxDecoration(
//                       color: colorScheme.surfaceContainerHighest,
//                       borderRadius: BorderRadius.circular(16),
//                       boxShadow: [
//                         BoxShadow(
//                           color: colorScheme.primary.withValues(alpha: 0.05),
//                           blurRadius: 10,
//                           offset: const Offset(0, 5),
//                         ),
//                       ],
//                     ),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Row(
//                           children: [
//                             Container(
//                               padding: const EdgeInsets.all(8),
//                               decoration: BoxDecoration(
//                                 color:
//                                     colorScheme.primary.withValues(alpha: 0.1),
//                                 borderRadius: BorderRadius.circular(8),
//                               ),
//                               child: Icon(
//                                 Icons.contact_phone,
//                                 color: colorScheme.primary,
//                                 size: 20,
//                               ),
//                             ),
//                             const SizedBox(width: 12),
//                             Text(
//                               'Contact Information',
//                               style: Theme.of(context)
//                                   .textTheme
//                                   .titleLarge
//                                   ?.copyWith(
//                                     fontWeight: FontWeight.bold,
//                                     color: colorScheme.onSurface,
//                                   ),
//                             ),
//                           ],
//                         ),
//                         const SizedBox(height: 20),
//                         if (ad.name != null && ad.name!.isNotEmpty) ...[
//                           _buildEnhancedContactCard(
//                             context,
//                             'Seller Name',
//                             ad.name!,
//                             Icons.person,
//                           ),
//                           const SizedBox(height: 12),
//                         ],
//                         if (ad.phone != null && ad.phone!.isNotEmpty)
//                           _buildEnhancedContactCard(
//                             context,
//                             'Phone',
//                             ad.phone!,
//                             Icons.phone,
//                           ),
//                       ],
//                     ),
//                   ),

//                   const SizedBox(height: 32),

//                   // Enhanced Action Buttons
//                   Container(
//                     padding: const EdgeInsets.all(20),
//                     decoration: BoxDecoration(
//                       color: colorScheme.surfaceContainerHighest,
//                       borderRadius: BorderRadius.circular(16),
//                       boxShadow: [
//                         BoxShadow(
//                           color: colorScheme.primary.withValues(alpha: 0.05),
//                           blurRadius: 10,
//                           offset: const Offset(0, 5),
//                         ),
//                       ],
//                     ),
//                     child: Row(
//                       children: [
//                         Expanded(
//                           child: Container(
//                             decoration: BoxDecoration(
//                               gradient: LinearGradient(
//                                 colors: [
//                                   colorScheme.primary,
//                                   colorScheme.primary.withValues(alpha: 0.8),
//                                 ],
//                               ),
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                             child: ElevatedButton.icon(
//                               onPressed: () {
//                                 // TODO: Implement call functionality
//                                 ScaffoldMessenger.of(context).showSnackBar(
//                                   const SnackBar(
//                                       content:
//                                           Text('Call feature coming soon!')),
//                                 );
//                               },
//                               icon: const Icon(Icons.phone),
//                               label: const Text('Call'),
//                               style: ElevatedButton.styleFrom(
//                                 backgroundColor: Colors.transparent,
//                                 foregroundColor: Colors.white,
//                                 padding:
//                                     const EdgeInsets.symmetric(vertical: 16),
//                                 elevation: 0,
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(12),
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ),
//                         const SizedBox(width: 16),
//                         Expanded(
//                           child: Container(
//                             decoration: BoxDecoration(
//                               gradient: LinearGradient(
//                                 colors: [
//                                   colorScheme.secondary,
//                                   colorScheme.secondary.withValues(alpha: 0.8),
//                                 ],
//                               ),
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                             child: ElevatedButton.icon(
//                               onPressed: () {
//                                 // TODO: Implement message functionality
//                                 ScaffoldMessenger.of(context).showSnackBar(
//                                   const SnackBar(
//                                       content:
//                                           Text('Message feature coming soon!')),
//                                 );
//                               },
//                               icon: const Icon(Icons.message),
//                               label: const Text('Message'),
//                               style: ElevatedButton.styleFrom(
//                                 backgroundColor: Colors.transparent,
//                                 foregroundColor: Colors.white,
//                                 padding:
//                                     const EdgeInsets.symmetric(vertical: 16),
//                                 elevation: 0,
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(12),
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),

//                   const SizedBox(height: 32),

//                   // Enhanced Reviews Section
//                   Container(
//                     padding: const EdgeInsets.all(20),
//                     decoration: BoxDecoration(
//                       color: colorScheme.surfaceContainerHighest,
//                       borderRadius: BorderRadius.circular(16),
//                       boxShadow: [
//                         BoxShadow(
//                           color: colorScheme.primary.withValues(alpha: 0.05),
//                           blurRadius: 10,
//                           offset: const Offset(0, 5),
//                         ),
//                       ],
//                     ),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Row(
//                           children: [
//                             Container(
//                               padding: const EdgeInsets.all(8),
//                               decoration: BoxDecoration(
//                                 color:
//                                     colorScheme.primary.withValues(alpha: 0.1),
//                                 borderRadius: BorderRadius.circular(8),
//                               ),
//                               child: Icon(
//                                 Icons.star,
//                                 color: colorScheme.primary,
//                                 size: 20,
//                               ),
//                             ),
//                             const SizedBox(width: 12),
//                             Text(
//                               'Reviews',
//                               style: Theme.of(context)
//                                   .textTheme
//                                   .titleLarge
//                                   ?.copyWith(
//                                     fontWeight: FontWeight.bold,
//                                     color: colorScheme.onSurface,
//                                   ),
//                             ),
//                           ],
//                         ),
//                         const SizedBox(height: 20),

//                         // Display existing reviews
//                         StreamBuilder<List<ReviewModel>>(
//                           stream: _reviewService.streamReviews(ad.id ?? ''),
//                           builder: (context, snapshot) {
//                             if (snapshot.connectionState ==
//                                 ConnectionState.waiting) {
//                               return const Center(
//                                   child: CircularProgressIndicator());
//                             }
//                             if (snapshot.hasError) {
//                               return Text(
//                                   'Error loading reviews: ${snapshot.error}');
//                             }
//                             if (!snapshot.hasData) {
//                               return const Text('No reviews data available');
//                             }
//                             final reviews = snapshot.data!;

//                             if (reviews.isEmpty) {
//                               return Container(
//                                 padding: const EdgeInsets.all(16),
//                                 decoration: BoxDecoration(
//                                   color: Theme.of(context)
//                                       .colorScheme
//                                       .surfaceContainerHighest,
//                                   borderRadius: BorderRadius.circular(8),
//                                   border: Border.all(
//                                     color: Theme.of(context)
//                                         .colorScheme
//                                         .outline
//                                         .withOpacity(0.3),
//                                   ),
//                                 ),
//                                 child: Text(
//                                   'No reviews yet. Be the first to review this car!',
//                                   style: Theme.of(context)
//                                       .textTheme
//                                       .bodyMedium
//                                       ?.copyWith(
//                                         color: Theme.of(context)
//                                             .colorScheme
//                                             .onSurfaceVariant,
//                                       ),
//                                 ),
//                               );
//                             }

//                             return Column(
//                               children: reviews
//                                   .map((r) => _buildReviewItem(context, r))
//                                   .toList(),
//                             );
//                           },
//                         ),
//                         const SizedBox(height: 16),
//                         _buildAddReviewCard(context, ad),
//                       ],
//                     ),
//                   ),

//                   const SizedBox(height: 32),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildSpecificationCard(
//     BuildContext context,
//     String label,
//     String value,
//     IconData icon,
//   ) {
//     final colorScheme = Theme.of(context).colorScheme;

//     return Container(
//       margin: const EdgeInsets.only(bottom: 12),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: colorScheme.surface,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: colorScheme.outline),
//       ),
//       child: Row(
//         children: [
//           Icon(
//             icon,
//             color: colorScheme.primary,
//             size: 24,
//           ),
//           const SizedBox(width: 16),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   label,
//                   style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//                         color: colorScheme.onSurfaceVariant,
//                         fontWeight: FontWeight.w500,
//                       ),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   value,
//                   style: Theme.of(context).textTheme.titleMedium?.copyWith(
//                         fontWeight: FontWeight.bold,
//                       ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // Enhanced specification card with modern styling
//   Widget _buildEnhancedSpecificationCard(
//     BuildContext context,
//     String label,
//     String value,
//     IconData icon,
//   ) {
//     final colorScheme = Theme.of(context).colorScheme;

//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: colorScheme.surface,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(
//           color: colorScheme.outline.withValues(alpha: 0.2),
//         ),
//         boxShadow: [
//           BoxShadow(
//             color: colorScheme.primary.withValues(alpha: 0.03),
//             blurRadius: 5,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           Container(
//             padding: const EdgeInsets.all(8),
//             decoration: BoxDecoration(
//               color: colorScheme.primary.withValues(alpha: 0.1),
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: Icon(
//               icon,
//               color: colorScheme.primary,
//               size: 20,
//             ),
//           ),
//           const SizedBox(width: 16),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   label,
//                   style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//                         color: colorScheme.onSurfaceVariant,
//                         fontWeight: FontWeight.w500,
//                       ),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   value,
//                   style: Theme.of(context).textTheme.titleMedium?.copyWith(
//                         fontWeight: FontWeight.bold,
//                         color: colorScheme.onSurface,
//                       ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // Enhanced contact card with modern styling
//   Widget _buildEnhancedContactCard(
//     BuildContext context,
//     String label,
//     String value,
//     IconData icon,
//   ) {
//     final colorScheme = Theme.of(context).colorScheme;

//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: colorScheme.surface,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(
//           color: colorScheme.outline.withValues(alpha: 0.2),
//         ),
//         boxShadow: [
//           BoxShadow(
//             color: colorScheme.primary.withValues(alpha: 0.03),
//             blurRadius: 5,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           Container(
//             padding: const EdgeInsets.all(8),
//             decoration: BoxDecoration(
//               color: colorScheme.primary.withValues(alpha: 0.1),
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: Icon(
//               icon,
//               color: colorScheme.primary,
//               size: 20,
//             ),
//           ),
//           const SizedBox(width: 16),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   label,
//                   style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//                         color: colorScheme.onSurfaceVariant,
//                         fontWeight: FontWeight.w500,
//                       ),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   value,
//                   style: Theme.of(context).textTheme.titleMedium?.copyWith(
//                         fontWeight: FontWeight.bold,
//                         color: colorScheme.onSurface,
//                       ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildContactCard(
//     BuildContext context,
//     String label,
//     String value,
//     IconData icon,
//   ) {
//     final colorScheme = Theme.of(context).colorScheme;

//     return Container(
//       margin: const EdgeInsets.only(bottom: 12),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: colorScheme.surface,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: colorScheme.outline),
//       ),
//       child: Row(
//         children: [
//           Icon(
//             icon,
//             color: colorScheme.primary,
//             size: 24,
//           ),
//           const SizedBox(width: 16),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   label,
//                   style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//                         color: colorScheme.onSurfaceVariant,
//                         fontWeight: FontWeight.w500,
//                       ),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   value,
//                   style: Theme.of(context).textTheme.titleMedium?.copyWith(
//                         fontWeight: FontWeight.bold,
//                       ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildAddReviewCard(BuildContext context, AdModel ad) {
//     final colorScheme = Theme.of(context).colorScheme;
//     final currentUser = FirebaseAuth.instance.currentUser;
//     final isOwner = currentUser != null && ad.userId == currentUser.uid;

//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: colorScheme.surface,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: colorScheme.outline),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             'Add your review',
//             style: Theme.of(context).textTheme.titleMedium?.copyWith(
//                   fontWeight: FontWeight.bold,
//                 ),
//           ),
//           const SizedBox(height: 12),
//           if (isOwner)
//             Text(
//               'You cannot review your own ad.',
//               style: Theme.of(context)
//                   .textTheme
//                   .bodyMedium
//                   ?.copyWith(color: colorScheme.error),
//             )
//           else ...[
//             Row(
//               children: List.generate(5, (index) {
//                 final starIndex = index + 1;
//                 final isSelected = _rating >= starIndex;
//                 return IconButton(
//                   onPressed: () {
//                     setState(() {
//                       _rating = starIndex;
//                     });
//                   },
//                   icon: Icon(
//                     isSelected ? Icons.star : Icons.star_border,
//                     color: isSelected
//                         ? Colors.amber
//                         : Theme.of(context).colorScheme.outline,
//                   ),
//                 );
//               }),
//             ),
//             TextField(
//               controller: _commentController,
//               maxLines: 3,
//               decoration: const InputDecoration(
//                 hintText: 'Share your experience...',
//                 border: OutlineInputBorder(),
//               ),
//             ),
//             const SizedBox(height: 12),
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 onPressed: _submitting
//                     ? null
//                     : () async {
//                         final adId = ad.id;
//                         if (adId == null || adId.isEmpty) return;
//                         if (_rating == 0) {
//                           ScaffoldMessenger.of(context).showSnackBar(
//                             const SnackBar(
//                                 content: Text('Please select a star rating')),
//                           );
//                           return;
//                         }
//                         setState(() {
//                           _submitting = true;
//                         });
//                         try {
//                           await _reviewService.addReview(
//                             adId: adId,
//                             rating: _rating,
//                             comment: _commentController.text,
//                           );
//                           _commentController.clear();
//                           setState(() {
//                             _rating = 0;
//                           });
//                           ScaffoldMessenger.of(context).showSnackBar(
//                             const SnackBar(content: Text('Review submitted')),
//                           );
//                         } catch (e) {
//                           ScaffoldMessenger.of(context).showSnackBar(
//                             SnackBar(content: Text('Failed: $e')),
//                           );
//                         } finally {
//                           if (mounted) {
//                             setState(() {
//                               _submitting = false;
//                             });
//                           }
//                         }
//                       },
//                 child: _submitting
//                     ? const SizedBox(
//                         height: 20,
//                         width: 20,
//                         child: CircularProgressIndicator(strokeWidth: 2),
//                       )
//                     : const Text('Submit Review'),
//               ),
//             ),
//           ]
//         ],
//       ),
//     );
//   }

//   Widget _buildReviewItem(BuildContext context, ReviewModel review) {
//     final colorScheme = Theme.of(context).colorScheme;
//     return Container(
//       margin: const EdgeInsets.only(bottom: 12),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: colorScheme.surface,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: colorScheme.outline),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(
//                 review.userName ?? 'Anonymous',
//                 style: Theme.of(context).textTheme.titleMedium?.copyWith(
//                       fontWeight: FontWeight.bold,
//                     ),
//               ),
//               Row(
//                 children: List.generate(5, (index) {
//                   final starIndex = index + 1;
//                   final filled = review.rating >= starIndex;
//                   return Icon(
//                     filled ? Icons.star : Icons.star_border,
//                     color: filled ? Colors.amber : colorScheme.outline,
//                     size: 18,
//                   );
//                 }),
//               )
//             ],
//           ),
//           const SizedBox(height: 8),
//           Text(
//             review.comment,
//             style: Theme.of(context).textTheme.bodyLarge,
//           ),
//           const SizedBox(height: 8),
//           Text(
//             _formatDate(review.createdAt),
//             style: Theme.of(context)
//                 .textTheme
//                 .bodySmall
//                 ?.copyWith(color: colorScheme.onSurfaceVariant),
//           ),
//         ],
//       ),
//     );
//   }

//   String _formatDate(DateTime date) {
//     return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
//   }

//   // Trust badge widget
//   Widget _buildTrustBadge(BuildContext context) {
//     final colorScheme = Theme.of(context).colorScheme;

//     return StreamBuilder<DocumentSnapshot>(
//       stream: FirebaseFirestore.instance
//           .collection('users')
//           .doc(widget.ad.userId)
//           .snapshots(),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return Container(
//             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//             decoration: BoxDecoration(
//               color: colorScheme.surfaceContainerHighest,
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: const Text('...'),
//           );
//         }

//         if (!snapshot.hasData || !snapshot.data!.exists) {
//           return const SizedBox.shrink();
//         }

//         final userData = snapshot.data!.data() as Map<String, dynamic>?;
//         final trustLevel = userData?['trustLevel'] as String?;

//         if (trustLevel == null ||
//             !['Bronze', 'Silver', 'Gold'].contains(trustLevel)) {
//           return const SizedBox.shrink();
//         }

//         Color badgeColor;
//         switch (trustLevel) {
//           case 'Gold':
//             badgeColor = Colors.amber;
//             break;
//           case 'Silver':
//             badgeColor = Colors.grey[400]!;
//             break;
//           case 'Bronze':
//             badgeColor = Colors.brown[400]!;
//             break;
//           default:
//             badgeColor = colorScheme.primary;
//         }

//         return Container(
//           padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//           decoration: BoxDecoration(
//             color: badgeColor.withValues(alpha: 0.1),
//             borderRadius: BorderRadius.circular(12),
//             border: Border.all(color: badgeColor),
//           ),
//           child: Text(
//             trustLevel.toUpperCase(),
//             style: TextStyle(
//               color: badgeColor,
//               fontWeight: FontWeight.bold,
//               fontSize: 12,
//             ),
//           ),
//         );
//       },
//     );
//   }
// }

//  above one is also correct------------
//  new version with phone call and messages---------------------------------
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/ad_model.dart';
import '../services/review_service.dart';
import '../models/review_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  // image page controller & index
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;

  // Save/Bookmark state
  bool _isSaved = false;
  bool _loadingSavedState = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _trackView();
      _loadSavedState();
    });

    _pageController.addListener(() {
      final newIndex = _pageController.page?.round() ?? 0;
      if (newIndex != _currentImageIndex) {
        setState(() {
          _currentImageIndex = newIndex;
        });
      }
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedState() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || widget.ad.id == null) {
      setState(() {
        _isSaved = false;
        _loadingSavedState = false;
      });
      return;
    }

    try {
      final favDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .doc(widget.ad.id)
          .get();

      setState(() {
        _isSaved = favDoc.exists;
        _loadingSavedState = false;
      });
    } catch (e) {
      setState(() {
        _isSaved = false;
        _loadingSavedState = false;
      });
    }
  }

  Future<void> _trackView() async {
    final adId = widget.ad.id;
    if (adId == null || adId.isEmpty) return;

    final statsRef = FirebaseFirestore.instance
        .collection('ads')
        .doc(adId)
        .collection('insights')
        .doc('stats');

    final eventsRef = FirebaseFirestore.instance
        .collection('ads')
        .doc(adId)
        .collection('insights')
        .doc('events')
        .collection('items');

    await statsRef.set({
      'views': FieldValue.increment(1),
      'lastViewed': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await eventsRef.add({
      'type': 'view',
      'ts': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _trackContactClick() async {
    final adId = widget.ad.id;
    if (adId == null || adId.isEmpty) return;

    final statsRef = FirebaseFirestore.instance
        .collection('ads')
        .doc(adId)
        .collection('insights')
        .doc('stats');

    final eventsRef = FirebaseFirestore.instance
        .collection('ads')
        .doc(adId)
        .collection('insights')
        .doc('events')
        .collection('items');

    await statsRef.set({
      'contacts': FieldValue.increment(1),
    }, SetOptions(merge: true));

    await eventsRef.add({
      'type': 'contact',
      'ts': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _trackSaveClick() async {
    final adId = widget.ad.id;
    if (adId == null || adId.isEmpty) return;

    final statsRef = FirebaseFirestore.instance
        .collection('ads')
        .doc(adId)
        .collection('insights')
        .doc('stats');

    final eventsRef = FirebaseFirestore.instance
        .collection('ads')
        .doc(adId)
        .collection('insights')
        .doc('events')
        .collection('items');

    await statsRef.set({
      'saves': FieldValue.increment(1),
    }, SetOptions(merge: true));

    await eventsRef.add({
      'type': 'save',
      'ts': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _toggleSave() async {
    final user = FirebaseAuth.instance.currentUser;
    final adId = widget.ad.id;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to save this ad.')),
      );
      return;
    }
    if (adId == null || adId.isEmpty) return;

    setState(() {
      _loadingSavedState = true;
    });

    final favRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .doc(adId);

    try {
      final snapshot = await favRef.get();
      if (snapshot.exists) {
        await favRef.delete();
        setState(() => _isSaved = false);
      } else {
        await favRef.set({
          'adId': adId,
          'savedAt': FieldValue.serverTimestamp(),
          'title': widget.ad.title,
          'image':
              widget.ad.imageUrls != null && widget.ad.imageUrls!.isNotEmpty
                  ? widget.ad.imageUrls!.first
                  : null,
        });
        setState(() => _isSaved = true);
        await _trackSaveClick();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update favorites: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loadingSavedState = false;
        });
      }
    }
  }

  Future<void> _onCallPressed() async {
    final phone = widget.ad.phone;
    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone number not available')),
      );
      return;
    }

    await _trackContactClick();

    final Uri telUri = Uri(scheme: 'tel', path: phone);
    try {
      if (await canLaunchUrl(telUri)) {
        await launchUrl(telUri);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open dialer')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening dialer: $e')),
      );
    }
  }

  Future<void> _onSmsPressed() async {
    final phone = widget.ad.phone;
    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone number not available')),
      );
      return;
    }

    await _trackContactClick();

    final Uri smsUri = Uri(scheme: 'sms', path: phone);
    try {
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open SMS app')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening SMS app: $e')),
      );
    }
  }

  Future<void> _onWhatsappPressed() async {
    final phoneRaw = widget.ad.phone;
    if (phoneRaw == null || phoneRaw.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone number not available')),
      );
      return;
    }

    await _trackContactClick();

    final phone = phoneRaw.replaceAll(RegExp(r'\D'), '');
    final uriApp = Uri.parse(
        'whatsapp://send?phone=$phone&text=${Uri.encodeComponent("Hi, I saw your ad on the app.")}');
    final uriWeb = Uri.parse(
        'https://wa.me/$phone?text=${Uri.encodeComponent("Hi, I saw your ad on the app.")}');

    try {
      if (await canLaunchUrl(uriApp)) {
        await launchUrl(uriApp);
      } else if (await canLaunchUrl(uriWeb)) {
        await launchUrl(uriWeb, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open WhatsApp')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening WhatsApp: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final ad = widget.ad;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Car Details'),
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.primary,
                colorScheme.primary.withValues(alpha: 0.8),
              ],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                  if (ad.imageUrls != null && ad.imageUrls!.isNotEmpty)
                    PageView.builder(
                      controller: _pageController,
                      itemCount: ad.imageUrls!.length,
                      itemBuilder: (context, index) {
                        return Container(
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            borderRadius: BorderRadius.only(
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
                  Positioned(
                    top: 20,
                    right: 20,
                    child: _buildTrustBadge(context),
                  ),
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
            Container(
              margin: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                    ),
                  ),
                  const SizedBox(height: 32),
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
                                  colorScheme.primary,
                                  colorScheme.primary.withValues(alpha: 0.8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ElevatedButton.icon(
                              onPressed: _onCallPressed,
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
                        const SizedBox(width: 12),
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
                              onPressed: _onSmsPressed,
                              icon: const Icon(Icons.message),
                              label: const Text('SMS'),
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
                        const SizedBox(width: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF25D366),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            onPressed: _onWhatsappPressed,
                            icon: Image.asset(
                              'assets/icons/whatsapp.png',
                              width: 28,
                              height: 28,
                              color: Colors.white,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.chat,
                                  color: Colors.white,
                                );
                              },
                            ),
                            tooltip: 'WhatsApp',
                          ),
                        ),
                        const SizedBox(width: 8),
                        _loadingSavedState
                            ? const SizedBox(
                                width: 48,
                                height: 48,
                                child: Center(
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : Container(
                                decoration: BoxDecoration(
                                  color: _isSaved
                                      ? Colors.green.withValues(alpha: 0.1)
                                      : colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _isSaved
                                        ? Colors.green
                                        : colorScheme.outline,
                                  ),
                                ),
                                child: IconButton(
                                  onPressed: _toggleSave,
                                  icon: Icon(
                                    _isSaved
                                        ? Icons.bookmark
                                        : Icons.bookmark_border,
                                    color: _isSaved
                                        ? Colors.green
                                        : colorScheme.onSurface,
                                  ),
                                  tooltip: _isSaved ? 'Unsave' : 'Save',
                                ),
                              ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
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
                                  color: colorScheme.surface,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: colorScheme.outline
                                        .withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Text(
                                  'No reviews yet. Be the first to review this car!',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
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
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
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
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.error,
                  ),
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
                    color: isSelected ? Colors.amber : colorScheme.outline,
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
              child: ElevatedButton(
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
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
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
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

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
