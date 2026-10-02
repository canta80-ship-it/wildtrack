import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../premium_ui.dart';
import '../services/did_you_know_service.dart';

class DidYouKnowCarousel extends StatefulWidget {
  const DidYouKnowCarousel({super.key});

  @override
  State<DidYouKnowCarousel> createState() => _DidYouKnowCarouselState();
}

class _DidYouKnowCarouselState extends State<DidYouKnowCarousel>
    with WidgetsBindingObserver {
  Timer? refreshTimer;
  late DidYouKnowFeed current;
  bool refreshing = false;
  String? warning;

  @override
  void initState() {
    super.initState();
    current = _localFeed();
    WidgetsBinding.instance.addObserver(this);
    refreshTimer = Timer.periodic(
      DidYouKnowService.refreshInterval,
      (_) => _refresh(silent: true),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh(silent: true));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh(silent: true);
  }

  @override
  void dispose() {
    refreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  DidYouKnowFeed _localFeed() {
    final now = DateTime.now();
    final items = <DidYouKnowItem>[
      DidYouKnowItem(
        id: 'local-1',
        category: 'FAUNA',
        title: 'Le tracce raccontano più dell’animale',
        body: 'Impronte, fatte, peli, penne e sfregamenti permettono di capire passaggi e comportamento senza avvicinare la fauna.',
        asset: '',
        source: 'WildTrack',
        publishedAt: now,
      ),
      DidYouKnowItem(
        id: 'local-2',
        category: 'FOTOGRAFIA',
        title: 'Il tempo rapido salva più foto dell’ISO basso',
        body: 'Con fauna in movimento e focali lunghe, un tempo rapido è spesso più importante di un file perfettamente pulito.',
        asset: '',
        source: 'WildTrack',
        publishedAt: now,
      ),
      DidYouKnowItem(
        id: 'local-3',
        category: 'OUTDOOR',
        title: 'La luce in valle può sparire prima del tramonto',
        body: 'Pareti e rilievi possono togliere luce molto prima dell’orario astronomico: pianifica il rientro sul terreno reale.',
        asset: '',
        source: 'WildTrack',
        publishedAt: now,
      ),
      DidYouKnowItem(
        id: 'local-4',
        category: 'ATTREZZATURA',
        title: 'Una batteria al caldo dura di più',
        body: 'In inverno tieni una batteria di scorta in una tasca interna: il freddo riduce sensibilmente l’autonomia disponibile.',
        asset: '',
        source: 'WildTrack',
        publishedAt: now,
      ),
    ];
    return DidYouKnowFeed(items: items, updatedAt: now, fromCache: true);
  }

  Future<void> _refresh({bool silent = false}) async {
    if (refreshing) return;
    if (mounted)
      setState(() {
        refreshing = true;
        if (!silent) warning = null;
      });
    try {
      final next = await DidYouKnowService.instance.load(force: !silent);
      if (mounted && next.items.isNotEmpty)
        setState(() {
          current = next;
          warning = null;
        });
    } catch (_) {
      if (mounted && !silent)
        setState(
          () => warning =
              'Aggiornamento non disponibile: mostro i contenuti salvati.',
        );
    } finally {
      if (mounted) setState(() => refreshing = false);
    }
  }

  double _cardHeight(BuildContext context) {
    double measure(String text, TextStyle style, double width) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      )..layout(maxWidth: width);
      final height = painter.height;
      painter.dispose();
      return height;
    }

    var height = 220.0;
    for (final item in current.items) {
      final needed =
          100 +
          measure(
            item.title,
            const TextStyle(
              fontFamily: 'serif',
              fontSize: 20,
              height: 1.05,
              fontWeight: FontWeight.w800,
            ),
            255,
          ) +
          measure(
            item.body,
            const TextStyle(fontSize: 10.5, height: 1.25),
            255,
          ) +
          measure(
            '${item.source} · ${DateFormat('d MMM').format(item.publishedAt)}',
            const TextStyle(fontSize: 9, fontWeight: FontWeight.w700),
            238,
          );
      if (needed > height) height = needed;
    }
    return height;
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      WildSectionTitle(
        'Lo sapevi che…',
        action: refreshing ? 'Aggiorno…' : 'Aggiorna',
        onAction: refreshing ? null : () => _refresh(),
      ),
      const SizedBox(height: 5),
      Text(
        current.fromCache
            ? 'Disponibile anche offline · aggiornamento automatico quando torna la rete'
            : 'Aggiornato ${DateFormat('HH:mm').format(current.updatedAt)} · fonti e curiosità selezionate',
        style: const TextStyle(fontSize: 9.5, color: WildColors.muted),
      ),
      if (warning != null)
        Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(
            warning!,
            style: const TextStyle(fontSize: 10, color: WildColors.earth),
          ),
        ),
      const SizedBox(height: 9),
      SizedBox(
        height: _cardHeight(context),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: current.items.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (context, index) =>
              _FeedCard(item: current.items[index]),
        ),
      ),
    ],
  );
}

class _FeedCard extends StatelessWidget {
  const _FeedCard({required this.item});
  final DidYouKnowItem item;

  IconData get icon => switch (item.category) {
    'FAUNA' => Icons.pets_outlined,
    'FOTOGRAFIA' => Icons.camera_alt_outlined,
    'ATTREZZATURA' => Icons.backpack_outlined,
    'ESCURSIONI' => Icons.hiking,
    'EVENTI' => Icons.event_outlined,
    'LUOGHI' => Icons.landscape_outlined,
    _ => Icons.explore_outlined,
  };

  Color get tint => switch (item.category) {
    'FAUNA' => WildColors.sageSoft,
    'FOTOGRAFIA' => const Color(0xFFE9EFF0),
    'ATTREZZATURA' => const Color(0xFFF3E9D9),
    'ESCURSIONI' => const Color(0xFFE7EFE4),
    'EVENTI' => const Color(0xFFF2E7D8),
    'LUOGHI' => const Color(0xFFE2ECE6),
    _ => WildColors.cream,
  };

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 285,
    child: Material(
      color: tint,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: item.link == null || item.link!.isEmpty
            ? null
            : () => launchUrl(
                Uri.parse(item.link!),
                mode: LaunchMode.externalApplication,
              ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: Opacity(
                opacity: .28,
                child: WildLandscape(
                  height: 220,
                  animal: item.category == 'FAUNA' ? 'Fauna' : null,
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: .05),
                    tint.withValues(alpha: .45),
                    WildColors.ivory.withValues(alpha: .97),
                  ],
                  stops: const [0, .38, 1],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .90),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(icon, size: 14, color: WildColors.forest),
                            const SizedBox(width: 4),
                            Text(
                              item.category,
                              style: const TextStyle(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: .5,
                                color: WildColors.forest,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      if (item.isLive)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xEAF3E3B8),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.sync,
                                size: 12,
                                color: WildColors.earth,
                              ),
                              SizedBox(width: 3),
                              Text(
                                'LIVE',
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w900,
                                  color: WildColors.earth,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontFamily: 'serif',
                      color: WildColors.ink,
                      fontSize: 20,
                      height: 1.05,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.body,
                    style: const TextStyle(
                      color: WildColors.muted,
                      fontSize: 10.5,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${item.source} · ${DateFormat('d MMM').format(item.publishedAt)}',
                          style: const TextStyle(
                            color: WildColors.forest,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (item.link != null)
                        const Icon(
                          Icons.arrow_forward,
                          color: WildColors.forest,
                          size: 17,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
