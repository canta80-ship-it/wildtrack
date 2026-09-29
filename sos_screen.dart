import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class SosScreen extends StatefulWidget {
  const SosScreen({super.key});
  @override
  State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen> {
  Position? position;
  bool busy = false;
  String? error;
  @override
  void initState() {
    super.initState();
    locate();
  }

  Future<void> locate() async {
    setState(() {
      busy = true;
      error = null;
      position = null;
    });
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw Exception('Attiva la posizione del telefono.');
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception(
          'Autorizza la posizione dalle impostazioni del telefono.',
        );
      }
      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
        throw Exception('Permesso GPS non concesso.');
      }
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      if (mounted) setState(() => position = p);
    } on TimeoutException {
      if (mounted) {
        setState(
          () => error =
              'GPS non disponibile entro 20 secondi. Puoi chiamare comunque.',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> call() async {
    try {
      if (!await launchUrl(Uri(scheme: 'tel', path: '112'))) throw Exception();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Apri il telefono e componi 112.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = position;
    return Scaffold(
      appBar: AppBar(title: const Text('SOS · Emergenza')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Chiama i soccorsi',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF9C282B),
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(64),
            ),
            onPressed: call,
            icon: const Icon(Icons.phone),
            label: const Text(
              'Apri telefono · 112',
              style: TextStyle(fontSize: 22),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'Conferma la chiamata nel telefono. Non aspettare il GPS per chiedere aiuto.',
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Coordinate da comunicare',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  if (busy) const LinearProgressIndicator(),
                  if (error != null) Text(error!),
                  if (p != null) ...[
                    SelectableText(
                      'Latitudine ${p.latitude.toStringAsFixed(6)}\nLongitudine ${p.longitude.toStringAsFixed(6)}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'WGS84 · gradi decimali\nPrecisione stimata ±${p.accuracy.toStringAsFixed(0)} m\nRilevata ${DateFormat('dd/MM HH:mm:ss').format(p.timestamp.toLocal())}',
                    ),
                    if (p.accuracy > 100)
                      const Text(
                        'Precisione bassa: comunica anche punti di riferimento.',
                      ),
                    TextButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(
                          ClipboardData(
                            text:
                                'Posizione WGS84: ${p.latitude.toStringAsFixed(6)}, ${p.longitude.toStringAsFixed(6)}. Precisione ±${p.accuracy.toStringAsFixed(0)} m. Rilevata ${p.timestamp.toIso8601String()}.',
                          ),
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Coordinate copiate')),
                          );
                        }
                      },
                      icon: const Icon(Icons.copy),
                      label: const Text('Copia coordinate'),
                    ),
                  ],
                  OutlinedButton.icon(
                    onPressed: busy ? null : locate,
                    icon: const Icon(Icons.gps_fixed),
                    label: const Text('Aggiorna GPS'),
                  ),
                  TextButton(
                    onPressed: () => Geolocator.openLocationSettings(),
                    child: const Text('Impostazioni posizione'),
                  ),
                ],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 16),
            child: Text(
              'Indica cosa è successo, quante persone sono coinvolte e dove ti trovi. Segui l’operatore. Le coordinate non vengono inviate automaticamente ai soccorsi. Senza copertura telefonica la chiamata potrebbe non riuscire.',
            ),
          ),
        ],
      ),
    );
  }
}
