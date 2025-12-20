import 'dart:math' as math;
import 'package:image/image.dart' as img;

/// Utilities for advanced image blending and processing
class ImageBlend {
  /// Cross-dissolve blend between two images
  static img.Image crossDissolve(
    img.Image imageA,
    img.Image imageB,
    double alpha,
  ) {
    final width = math.min(imageA.width, imageB.width);
    final height = math.min(imageA.height, imageB.height);
    
    final resizedA = img.copyResize(imageA, width: width, height: height);
    final resizedB = img.copyResize(imageB, width: width, height: height);
    
    final output = img.Image(width: width, height: height);
    
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final pixelA = resizedA.getPixel(x, y);
        final pixelB = resizedB.getPixel(x, y);
        
        // Extract color channels from pixel
        final rA = pixelA.r.toDouble();
        final gA = pixelA.g.toDouble();
        final bA = pixelA.b.toDouble();
        final aA = pixelA.a.toDouble();
        
        final rB = pixelB.r.toDouble();
        final gB = pixelB.g.toDouble();
        final bB = pixelB.b.toDouble();
        final aB = pixelB.a.toDouble();
        
        // Blend channels
        final r = (rA * (1 - alpha) + rB * alpha).round().clamp(0, 255);
        final g = (gA * (1 - alpha) + gB * alpha).round().clamp(0, 255);
        final b = (bA * (1 - alpha) + bB * alpha).round().clamp(0, 255);
        final a = (aA * (1 - alpha) + aB * alpha).round().clamp(0, 255);
        
        output.setPixel(x, y, img.ColorRgba8(r, g, b, a));
      }
    }
    
    return output;
  }

  /// Equalize brightness between two images
  static void equalizeBrightness(img.Image imageA, img.Image imageB) {
    final avgA = _calculateAverageBrightness(imageA);
    final avgB = _calculateAverageBrightness(imageB);
    
    if ((avgA - avgB).abs() < 5) return;
    
    final ratio = avgB > 0 ? avgA / avgB : 1.0;
    final adjustment = ratio.clamp(0.8, 1.2);
    
    _adjustBrightness(imageB, adjustment);
  }

  static double _calculateAverageBrightness(img.Image image) {
    double totalBrightness = 0;
    int pixelCount = 0;
    
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final r = pixel.r.toDouble();
        final g = pixel.g.toDouble();
        final b = pixel.b.toDouble();
        
        final brightness = (0.299 * r + 0.587 * g + 0.114 * b);
        totalBrightness += brightness;
        pixelCount++;
      }
    }
    
    return pixelCount > 0 ? totalBrightness / pixelCount : 0;
  }

  static void _adjustBrightness(img.Image image, double factor) {
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final r = ((pixel.r * factor).round()).clamp(0, 255).toInt();
        final g = ((pixel.g * factor).round()).clamp(0, 255).toInt();
        final b = ((pixel.b * factor).round()).clamp(0, 255).toInt();
        final a = pixel.a.round().clamp(0, 255).toInt();
        
        image.setPixel(x, y, img.ColorRgba8(r, g, b, a));
      }
    }
  }

  /// Normalize contrast
  static img.Image normalizeContrast(img.Image image) {
    double minLum = 255;
    double maxLum = 0;
    
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final r = pixel.r.toDouble();
        final g = pixel.g.toDouble();
        final b = pixel.b.toDouble();
        final lum = 0.299 * r + 0.587 * g + 0.114 * b;
        
        if (lum < minLum) minLum = lum;
        if (lum > maxLum) maxLum = lum;
      }
    }
    
    if ((maxLum - minLum) < 10) return image;
    
    final output = img.Image(width: image.width, height: image.height);
    final range = maxLum - minLum;
    
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final r = pixel.r.toDouble();
        final g = pixel.g.toDouble();
        final b = pixel.b.toDouble();
        final a = pixel.a;
        
        final rNorm = ((r - minLum) / range * 255).round().clamp(0, 255);
        final gNorm = ((g - minLum) / range * 255).round().clamp(0, 255);
        final bNorm = ((b - minLum) / range * 255).round().clamp(0, 255);
        final aInt = a.round().clamp(0, 255);
        
        output.setPixel(x, y, img.ColorRgba8(rNorm, gNorm, bNorm, aInt));
      }
    }
    
    return output;
  }

  /// Apply optical flow-like warping to reduce ghosting
  static img.Image applyWarp(img.Image image, double intensity) {
    if (intensity <= 0) return image;
    
    final output = img.Image(width: image.width, height: image.height);
    final blurRadius = (intensity * 2).round().clamp(0, 3);
    
    if (blurRadius == 0) return image;
    
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        int rSum = 0, gSum = 0, bSum = 0, aSum = 0;
        int count = 0;
        
        for (int dx = -blurRadius; dx <= blurRadius; dx++) {
          final sx = (x + dx).clamp(0, image.width - 1);
          final pixel = image.getPixel(sx, y);
          
          rSum += pixel.r.round();
          gSum += pixel.g.round();
          bSum += pixel.b.round();
          aSum += pixel.a.round();
          count++;
        }
        
        final r = (rSum / count).round().clamp(0, 255);
        final g = (gSum / count).round().clamp(0, 255);
        final b = (bSum / count).round().clamp(0, 255);
        final a = (aSum / count).round().clamp(0, 255);
        
        output.setPixel(x, y, img.ColorRgba8(r, g, b, a));
      }
    }
    
    return output;
  }

  /// Blending curve for smooth transitions
  static double blendingCurve(double t) {
    if (t < 0.5) {
      return 4 * t * t * t;
    } else {
      return 1 - math.pow(-2 * t + 2, 3) / 2;
    }
  }

  /// Normalize exposure
  static void normalizeExposure(img.Image imageA, img.Image imageB) {
    final exposureA = _calculateExposure(imageA);
    final exposureB = _calculateExposure(imageB);
    
    if ((exposureA - exposureB).abs() < 0.05) return;
    
    final adjustment = exposureA > 0 ? exposureB / exposureA : 1.0;
    final clampedAdjustment = adjustment.clamp(0.9, 1.1);
    
    _adjustExposure(imageB, clampedAdjustment);
  }

  static double _calculateExposure(img.Image image) {
    double totalLuminance = 0;
    int pixelCount = 0;
    
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final r = pixel.r.toDouble();
        final g = pixel.g.toDouble();
        final b = pixel.b.toDouble();
        
        final luminance = (0.299 * r + 0.587 * g + 0.114 * b) / 255.0;
        totalLuminance += luminance;
        pixelCount++;
      }
    }
    
    return pixelCount > 0 ? totalLuminance / pixelCount : 0.5;
  }

  static void _adjustExposure(img.Image image, double factor) {
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final r = ((pixel.r * factor).round()).clamp(0, 255).toInt();
        final g = ((pixel.g * factor).round()).clamp(0, 255).toInt();
        final b = ((pixel.b * factor).round()).clamp(0, 255).toInt();
        final a = pixel.a.round().clamp(0, 255).toInt();
        
        image.setPixel(x, y, img.ColorRgba8(r, g, b, a));
      }
    }
  }
}
