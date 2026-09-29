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
    final s = await DatabaseService.instance.getSightings();
    final r = await DatabaseService.instance.getSessions();
    if (!mounted) return;
    setState(() {
      sightings = s.length;
      sessions = r.length;
      animals = s.fold(0, (sum, e) => sum + e.count);
      distance = r.fold(0, (sum, e) => sum + e.distanceMeters);
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Statistiche')),
    body: RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
