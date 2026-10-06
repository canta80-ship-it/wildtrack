import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

class PhotoProcessingService {
  static const maxPhotoBytes = 1000000;
  static const maxPhotoEdge = 2400;

  static Future<String> encode(Uint8List input, {bool avatar = false}) async {
    if (!avatar) return _encodeForPost(input);
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
  static Future<String> _encodeForPost(Uint8List input) async {
    final buffer = await ui.ImmutableBuffer.fromUint8List(input);
    ui.ImageDescriptor? descriptor;
    try {
      descriptor = await ui.ImageDescriptor.encoded(buffer);
      final longest = descriptor.width > descriptor.height ? descriptor.width : descriptor.height;
      final edge = longest.clamp(1, maxPhotoEdge).toInt();
      final codec = await descriptor.instantiateCodec(
        targetWidth: (descriptor.width * edge / longest).round().clamp(1, maxPhotoEdge).toInt(),
        targetHeight: (descriptor.height * edge / longest).round().clamp(1, maxPhotoEdge).toInt(),
      );
      try {
        final frame = await codec.getNextFrame();
        try {
          final pixels = await frame.image.toByteData(format: ui.ImageByteFormat.rawRgba);
          if (pixels == null) throw Exception('Impossibile leggere la foto.');
          return compute(_encodeJpeg, <String, Object>{
            'width': frame.image.width, 'height': frame.image.height,
            'pixels': Uint8List.fromList(pixels.buffer.asUint8List(pixels.offsetInBytes, pixels.lengthInBytes)),
          });
        } finally { frame.image.dispose(); }
      } finally { codec.dispose(); }
    } finally { descriptor?.dispose(); buffer.dispose(); }
  }

}

// JPEG is appropriate for photographs. Lower quality before reducing resolution;
// never silently shrink a detailed photograph to a tiny PNG thumbnail.
String _encodeJpeg(Map<String, Object> request) {
  final original = img.Image.fromBytes(width: request['width'] as int, height: request['height'] as int, bytes: (request['pixels'] as Uint8List).buffer, numChannels: 4).convert(numChannels: 3);
  final longest = original.width > original.height ? original.width : original.height;
  var edge = longest;
  while (true) {
    final current = edge == longest ? original : img.copyResize(original,
      width: (original.width * edge / longest).round(), height: (original.height * edge / longest).round(), interpolation: img.Interpolation.cubic);
    for (final quality in [92, 88, 84, 80]) {
      final encoded = img.encodeJpg(current, quality: quality, chroma: img.JpegChroma.yuv444);
      if (encoded.length <= PhotoProcessingService.maxPhotoBytes) return base64Encode(encoded);
    }
    final minimum = longest < 1280 ? longest : 1280;
    if (edge <= minimum) throw Exception('Foto troppo complessa per il limite di caricamento. Scegli una copia JPEG di qualità alta.');
    edge = (edge * .85).round().clamp(minimum, PhotoProcessingService.maxPhotoEdge).toInt();
  }
}
