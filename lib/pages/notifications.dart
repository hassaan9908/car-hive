import 'package:flutter/material.dart';

class Notifications extends StatefulWidget {
  const Notifications({super.key});

  @override
  State<Notifications> createState() => _NotificationsState();
}

class _NotificationsState extends State<Notifications> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
                'Notifications',
                style: TextStyle(
                  color: Colors.white
                ),
                ),
              backgroundColor: Color.fromARGB(255, 132, 33, 156),
              centerTitle: true,
      ),
      body: Center(
        child: Text('Notifications'),
      ),
    );
  }
}