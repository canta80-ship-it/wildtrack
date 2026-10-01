import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'access_screen.dart';
import 'settings_screen.dart';
import '../premium_ui.dart';

class IntroScreen extends StatelessWidget {
  const IntroScreen({super.key, required this.home});
  final Widget home;
  void openAccess(BuildContext context, {bool register = false}) =>
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => AccessScreen(home: home, register: register),
        ),
      );
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: WildColors.ivory,
    body: LayoutBuilder(
      builder: (context, box) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: box.maxHeight),
          child: IntrinsicHeight(
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    'assets/approved/welcome_scene.jpg',
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.high,
                  ),
                ),
                const Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xCCF8F6EF),
                          Color(0x00F8F6EF),
                          Color(0xB01D3526),
                          WildColors.ivory,
                        ],
                        stops: [0, .32, .66, 1],
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 55, 20, 20),
                    child: Column(
                      children: [
                        const FittedBox(child: WildLogo()),
                        const SizedBox(height: 12),
                        const Text(
                          'Osserva. Registra. Esplora.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'serif',
                            fontSize: 21,
                            fontWeight: FontWeight.w700,
                            color: WildColors.forest,
                          ),
                        ),
                        const Spacer(),
                        const SizedBox(height: 240),
                        const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _Benefit(
                              icon: WildIcons.binoculars,
                              title: 'Scopri la fauna',
                              body: 'Esplora sentieri, habitat e specie nel tuo territorio.',
                            ),
                            SizedBox(width: 10),
                            _Benefit(
                              icon: CupertinoIcons.doc_text,
                              title: 'Registra avvistamenti',
                              body: 'Contribuisci alla conoscenza della biodiversità.',
                            ),
                            SizedBox(width: 10),
                            _Benefit(
                              icon: CupertinoIcons.leaf_arrow_circlepath,
                              title: 'Proteggi la natura',
                              body: 'I tuoi dati aiutano la ricerca e la conservazione.',
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        InkWell(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => const SettingsScreen(),
                            ),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(13),
                            decoration: BoxDecoration(
                              color: const Color(0xDAEEF0E3),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Row(
                              children: [
                                WildIconDisc(Icons.lock, size: 37),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'I tuoi dati sono al sicuro',
                                        style: TextStyle(
                                          fontFamily: 'serif',
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                        ),
                                      ),
                                      SizedBox(height: 3),
                                      Text(
                                        'La tua privacy è la nostra priorità.\nCondividi solo ciò che desideri.',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: WildColors.muted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.chevron_right),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        WildPrimaryButton(
                          label: 'Accedi',
                          icon: Icons.arrow_forward,
                          onPressed: () => openAccess(context),
                        ),
                        const SizedBox(height: 7),
                        SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: FilledButton(
                            onPressed: () =>
                                openAccess(context, register: true),
                            style: FilledButton.styleFrom(
                              backgroundColor: WildColors.ivory,
                              foregroundColor: WildColors.forest,
                            ),
                            child: const Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Crea account',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: 'serif',
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                Icon(Icons.arrow_forward),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        TextButton.icon(
                          onPressed: () => Navigator.of(context)
                              .pushReplacement(
                                MaterialPageRoute<void>(builder: (_) => home),
                              ),
                          iconAlignment: IconAlignment.end,
                          icon: const Icon(Icons.arrow_forward, size: 17),
                          label: const Text(
                            'Continua come ospite',
                            style: TextStyle(
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: WildColors.forest,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.circle,
                              size: 8,
                              color: WildColors.forest,
                            ),
                            SizedBox(width: 12),
                            Icon(Icons.circle, size: 8, color: WildColors.sand),
                            SizedBox(width: 12),
                            Icon(Icons.circle, size: 8, color: WildColors.sand),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _Benefit extends StatelessWidget {
  const _Benefit({required this.icon, required this.title, required this.body});
  final IconData icon;
  final String title, body;
  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        WildIconDisc(
          icon,
          size: 43,
          background: const Color(0xB045664A),
          foreground: WildColors.ivory,
        ),
        const SizedBox(height: 8),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'serif',
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: WildColors.ivory,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          body,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 11,
            height: 1.2,
            color: Color(0xFFE5E7D7),
          ),
        ),
      ],
    ),
  );
}
