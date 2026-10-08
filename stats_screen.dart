import 'premium_screen.dart';
import 'package:flutter/material.dart';
import '../services/database_service.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});
  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  int sightings = 0;
  int sessions = 0;
  int animals = 0;
  double distance = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final values = await DatabaseService.instance.statistics();
      if (!mounted) return;
      setState(() {
        sightings = values['sightings']!.toInt();
        sessions = values['sessions']!.toInt();
        animals = values['animals']!.toInt();
        distance = values['distance']!.toDouble();
      });
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Statistiche non disponibili: $e')),
        );
    }
  }

  @override
  Widget build(BuildContext context) => PremiumScaffold(
    appBar: AppBar(title: const Text('Statistiche')),
    body: RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const PremiumHeading(
            'Le tracce dei tuoi incontri.',
            eyebrow: 'Il tuo riepilogo',
          ),
          _Stat(icon: Icons.pets, label: 'Avvistamenti', value: '$sightings'),
          _Stat(
            icon: Icons.groups,
            label: 'Animali osservati',
            value: '$animals',
          ),
          _Stat(
            icon: Icons.route,
            label: 'Uscite registrate',
            value: '$sessions',
          ),
          _Stat(
            icon: Icons.hiking,
            label: 'Distanza totale',
            value: '${(distance / 1000).toStringAsFixed(1)} km',
          ),
        ],
      ),
    ),
  );
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _Stat({required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Icon(icon, size: 34),
          const SizedBox(width: 16),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.titleMedium),
          ),
          Text(value, style: Theme.of(context).textTheme.headlineSmall),
        ],
      ),
    ),
  );
}
