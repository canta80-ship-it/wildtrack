import 'package:flutter/material.dart';
import 'access_screen.dart';
import 'premium_ui.dart';

class IntroScreen extends StatelessWidget {
  const IntroScreen({super.key, required this.home});
  final Widget home;

  void openAccess(BuildContext context, {bool register = false}) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => AccessScreen(home: home, register: register)));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: WildColors.ivory,
    body: Stack(fit: StackFit.expand, children: [
      Image.asset('intro_cervo.jpg', fit: BoxFit.cover, alignment: const Alignment(.25, -.12)),
      const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x08FFFFFF), Color(0x00121F16), Color(0x2D0C1C13), Color(0xD20C1C13), WildColors.ivory],
            stops: [0, .36, .56, .77, 1],
          ),
        ),
      ),
      SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 30, 24, 18),
          child: Column(children: [
            const WildLogo(),
            const SizedBox(height: 8),
            const Text('Osserva. Registra. Esplora.', style: TextStyle(fontFamily: 'serif', fontSize: 18, fontWeight: FontWeight.w700, color: WildColors.ink)),
            const Spacer(),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: const [
              Expanded(child: _Benefit(icon: Icons.binoculars_outlined, title: 'Scopri la fauna', body: 'Esplora sentieri, habitat e specie nel tuo territorio.')),
              SizedBox(width: 8),
              Expanded(child: _Benefit(icon: Icons.description_outlined, title: 'Registra avvistamenti', body: 'Costruisci il tuo diario naturalistico.')),
              SizedBox(width: 8),
              Expanded(child: _Benefit(icon: Icons.eco_outlined, title: 'Proteggi la natura', body: 'Condividi solo ciò che desideri.')),
            ]),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: .78), borderRadius: BorderRadius.circular(20)),
              child: const Row(children: [
                WildIconDisc(Icons.lock_outline, size: 42, background: Color(0xFFE2EADC)),
                SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('I tuoi dati sono al sicuro', style: TextStyle(fontWeight: FontWeight.w800, color: WildColors.ink)),
                  SizedBox(height: 2),
                  Text('La tua privacy è la nostra priorità. Condividi solo ciò che desideri.', style: TextStyle(fontSize: 12, color: WildColors.muted)),
                ])),
                Icon(Icons.chevron_right, color: WildColors.forest),
              ]),
            ),
            const SizedBox(height: 14),
            WildPrimaryButton(label: 'Accedi', icon: Icons.arrow_forward, onPressed: () => openAccess(context)),
            const SizedBox(height: 10),
            WildOutlineButton(label: 'Crea account', icon: Icons.arrow_forward, onPressed: () => openAccess(context, register: true)),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute<void>(builder: (_) => home)),
              iconAlignment: IconAlignment.end,
              icon: const Icon(Icons.arrow_forward, size: 18),
              label: const Text('Continua come ospite', style: TextStyle(fontSize: 15, decoration: TextDecoration.underline)),
              style: TextButton.styleFrom(foregroundColor: WildColors.forest),
            ),
            const SizedBox(height: 2),
            const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _Dot(active: true), SizedBox(width: 9), _Dot(), SizedBox(width: 9), _Dot(),
            ]),
          ]),
        ),
      ),
    ]),
  );
}

class _Benefit extends StatelessWidget {
  const _Benefit({required this.icon, required this.title, required this.body});
  final IconData icon;
  final String title;
  final String body;
  @override
  Widget build(BuildContext context) => Column(children: [
    WildIconDisc(icon, background: const Color(0xB028563C), foreground: Colors.white, size: 48),
    const SizedBox(height: 8),
    Text(title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontFamily: 'serif', fontWeight: FontWeight.w700, fontSize: 14)),
    const SizedBox(height: 4),
    Text(body, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFDDE5DC), fontSize: 10, height: 1.25)),
  ]);
}

class _Dot extends StatelessWidget {
  const _Dot({this.active = false});
  final bool active;
  @override
  Widget build(BuildContext context) => Container(width: active ? 12 : 8, height: 8, decoration: BoxDecoration(color: active ? WildColors.forest : const Color(0xFFD8CDBB), borderRadius: BorderRadius.circular(8)));
}
