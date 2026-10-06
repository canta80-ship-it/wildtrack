import 'package:flutter/material.dart';

import '../models/track_session.dart';
import '../services/outing_management_service.dart';

class OutingDeleteButton extends StatefulWidget {
  const OutingDeleteButton({super.key, required this.session, this.onDeleted});
  final TrackSession session;
  final VoidCallback? onDeleted;
  @override
  State<OutingDeleteButton> createState() => _OutingDeleteButtonState();
}

class _OutingDeleteButtonState extends State<OutingDeleteButton> {
  bool busy = false, confirming = false;
  Future<void> remove() async {
    if (busy || confirming) return;
    confirming = true;
    try {
      final accepted = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            'Eliminare questa uscita?',
            style: TextStyle(fontFamily: 'serif', fontWeight: FontWeight.w800),
          ),
          content: Text(
            widget.session.isPublic
                ? 'Verranno rimosse la pubblicazione nella community, la traccia GPS e le statistiche dell’uscita. Se la rimozione online non riesce, l’uscita resterà salvata. Gli avvistamenti verranno conservati.'
                : 'L’uscita e i suoi punti GPS saranno eliminati. Distanza e tempo nelle statistiche verranno aggiornati. Gli avvistamenti verranno conservati. Questa operazione non può essere annullata.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Annulla'),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF9F3F32),
              ),
              onPressed: () => Navigator.pop(c, true),
              icon: const Icon(Icons.delete_outline),
              label: const Text('Elimina uscita'),
            ),
          ],
        ),
      );
      confirming = false;
      if (accepted != true || !mounted) return;
      setState(() => busy = true);
      await OutingManagementService.instance.delete(widget.session);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Uscita eliminata. Statistiche aggiornate.'),
        ),
      );
      widget.onDeleted?.call();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Eliminazione non riuscita: ${e.toString().replaceFirst('Exception: ', '')}',
            ),
          ),
        );
    } finally {
      confirming = false;
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => busy
      ? const SizedBox(
          width: 40,
          height: 40,
          child: Padding(
            padding: EdgeInsets.all(10),
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        )
      : IconButton.filledTonal(
          tooltip: 'Elimina uscita',
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xFFF7E6DF),
            foregroundColor: const Color(0xFF9F3F32),
          ),
          onPressed: remove,
          icon: const Icon(Icons.delete_outline),
        );
}
