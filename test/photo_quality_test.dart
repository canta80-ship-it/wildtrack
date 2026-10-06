import 'dart:convert';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:wildtrack_mvp/services/photo_processing_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Post encoder preserves a detailed photo at display resolution and within upload limits', () async {
    final original=img.Image(width:2400,height:1600);
    final noise=Random(42);
    for (final p in original) { final texture=noise.nextInt(16); p.r=(p.x~/4)%128+texture; p.g=64+(p.y~/4)%128+texture; p.b=32+texture; }
    final input=img.encodePng(original);
    expect(input.length,greaterThan(PhotoProcessingService.maxPhotoBytes));
    final bytes=base64Decode(await PhotoProcessingService.encode(input));
    expect(bytes.length,lessThanOrEqualTo(PhotoProcessingService.maxPhotoBytes));
    final decoded=img.decodeJpg(bytes)!;
    expect(decoded.width,greaterThanOrEqualTo(1280));
    expect(decoded.width/decoded.height,closeTo(1.5,.005));
  });
  test('Small photos are not enlarged and avatar crop remains square PNG', () async {
    final input=img.encodePng(img.Image(width:640,height:480));
    final photo=img.decodeJpg(base64Decode(await PhotoProcessingService.encode(input)))!;
    expect(photo.width,640); expect(photo.height,480);
    final avatar=img.decodePng(base64Decode(await PhotoProcessingService.encode(input,avatar:true)))!;
    expect(avatar.width,256); expect(avatar.height,256);
  });
}
