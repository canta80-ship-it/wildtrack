import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/community_service.dart';
import '../services/photo_processing_service.dart';
import '../services/media_storage_service.dart';
import '../services/database_service.dart';
import '../premium_ui.dart';

class CommunityEditPhotoButton extends StatefulWidget {
  const CommunityEditPhotoButton({super.key, required this.sighting});
  final Map<String, dynamic> sighting;
  @override
  State<CommunityEditPhotoButton> createState() => _CommunityEditPhotoButtonState();
}
class _CommunityEditPhotoButtonState extends State<CommunityEditPhotoButton> {
  bool busy = false;
  Future<void> add() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null || !mounted) return;
    setState(() => busy = true);
    try {
      final photo = await PhotoProcessingService.encode(await picked.readAsBytes());
      final id = '${widget.sighting['id']}';
      final path = await MediaStorageService.instance.persistPhoto(picked.path, '${id}_${const Uuid().v4()}');
      // Persist the private diary copy before sending the new public photo.
      if (path != null) {
        await DatabaseService.instance.retainPublicSighting(widget.sighting);
        await DatabaseService.instance.appendCommunityPhoto(id, path);
      }
      await CommunityService.instance.api('sightings', method: 'PATCH', body: {'id': id, 'photo': photo});
      await CommunityService.instance.refresh();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Foto aggiunta al post.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Foto non pubblicata: ${e.toString().replaceFirst('Exception: ', '')} Riprova quando torna la rete.')));
    } finally { if (mounted) setState(() => busy = false); }
  }
  @override
  Widget build(BuildContext context) {
    if (!CommunityService.instance.isMine(widget.sighting)) return const SizedBox.shrink();
    return OutlinedButton.icon(onPressed: busy ? null : add,
      style: OutlinedButton.styleFrom(foregroundColor: WildColors.forest),
      icon: const Icon(Icons.add_photo_alternate_outlined),
      label: Text(busy ? 'Caricamento…' : widget.sighting['photo'] == null ? 'Aggiungi foto' : 'Sostituisci foto'));
  }
}
