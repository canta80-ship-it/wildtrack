import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../models/sighting.dart';
import '../services/database_service.dart';
import '../services/location_service.dart';
import '../services/media_storage_service.dart';
import 'community_screen.dart';
import 'species_screen.dart';
import '../premium_ui.dart';

class PremiumSightingScreen extends StatefulWidget {
  const PremiumSightingScreen({super.key});
  @override
  State<PremiumSightingScreen> createState() => _PremiumSightingScreenState();
}

class _PremiumSightingScreenState extends State<PremiumSightingScreen> {
  String kind = 'Animale';
  String selectedSpecies = 'Cervo';
  int count = 1;
  String? photo;
  double? lat, lng, accuracy;
  bool locating = false, saving = false, publicMode = false;
  final notes = TextEditingController();

  @override
  void dispose() { notes.dispose(); super.dispose(); }

  Future<void> pick(ImageSource source) async {
    final f = await ImagePicker().pickImage(source: source, maxWidth: 1600, imageQuality: 85);
    if (f != null && mounted) setState(() => photo = f.path);
  }

  Future<void> locate() async {
    setState(() => locating = true);
    try {
      final p = await LocationService.currentPosition();
      if (p != null && mounted) setState(() { lat = p.latitude; lng = p.longitude; accuracy = p.accuracy; });
    } finally {
      if (mounted) setState(() => locating = false);
    }
  }

  Future<Sighting?> persist() async {
    if (saving) return null;
    setState(() => saving = true);
    try {
      final id = const Uuid().v4();
      final storedPhoto = await MediaStorageService.instance.persistPhoto(photo, id);
      final row = Sighting(
        id: id, species: selectedSpecies, count: count,
        notes: notes.text.trim(), latitude: lat, longitude: lng,
        timestamp: DateTime.now(), photoPath: storedPhoto, kind: kind,
        accuracy: accuracy, positionSource: lat == null ? 'missing' : 'gps',
      );
      await DatabaseService.instance.insertSighting(row);
      return row;
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> savePrivate() async {
    final row = await persist();
    if (!mounted || row == null) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Avvistamento salvato nel diario privato.')));
  }

  Future<void> publish() async {
    final row = await persist();
    if (!mounted || row == null) return;
    if (!row.hasPosition) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Salvato. Per pubblicare aggiungi prima la posizione.')));
      return;
    }
    await Navigator.push(context, MaterialPageRoute<void>(builder: (_) => PublishScreen(initial: row)));
  }

  String assetForSpecies(String name) {
    final n = name.toLowerCase();
    if (n.contains('lupo') || n.contains('volpe')) return 'intro_lupo.jpg';
    if (n.contains('marmotta')) return 'intro_marmotta.jpg';
    if (n.contains('gufo') || n.contains('poiana') || n.contains('allocco')) return 'intro_gufo.jpg';
    return 'intro_cervo.jpg';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: WildColors.ivory,
    body: CustomScrollView(slivers: [
      SliverToBoxAdapter(child: SizedBox(height: 245, child: Stack(fit: StackFit.expand, children: [
        Image.asset('intro_cervo.jpg', fit: BoxFit.cover, alignment: const Alignment(.1, -.2)),
        const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x15FFFFFF), Color(0xB8F8F6EF), WildColors.ivory], stops: [0, .67, 1]))),
        SafeArea(bottom: false, child: Padding(padding: const EdgeInsets.fromLTRB(18, 8, 18, 14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [IconButton(onPressed: () => Navigator.maybePop(context), icon: const Icon(Icons.arrow_back_ios_new, color: WildColors.forest)), const WildLogo(compact: true), const Spacer(), const Icon(Icons.notifications_none, color: WildColors.forest)]),
          const Spacer(),
          const Text('Nuovo avvistamento', style: TextStyle(fontFamily: 'serif', fontSize: 37, height: 1, fontWeight: FontWeight.w800, color: WildColors.ink)),
          const SizedBox(height: 6), const Text('Cosa hai osservato?', style: TextStyle(fontSize: 19, color: WildColors.muted)),
        ]))),
      ]))),
      SliverPadding(padding: const EdgeInsets.fromLTRB(14, 0, 14, 120), sliver: SliverList(delegate: SliverChildListDelegate([
        Row(children: [
          Expanded(child: _KindCard(label: 'Animale', icon: Icons.pets, active: kind == 'Animale', onTap: () => setState(() => kind = 'Animale'))),
          const SizedBox(width: 7), Expanded(child: _KindCard(label: 'Impronta /\ntraccia', icon: Icons.pets_outlined, active: kind == 'Impronta', onTap: () => setState(() => kind = 'Impronta'))),
          const SizedBox(width: 7), Expanded(child: _KindCard(label: 'Penna / resto', icon: Icons.article_outlined, active: kind == 'Penna', onTap: () => setState(() => kind = 'Penna'))),
          const SizedBox(width: 7), Expanded(child: _KindCard(label: 'Non so,\naiutami', icon: Icons.search, active: kind == 'Non identificato', onTap: () => setState(() => kind = 'Non identificato'))),
        ]),
        const SizedBox(height: 12),
        _Panel(title: 'Foto', subtitle: 'facoltativa ma consigliata', child: SizedBox(height: 135, child: Row(children: [
          Expanded(child: InkWell(onTap: () => pick(ImageSource.camera), borderRadius: BorderRadius.circular(16), child: Container(decoration: BoxDecoration(border: Border.all(color: const Color(0xFFBCC5B9), style: BorderStyle.solid), borderRadius: BorderRadius.circular(16)), child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.camera_alt, size: 36, color: WildColors.forest), SizedBox(height: 8), Text('Aggiungi foto', style: TextStyle(fontWeight: FontWeight.w700))])))),
          if (photo != null) ...[const SizedBox(width: 9), Expanded(child: Stack(fit: StackFit.expand, children: [ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.file(File(photo!), fit: BoxFit.cover)), Positioned(top: 5, right: 5, child: InkWell(onTap: () => setState(() => photo = null), child: const CircleAvatar(radius: 13, backgroundColor: Color(0xCC17231A), child: Icon(Icons.close, size: 16, color: Colors.white))))]))],
          const SizedBox(width: 9), Expanded(child: InkWell(onTap: () => pick(ImageSource.gallery), child: Container(decoration: BoxDecoration(color: WildColors.sageSoft, borderRadius: BorderRadius.circular(16)), child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add, size: 36, color: WildColors.forest), SizedBox(height: 6), Text('Aggiungi\naltra foto', textAlign: TextAlign.center, style: TextStyle(color: WildColors.forest))])))),
        ]))),
        const SizedBox(height: 10),
        _Panel(title: 'Specie', trailing: 'Cerca o seleziona', child: InkWell(
          onTap: () async {
            final result = await showModalBottomSheet<String>(context: context, showDragHandle: true, builder: (_) => ListView(children: [for (final a in animals) ListTile(leading: SpeciesIcon(a.name, size: 34), title: Text(a.name), subtitle: Text(a.latin), onTap: () => Navigator.pop(context, a.name))]));
            if (result != null && mounted) setState(() => selectedSpecies = result);
          },
          child: Row(children: [ClipRRect(borderRadius: BorderRadius.circular(13), child: Image.asset(assetForSpecies(selectedSpecies), width: 66, height: 66, fit: BoxFit.cover)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(selectedSpecies, style: const TextStyle(fontFamily: 'serif', fontSize: 19, fontWeight: FontWeight.w800)), Text(animals.where((a) => a.name == selectedSpecies).map((a) => a.latin).firstOrNull ?? '', style: const TextStyle(fontStyle: FontStyle.italic, color: WildColors.muted))])), const Icon(Icons.chevron_right)]),
        )),
        const SizedBox(height: 10),
        _Panel(title: 'Numero di individui', child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          IconButton.filledTonal(onPressed: count > 1 ? () => setState(() => count--) : null, icon: const Icon(Icons.remove)),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 26), child: Text('$count', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800))),
          IconButton.filledTonal(onPressed: () => setState(() => count++), icon: const Icon(Icons.add)),
        ])),
        const SizedBox(height: 10),
        _Panel(title: 'Posizione', child: Row(children: [const WildIconDisc(Icons.location_on, size: 48), const SizedBox(width: 12), Expanded(child: Text(lat == null ? 'Posizione non ancora rilevata' : '${lat!.toStringAsFixed(4)}, ${lng!.toStringAsFixed(4)}\nPrecisione ±${accuracy?.toStringAsFixed(0) ?? '—'} m', style: const TextStyle(color: WildColors.muted))), FilledButton.tonalIcon(onPressed: locating ? null : locate, icon: const Icon(Icons.map_outlined), label: Text(locating ? 'GPS…' : 'Usa posizione attuale'))])),
        const SizedBox(height: 10),
        _Panel(title: 'Note', subtitle: 'facoltativo', child: TextField(controller: notes, maxLines: 2, decoration: const InputDecoration(hintText: 'Es. comportamento, habitat, condizioni…'))),
        const SizedBox(height: 10),
        _Panel(title: 'Modalità di pubblicazione', child: Row(children: [
          Expanded(child: _PrivacyChoice(icon: Icons.lock, title: 'Privato', subtitle: 'Solo per te', active: !publicMode, onTap: () => setState(() => publicMode = false))),
          const SizedBox(width: 9), Expanded(child: _PrivacyChoice(icon: Icons.groups, title: 'Pubblico', subtitle: 'Condividi con la community', active: publicMode, onTap: () => setState(() => publicMode = true))),
        ])),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: SizedBox(height: 60, child: FilledButton.icon(onPressed: saving ? null : savePrivate, icon: const Icon(Icons.lock), label: const Text('Salva privato'), style: FilledButton.styleFrom(backgroundColor: WildColors.cream, foregroundColor: WildColors.forest, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)))))),
          const SizedBox(width: 10), Expanded(child: SizedBox(height: 60, child: FilledButton.icon(onPressed: saving ? null : publish, icon: const Icon(Icons.send), label: const Text('Pubblica'), style: FilledButton.styleFrom(backgroundColor: WildColors.forest, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)))))),
        ]),
      ]))),
    ]),
  );
}

class _KindCard extends StatelessWidget {
  const _KindCard({required this.label, required this.icon, required this.active, required this.onTap});
  final String label; final IconData icon; final bool active; final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(20), child: AnimatedContainer(duration: const Duration(milliseconds: 150), height: 130, padding: const EdgeInsets.all(9), decoration: BoxDecoration(color: active ? WildColors.sageSoft : Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: active ? const Color(0xFF8CB883) : const Color(0x10000000), width: 1.2)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 40, color: active ? WildColors.forest : WildColors.earth), const SizedBox(height: 10), Text(label, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800, height: 1.05))])));
}

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.child, this.subtitle, this.trailing});
  final String title; final String? subtitle; final String? trailing; final Widget child;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: const Color(0x12000000))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Text(title, style: const TextStyle(fontFamily: 'serif', fontSize: 19, fontWeight: FontWeight.w800)), if (subtitle != null) ...[const SizedBox(width: 5), Text('($subtitle)', style: const TextStyle(fontSize: 11, color: WildColors.muted))], const Spacer(), if (trailing != null) Text(trailing!, style: const TextStyle(fontSize: 11, color: WildColors.forest))]), const SizedBox(height: 10), child]));
}

class _PrivacyChoice extends StatelessWidget {
  const _PrivacyChoice({required this.icon, required this.title, required this.subtitle, required this.active, required this.onTap});
  final IconData icon; final String title; final String subtitle; final bool active; final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(16), child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), decoration: BoxDecoration(color: active ? WildColors.sageSoft : Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: active ? const Color(0xFF79A873) : const Color(0x22000000))), child: Row(children: [Icon(icon, color: active ? WildColors.forest : WildColors.muted), const SizedBox(width: 8), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w800)), Text(subtitle, style: const TextStyle(fontSize: 9, color: WildColors.muted))]))])));
}
