import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:latlong2/latlong.dart';

import '../models/sighting.dart';
import '../services/database_service.dart';
import '../services/location_service.dart';
import '../services/media_storage_service.dart';
import 'community_screen.dart';
import 'species_screen.dart';
import 'map_position_screen.dart';
import '../premium_ui.dart';

class PremiumSightingScreen extends StatefulWidget {
  const PremiumSightingScreen({super.key, this.initialPosition});
  final LatLng? initialPosition;
  @override
  State<PremiumSightingScreen> createState() => _PremiumSightingScreenState();
}

class _PremiumSightingScreenState extends State<PremiumSightingScreen> {
  String kind = 'Animale';
  String selectedSpecies = 'Cervo';
  int count = 1;
  final List<String> photos = [];
  double? lat, lng, accuracy;
  String positionSource = 'missing';
  bool locating = false, saving = false, publicMode = false;
  final notes = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialPosition != null) {
      lat = widget.initialPosition!.latitude;
      lng = widget.initialPosition!.longitude;
      positionSource = 'manual';
    }
  }

  Future<void> chooseOnMap() async {
    final point = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute<LatLng>(
        builder: (_) => MapPositionScreen(
          initialPosition: lat == null || lng == null
              ? null
              : LatLng(lat!, lng!),
        ),
      ),
    );
    if (point == null || !mounted) return;
    setState(() {
      lat = point.latitude;
      lng = point.longitude;
      accuracy = null;
      positionSource = 'manual';
    });
  }

  @override
  void dispose() {
    notes.dispose();
    super.dispose();
  }

  Future<void> pickCamera() async {
    if (photos.length >= 5) return;
    final f = await ImagePicker().pickImage(
      source: ImageSource.camera,
      maxWidth: 1800,
      imageQuality: 88,
    );
    if (f != null && mounted) setState(() => photos.add(f.path));
  }

  Future<void> pickGallery() async {
    if (photos.length >= 5) return;
    final remaining = 5 - photos.length;
    final files = await ImagePicker().pickMultiImage(
      limit: remaining,
      maxWidth: 1800,
      imageQuality: 88,
    );
    if (files.isNotEmpty && mounted)
      setState(() => photos.addAll(files.take(remaining).map((e) => e.path)));
  }

  Future<void> locate() async {
    setState(() => locating = true);
    try {
      final p = await LocationService.currentPosition();
      if (p != null && mounted)
        setState(() {
          lat = p.latitude;
          lng = p.longitude;
          accuracy = p.accuracy;
          positionSource = 'gps';
        });
    } finally {
      if (mounted) setState(() => locating = false);
    }
  }

  Future<void> _helpIdentify() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: WildColors.ivory,
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Cosa hai trovato?', style: WildText.h1),
              const SizedBox(height: 6),
              const Text(
                'Salviamo correttamente l’osservazione anche se la specie non è ancora identificata.',
                style: TextStyle(color: WildColors.muted),
              ),
              const SizedBox(height: 12),
              _HelpTile(
                icon: Icons.pets_outlined,
                title: 'Animale non identificato',
                value: 'Animale',
              ),
              _HelpTile(
                icon: Icons.pets,
                title: 'Impronta o traccia',
                value: 'Impronta',
              ),
              _HelpTile(
                icon: Icons.article_outlined,
                title: 'Penna, pelo o resto',
                value: 'Penna',
              ),
              _HelpTile(
                icon: Icons.scatter_plot_outlined,
                title: 'Fatta / escrementi',
                value: 'Fatta',
              ),
            ],
          ),
        ),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      kind = result;
      selectedSpecies = 'Specie non identificata';
    });
    final addPhoto = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Aggiungere una foto?'),
        content: const Text(
          'Una foto nitida di forma, dimensioni e contesto renderà molto più semplice identificare la traccia in seguito.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Non ora'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Scatta foto'),
          ),
        ],
      ),
    );
    if (addPhoto == true) await pickCamera();
  }

  Future<Sighting?> persist() async {
    if (saving) return null;
    setState(() => saving = true);
    try {
      final id = const Uuid().v4();
      final stored = <String>[];
      for (var i = 0; i < photos.length; i++) {
        final path = await MediaStorageService.instance.persistPhoto(
          photos[i],
          '$id-$i',
        );
        if (path != null) stored.add(path);
      }
      final row = Sighting(
        id: id,
        species: selectedSpecies,
        count: count,
        notes: notes.text.trim(),
        latitude: lat,
        longitude: lng,
        timestamp: DateTime.now(),
        photoPath: stored.firstOrNull,
        kind: kind,
        accuracy: accuracy,
        positionSource: lat == null ? 'missing' : positionSource,
      );
      await DatabaseService.instance.insertSighting(row);
      await DatabaseService.instance.replaceSightingPhotos(id, stored);
      return row;
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> saveSelectedMode() async {
    final row = await persist();
    if (!mounted || row == null) return;
    if (!publicMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Avvistamento salvato nel diario privato.'),
        ),
      );
      return;
    }
    if (!row.hasPosition) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Salvato in privato. Per pubblicare aggiungi prima la posizione.',
          ),
        ),
      );
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => PublishScreen(initial: row)),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: WildColors.ivory,
    body: CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: SizedBox(
            height: 157,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const WildLandscape(height: 157),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x08FFFFFF),
                        Color(0xC8F8F6EF),
                        WildColors.ivory,
                      ],
                      stops: [0, .67, 1],
                    ),
                  ),
                ),
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => Navigator.maybePop(context),
                              icon: const Icon(
                                Icons.arrow_back_ios_new,
                                color: WildColors.forest,
                              ),
                            ),
                            const WildLogo(compact: true),
                            const Spacer(),
                            const Icon(
                              Icons.notifications_none,
                              color: WildColors.forest,
                            ),
                          ],
                        ),
                        const Spacer(),
                        const FittedBox(
                          alignment: Alignment.centerLeft,
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Nuovo avvistamento',
                            style: TextStyle(
                              fontFamily: 'serif',
                              fontSize: 27,
                              height: 1,
                              fontWeight: FontWeight.w800,
                              color: WildColors.ink,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Cosa hai osservato?',
                          style: TextStyle(
                            fontSize: 17,
                            color: WildColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 120),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Row(
                children: [
                  Expanded(
                    child: _KindCard(
                      asset: 'kind_animal.jpg',
                      label: 'Animale',
                      icon: Icons.pets,
                      active:
                          kind == 'Animale' &&
                          selectedSpecies != 'Specie non identificata',
                      onTap: () => setState(() {
                        kind = 'Animale';
                        if (selectedSpecies == 'Specie non identificata')
                          selectedSpecies = 'Cervo';
                      }),
                    ),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: _KindCard(
                      asset: 'kind_track.jpg',
                      label: 'Impronta /\ntraccia',
                      icon: Icons.pets_outlined,
                      active: kind == 'Impronta',
                      onTap: () => setState(() => kind = 'Impronta'),
                    ),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: _KindCard(
                      asset: 'kind_feather.jpg',
                      label: 'Penna / resto',
                      icon: Icons.article_outlined,
                      active: kind == 'Penna',
                      onTap: () => setState(() => kind = 'Penna'),
                    ),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: _KindCard(
                      asset: 'kind_unknown.jpg',
                      label: 'Non so,\naiutami',
                      icon: Icons.search,
                      active: selectedSpecies == 'Specie non identificata',
                      onTap: _helpIdentify,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _Panel(
                title: 'Foto',
                subtitle: 'facoltativa ma consigliata',
                child: SizedBox(
                  height: 86,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      InkWell(
                        onTap: photos.length >= 5
                            ? null
                            : () => showModalBottomSheet<void>(
                                context: context,
                                builder: (sheet) => SafeArea(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ListTile(
                                        leading: const Icon(Icons.camera_alt),
                                        title: const Text('Scatta foto'),
                                        onTap: () {
                                          Navigator.pop(sheet);
                                          pickCamera();
                                        },
                                      ),
                                      ListTile(
                                        leading: const Icon(
                                          Icons.photo_library_outlined,
                                        ),
                                        title: const Text(
                                          'Scegli dalla galleria',
                                        ),
                                        onTap: () {
                                          Navigator.pop(sheet);
                                          pickGallery();
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                        child: Container(
                          width: 116,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: WildColors.muted.withValues(alpha: .4),
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.camera_alt,
                                color: WildColors.forest,
                                size: 28,
                              ),
                              SizedBox(height: 5),
                              Text(
                                'Aggiungi foto',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      for (var i = 0; i < photos.length; i++)
                        Container(
                          width: 78,
                          margin: const EdgeInsets.only(right: 8),
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(
                                    File(photos[i]),
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 0,
                                top: 0,
                                child: IconButton.filled(
                                  onPressed: () =>
                                      setState(() => photos.removeAt(i)),
                                  icon: const Icon(Icons.close, size: 15),
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.black54,
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size(25, 25),
                                    padding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _Panel(
                title: 'Specie',
                trailing: 'Cerca o seleziona',
                child: InkWell(
                  onTap: () async {
                    final result = await showModalBottomSheet<String>(
                      context: context,
                      showDragHandle: true,
                      builder: (_) => ListView(
                        children: [
                          for (final a in animals)
                            ListTile(
                              leading: SpeciesIcon(a.name, size: 34),
                              title: Text(a.name),
                              subtitle: Text(a.latin),
                              onTap: () => Navigator.pop(context, a.name),
                            ),
                        ],
                      ),
                    );
                    if (result != null && mounted)
                      setState(() {
                        selectedSpecies = result;
                        kind = 'Animale';
                      });
                  },
                  child: Row(
                    children: [
                      WildAnimalIllustration(selectedSpecies, size: 66),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              selectedSpecies,
                              style: const TextStyle(
                                fontFamily: 'serif',
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              animals
                                      .where((a) => a.name == selectedSpecies)
                                      .map((a) => a.latin)
                                      .firstOrNull ??
                                  'Da identificare',
                              style: const TextStyle(
                                fontStyle: FontStyle.italic,
                                color: WildColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _Panel(
                title: 'Numero di individui',
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton.filledTonal(
                      onPressed: count > 1
                          ? () => setState(() => count--)
                          : null,
                      icon: const Icon(Icons.remove),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 26),
                      child: Text(
                        '$count',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton.filledTonal(
                      onPressed: () => setState(() => count++),
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              _Panel(
                title: 'Posizione',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const WildIconDisc(Icons.location_on, size: 48),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            lat == null
                                ? 'Posizione non ancora scelta'
                                : '${lat!.toStringAsFixed(5)}, ${lng!.toStringAsFixed(5)}\n${positionSource == 'manual' ? 'Punto scelto sulla mappa' : 'GPS · precisione ±${accuracy?.toStringAsFixed(0) ?? '—'} m'}',
                            style: const TextStyle(color: WildColors.muted),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton.tonalIcon(
                          onPressed: locating ? null : locate,
                          icon: const Icon(Icons.my_location, size: 18),
                          label: Text(
                            locating ? 'GPS…' : 'Usa posizione attuale',
                          ),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: chooseOnMap,
                          icon: const Icon(Icons.map_outlined, size: 18),
                          label: const Text('Scegli sulla mappa'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              _Panel(
                title: 'Note',
                subtitle: 'facoltativo',
                child: TextField(
                  controller: notes,
                  minLines: 2,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    hintText: 'Es. comportamento, habitat, condizioni…',
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _Panel(
                title: 'Modalità di pubblicazione',
                child: Row(
                  children: [
                    Expanded(
                      child: _PrivacyChoice(
                        icon: Icons.lock,
                        title: 'Privato',
                        subtitle: 'Solo per te',
                        active: !publicMode,
                        onTap: () => setState(() => publicMode = false),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: _PrivacyChoice(
                        icon: Icons.groups,
                        title: 'Pubblico',
                        subtitle: 'Community',
                        active: publicMode,
                        onTap: () => setState(() => publicMode = true),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: saving
                          ? null
                          : () {
                              setState(() => publicMode = false);
                              saveSelectedMode();
                            },
                      icon: const Icon(Icons.lock),
                      label: const Text('Salva privato'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 48),
                        backgroundColor: WildColors.cream,
                        foregroundColor: WildColors.forest,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: saving
                          ? null
                          : () {
                              setState(() => publicMode = true);
                              saveSelectedMode();
                            },
                      icon: const Icon(Icons.send),
                      label: const Text('Pubblica'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 48),
                      ),
                    ),
                  ),
                ],
              ),
            ]),
          ),
        ),
      ],
    ),
  );
}

class _HelpTile extends StatelessWidget {
  const _HelpTile({
    required this.icon,
    required this.title,
    required this.value,
  });
  final IconData icon;
  final String title;
  final String value;
  @override
  Widget build(BuildContext context) => ListTile(
    leading: WildIconDisc(icon),
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
    trailing: const Icon(Icons.chevron_right),
    onTap: () => Navigator.pop(context, value),
  );
}

class _KindCard extends StatelessWidget {
  const _KindCard({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
    this.asset,
  });
  final String? asset;
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(20),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      height: 119,
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: active ? WildColors.sageSoft : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: active ? const Color(0xFF8CB883) : const Color(0x10000000),
          width: 1.2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (asset != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'assets/approved/$asset',
                height: 52,
                width: 65,
                fit: BoxFit.contain,
              ),
            )
          else
            Icon(
              icon,
              size: 40,
              color: active ? WildColors.forest : WildColors.earth,
            ),
          const SizedBox(height: 5),
          Text(
            label,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              height: 1.05,
            ),
          ),
        ],
      ),
    ),
  );
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.title,
    required this.child,
    this.subtitle,
    this.trailing,
  });
  final String title;
  final String? subtitle;
  final String? trailing;
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: const Color(0x12000000)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 5,
          runSpacing: 3,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'serif',
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (subtitle != null)
              Text(
                '($subtitle)',
                style: const TextStyle(fontSize: 11, color: WildColors.muted),
              ),
            if (trailing != null)
              Text(
                trailing!,
                style: const TextStyle(fontSize: 11, color: WildColors.forest),
              ),
          ],
        ),
        const SizedBox(height: 10),
        child,
      ],
    ),
  );
}

class _PrivacyChoice extends StatelessWidget {
  const _PrivacyChoice({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.active,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final bool active;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: active ? WildColors.sageSoft : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: active ? const Color(0xFF79A873) : const Color(0x22000000),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: active ? WildColors.forest : WildColors.muted),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 9, color: WildColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
