import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/foundation.dart';

class CameraFrameConverter {
  static Float32List convertCameraImageToFloat32(CameraImage image, int targetWidth, int targetHeight) {
    img.Image? rgbImage;

    try {
      if (image.format.group == ImageFormatGroup.yuv420) {
        rgbImage = _convertYUV420ToImage(image);
      } else if (image.format.group == ImageFormatGroup.bgra8888) {
        rgbImage = _convertBGRA8888ToImage(image);
      }
    } catch (e) {
      debugPrint('Error converting camera image: $e');
    }

    if (rgbImage == null) {
      return Float32List(targetWidth * targetHeight * 3);
    }

    debugPrint('YUV420 -> RGB conversion successful');

    img.Image resized = img.copyResize(rgbImage, width: targetWidth, height: targetHeight);

    Float32List float32List = Float32List(targetWidth * targetHeight * 3);
    int index = 0;
    
    for (var y = 0; y < targetHeight; y++) {
      for (var x = 0; x < targetWidth; x++) {
        final pixel = resized.getPixel(x, y);
        float32List[index++] = pixel.r / 255.0;
        float32List[index++] = pixel.g / 255.0;
        float32List[index++] = pixel.b / 255.0;
      }
    }

    debugPrint('Input tensor dimensions: ${float32List.length}');
    return float32List;
  }

  static img.Image _convertBGRA8888ToImage(CameraImage cameraImage) {
    return img.Image.fromBytes(
      width: cameraImage.width,
      height: cameraImage.height,
      bytes: cameraImage.planes[0].bytes.buffer,
      order: img.ChannelOrder.bgra,
    );
  }

  static img.Image _convertYUV420ToImage(CameraImage cameraImage) {
    final width = cameraImage.width;
    final height = cameraImage.height;
    
    final uvRowStride = cameraImage.planes[1].bytesPerRow;
    final uvPixelStride = cameraImage.planes[1].bytesPerPixel ?? 1;

    final image = img.Image(width: width, height: height);

    for (int w = 0; w < width; w++) {
      for (int h = 0; h < height; h++) {
        final uvIndex = uvPixelStride * (w / 2).floor() + uvRowStride * (h / 2).floor();
        final index = h * cameraImage.planes[0].bytesPerRow + w;

        final y = cameraImage.planes[0].bytes[index];
        final u = cameraImage.planes[1].bytes[uvIndex];
        final v = cameraImage.planes[2].bytes[uvIndex];

        int r = (y + 1.402 * (v - 128)).round();
        int g = (y - 0.344136 * (u - 128) - 0.714136 * (v - 128)).round();
        int b = (y + 1.772 * (u - 128)).round();

        image.setPixelRgb(w, h, r.clamp(0, 255), g.clamp(0, 255), b.clamp(0, 255));
      }
    }
    return image;
  }
}
