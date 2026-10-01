from pathlib import Path

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

# Active premium UI must never use bundled intro JPGs as decoration.
# User-provided/community photos are permitted because they are real content.
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
