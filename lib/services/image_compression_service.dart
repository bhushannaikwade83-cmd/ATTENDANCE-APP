import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class ImageCompressionService {
  static const int targetBytes50kb = 50 * 1024;

  static Future<Uint8List> compressToTarget({
    required Uint8List input,
    int targetBytes = targetBytes50kb,
    int startQuality = 90,
    int minQuality = 20,
    int step = 10,
  }) async {
    if (input.lengthInBytes <= targetBytes) return input;

    Uint8List best = input;

    for (int quality = startQuality; quality >= minQuality; quality -= step) {
      final compressed = await FlutterImageCompress.compressWithList(
        input,
        quality: quality,
        format: CompressFormat.jpeg,
        keepExif: false,
      );

      if (compressed.isEmpty) {
        continue;
      }

      final result = Uint8List.fromList(compressed);
      if (result.lengthInBytes < best.lengthInBytes) {
        best = result;
      }

      if (result.lengthInBytes <= targetBytes) {
        return result;
      }
    }

    return best;
  }
}
