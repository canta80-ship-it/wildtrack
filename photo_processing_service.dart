import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

class PhotoProcessingService {
  static Future<String> encode(Uint8List input, {bool avatar = false}) async {
    final buffer = await ui.ImmutableBuffer.fromUint8List(input);
    final descriptor = await ui.ImageDescriptor.encoded(buffer);
    try {
      final longest = descriptor.width > descriptor.height ? descriptor.width : descriptor.height;
      var edge = avatar ? 512 : longest.clamp(1, 1600).toInt();
      while (true) {
        final codec = await descriptor.instantiateCodec(
          targetWidth: (descriptor.width * edge / longest).round().clamp(1, 1600).toInt(),
          targetHeight: (descriptor.height * edge / longest).round().clamp(1, 1600).toInt(),
        );
        try {
          final frame = await codec.getNextFrame();
          try {
            ui.Image image = frame.image;
            if (avatar) {
              final recorder = ui.PictureRecorder();
              final canvas = ui.Canvas(recorder);
              final side = image.width < image.height ? image.width : image.height;
              canvas.drawImageRect(image,
                ui.Rect.fromLTWH((image.width-side)/2, (image.height-side)/2, side.toDouble(), side.toDouble()),
                const ui.Rect.fromLTWH(0, 0, 256, 256), ui.Paint()..filterQuality = ui.FilterQuality.high);
              final picture = recorder.endRecording();
              image = await picture.toImage(256, 256);
              picture.dispose();
            }
            try {
              final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
              if (bytes != null && bytes.lengthInBytes <= (avatar ? 300000 : 1000000)) {
                return base64Encode(bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes));
              }
            } finally { if (avatar) image.dispose(); }
          } finally { frame.image.dispose(); }
        } finally { codec.dispose(); }
        if (avatar || edge <= 256) throw Exception('Impossibile preparare questa foto. Scegli un’altra immagine.');
        edge = (edge * .8).floor().clamp(256, 1600).toInt();
      }
    } finally { descriptor.dispose(); buffer.dispose(); }
  }
}
