import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/sighting.dart';
import '../premium_ui.dart';
import '../services/community_service.dart';
import '../services/database_service.dart';
import '../services/sighting_management_service.dart';

class SightingDiaryScreen extends StatefulWidget {
  const SightingDiaryScreen({super.key});
  @override
  State<SightingDiaryScreen> createState() => _SightingDiaryScreenState();
}

class _SightingDiaryScreenState extends State<SightingDiaryScreen> {
  List<Sighting> sightings = [];
  String filter = 'Tutti';
  String? busyId, error;
  @override
  void initState() {
    super.initState();
    DatabaseService.instance.changes.addListener(load);
    load();
  }

  @override
  void dispose() {
    DatabaseService.instance.changes.removeListener(load);
    super.dispose();
  }

  Future<void> load() async {
    final rows = await DatabaseService.instance.getSightings();
    if (mounted) setState(() => sightings = rows);
  }

  Future<void> remove(Sighting sighting) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Eliminare ${sighting.species}?',
          style: const TextStyle(
            fontFamily: 'serif',
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          sighting.isPublic
              ? 'L’avvistamento verrà rimosso dalla community e dal tuo diario. Se la rimozione online non riesce, il dato rimarrà disponibile per riprovare.'
              : sighting.publicationState == 'queued'
              ? 'La pubblicazione in attesa verrà annullata e l’avvistamento sarà eliminato dal diario.'
              : 'L’avvistamento verrà eliminato dal diario. Le statistiche verranno aggiornate. Questa operazione non può essere annullata.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annulla'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF9F3F32),
            ),
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Elimina'),
          ),
        ],
      ),
    );
    if (accepted != true || !mounted) return;
    setState(() {
      busyId = sighting.id;
      error = null;
    });
    try {
      await SightingManagementService.instance.delete(sighting);
      await load();
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Avvistamento eliminato. Statistiche aggiornate.'),
          ),
        );
    } catch (e) {
      if (mounted)
        setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => busyId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rows = sightings
        .where(
          (s) =>
              filter == 'Tutti' ||
              (filter == 'Privati'
                  ? s.publicationState == 'private'
                  : s.publicationState != 'private'),
        )
        .toList();
    return Scaffold(
      backgroundColor: WildColors.ivory,
      appBar: AppBar(
        title: const Text(
          'I tuoi avvistamenti',
          style: TextStyle(fontFamily: 'serif', fontWeight: FontWeight.w800),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Wrap(
              spacing: 8,
              children: [
                for (final label in ['Tutti', 'Privati', 'Pubblici'])
                  ChoiceChip(
                    label: Text(label),
                    selected: filter == label,
                    onSelected: (_) => setState(() => filter = label),
                  ),
              ],
            ),
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Eliminazione non completata: $error',
                style: const TextStyle(color: Color(0xFF9F3F32)),
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await CommunityService.instance.refresh();
                await load();
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  if (rows.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('Nessun avvistamento in questa categoria.'),
                    ),
                  for (final sighting in rows)
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: const Color(0xFFE6E8DF)),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: const WildIconDisc(
                          WildIcons.binoculars,
                          size: 44,
                        ),
                        title: Text(
                          sighting.species,
                          style: const TextStyle(
                            fontFamily: 'serif',
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                        subtitle: Text(
                          '${DateFormat('d MMM yyyy · HH:mm').format(sighting.timestamp)} · ${sighting.count} individui\n${sighting.isPublic
                              ? 'Pubblico'
                              : sighting.publicationState == 'queued'
                              ? 'Pubblicazione in attesa'
                              : 'Privato'}${sighting.notes.isEmpty ? '' : '\n${sighting.notes}'}',
                        ),
                        trailing: busyId == sighting.id
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : IconButton.filledTonal(
                                tooltip: 'Elimina ${sighting.species}',
                                style: IconButton.styleFrom(
                                  backgroundColor: const Color(0xFFF7E6DF),
                                  foregroundColor: const Color(0xFF9F3F32),
                                ),
                                onPressed: busyId == null
                                    ? () => remove(sighting)
                                    : null,
                                icon: const Icon(Icons.delete_outline),
                              ),
                      ),
                    ),
                  if (CommunityService.instance.nextOffset != null)
                    TextButton(
                      onPressed: () async {
                        await CommunityService.instance.refresh(more: true);
                        await load();
                      },
                      child: const Text('Carica altri avvistamenti pubblicati'),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
