import 'package:carhive/ads/basic&carinfobycarhive.dart';
import 'package:carhive/ads/postadcar.dart';
import 'package:flutter/material.dart';
import '../components/custom_bottom_nav.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Upload extends StatelessWidget {
  const Upload({super.key});

  static const int _selectedIndex = 2;
  static const List<String> _navRoutes = [
    '/',
    '/myads',
    '/upload',
    '/investment',
    '/profile'
  ];

  void _onTabSelected(BuildContext context, int index) {
    if (_selectedIndex == index) return;
    if (index == 0) {
      Navigator.pushNamedAndRemoveUntil(
          context, _navRoutes[0], (route) => false);
    } else {
      Navigator.pushReplacementNamed(context, _navRoutes[index]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return WillPopScope(
      onWillPop: () async {
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          title: const Text("Choose a plan"),
        ),
        body: currentUser == null
            ? _buildLoginPrompt(context)
            : _buildUploadOptions(context),
        bottomNavigationBar: CustomBottomNav(
          selectedIndex: _selectedIndex,
          onTabSelected: (index) => _onTabSelected(context, index),
          onFabPressed: () {
            if (_selectedIndex != 2) {
              Navigator.pushReplacementNamed(context, _navRoutes[2]);
            }
          },
        ),
      ),
    );
  }

  Widget _buildLoginPrompt(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.login, size: 64, color: colorScheme.onSurfaceVariant),
          SizedBox(height: 16),
          Text(
            'Please login to upload ads',
            style: TextStyle(
              fontSize: 18,
              color: colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, 'loginscreen');
            },
            child: Text('Login'),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadOptions(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Text(
              "How do you want to sell your car?",
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(5),
            child: Container(
              width: double.infinity,
              height: 200,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colorScheme.outline),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Text and Button Column
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Sell It Myself!",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(Icons.check, color: Colors.green, size: 18),
                            SizedBox(width: 5),
                            Text(
                              "Post an ad in 2 minutes",
                              style: TextStyle(color: colorScheme.onSurface),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Icon(Icons.check, color: Colors.green, size: 18),
                            SizedBox(width: 5),
                            Text(
                              "20 million users",
                              style: TextStyle(color: colorScheme.onSurface),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Icon(Icons.check, color: Colors.green, size: 18),
                            SizedBox(width: 5),
                            Text(
                              "Connect directly with buyers",
                              style: TextStyle(color: colorScheme.onSurface),
                            ),
                          ],
                        ),
                        // const Spacer(),
                        const SizedBox(
                          height: 20,
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const PostAdCar()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                          ),
                          child: const Text("Post Your Ad"),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 10),

                  // Image Column
                  Expanded(
                    flex: 1,
                    child: Container(
                      height: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: colorScheme.surfaceVariant,
                        image: const DecorationImage(
                          image: AssetImage('assets/images/car-image.png'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // ---=========-=-=-=-=-=-=-
          Padding(
            padding: const EdgeInsets.all(5),
            child: Container(
              width: double.infinity,
              height: 200,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colorScheme.outline),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Text and Button Column
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Sell It Through CarHive!",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(Icons.check, color: Colors.green, size: 18),
                            SizedBox(width: 5),
                            Text(
                              "Post an ad in 2 minutes",
                              style: TextStyle(color: colorScheme.onSurface),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Icon(Icons.check, color: Colors.green, size: 18),
                            SizedBox(width: 5),
                            Text(
                              "20 million users",
                              style: TextStyle(color: colorScheme.onSurface),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Icon(Icons.check, color: Colors.green, size: 18),
                            SizedBox(width: 5),
                            Text(
                              "Connect directly with buyers",
                              style: TextStyle(color: colorScheme.onSurface),
                            ),
                          ],
                        ),
                        // const Spacer(),
                        const SizedBox(
                          height: 20,
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const CombinedInfoScreen()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                          ),
                          child: const Text("Help to sell car!"),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 10),

                  // Image Column
                  Expanded(
                    flex: 1,
                    child: Container(
                      height: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: colorScheme.surfaceVariant,
                        image: const DecorationImage(
                          image: AssetImage('assets/images/car-image.png'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
