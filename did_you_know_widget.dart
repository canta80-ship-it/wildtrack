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

class _DidYouKnowCarouselState extends State<DidYouKnowCarousel> {
  late Future<DidYouKnowFeed> feed;

  @override
  void initState() {
    super.initState();
    feed = DidYouKnowService.instance.load();
  }

  Future<void> _refresh() async {
    final next = DidYouKnowService.instance.load(force: true);
    setState(() => feed = next);
    await next;
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WildSectionTitle('Sapevi che…', action: 'Aggiorna', onAction: _refresh),
          const SizedBox(height: 5),
          FutureBuilder<DidYouKnowFeed>(
            future: feed,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SizedBox(height: 218, child: Center(child: CircularProgressIndicator()));
              }
              final data = snapshot.data!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.fromCache
                        ? 'Contenuti salvati · si aggiornano automaticamente quando torna la rete'
                        : 'Aggiornato ${DateFormat('HH:mm').format(data.updatedAt)} · fonti e curiosità selezionate',
                    style: const TextStyle(fontSize: 9.5, color: WildColors.muted),
                  ),
                  const SizedBox(height: 9),
                  SizedBox(
                    height: 220,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: data.items.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, index) => _FeedCard(item: data.items[index]),
                    ),
                  ),
                ],
              );
            },
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

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 285,
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: item.link == null || item.link!.isEmpty
                ? null
                : () => launchUrl(Uri.parse(item.link!), mode: LaunchMode.externalApplication),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(item.asset, fit: BoxFit.cover),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x22000000), Color(0x22000000), Color(0xDD0B2117)],
                      stops: [0, .28, 1],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                          decoration: BoxDecoration(color: const Color(0xDDF8F6EF), borderRadius: BorderRadius.circular(15)),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(icon, size: 14, color: WildColors.forest),
                            const SizedBox(width: 4),
                            Text(item.category, style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, letterSpacing: .5, color: WildColors.forest)),
                          ]),
                        ),
                        const Spacer(),
                        if (item.isLive)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                            decoration: BoxDecoration(color: const Color(0xDDF3E3B8), borderRadius: BorderRadius.circular(14)),
                            child: const Row(children: [
                              Icon(Icons.sync, size: 12, color: WildColors.earth),
                              SizedBox(width: 3),
                              Text('LIVE', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: WildColors.earth)),
                            ]),
                          ),
                      ]),
                      const Spacer(),
                      Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: 'serif', color: Colors.white, fontSize: 20, height: 1.05, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      Text(item.body, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFFE5EBE6), fontSize: 10.5, height: 1.25)),
                      const SizedBox(height: 8),
                      Row(children: [
                        Expanded(child: Text('${item.source} · ${DateFormat('d MMM', 'it').format(item.publishedAt)}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 9))),
                        if (item.link != null) const Icon(Icons.arrow_forward, color: Colors.white, size: 17),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
