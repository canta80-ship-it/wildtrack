from pathlib import Path

# Refine the illustrated species taxonomy used across Home, Radar, Community and species cards.
for ui_path in [Path('lib/premium_ui.dart'), Path('lib/screens/premium_ui.dart')]:
    if not ui_path.exists():
        continue
    text = ui_path.read_text()
    text = text.replace("if (n.contains('lupo')) return _AnimalKind.wolf;", "if (n.contains('lupo') || n.contains('sciacallo')) return _AnimalKind.wolf;")
    text = text.replace("if (n.contains('tasso') || n.contains('martora') || n.contains('faina') || n.contains('lontra')) return _AnimalKind.mustelid;", "if (n.contains('tasso') || n.contains('martora') || n.contains('faina') || n.contains('lontra') || n.contains('ermellino')) return _AnimalKind.mustelid;")
    text = text.replace("if (n.contains('gufo') || n.contains('civetta') || n.contains('allocco')) return _AnimalKind.owl;", "if (n.contains('gufo') || n.contains('civetta') || n.contains('allocco') || n.contains('barbagianni')) return _AnimalKind.owl;")
    text = text.replace("if (n.contains('poiana') || n.contains('aquila') || n.contains('falco') || n.contains('gheppio')) return _AnimalKind.raptor;", "if (n.contains('poiana') || n.contains('aquila') || n.contains('falco') || n.contains('gheppio') || n.contains('grifone')) return _AnimalKind.raptor;")
    text = text.replace("if (n.contains('airone') || n.contains('germano') || n.contains('picchio') || n.contains('ucc') || n.contains('anatra')) return _AnimalKind.bird;", "if (n.contains('airone') || n.contains('germano') || n.contains('picchio') || n.contains('ucc') || n.contains('anatra') || n.contains('gracchio') || n.contains('ghiandaia')) return _AnimalKind.bird;")
    ui_path.write_text(text)

# A chevron is a promise. Make every recent outing row open its actual stored diary.
stats = Path('lib/screens/premium_stats_screen.dart')
if stats.exists():
    text = stats.read_text()
    if "import 'outing_diary_screen.dart';" not in text:
        text = text.replace("import '../premium_ui.dart';", "import '../premium_ui.dart';\nimport 'outing_diary_screen.dart';")
    text = text.replace(
        "Column(children:[for(final s in sessions.take(5)) _TripRow(session:s)])",
        "Column(children:[for(final s in sessions.take(5)) InkWell(borderRadius: BorderRadius.circular(16), onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => OutingDiaryScreen(session:s))), child:_TripRow(session:s))])",
    )
    stats.write_text(text)
