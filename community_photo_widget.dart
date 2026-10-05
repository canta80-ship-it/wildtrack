import 'package:flutter/material.dart';
import '../services/community_service.dart';
import '../services/preferences_service.dart';
import '../premium_ui.dart';

class CommunityPhoto extends StatefulWidget {
  const CommunityPhoto({super.key, required this.sightingId, this.height = 220, this.version, this.imageBuilder});
  final String sightingId;
  final double height;
  final String? version;
  final ImageProvider Function(String url)? imageBuilder;
  @override
  State<CommunityPhoto> createState() => _CommunityPhotoState();
}

class _CommunityPhotoState extends State<CommunityPhoto> {
  int attempt = 0;
  String get url => '$communityUrl/api/photo?id=${Uri.encodeQueryComponent(widget.sightingId)}&v=${Uri.encodeQueryComponent(widget.version ?? "")}&retry=$attempt';
  ImageProvider get provider => widget.imageBuilder?.call(url) ?? NetworkImage(url, headers: {'Authorization': 'Bearer ${PreferencesService.instance.token}'});
  Future<void> retry() async {
    await provider.evict();
    if (mounted) setState(() => attempt++);
  }
  @override
  void didUpdateWidget(covariant CommunityPhoto oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sightingId != widget.sightingId) attempt = 0;
  }
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: widget.height,
    child: Image(
      image: provider,
      fit: BoxFit.contain,
      frameBuilder: (context, child, frame, synchronous) {
        if (frame == null && !synchronous) return const Center(child: CircularProgressIndicator(color: WildColors.forest));
        return Semantics(label: 'Foto dell’avvistamento. Tocca per ingrandire.', button: true, child: GestureDetector(onTap: () => showDialog<void>(context: context, builder: (dialog) => Dialog.fullscreen(backgroundColor: Colors.black, child: SafeArea(child: Stack(children: [Positioned.fill(child: InteractiveViewer(minScale: 0.5, maxScale: 5, child: Image(image: provider, fit: BoxFit.contain))), Positioned(top: 8, right: 8, child: IconButton(tooltip: 'Chiudi foto', onPressed: () => Navigator.pop(dialog), icon: const Icon(Icons.close, color: Colors.white)))])))), child: child));
      },
      errorBuilder: (context, error, stack) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.broken_image_outlined, color: WildColors.forest), const SizedBox(height: 5), const Text('Foto non caricata', style: TextStyle(color: WildColors.forest)), const Text('Controlla la connessione e riprova.', textAlign: TextAlign.center, style: TextStyle(fontSize: 11)), TextButton.icon(onPressed: retry, icon: const Icon(Icons.refresh), label: const Text('Riprova foto'))])),
    ),
  );
}
