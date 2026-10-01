import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

class ApprovedAssets {
  ApprovedAssets._();
  static const String homeLandscape = 'PLACEHOLDER';
  static Uint8List bytes(String data) => base64Decode(data);
}

class ApprovedImage extends StatelessWidget {
  const ApprovedImage(this.data, {super.key, this.fit = BoxFit.cover, this.alignment = Alignment.center});
  final String data;
  final BoxFit fit;
  final Alignment alignment;
  @override
  Widget build(BuildContext context) => Image.memory(
        ApprovedAssets.bytes(data),
        fit: fit,
        alignment: alignment,
        gaplessPlayback: true,
        filterQuality: FilterQuality.high,
      );
}
