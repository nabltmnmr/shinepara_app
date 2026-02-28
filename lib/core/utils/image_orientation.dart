import 'dart:io';

import 'package:image/image.dart' as img;

class ImageOrientation {
  /// Many devices save JPEGs sideways with an EXIF orientation flag.
  /// Our filter/visualization pipeline doesn't apply EXIF, so we "bake" the
  /// orientation into the pixels before further processing.
  static Future<File> bakeExifOrientationIfNeeded(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return file;

      final baked = img.bakeOrientation(decoded);

      // If nothing changed, keep the original file.
      if (identical(baked, decoded)) return file;

      final outPath =
          '${file.parent.path}${Platform.pathSeparator}scan_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final outBytes = img.encodeJpg(baked, quality: 95);
      final outFile = File(outPath);
      await outFile.writeAsBytes(outBytes, flush: true);
      return outFile;
    } catch (_) {
      return file;
    }
  }
}

