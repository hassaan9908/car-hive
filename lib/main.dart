import 'package:carhive/pages/homepage.dart';
import 'package:carhive/pages/mutualinvestment.dart';
import 'package:carhive/pages/myads.dart';
import 'package:carhive/pages/notifications.dart';
import 'package:carhive/pages/profilepage.dart';
import 'package:carhive/pages/upload.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/light_theme.dart';
import 'theme/dark_theme.dart';
import 'theme/theme_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
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
              '/upload' : (context) => const Upload()
            },
          );
        },
      ),
    );
  }
}
