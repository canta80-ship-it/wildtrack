import 'package:flutter/material.dart';
import '../services/community_service.dart';
import '../premium_ui.dart';

class CommunityDeleteButton extends StatefulWidget {
  const CommunityDeleteButton({super.key, required this.sighting});
  final Map<String, dynamic> sighting;
  @override
  State<CommunityDeleteButton> createState() => _CommunityDeleteButtonState();
}
class _CommunityDeleteButtonState extends State<CommunityDeleteButton> {
  bool busy = false;
  Future<void> remove() async {
    final approved = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text('Eliminare questo avvistamento?'),
      content: const Text('Il post verrà rimosso dalla Community e dal tuo diario. Solo tu, come creatore, puoi eliminarlo.'),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annulla')),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Elimina'))],
    ));
    if (approved != true || !mounted) return;
    setState(() => busy = true);
    try {
      await CommunityService.instance.deleteSighting('${widget.sighting['id']}');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Avvistamento eliminato.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    } finally { if (mounted) setState(() => busy = false); }
  }
  @override
  Widget build(BuildContext context) {
    if (!CommunityService.instance.isMine(widget.sighting)) return const SizedBox.shrink();
    return Padding(padding: const EdgeInsets.only(top: 8), child: OutlinedButton.icon(
      style: OutlinedButton.styleFrom(foregroundColor: WildColors.forest, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
      onPressed: busy ? null : remove, icon: const Icon(Icons.delete_outline), label: Text(busy ? 'Eliminazione…' : 'Elimina avvistamento')));
  }
}
