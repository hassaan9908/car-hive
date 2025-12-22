import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/ad_model.dart';
import '../services/nearby_search_service.dart';
import '../services/custom_marker_service.dart';
import 'car_details_page.dart';

class MapViewScreen extends StatefulWidget {
  const MapViewScreen({super.key});

  @override
  State<MapViewScreen> createState() => _MapViewScreenState();
}

class _MapViewScreenState extends State<MapViewScreen> {
  GoogleMapController? _mapController;
  Position? _userPosition;
  bool _isLoadingLocation = true;
  bool _hasLocationPermission = false;
  bool _mapError = false;
  String? _mapErrorMessage;
  double _searchRadius = 10.0; // Default 10km
  final NearbySearchService _nearbySearchService = NearbySearchService();
  List<AdModel> _nearbyAds = [];
  bool _isLoadingAds = false;
  Set<Marker> _markers = {};
  AdModel? _selectedAd;
  bool _isCreatingMarkers = false;
  bool _isMapInitialized = false; // Track if map has been properly initialized

  @override
  void initState() {
    super.initState();
    // Check if user is logged in
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      // Redirect to login if not authenticated
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, 'loginscreen');
        }
      });
      return;
    }
    _requestLocationPermission();
  }

  Future<void> _requestLocationPermission() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location services are disabled. Please enable them.'),
            ),
          );
        }
        setState(() {
          _isLoadingLocation = false;
          _hasLocationPermission = false;
        });
        return;
      }

      // Request location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Location permissions are denied.'),
              ),
            );
          }
          setState(() {
            _isLoadingLocation = false;
            _hasLocationPermission = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Location permissions are permanently denied. Please enable them in settings.',
              ),
            ),
          );
        }
        setState(() {
          _isLoadingLocation = false;
          _hasLocationPermission = false;
        });
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _userPosition = position;
        _hasLocationPermission = true;
        _isLoadingLocation = false;
      });

      // Move camera to user position
      _moveCameraToUserPosition();

      // Load nearby ads
      _loadNearbyAds();
    } catch (e) {
      print('Error getting location: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error getting location: $e'),
          ),
        );
      }
      setState(() {
        _isLoadingLocation = false;
        _hasLocationPermission = false;
      });
    }
  }

  void _moveCameraToUserPosition() {
    if (_mapController != null && _userPosition != null) {
      try {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(_userPosition!.latitude, _userPosition!.longitude),
            13.0,
          ),
        );
      } catch (e) {
        print('Error moving camera: $e');
        // If map controller fails, it might be a billing/API error
        if (kIsWeb && mounted) {
          setState(() {
            _mapError = true;
            _mapErrorMessage = 'Google Maps API error. Please check:\n'
                '1. Billing is enabled in Google Cloud Console\n'
                '2. Maps JavaScript API is enabled\n'
                '3. API key is valid and has proper permissions';
          });
        }
      }
    }
  }

  Future<void> _loadNearbyAds() async {
    if (_userPosition == null) return;

    setState(() {
      _isLoadingAds = true;
    });

    try {
      final ads = await _nearbySearchService.searchNearby(
        userLat: _userPosition!.latitude,
        userLng: _userPosition!.longitude,
        radiusKm: _searchRadius,
      );

      setState(() {
        _nearbyAds = ads;
        _isLoadingAds = false;
      });

      await _updateMarkers();
    } catch (e) {
      print('Error loading nearby ads: $e');
      setState(() {
        _isLoadingAds = false;
      });
    }
  }

  // Validate coordinates are within valid ranges
  bool _isValidCoordinate(double? value, double min, double max) {
    return value != null && value >= min && value <= max;
  }

  // Extract and validate coordinates from ad
  LatLng? _extractCoordinates(AdModel ad) {
    if (ad.locationCoordinates == null) {
      print('Ad ${ad.id}: No locationCoordinates');
      return null;
    }

    final coords = ad.locationCoordinates!;
    final lat = coords['lat'];
    final lng = coords['lng'];

    // Check for null values
    if (lat == null || lng == null) {
      print('Ad ${ad.id}: Null coordinates: lat=$lat, lng=$lng');
      return null;
    }

    // Validate latitude (-90 to 90)
    if (!_isValidCoordinate(lat, -90.0, 90.0)) {
      print('Ad ${ad.id}: Invalid latitude: $lat');
      return null;
    }

    // Validate longitude (-180 to 180)
    if (!_isValidCoordinate(lng, -180.0, 180.0)) {
      print('Ad ${ad.id}: Invalid longitude: $lng');
      return null;
    }

    // Check if coordinates are swapped (common mistake: lng/lat instead of lat/lng)
    // Pakistan coordinates: lat ~24-37, lng ~60-75
    // If we see lat > 60 or lng < 30, they might be swapped
    if (lat > 60.0 || lng < 30.0) {
      // Check if swapping makes more sense
      if (_isValidCoordinate(lng, -90.0, 90.0) && _isValidCoordinate(lat, -180.0, 180.0)) {
        print('Ad ${ad.id}: Coordinates appear swapped, correcting: lat=$lat, lng=$lng -> lat=$lng, lng=$lat');
        return LatLng(lng, lat); // Swap them
      }
    }

    return LatLng(lat, lng);
  }

  Future<void> _updateMarkers() async {
    if (_isCreatingMarkers) return; // Prevent multiple simultaneous marker creation
    
    setState(() {
      _isCreatingMarkers = true;
    });

    final Set<Marker> newMarkers = {};
    int validMarkers = 0;
    int invalidMarkers = 0;

    // Create markers with custom thumbnails
    for (final ad in _nearbyAds) {
      // Extract and validate coordinates
      final position = _extractCoordinates(ad);
      if (position == null) {
        invalidMarkers++;
        continue;
      }

      validMarkers++;

      try {
        // Create custom marker with car thumbnail
        final BitmapDescriptor customIcon = await CustomMarkerService.createCarMarker(
          imageUrl: ad.imageUrls?.isNotEmpty == true ? ad.imageUrls![0] : null,
          price: ad.price,
          title: ad.title.isNotEmpty ? ad.title : ad.carBrand,
        );

        newMarkers.add(
          Marker(
            markerId: MarkerId(ad.id ?? '${position.latitude}_${position.longitude}'),
            position: position,
            infoWindow: InfoWindow(
              title: ad.title.isNotEmpty ? ad.title : (ad.carBrand ?? 'Car'),
              snippet: 'PKR ${ad.price} • ${ad.location}',
            ),
            onTap: () {
              setState(() {
                _selectedAd = ad;
              });
            },
            icon: customIcon,
          ),
        );
      } catch (e) {
        print('Error creating custom marker for ad ${ad.id}: $e');
        // Fallback to simple marker
        try {
          final BitmapDescriptor fallbackIcon = await CustomMarkerService.createSimpleMarker(
            color: const Color(0xFFf48c25),
            text: ad.price.length > 6 ? '${ad.price.substring(0, 4)}K' : ad.price,
          );

          newMarkers.add(
            Marker(
              markerId: MarkerId(ad.id ?? '${position.latitude}_${position.longitude}'),
              position: position,
              infoWindow: InfoWindow(
                title: ad.title.isNotEmpty ? ad.title : (ad.carBrand ?? 'Car'),
                snippet: 'PKR ${ad.price} • ${ad.location}',
              ),
              onTap: () {
                setState(() {
                  _selectedAd = ad;
                });
              },
              icon: fallbackIcon,
            ),
          );
        } catch (fallbackError) {
          print('Error creating fallback marker for ad ${ad.id}: $fallbackError');
          invalidMarkers++;
        }
      }
    }

    print('Map markers: $validMarkers valid, $invalidMarkers invalid out of ${_nearbyAds.length} ads');

    if (mounted) {
      setState(() {
        _markers = newMarkers;
        _isCreatingMarkers = false;
      });
    }
  }

  @override
  void dispose() {
    // On web, the GoogleMap widget handles controller disposal internally
    // Manually disposing can cause "buildView" errors due to async lifecycle
    // On mobile platforms, we can safely dispose manually
    if (!kIsWeb && _mapController != null && _isMapInitialized) {
      try {
        _mapController!.dispose();
      } catch (e) {
        // Ignore disposal errors if map wasn't properly initialized
        if (kDebugMode) {
          print('Error disposing map controller: $e');
        }
      }
    }
    // Always clear the reference to prevent memory leaks
    _mapController = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Check authentication again in build to handle logout during session
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Map View'),
          backgroundColor: Colors.transparent,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.login, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'Please login to access Map View',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, 'loginscreen');
                },
                child: const Text('Go to Login'),
              ),
            ],
          ),
        ),
      );
    }

    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Map View'),
        backgroundColor: Colors.transparent,
        actions: [
          if (_userPosition != null)
            IconButton(
              icon: const Icon(Icons.my_location),
              onPressed: _moveCameraToUserPosition,
              tooltip: 'My Location',
            ),
        ],
      ),
      body: Stack(
        children: [
          // Google Map
          if (_isLoadingLocation)
            const Center(child: CircularProgressIndicator())
          else if (!_hasLocationPermission)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.location_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('Location permission required'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _requestLocationPermission,
                    child: const Text('Request Permission'),
                  ),
                ],
              ),
            )
          else if (_mapError)
            // Show error message when map fails to load
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Map Unavailable',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _mapErrorMessage ??
                          'Google Maps requires billing to be enabled in your Google Cloud project.\n\n'
                          'To fix this:\n'
                          '1. Go to Google Cloud Console\n'
                          '2. Enable billing for your project\n'
                          '3. Enable "Maps JavaScript API"\n'
                          '4. Ensure your API key has proper permissions',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _mapError = false;
                          _mapErrorMessage = null;
                        });
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          else
            GoogleMap(
              key: const ValueKey('google_map'), // Stable key for proper lifecycle management
              initialCameraPosition: CameraPosition(
                target: _userPosition != null
                    ? LatLng(_userPosition!.latitude, _userPosition!.longitude)
                    : const LatLng(24.8607, 67.0011), // Default to Karachi
                zoom: 13.0,
              ),
              onMapCreated: (GoogleMapController controller) {
                if (!mounted) return; // Check if widget is still mounted
                _mapController = controller;
                _isMapInitialized = true; // Mark map as initialized
                if (_userPosition != null) {
                  _moveCameraToUserPosition();
                }
                // Map created successfully, clear any errors
                if (_mapError && mounted) {
                  setState(() {
                    _mapError = false;
                    _mapErrorMessage = null;
                  });
                }
              },
              markers: _markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: true,
              // MapType may not be fully supported on web
              mapType: kIsWeb ? MapType.normal : MapType.normal,
            ),

          // Radius Slider
          if (_hasLocationPermission && _userPosition != null)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Search Radius: ${_searchRadius.toStringAsFixed(1)} km',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          if (_isLoadingAds || _isCreatingMarkers)
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          else
                            Text(
                              '${_nearbyAds.length} listings',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Slider(
                        value: _searchRadius,
                        min: 1.0,
                        max: 50.0,
                        divisions: 49,
                        label: '${_searchRadius.toStringAsFixed(1)} km',
                        onChanged: (value) {
                          setState(() {
                            _searchRadius = value;
                          });
                          _loadNearbyAds();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Selected Ad Bottom Sheet
          if (_selectedAd != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildAdBottomSheet(context, _selectedAd!),
            ),
        ],
      ),
    );
  }

  Widget _buildAdBottomSheet(BuildContext context, AdModel ad) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 100,
                    height: 75,
                    color: colorScheme.surfaceContainerHighest,
                    child: (ad.imageUrls != null && ad.imageUrls!.isNotEmpty)
                        ? CachedNetworkImage(
                            imageUrl: ad.imageUrls![0],
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            errorWidget: (context, url, error) => Icon(
                              Icons.car_rental,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          )
                        : Icon(
                            Icons.car_rental,
                            size: 40,
                            color: colorScheme.onSurfaceVariant,
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ad.title.isNotEmpty
                            ? ad.title
                            : (ad.carBrand ?? 'Car'),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'PKR ${ad.price}',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 16,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              ad.location,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Close button
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _selectedAd = null;
                    });
                  },
                ),
              ],
            ),
          ),
          // View Details button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CarDetailsPage(ad: ad),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('View Full Details'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
