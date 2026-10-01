from pathlib import Path

# Small compile-time normalizations required by the repository's generated Flutter layout.
for ui_path in [Path('lib/premium_ui.dart'), Path('lib/screens/premium_ui.dart')]:
    if ui_path.exists():
        text = ui_path.read_text().replace(
            "p.lineTo(s.width, s.height)..close();",
            "p.lineTo(s.width, s.height);\n    p.close();",
        )
        ui_path.write_text(text)

access = Path('lib/screens/access_screen.dart')
if access.exists():
    text = access.read_text().replace("import 'auth_service.dart';", "import '../services/auth_service.dart';")
    access.write_text(text)

exploration_service = Path('lib/services/exploration_service.dart')
if exploration_service.exists():
    text = exploration_service.read_text().replace('^(hiking|foot)$"]', '^(hiking|foot)\\$"]')
    exploration_service.write_text(text)

private_maps = Path('lib/screens/private_maps_screen.dart')
if private_maps.exists():
    text = private_maps.read_text()
    if "import 'expedition_tools_screen.dart';" not in text:
        text = text.replace("import 'community_screen.dart';", "import 'community_screen.dart';\nimport 'expedition_tools_screen.dart';")
    text = text.replace(
        "_MapPreview(memberCount: mapMembers.length),",
        "InkWell(borderRadius: BorderRadius.circular(26), onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => ExpeditionMapScreen(mapId: '${current['id']}', mapName: '${current['name'] ?? 'Spedizione'}'))), child: _MapPreview(memberCount: mapMembers.length)),",
    )
    text = text.replace(
        "const _ExpeditionCard(icon: Icons.chat_bubble_outline, title: 'Messaggi', body: 'Comunica con il gruppo durante la spedizione.', tint: Color(0xFFEAF2F3)),",
        "_ExpeditionCard(icon: Icons.chat_bubble_outline, title: 'Messaggi', body: 'Comunica con il gruppo durante la spedizione.', tint: const Color(0xFFEAF2F3), onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => ExpeditionMessagesScreen(mapId: '${current['id']}', mapName: '${current['name'] ?? 'Spedizione'}')))),",
    )
    text = text.replace(
        "const _ExpeditionCard(icon: Icons.visibility_outlined, title: 'Avvistamenti\\ndel gruppo', body: 'Tutti gli avvistamenti condivisi.', tint: Color(0xFFF4E9D9)),",
        "_ExpeditionCard(icon: Icons.visibility_outlined, title: 'Avvistamenti\\ndel gruppo', body: 'Tutti gli avvistamenti condivisi.', tint: const Color(0xFFF4E9D9), onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => ExpeditionSightingsScreen(mapId: '${current['id']}', mapName: '${current['name'] ?? 'Spedizione'}')))),",
    )
    private_maps.write_text(text)

field_tools = Path('lib/screens/field_tools_screen.dart')
if field_tools.exists():
    text = field_tools.read_text()
    additions = []
    if "import 'package:share_plus/share_plus.dart';" not in text:
        additions.append("import 'package:share_plus/share_plus.dart';")
    if "import 'camera_assistant_screen.dart';" not in text:
        additions.append("import 'camera_assistant_screen.dart';")
    if "import 'mission_action_screen.dart';" not in text:
        additions.append("import 'mission_action_screen.dart';")
    if "import 'lens_assistant_screen.dart';" not in text:
        additions.append("import 'lens_assistant_screen.dart';")
    if additions:
        text = text.replace("import '../premium_ui.dart';", "import '../premium_ui.dart';\n" + "\n".join(additions))
    text = text.replace("_PhotoMode(snapshot: snapshot),", "CameraAssistantCard(snapshot: snapshot),")
    text = text.replace("_Mission(mission: m),", "MissionActionCard(mission: m),")
    text = text.replace(
        "onShare: () => _copyPassport(report, first.length),",
        "onShare: () => SharePlus.instance.share(ShareParams(text: 'WildTrack · Passaporto naturalistico\\n${report.uniqueSpecies} specie · ${first.length} lifer · ${sessions.length} uscite · ${report.seasons}/4 stagioni · ${report.geoCells} aree · indice biodiversità ${report.score}/100')) ,",
    )
    old_lens = "const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [\n                Icon(Icons.auto_awesome_outlined, color: WildColors.earth),\n                SizedBox(width: 10),\n                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [\n                  Text('WildTrack Lens', style: TextStyle(fontWeight: FontWeight.w900)),\n                  SizedBox(height: 3),\n                  Text('Resta separato finché non colleghiamo un motore di riconoscimento reale. Nessuna falsa identificazione “AI” viene mostrata come certezza.', style: TextStyle(fontSize: 11, color: WildColors.muted, height: 1.3)),\n                ])),\n              ]),"
    new_lens = "InkWell(onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const LensAssistantScreen())), borderRadius: BorderRadius.circular(18), child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(Icons.auto_awesome_outlined, color: WildColors.earth), SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('WildTrack Lens', style: TextStyle(fontWeight: FontWeight.w900)), SizedBox(height: 3), Text('Fotografa o descrivi una traccia e restringi le alternative con un livello di confidenza esplicito.', style: TextStyle(fontSize: 11, color: WildColors.muted, height: 1.3))])), Icon(Icons.chevron_right)])),"
    text = text.replace(old_lens, new_lens)
    field_tools.write_text(text)

stats = Path('lib/screens/premium_stats_screen.dart')
if stats.exists():
    text = stats.read_text()
    if "import 'real_geo_stats_widget.dart';" not in text:
        text = text.replace("import '../premium_ui.dart';", "import '../premium_ui.dart';\nimport 'real_geo_stats_widget.dart';")
    text = text.replace(
        "const Expanded(child:_Panel(title:'Heatmap privata',child:_HeatmapIllustration())),",
        "Expanded(child:_Panel(title:'Heatmap privata',child:RealHeatmap(sightings:sightings))),",
    )
    text = text.replace(
        "const _Panel(title:'Regioni / province visitate',child:_RegionsIllustration()),",
        "_Panel(title:'Regioni / province visitate',child:RealRegions(sightings:sightings)),",
    )
    stats.write_text(text)

replacements = {
    Path('lib/screens/premium_explore_screen.dart'): [
        (
            "CircleAvatar(radius: 18, backgroundImage: AssetImage('intro_cervo.jpg'))",
            "CircleAvatar(radius: 18, backgroundColor: WildColors.sage, child: Icon(Icons.person_outline, color: WildColors.forest))",
        ),
        (
            "ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.asset('intro_cervo.jpg', width: 135, height: 145, fit: BoxFit.cover))",
            "ClipRRect(borderRadius: BorderRadius.circular(16), child: const SizedBox(width: 135, height: 145, child: WildLandscape(height: 145)))",
        ),
    ],
    Path('lib/screens/private_maps_screen.dart'): [
        (
            "Image.asset('intro_cervo.jpg', fit: BoxFit.cover)",
            "const WildLandscape(height: 260)",
        ),
    ],
    Path('lib/screens/premium_stats_screen.dart'): [
        (
            "Text(session.title ?? 'Uscita',style:",
            "Text('Uscita',style:",
        ),
    ],
}

for path, rules in replacements.items():
    if not path.exists():
        continue
    text = path.read_text()
    for old, new in rules:
        text = text.replace(old, new)
    path.write_text(text)

active = [
    'home_screen.dart',
    'intro_screen.dart',
    'access_screen.dart',
    'premium_sighting_screen.dart',
    'premium_community_screen.dart',
    'premium_animal_screen.dart',
    'premium_stats_screen.dart',
    'settings_screen.dart',
]
for name in active:
    path = Path('lib/screens') / name
    if path.exists() and "Image.asset('intro_" in path.read_text():
        raise SystemExit(f'Decorative photo still present in active UI: {name}')
