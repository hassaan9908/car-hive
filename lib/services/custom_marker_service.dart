import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class CustomMarkerService {
  static const double _markerSize = 120.0;
  static const double _imageSize = 80.0;

  /// Creates a custom marker with a car thumbnail image
  static Future<BitmapDescriptor> createCarMarker({
    required String? imageUrl,
    required String price,
    String? title,
  }) async {
    try {
      // Create a custom marker with thumbnail
      final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(pictureRecorder);
      
      // Draw marker background (rounded rectangle with shadow)
      final Paint shadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      
      final Paint backgroundPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      
      final Paint borderPaint = Paint()
        ..color = const Color(0xFFf48c25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      // Draw shadow
      final RRect shadowRect = RRect.fromRectAndRadius(
        const Rect.fromLTWH(2, 2, _markerSize - 4, _markerSize - 20),
        const Radius.circular(8),
      );
      canvas.drawRRect(shadowRect, shadowPaint);

      // Draw background
      final RRect backgroundRect = RRect.fromRectAndRadius(
        const Rect.fromLTWH(0, 0, _markerSize - 4, _markerSize - 20),
        const Radius.circular(8),
      );
      canvas.drawRRect(backgroundRect, backgroundPaint);
      canvas.drawRRect(backgroundRect, borderPaint);

      // Draw car image if available
      if (imageUrl != null && imageUrl.isNotEmpty) {
        try {
          final response = await http.get(Uri.parse(imageUrl));
          if (response.statusCode == 200) {
            final Uint8List imageBytes = response.bodyBytes;
            final ui.Codec codec = await ui.instantiateImageCodec(
              imageBytes,
              targetWidth: _imageSize.toInt(),
              targetHeight: (_imageSize * 0.6).toInt(),
            );
            final ui.FrameInfo frameInfo = await codec.getNextFrame();
            
            // Draw image
            const double imageTop = 8;
            const double imageLeft = (_markerSize - _imageSize) / 2;
            final Rect imageRect = Rect.fromLTWH(
              imageLeft,
              imageTop,
              _imageSize,
              _imageSize * 0.6,
            );
            
            // Clip image to rounded rectangle
            final RRect imageRRect = RRect.fromRectAndRadius(
              imageRect,
              const Radius.circular(6),
            );
            canvas.clipRRect(imageRRect);
            canvas.drawImageRect(
              frameInfo.image,
              Rect.fromLTWH(0, 0, frameInfo.image.width.toDouble(), frameInfo.image.height.toDouble()),
              imageRect,
              Paint(),
            );
          }
        } catch (e) {
          // If image loading fails, draw a car icon instead
          _drawCarIcon(canvas);
        }
      } else {
        // Draw car icon if no image
        _drawCarIcon(canvas);
      }

      // Draw price text
      final TextPainter pricePainter = TextPainter(
        text: TextSpan(
          text: 'PKR $price',
          style: TextStyle(
            color: const Color(0xFFf48c25),
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      pricePainter.layout();
      
      final double priceX = (_markerSize - pricePainter.width) / 2;
      final double priceY = _markerSize - 35;
      pricePainter.paint(canvas, Offset(priceX, priceY));

      // Draw pointer at bottom
      final Path pointerPath = Path();
      const double pointerWidth = 20;
      const double pointerHeight = 15;
      const double pointerX = (_markerSize - pointerWidth) / 2;
      const double pointerY = _markerSize - 20;
      
      pointerPath.moveTo(pointerX, pointerY);
      pointerPath.lineTo(pointerX + pointerWidth / 2, pointerY + pointerHeight);
      pointerPath.lineTo(pointerX + pointerWidth, pointerY);
      pointerPath.close();
      
      canvas.drawPath(pointerPath, backgroundPaint);
      canvas.drawPath(pointerPath, borderPaint);

      // Convert to image
      final ui.Picture picture = pictureRecorder.endRecording();
      final ui.Image image = await picture.toImage(
        _markerSize.toInt(),
        (_markerSize + 5).toInt(),
      );
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      
      if (byteData != null) {
        return BitmapDescriptor.fromBytes(byteData.buffer.asUint8List());
      }
    } catch (e) {
      print('Error creating custom marker: $e');
    }
    
    // Fallback to default marker
    return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
  }

  static void _drawCarIcon(Canvas canvas) {
    final Paint iconPaint = Paint()
      ..color = Colors.blue.shade800
      ..style = PaintingStyle.fill;

    // Simple car icon
    const double iconSize = 40;
    const double iconX = (_markerSize - iconSize) / 2;
    const double iconY = 20;

    // Car body
    final RRect carBody = RRect.fromRectAndRadius(
      const Rect.fromLTWH(iconX + 5, iconY + 10, iconSize - 10, 20),
      const Radius.circular(4),
    );
    canvas.drawRRect(carBody, iconPaint);

    // Car roof
    final RRect carRoof = RRect.fromRectAndRadius(
      const Rect.fromLTWH(iconX + 10, iconY + 5, iconSize - 20, 15),
      const Radius.circular(3),
    );
    canvas.drawRRect(carRoof, iconPaint);

    // Wheels
    final Paint wheelPaint = Paint()
      ..color = Colors.grey.shade800
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      const Offset(iconX + 10, iconY + 25),
      4,
      wheelPaint,
    );
    canvas.drawCircle(
      const Offset(iconX + iconSize - 10, iconY + 25),
      4,
      wheelPaint,
    );
  }

  /// Creates a simple colored marker for fallback
  static Future<BitmapDescriptor> createSimpleMarker({
    required Color color,
    String? text,
  }) async {
    try {
      final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(pictureRecorder);
      
      const double size = 60;
      
      // Draw circle
      final Paint paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      
      final Paint borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;

      canvas.drawCircle(const Offset(size / 2, size / 2), size / 2 - 2, paint);
      canvas.drawCircle(const Offset(size / 2, size / 2), size / 2 - 2, borderPaint);

      // Draw text if provided
      if (text != null && text.isNotEmpty) {
        final TextPainter textPainter = TextPainter(
          text: TextSpan(
            text: text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        
        final double textX = (size - textPainter.width) / 2;
        final double textY = (size - textPainter.height) / 2;
        textPainter.paint(canvas, Offset(textX, textY));
      }

      final ui.Picture picture = pictureRecorder.endRecording();
      final ui.Image image = await picture.toImage(size.toInt(), size.toInt());
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      
      if (byteData != null) {
        return BitmapDescriptor.fromBytes(byteData.buffer.asUint8List());
      }
    } catch (e) {
      print('Error creating simple marker: $e');
    }
    
    return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
  }
}
