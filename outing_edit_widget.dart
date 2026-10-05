import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../models/track_session.dart';
import '../services/database_service.dart';
import '../services/media_storage_service.dart';
class OutingEditScreen extends StatefulWidget {
  const OutingEditScreen({super.key, required this.session});
  final TrackSession session;
  @override State<OutingEditScreen> createState() => _OutingEditScreenState();
}
class _OutingEditScreenState extends State<OutingEditScreen> {
  late final name = TextEditingController(text: widget.session.name);
  late final description = TextEditingController(text: widget.session.notes);
  late final photos = List<String>.from(widget.session.photos);
  bool busy = false;
  @override void dispose() { name.dispose(); description.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Modifica traccia')),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      TextField(controller: name, maxLength: 120, decoration: const InputDecoration(labelText: 'Nome traccia')),
      const SizedBox(height: 16),
      TextField(controller: description, maxLength: 3000, minLines: 3, maxLines: 8, decoration: const InputDecoration(labelText: 'Descrizione')),
      const SizedBox(height: 16),
      Wrap(spacing: 8, runSpacing: 8, children: [for(final photo in photos) SizedBox(width: 140, height: 140, child: Stack(children:[
        Positioned.fill(child: ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.file(File(photo), fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.broken_image)))),
        Positioned(right: 0, child: IconButton.filled(tooltip: 'Rimuovi foto', onPressed: busy ? null : () => setState(() => photos.remove(photo)), icon: const Icon(Icons.close))),
      ]))]),
      OutlinedButton.icon(icon: const Icon(Icons.add_photo_alternate), label: const Text('Aggiungi foto'), onPressed: busy ? null : () async {
        try {
          final picked = await ImagePicker().pickMultiImage(maxWidth: 2048, imageQuality: 90);
          for(final file in picked) {final path = await MediaStorageService.instance.persistPhoto(file.path, 'outing_${widget.session.id}_${const Uuid().v4()}'); if(path != null) photos.add(path);}
          if(mounted) setState(() {});
        } catch(e) {if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));}
      }),
      FilledButton.icon(icon: const Icon(Icons.save_outlined), label: const Text('Salva modifiche'), onPressed: busy ? null : () async {
        setState(() => busy = true);
        try { final updated = widget.session.copyWith(name: name.text.trim(), notes: description.text.trim(), photos: List<String>.from(photos)); await DatabaseService.instance.updateSession(updated); if(context.mounted) Navigator.pop(context, updated); }
        catch(e) {if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));}
        finally {if(mounted) setState(() => busy = false);}
      }),
    ]));
}
