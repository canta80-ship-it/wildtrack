from pathlib import Path

# Imports and navigation wiring that must survive the generated Flutter layout.
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
