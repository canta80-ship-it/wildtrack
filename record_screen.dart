import 'dart:async';

import 'package:flutter/material.dart';

import '../services/tracking_service.dart';
import '../premium_ui.dart';

class RecordScreen extends StatefulWidget {
  const RecordScreen({super.key});
  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> {
  final TrackingService tracker = TrackingService.instance;
  Timer? ticker;

  @override
  void initState() {
    super.initState();
    tracker.addListener(changed);
    ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && tracker.isTracking) setState(() {});
    });
  }

  void changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    ticker?.cancel();
    tracker.removeListener(changed);
    super.dispose();
  }

  String _km(double m) => (m / 1000).toStringAsFixed(m >= 10000 ? 1 : 2);
  String _meters(double? value) => value == null ? '—' : '${value.toStringAsFixed(0)} m';
  String _percent(double? value) => value == null ? '—' : '${value >= 0 ? '+' : ''}${value.toStringAsFixed(1)}%';
  String _speed(double? mps) => mps == null ? '—' : '${(mps * 3.6).toStringAsFixed(1)} km/h';

  String _elapsed(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String _gpsLabel() {
    final a = tracker.gpsAccuracyMeters;
    if (a == null) return 'In attesa del GPS';
    if (a <= 10) return 'GPS ottimo · ±${a.toStringAsFixed(0)} m';
    if (a <= 25) return 'GPS buono · ±${a.toStringAsFixed(0)} m';
    if (a <= 60) return 'GPS discreto · ±${a.toStringAsFixed(0)} m';
    return 'GPS debole · ±${a.toStringAsFixed(0)} m';
  }

  Color _gpsColor() {
    final a = tracker.gpsAccuracyMeters;
    if (a == null) return const Color(0xFFF0C66F);
    if (a <= 10) return const Color(0xFF8BD47A);
    if (a <= 25) return const Color(0xFFB4D27B);
    return const Color(0xFFF0C66F);
  }

  Future<void> _toggle() async {
    try {
      if (!tracker.isTracking) {
        final ok = await tracker.start();
        if (!mounted) return;
        if (!ok) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('GPS non disponibile o permesso negato.')),
          );
        }
      } else {
        final session = await tracker.stop();
        if (!mounted) return;
        if (session != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Uscita salvata nel diario.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final active = tracker.isTracking;
    final currentSpeed = tracker.currentSpeedMps ?? (tracker.averageSpeedMps > 0 ? tracker.averageSpeedMps : null);

    return Scaffold(
      backgroundColor: WildColors.ivory,
      body: CustomScrollView(slivers: [
        SliverToBoxAdapter(
          child: WildHero(
            image: 'intro_marmotta.jpg',
            height: 330,
            alignment: const Alignment(.08, -.2),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 22),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                    ),
                    const WildLogo(compact: true, light: true),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: const Color(0x99173F2B),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.white30),
                      ),
                      child: Row(children: [
                        Container(width: 8, height: 8, decoration: BoxDecoration(color: active ? const Color(0xFF8BE278) : Colors.white54, shape: BoxShape.circle)),
                        const SizedBox(width: 7),
                        Text(active ? 'REGISTRAZIONE ATTIVA' : 'PRONTO', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: .7)),
                      ]),
                    ),
                  ]),
                  const Spacer(),
                  const Text('Registra attività', style: TextStyle(fontFamily: 'serif', color: Colors.white, fontSize: 37, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 5),
                  Text(active ? 'La tua uscita viene registrata sul dispositivo.' : 'Avvia il tracciamento quando inizi l’escursione.', style: const TextStyle(color: Colors.white, fontSize: 14)),
                  const SizedBox(height: 18),
                  Text(_elapsed(tracker.elapsed), style: const TextStyle(color: Colors.white, fontSize: 44, fontWeight: FontWeight.w900, letterSpacing: -1.6)),
                  const SizedBox(height: 8),
                  Row(children: [
                    Icon(Icons.gps_fixed, color: _gpsColor(), size: 18),
                    const SizedBox(width: 6),
                    Text(_gpsLabel(), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                  ]),
                ]),
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 110),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.55,
                children: [
                  _MetricCard(icon: Icons.route_outlined, label: 'Distanza', value: '${_km(tracker.distanceMeters)} km', tint: WildColors.sageSoft),
                  _MetricCard(icon: Icons.speed_outlined, label: 'Velocità', value: _speed(currentSpeed), tint: const Color(0xFFF3E9DB)),
                  _MetricCard(icon: Icons.trending_up, label: 'Dislivello +', value: _meters(tracker.ascentMeters), tint: WildColors.sageSoft),
                  _MetricCard(icon: Icons.trending_down, label: 'Dislivello −', value: _meters(tracker.descentMeters), tint: const Color(0xFFF3E9DB)),
                  _MetricCard(icon: Icons.landscape_outlined, label: 'Quota attuale', value: _meters(tracker.currentAltitudeMeters), tint: const Color(0xFFEAF2F3)),
                  _MetricCard(icon: Icons.show_chart, label: 'Pendenza attuale', value: _percent(tracker.currentGradePercent), tint: const Color(0xFFF4E9D9)),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Altimetria', style: WildText.h2),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _SmallStat(label: 'Quota min', value: _meters(tracker.minAltitudeMeters))),
                    Expanded(child: _SmallStat(label: 'Quota max', value: _meters(tracker.maxAltitudeMeters))),
                    Expanded(child: _SmallStat(label: 'Pendenza media', value: _percent(tracker.averageGradePercent))),
                  ]),
                  const SizedBox(height: 12),
                  _GradeBar(value: tracker.currentGradePercent),
                ]),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                child: Row(children: [
                  const WildIconDisc(Icons.satellite_alt_outlined, size: 52),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Qualità registrazione', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                    const SizedBox(height: 3),
                    Text(_gpsLabel(), style: const TextStyle(fontSize: 11, color: WildColors.muted)),
                    const SizedBox(height: 2),
                    Text('${tracker.points.length} punti GPS · precisione altimetrica ${tracker.altitudeAccuracyMeters == null ? '—' : '±${tracker.altitudeAccuracyMeters!.toStringAsFixed(0)} m'}', style: const TextStyle(fontSize: 10, color: WildColors.muted)),
                  ])),
                ]),
              ),
              if (tracker.error != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: const Color(0xFFFFE9E2), borderRadius: BorderRadius.circular(18)),
                  child: Row(children: [const Icon(Icons.warning_amber_rounded), const SizedBox(width: 8), Expanded(child: Text(tracker.error!, style: const TextStyle(fontSize: 11)))]),
                ),
              ],
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: WildColors.sageSoft, borderRadius: BorderRadius.circular(20)),
                child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(Icons.info_outline, color: WildColors.forest),
                  SizedBox(width: 9),
                  Expanded(child: Text('Il tracciamento continua a schermo spento. I punti vengono salvati progressivamente sul telefono. Le variazioni altimetriche molto piccole vengono filtrate per limitare il rumore GPS.', style: TextStyle(fontSize: 10, height: 1.3))),
                ]),
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 62,
                child: FilledButton.icon(
                  onPressed: tracker.busy ? null : _toggle,
                  icon: Icon(active ? Icons.stop_circle_outlined : Icons.play_arrow_rounded, size: 28),
                  label: Text(tracker.busy ? 'Operazione in corso…' : active ? 'Termina e salva attività' : 'Avvia registrazione', style: const TextStyle(fontWeight: FontWeight.w900)),
                  style: FilledButton.styleFrom(
                    backgroundColor: active ? const Color(0xFF6A3B31) : WildColors.forest,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.icon, required this.label, required this.value, required this.tint});
  final IconData icon;
  final String label, value;
  final Color tint;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(22)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: WildColors.forest, size: 24),
          const Spacer(),
          Text(label, style: const TextStyle(fontSize: 10, color: WildColors.muted, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
        ]),
      );
}

class _SmallStat extends StatelessWidget {
  const _SmallStat({required this.label, required this.value});
  final String label, value;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 9, color: WildColors.muted)),
        const SizedBox(height: 3),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
      ]);
}

class _GradeBar extends StatelessWidget {
  const _GradeBar({required this.value});
  final double? value;
  @override
  Widget build(BuildContext context) {
    final v = (value ?? 0).clamp(-25.0, 25.0);
    final position = (v + 25) / 50;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Row(children: [Text('−25%', style: TextStyle(fontSize: 8, color: WildColors.muted)), Spacer(), Text('0%', style: TextStyle(fontSize: 8, color: WildColors.muted)), Spacer(), Text('+25%', style: TextStyle(fontSize: 8, color: WildColors.muted))]),
      const SizedBox(height: 5),
      LayoutBuilder(builder: (context, c) => SizedBox(
            height: 20,
            child: Stack(children: [
              Positioned.fill(child: Container(decoration: BoxDecoration(color: const Color(0xFFE8E8E1), borderRadius: BorderRadius.circular(10)))),
              Positioned(left: (c.maxWidth - 14) * position, top: 2, child: Container(width: 14, height: 16, decoration: BoxDecoration(color: WildColors.forest, borderRadius: BorderRadius.circular(8)))),
            ]),
          )),
    ]);
  }
}
