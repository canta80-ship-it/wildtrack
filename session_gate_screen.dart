import 'package:flutter/material.dart';

import '../services/auth_service.dart';

/// Restores the saved account before deciding which first screen to show.
class SessionGate extends StatefulWidget {
  const SessionGate({super.key, required this.home, required this.welcome});
  final Widget home;
  final Widget welcome;
  @override
  State<SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<SessionGate> {
  late Future<String?> session = AuthService.instance.currentUsername();
  @override
  Widget build(BuildContext context) => FutureBuilder<String?>(
    future: session,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      if (snapshot.hasError) {
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Impossibile leggere la sessione. I tuoi dati restano sul telefono.',
                ),
                TextButton(
                  onPressed: () => setState(
                    () => session = AuthService.instance.currentUsername(),
                  ),
                  child: const Text('Riprova'),
                ),
              ],
            ),
          ),
        );
      }
      return snapshot.data == null ? widget.welcome : widget.home;
    },
  );
}
