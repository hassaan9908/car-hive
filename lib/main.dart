import 'package:carhive/pages/homepage.dart';
import 'package:carhive/pages/startup_page.dart';
import 'package:carhive/auth/loginscreen.dart';
import 'package:carhive/pages/mutualinvestment.dart';
import 'package:carhive/pages/myads.dart';
import 'package:carhive/pages/chat.dart';
import 'package:carhive/pages/profilepage.dart';
import 'package:carhive/pages/upload.dart';
import 'package:carhive/pages/car_details_page.dart';
import 'package:carhive/pages/map_view_screen.dart';
import 'package:carhive/models/ad_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme/light_theme.dart';
import 'theme/dark_theme.dart';
import 'theme/theme_provider.dart';
import 'auth/auth_provider.dart';
import 'firebase_options.dart';
import 'pages/admin/admin_main.dart';
import 'providers/admin_provider.dart';
import 'providers/search_provider.dart';
import 'providers/content_provider.dart'; // Add ContentProvider import
import 'pages/admin/admin_debug_page.dart';
import 'widgets/gradient_scaffold_wrapper.dart';
import 'pages/blog_list_page.dart';
import 'pages/video_list_page.dart';
import 'pages/help_page.dart';
import 'pages/chat_detail_page.dart';

/// Custom route generator that maintains gradient during transitions
class GradientPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  GradientPageRoute({
    required this.page,
    RouteSettings? settings,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          settings: settings,
          transitionDuration: const Duration(milliseconds: 200),
          reverseTransitionDuration: const Duration(milliseconds: 200),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Use fade transition to prevent glitches
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with error handling
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully');
  } catch (e) {
    print('Firebase initialization failed: $e');
    // Continue without Firebase for now
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        ChangeNotifierProvider(create: (_) => SearchProvider()),
        ChangeNotifierProvider(
            create: (_) => ContentProvider()), // Add ContentProvider
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'CarHive',
            theme: lightTheme,
            darkTheme: darkTheme,
            themeMode: themeProvider.themeMode,
            builder: (context, child) {
              if (child == null) return const SizedBox();
              // Use RepaintBoundary to prevent glitches during navigation
              return RepaintBoundary(
                child: GradientScaffoldWrapper(
                  child: child,
                ),
              );
            },
            home: const AppInitializer(),
            debugShowCheckedModeBanner: false,
            routes: {
              '/startup': (context) => const StartupPage(),
              '/home': (context) => const HomepageWithAdminInit(),
              '/myads': (context) => const Myads(),
              '/profile': (context) => const Profilepage(),
              '/help': (context) => const HelpPage(),
              '/notifications': (context) => const Chat(),
              '/chat-detail': (context) {
                final args = ModalRoute.of(context)?.settings.arguments;
                if (args is Map<String, dynamic>) {
                  return ChatDetailPage(
                    conversationId: args['conversationId'] ?? '',
                    otherUserId: args['otherUserId'] ?? '',
                    otherUserName: args['otherUserName'] ?? 'User',
                  );
                }
                return const Scaffold(
                  body: Center(child: Text('Invalid chat parameters')),
                );
              },
              '/investment': (context) => const Mutualinvestment(),
              '/upload': (context) => const Upload(),
              'loginscreen': (context) => const Loginscreen(),
              '/admin': (context) => const AdminMain(),
              '/admin-debug': (context) => const AdminDebugPage(),
              '/blogs': (context) => const BlogListPage(), // Add this route
              '/videos': (context) => const VideoListPage(), // Add this route
              '/car-details': (context) {
                final args = ModalRoute.of(context)?.settings.arguments;
                if (args is AdModel) {
                  return CarDetailsPage(ad: args);
                }
                // Graceful fallback when navigated directly without arguments
                return Scaffold(
                  appBar: AppBar(title: const Text('Car Details')),
                  body: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.directions_car,
                            size: 64, color: Colors.redAccent),
                        const SizedBox(height: 16),
                        const Text('No car data provided.',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () =>
                              Navigator.pushReplacementNamed(context, '/home'),
                          child: const Text('Go Home'),
                        ),
                      ],
                    ),
                  ),
                );
              },
              '/map-view': (context) => const MapViewScreen(),
            },
            onGenerateRoute: (settings) {
              // Handle routes that need custom transitions
              if (settings.name == '/car-details') {
                final ad = settings.arguments as AdModel;
                return GradientPageRoute(
                  page: CarDetailsPage(ad: ad),
                  settings: settings,
                );
              }
              return null; // Let MaterialApp handle other routes
            },
          );
        },
      ),
    );
  }
}

// App Initializer - handles startup page logic
class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _isInitialized = false;
  bool _hasSeenStartup = false;

  @override
  void initState() {
    super.initState();
    _checkStartupStatus();
  }

  Future<void> _checkStartupStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _hasSeenStartup = prefs.getBool('has_seen_startup') ?? false;

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      print('Error checking startup status: $e');
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // If user has seen startup page before, go directly to homepage
    if (_hasSeenStartup) {
      return const HomepageWithAdminInit();
    }

    // Show startup page for first-time users
    return const StartupPage();
  }
}

// Homepage with admin initialization
class HomepageWithAdminInit extends StatefulWidget {
  const HomepageWithAdminInit({super.key});

  @override
  State<HomepageWithAdminInit> createState() => _HomepageWithAdminInitState();
}

class _HomepageWithAdminInitState extends State<HomepageWithAdminInit> {
  @override
  void initState() {
    super.initState();
    // Wait for main auth to be ready before initializing admin
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAdminWhenAuthReady();
    });
  }

  Future<void> _initializeAdminWhenAuthReady() async {
    try {
      // Wait a bit for Firebase Auth to initialize
      await Future.delayed(const Duration(milliseconds: 500));

      // Check if we have a context and user is logged in
      if (mounted) {
        final authProvider = context.read<AuthProvider>();
        print(
            'HomepageWithAdminInit: Auth provider isLoggedIn: ${authProvider.isLoggedIn}');

        if (authProvider.isLoggedIn) {
          print(
              'HomepageWithAdminInit: User is logged in, initializing admin provider...');
          await context.read<AdminProvider>().initialize();
        } else {
          print(
              'HomepageWithAdminInit: No user logged in, skipping admin initialization');
        }

        // Listen for auth state changes
        authProvider.addListener(() {
          if (mounted && authProvider.isLoggedIn) {
            print(
                'HomepageWithAdminInit: Auth state changed, user logged in, initializing admin...');
            context.read<AdminProvider>().initialize();
          } else if (mounted && !authProvider.isLoggedIn) {
            print(
                'HomepageWithAdminInit: Auth state changed, user logged out, clearing admin data...');
            // Clear admin data when user logs out
            final adminProvider = context.read<AdminProvider>();
            adminProvider.adminLogout();
          }
        });
      }
    } catch (e) {
      print('HomepageWithAdminInit: Error during admin initialization: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Homepage();
  }
}
