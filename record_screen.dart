import 'premium_screen.dart';
import 'package:flutter/material.dart';

import '../services/tracking_service.dart';

class RecordScreen extends StatefulWidget {
  const RecordScreen({super.key});
  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> {
  final TrackingService tracker = TrackingService.instance;
  @override
  void initState() {
    super.initState();
    tracker.addListener(changed);
  }

  void changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    tracker.removeListener(changed);
    super.dispose();
  }

  String _km(double m) => (m / 1000).toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    return PremiumScaffold(
      appBar: AppBar(title: const Text('Registra uscita')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            const PremiumHeading(
              'Il tuo percorso, punto dopo punto.',
              eyebrow: 'Registrazione GPS',
            ),
            _Metric(
              label: 'Distanza',
              value: '${_km(tracker.distanceMeters)} km',
            ),
            _Metric(
              label: 'Dislivello +',
              value: '${tracker.ascentMeters.toStringAsFixed(0)} m',
            ),
            _Metric(label: 'Punti GPS', value: '${tracker.points.length}'),
            const Text(
              'Il percorso continua a schermo spento. Ogni punto viene salvato sul telefono; per fermare premi Termina. Un arresto forzato interrompe il GPS, ma conserva i punti già scritti.',
            ),
            if (tracker.error != null) Text(tracker.error!),
            const SizedBox(height: 24),
            PremiumFilledButton.icon(
              onPressed: tracker.busy
                  ? null
                  : () async {
                      try {
                        if (!tracker.isTracking) {
                          final ok = await tracker.start();
                          if (!mounted) return;
                          if (!ok) {
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'GPS non disponibile o permesso negato.',
                                ),
                              ),
                            );
                          }
                        } else {
                          final session = await tracker.stop();
                          if (!mounted) return;
                          {
                            setState(() {});
                            if (session != null) {
                              ScaffoldMessenger.of(this.context).showSnackBar(
                                const SnackBar(
                                  content: Text('Uscita salvata.'),
                                ),
                              );
                            }
                          }
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('$e')));
                        }
                      }
                    },
              icon: Icon(tracker.isTracking ? Icons.stop : Icons.play_arrow),
              label: Text(
                tracker.isTracking ? 'Termina e salva' : 'Avvia registrazione',
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
              ),
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
  Widget build(BuildContext context) {
    final featured = label == 'Distanza';
    final content = Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w600,
              color: featured
                  ? const Color(0xFFD2DFC1)
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: TextStyle(
              fontSize: featured ? 42 : 30,
              letterSpacing: -1,
              color: featured
                  ? const Color(0xFFF7FAEF)
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
    return featured
        ? Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(23),
              gradient: const LinearGradient(
                colors: [Color(0xFF214A35), Color(0xFF57764E)],
              ),
            ),
            child: content,
          )
        : Card(child: content);
  }
}
