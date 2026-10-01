import 'package:flutter/material.dart';

import 'access_screen.dart';
import 'book_widget.dart';
import '../premium_ui.dart';

class IntroScreen extends StatelessWidget {
  const IntroScreen({super.key, required this.home});
  final Widget home;

  void openAccess(BuildContext context, {bool register = false}) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => AccessScreen(home: home, register: register)));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: WildColors.ivory,
        body: Stack(
          fit: StackFit.expand,
          children: [
            const BookPhoto(asset: 'intro_cervo.jpg', alignment: Alignment.center),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x10FFFFFF),
                    Color(0x00121F16),
                    Color(0x30121F16),
                    Color(0xE0173325),
                  ],
                  stops: [0, .35, .58, 1],
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 30, 24, 20),
                child: Column(
                  children: [
                    const WildLogo(light: true),
                    const SizedBox(height: 8),
                    const Text(
                      'NATURA  •  SCOPERTA  •  CONSERVAZIONE',
                      style: TextStyle(fontSize: 9, letterSpacing: 1.7, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                    const Spacer(),
                    const Text(
                      'Osserva. Riconosci. Ricorda.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontFamily: 'serif', fontSize: 30, height: 1, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xEFFFFEF9),
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 24, offset: Offset(0, 8))],
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Benefit(icon: Icons.visibility_outlined, title: 'Scopri', body: 'Fauna, habitat e sentieri'),
                          SizedBox(width: 8),
                          _Benefit(icon: Icons.photo_camera_outlined, title: 'Avvista', body: 'Registra foto e posizione'),
                          SizedBox(width: 8),
                          _Benefit(icon: Icons.menu_book_outlined, title: 'Ricorda', body: 'Costruisci il tuo diario'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    WildPrimaryButton(label: 'Accedi', icon: Icons.arrow_forward, onPressed: () => openAccess(context)),
                    const SizedBox(height: 10),
                    WildOutlineButton(label: 'Crea account', icon: Icons.arrow_forward, onPressed: () => openAccess(context, register: true)),
                    const SizedBox(height: 7),
                    TextButton.icon(
                      onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute<void>(builder: (_) => home)),
                      iconAlignment: IconAlignment.end,
                      icon: const Icon(Icons.arrow_forward, size: 18),
                      label: const Text('Continua come ospite', style: TextStyle(fontSize: 15, decoration: TextDecoration.underline)),
                      style: TextButton.styleFrom(foregroundColor: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
}

class _Benefit extends StatelessWidget {
  const _Benefit({required this.icon, required this.title, required this.body});
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: const BoxDecoration(color: WildColors.sageSoft, shape: BoxShape.circle),
              child: Icon(icon, color: WildColors.forest),
            ),
            const SizedBox(height: 8),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'serif', fontWeight: FontWeight.w800, fontSize: 15, color: WildColors.ink)),
            const SizedBox(height: 3),
            Text(body, textAlign: TextAlign.center, style: const TextStyle(color: WildColors.muted, fontSize: 10, height: 1.25)),
          ],
        ),
      );
}
