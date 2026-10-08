import 'premium_screen.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key, required this.home});
  final Widget home;
  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> with WidgetsBindingObserver {
  final pages = PageController();
  Timer? timer;
  bool logo = true, finished = false, configured = false, manual = false;
  int selected = 0;
  static const slides = [
    ('Cervo', 'Cervus elaphus', 'intro_cervo.jpg'),
    ('Lupo', 'Canis lupus', 'intro_lupo.jpg'),
    ('Marmotta', 'Marmota marmota', 'intro_marmotta.jpg'),
    ('Gufo reale', 'Bubo bubo', 'intro_gufo.jpg'),
  ];
  static const green = Color(0xFFB4CD91);
  static const ink = Color(0xFF102B22);
  static const signature = 'A Trek.king.dolomiti App';
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!configured) {
      configured = true;
      manual = MediaQuery.of(context).disableAnimations;
      if (!manual) schedule(const Duration(milliseconds: 1800));
    }
  }

  void schedule(Duration duration) {
    timer?.cancel();
    if (finished || manual) return;
    timer = Timer(duration, () {
      if (!mounted) return;
      if (logo) {
        setState(() => logo = false);
        schedule(const Duration(milliseconds: 2300));
      } else if (selected < slides.length - 1) {
        pages.animateToPage(
          selected + 1,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeInOut,
        );
        schedule(const Duration(milliseconds: 2300));
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      timer?.cancel();
    } else if (!finished) {
      schedule(const Duration(milliseconds: 2300));
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    pages.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void enter() {
    timer?.cancel();
    setState(() => finished = true);
  }

  Future<void> credits() async {
    final text = await rootBundle.loadString('INTRO_CREDITS.txt');
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Crediti fotografici'),
        content: SingleChildScrollView(child: SelectableText(text)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Chiudi'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (finished) return widget.home;
    final pixels =
        (MediaQuery.sizeOf(context).width *
                MediaQuery.devicePixelRatioOf(context))
            .round()
            .clamp(1, 1600);
    return PremiumScaffold(
      backgroundColor: ink,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
            final height = math.max(
              constraints.maxHeight,
              680.0 * scale.clamp(1.0, 1.5),
            );
            return SingleChildScrollView(
              child: SizedBox(
                height: height,
                child: logo
                    ? DecoratedBox(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF193B2D), Color(0xFF09221D)],
                          ),
                        ),
                        child: Stack(
                          children: [
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(26),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ClipOval(
                                      child: Image.asset(
                                        'intro_logo.jpg',
                                        width: 240,
                                        height: 200,
                                        cacheWidth: 600,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    const SizedBox(height: 26),
                                    const Text(
                                      'WildTrack',
                                      style: TextStyle(
                                        color: Color(0xFFEDF4E0),
                                        fontSize: 43,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: -2,
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    const Text(
                                      'Ogni incontro\nlascia una traccia.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Color(0xFFC5D6B2),
                                        fontFamily: 'WildTrackSerif',
                                        fontSize: 19,
                                        height: 1.5,
                                      ),
                                    ),
                                    const SizedBox(height: 32),
                                    SizedBox(
                                      width: double.infinity,
                                      child: PremiumFilledButton(
                                        onPressed: () {
                                          timer?.cancel();
                                          setState(() {
                                            logo = false;
                                            manual = true;
                                          });
                                        },
                                        style: FilledButton.styleFrom(
                                          backgroundColor: green,
                                          foregroundColor: ink,
                                        ),
                                        child: const Text('Scopri gli animali'),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              top: 6,
                              right: 16,
                              child: TextButton(
                                onPressed: enter,
                                child: const Text(
                                  'Salta',
                                  style: TextStyle(color: green),
                                ),
                              ),
                            ),
                            const Positioned(
                              bottom: 28,
                              left: 18,
                              right: 18,
                              child: Text(
                                signature,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Color(0xFFC4D2B4),
                                  fontSize: 11,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : Stack(
                        children: [
                          Positioned.fill(
                            child:
                                NotificationListener<ScrollStartNotification>(
                                  onNotification: (notice) {
                                    if (notice.dragDetails != null) {
                                      manual = true;
                                      timer?.cancel();
                                    }
                                    return false;
                                  },
                                  child: PageView.builder(
                                    controller: pages,
                                    itemCount: slides.length,
                                    onPageChanged: (i) =>
                                        setState(() => selected = i),
                                    itemBuilder: (context, i) {
                                      final slide = slides[i];
                                      return Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          Image.asset(
                                            slide.$3,
                                            cacheWidth: pixels,
                                            fit: BoxFit.cover,
                                            semanticLabel: slide.$1,
                                          ),
                                          const DecoratedBox(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                                colors: [
                                                  Color(0x44102B22),
                                                  Colors.transparent,
                                                  Color(0xDD09281D),
                                                  Color(0xFF09261D),
                                                ],
                                                stops: [0, .3, .65, 1],
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            bottom: 232 * scale,
                                            left: 27,
                                            right: 27,
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  'INCONTRI SELVATICI',
                                                  style: TextStyle(
                                                    color: Color(0xFFD0DFB7),
                                                    fontSize: 10,
                                                    letterSpacing: 1.8,
                                                  ),
                                                ),
                                                const SizedBox(height: 10),
                                                Text(
                                                  slide.$1,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontFamily:
                                                        'WildTrackSerif',
                                                    fontSize: 40,
                                                    letterSpacing: -1.3,
                                                  ),
                                                ),
                                                const SizedBox(height: 5),
                                                Text(
                                                  slide.$2,
                                                  style: const TextStyle(
                                                    color: Color(0xFFD4DEC6),
                                                    fontSize: 13,
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                          ),
                          Positioned(
                            top: 10,
                            left: 24,
                            right: 12,
                            child: Row(
                              children: [
                                const Text(
                                  'WildTrack',
                                  style: TextStyle(
                                    color: Color(0xFFEDF4E0),
                                    fontSize: 23,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const Spacer(),
                                TextButton(
                                  onPressed: enter,
                                  child: const Text(
                                    'Salta',
                                    style: TextStyle(color: green),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            bottom: 20,
                            left: 26,
                            right: 26,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: List.generate(
                                    slides.length,
                                    (i) => Semantics(
                                      selected: selected == i,
                                      child: IconButton(
                                        tooltip: slides[i].$1,
                                        onPressed: () {
                                          manual = true;
                                          timer?.cancel();
                                          pages.jumpToPage(i);
                                        },
                                        icon: AnimatedContainer(
                                          duration: manual
                                              ? Duration.zero
                                              : const Duration(
                                                  milliseconds: 120,
                                                ),
                                          width: selected == i ? 22 : 6,
                                          height: 6,
                                          decoration: BoxDecoration(
                                            color: selected == i
                                                ? green
                                                : const Color(0xFF68745E),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const Text(
                                  'Osserva. Riconosci. Ricorda.',
                                  style: TextStyle(
                                    color: Color(0xFFD1DEC3),
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  child: PremiumFilledButton(
                                    onPressed: enter,
                                    style: FilledButton.styleFrom(
                                      backgroundColor: green,
                                      foregroundColor: ink,
                                    ),
                                    child: const Text('Entra in WildTrack  ↗'),
                                  ),
                                ),
                                const SizedBox(height: 18),
                                const Center(
                                  child: Text(
                                    signature,
                                    style: TextStyle(
                                      color: Color(0xFFC4D2B4),
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                                Center(
                                  child: TextButton(
                                    onPressed: credits,
                                    child: const Text(
                                      'Crediti foto',
                                      style: TextStyle(
                                        color: Color(0xFFC4D2B4),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
              ),
            );
          },
        ),
      ),
    );
  }
}
