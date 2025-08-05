import 'package:carhive/pages/homepage.dart';
import 'package:carhive/auth/loginscreen.dart';
import 'package:carhive/pages/mutualinvestment.dart';
import 'package:carhive/pages/myads.dart';
import 'package:carhive/pages/notifications.dart';
import 'package:carhive/pages/profilepage.dart';
import 'package:carhive/pages/upload.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'theme/light_theme.dart';
import 'theme/dark_theme.dart';
import 'theme/theme_provider.dart';
import 'auth/auth_provider.dart';
import 'firebase_options.dart';

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
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'Flutter Demo',
            theme: lightTheme,
            darkTheme: darkTheme,
            themeMode: themeProvider.themeMode,
            home: const Homepage(),
            debugShowCheckedModeBanner: false,
            routes: {
              '/myads' : (context) => const Myads(),
              '/profile' : (context) => const Profilepage(),
              '/notifications' : (context) => const Notifications(),
              '/investment' : (context) => const Mutualinvestment(), 
              '/upload' : (context) => const Upload(),
              'loginscreen' : (context) => const Loginscreen()
            },
          );
        },
      ),
    );
  }
}
