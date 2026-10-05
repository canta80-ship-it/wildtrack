import 'package:flutter/material.dart';
import '../services/gpx_import_service.dart';
import 'outing_diary_screen.dart';
class GpxImportButton extends StatefulWidget {
  const GpxImportButton({super.key});
  @override State<GpxImportButton> createState() => _GpxImportButtonState();
}
class _GpxImportButtonState extends State<GpxImportButton> {
  bool busy = false;
  @override Widget build(BuildContext context) => TextButton.icon(
    icon: Icon(busy ? Icons.hourglass_top : Icons.upload_file), label: const Text('Importa GPX'),
    onPressed: busy ? null : () async {
      setState(() => busy = true);
      try {
        final session = await GpxImportService.pickAndImport();
        if (session != null && context.mounted) await Navigator.push(context, MaterialPageRoute<void>(builder: (_) => OutingDiaryScreen(session: session)));
      } catch(e) { if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('FormatException: ', '')))); }
      finally {if(mounted) setState(() => busy = false);}
    });
}
