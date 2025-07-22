import 'package:carhive/pages/homepage.dart';
import 'package:carhive/pages/mutualinvestment.dart';
import 'package:carhive/pages/myads.dart';
import 'package:carhive/pages/notifications.dart';
import 'package:carhive/pages/profilepage.dart';
import 'package:carhive/pages/upload.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
      ),
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
  }
}
