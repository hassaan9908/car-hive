import 'package:flutter/material.dart';

class Chat extends StatefulWidget {
  const Chat({super.key});

  @override
  State<Chat> createState() => _ChatState();
}

class _ChatState extends State<Chat> {
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
    );;
  }
}