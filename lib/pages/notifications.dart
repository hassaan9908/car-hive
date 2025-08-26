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
                'Chats',
                style: TextStyle(
                  color: Colors.white
                ),
                ),
              backgroundColor: Theme.of(context).colorScheme.primary,
              centerTitle: true,
      ),
      body: Center(
        child: Text('Chats'),
      ),
    );
  }
}