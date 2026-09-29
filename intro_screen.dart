import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'brand_screen.dart';

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
  static const ink = Color(0xFF202020);
  static const signature = 'A Trek.king.dolomiti App';
  @override
  void initState() { super.initState(); WidgetsBinding.instance.addObserver(this); }
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
        pages.animateToPage(selected + 1, duration: const Duration(milliseconds: 450), curve: Curves.easeInOut);
        schedule(const Duration(milliseconds: 2300));
      }
    });
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) { timer?.cancel(); }
    else if (!finished) { schedule(const Duration(milliseconds: 2300)); }
  }
  @override
  void dispose() { timer?.cancel(); pages.dispose(); WidgetsBinding.instance.removeObserver(this); super.dispose(); }
  void enter() { timer?.cancel(); setState(() => finished = true); }
  Future<void> credits() async {
    final text = await rootBundle.loadString('INTRO_CREDITS.txt');
    if (!mounted) return;
    await showDialog<void>(context: context, builder: (c) => AlertDialog(
      title: const Text('Crediti fotografici'),
      content: SingleChildScrollView(child: SelectableText(text)),
      actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('Chiudi'))],
    ));
  }
  @override
  Widget build(BuildContext context) {
    if (finished) return widget.home;
    return Scaffold(
      backgroundColor: ink,
      body: SafeArea(child: logo ? Stack(children: [
        Center(child: SingleChildScrollView(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
          Image.asset('intro_logo.jpg', width: 295, height: 213, fit: BoxFit.contain),
          const SizedBox(height: 10),
          const Text('WildTrack', style: TextStyle(color: Color(0xFFE7EDDC), fontSize: 39, fontWeight: FontWeight.w500, letterSpacing: -1.8)),
          const SizedBox(height: 14),
          const Text('Ogni incontro lascia una traccia.', style: TextStyle(color: Color(0xFFAAB79D), fontSize: 13)),
          const SizedBox(height: 26),
          TextButton(onPressed: () { timer?.cancel(); setState(() { logo = false; manual = true; }); }, child: const Text('Scopri gli animali', style: TextStyle(color: green))),
        ])))),
        Positioned(top: 6, right: 16, child: TextButton(onPressed: enter, child: const Text('Salta', style: TextStyle(color: green)))),
        const Positioned(bottom: 24, left: 12, right: 12, child: Text(signature, textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFB8C3AD), fontSize: 11))),
      ]) : LayoutBuilder(builder: (context, constraints) {
        final photoHeight = (constraints.maxHeight - 245).clamp(200.0, 520.0).toDouble();
        return SingleChildScrollView(child: Column(children: [
          Padding(padding: const EdgeInsets.fromLTRB(20, 6, 12, 8), child: Row(children: [
            const WildTrackLogo(size: 36),
            const SizedBox(width: 10),
            const Text('WildTrack', style: TextStyle(color: Color(0xFFE7EDDC), fontSize: 25, fontWeight: FontWeight.w500)),
            const Spacer(),
            TextButton(onPressed: enter, child: const Text('Salta', style: TextStyle(color: green))),
          ])),
          SizedBox(height: photoHeight, child: NotificationListener<ScrollStartNotification>(onNotification: (notice) {
            if (notice.dragDetails != null) { manual = true; timer?.cancel(); }
            return false;
          }, child: PageView.builder(controller: pages, itemCount: slides.length, onPageChanged: (i) => setState(() => selected = i), itemBuilder: (context, i) {
            final slide = slides[i];
            return Stack(fit: StackFit.expand, children: [
              Image.asset(slide.$3, fit: BoxFit.cover, semanticLabel: slide.$1),
              const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Color(0x00111B16), Color(0xEE111B16)], stops: [0, .45, 1]))),
              Positioned(bottom: 25, left: 24, right: 24, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('INCONTRI SELVATICI', style: TextStyle(color: Color(0xFFD4E1BC), fontSize: 10, letterSpacing: 2)),
                const SizedBox(height: 7),
                Text(slide.$1, style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w500)),
                const SizedBox(height: 3),
                Text(slide.$2, style: const TextStyle(color: Color(0xFFDCE5D4), fontSize: 13, fontStyle: FontStyle.italic)),
              ])),
            ]);
          }))),
          Padding(padding: const EdgeInsets.fromLTRB(22, 6, 22, 8), child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(slides.length, (i) => Semantics(selected: selected == i, child: IconButton(
              tooltip: slides[i].$1,
              onPressed: () { manual = true; timer?.cancel(); pages.jumpToPage(i); },
              icon: Container(width: selected == i ? 22 : 6, height: 6, decoration: BoxDecoration(color: selected == i ? green : const Color(0xFF68745E), borderRadius: BorderRadius.circular(6))),
            )))),
            const Text('Osserva. Riconosci. Ricorda.', style: TextStyle(color: Color(0xFFAAB79D), fontSize: 12)),
            const SizedBox(height: 14),
            SizedBox(width: double.infinity, height: 46, child: FilledButton(onPressed: enter, style: FilledButton.styleFrom(backgroundColor: green, foregroundColor: const Color(0xFF1E301F), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('Entra in WildTrack  ↗'))),
            const SizedBox(height: 14),
            const Text(signature, style: TextStyle(color: Color(0xFFB8C3AD), fontSize: 11, letterSpacing: .3)),
            TextButton(onPressed: credits, child: const Text('Crediti foto', style: TextStyle(color: Color(0xFFAAB79D), fontSize: 11))),
          ])),
        ]));
      })),
    );
  }
}
