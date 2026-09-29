import 'package:flutter/material.dart';
import '../services/tracking_service.dart';

class RecordScreen extends StatefulWidget {
  const RecordScreen({super.key});
  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> {
  final TrackingService tracker = TrackingService();

  @override
  void dispose() {
    tracker.dispose();
    super.dispose();
  }

  String _km(double m) => (m / 1000).toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registra uscita')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Metric(label: 'Distanza', value: '${_km(tracker.distanceMeters)} km'),
            _Metric(label: 'Dislivello +', value: '${tracker.ascentMeters.toStringAsFixed(0)} m'),
            _Metric(label: 'Punti GPS', value: '${tracker.points.length}'),
            const Spacer(),
            FilledButton.icon(
              onPressed: () async {
                if (!tracker.isTracking) {
                  final ok = await tracker.start(() {
                    if (mounted) setState(() {});
                  });
                  if (!ok && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('GPS non disponibile o permesso negato.')),
                    );
                  }
                } else {
                  final session = await tracker.stop();
                  if (mounted) {
                    setState(() {});
                    if (session != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Uscita salvata.')),
                      );
                    }
                  }
                }
              },
              icon: Icon(tracker.isTracking ? Icons.stop : Icons.play_arrow),
              label: Text(tracker.isTracking ? 'Termina e salva' : 'Avvia registrazione'),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  const _Metric({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          title: Text(label),
          trailing: Text(value, style: Theme.of(context).textTheme.titleLarge),
        ),
      );
}
