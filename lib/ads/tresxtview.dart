import 'package:flutter/material.dart';
import 'package:imageview360/imageview360.dart';

/// A simple wrapper that shows a 360° rotatable view using `imageview360`.
/// Pass a list of image URLs (uploaded frames for the 360 view).
class Car360View extends StatelessWidget {
  final List<String> carImages; // list of image URLs (network) or asset paths

  const Car360View({super.key, required this.carImages});

  @override
  Widget build(BuildContext context) {
    if (carImages.isEmpty) {
      return const Center(child: Text("No 360° view available"));
    }

    // Convert URL strings to ImageProvider objects (NetworkImage)
    final List<ImageProvider> providers =
        carImages.map((url) => NetworkImage(url)).toList();
    // 👆 IMPORTANT: we changed from Image.network(...) (Widget) to NetworkImage(...)

    return SizedBox(
      height: 300, // adjust height to your layout
      child: Center(
        child: ImageView360(
          key: ValueKey(providers.length), // ensure rebuild when list changes
          imageList: providers, // <-- expects ImageProvider list
          autoRotate: false,
          rotationCount: 1,
          swipeSensitivity: 2,
          allowSwipeToRotate: true,
          frameChangeDuration: const Duration(milliseconds: 50),
        ),
      ),
    );
  }
}
  