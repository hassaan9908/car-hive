import 'package:flutter/material.dart';

class CarTabs extends StatelessWidget {
  const CarTabs({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: TabBar(
              indicator: BoxDecoration(), // Removes the underline/white line
              labelColor: Color.fromARGB(255, 35, 38, 68),
              labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              unselectedLabelColor: Colors.grey,
              unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal, fontSize: 16),
              tabs: [
                Tab(text: 'Used Cars'),
                Tab(text: 'New Cars'),
              ],
            ),
          ),
          SizedBox(height: 16),
          SizedBox(
            height: 300, // Fixed height for TabBarView
            child: TabBarView(
              children: [
                Center(child: Text('Used Cars List Placeholder')),
                Center(child: Text('New Cars List Placeholder')),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 