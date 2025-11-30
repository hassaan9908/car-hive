import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'providers/admin_provider.dart';
import 'providers/content_provider.dart'; // Add ContentProvider import
import 'pages/homepage.dart';
import 'pages/admin/admin_main.dart';
import 'pages/blog_list_page.dart';
import 'pages/video_list_page.dart';
import 'pages/blog_detail_page.dart';
import 'pages/video_detail_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Your existing providers
        // ChangeNotifierProvider(create: (_) => AuthProvider()),
        // ChangeNotifierProvider(create: (_) => YourOtherProvider()),
        
        // Admin provider
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        ChangeNotifierProvider(create: (_) => ContentProvider()), // Add ContentProvider
      ],
      child: MaterialApp(
        title: 'CarHive',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const Homepage(),
          '/myads': (context) => const Homepage(), // Replace with your actual pages
          '/upload': (context) => const Homepage(), // Replace with your actual pages
          '/investment': (context) => const Homepage(), // Replace with your actual pages
          '/profile': (context) => const Homepage(), // Replace with your actual pages
          '/notifications': (context) => const Homepage(), // Replace with your actual pages
          '/blogs': (context) => const BlogListPage(), // Add this route
          '/videos': (context) => const VideoListPage(), // Add this route
          
          // Admin routes
          '/admin': (context) => const AdminMain(),
          '/admin/login': (context) => const AdminMain(),
          '/admin/dashboard': (context) => const AdminMain(),
        },
      ),
    );
  }
}

// Example of how to add an admin access button to your homepage
class HomepageWithAdminAccess extends StatelessWidget {
  const HomepageWithAdminAccess({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CarHive'),
        actions: [
          // Add admin access button for web
          if (kIsWeb)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings),
              onPressed: () {
                Navigator.pushNamed(context, '/admin');
              },
              tooltip: 'Admin Panel',
            ),
          IconButton(
            icon: const Icon(Icons.chat),
            onPressed: () {
              Navigator.pushNamed(context, '/notifications');
            },
          ),
        ],
      ),
      body: const Homepage(),
    );
  }
}
