from pathlib import Path

ROOT = Path('lib/screens')
SKIP = {
    'book_widget.dart',
    'access_screen.dart',
    'intro_screen.dart',
    'premium_animal_screen.dart',
    'premium_home_screen.dart',
}

for path in ROOT.glob('*.dart'):
    if path.name in SKIP:
        continue
    text = path.read_text(encoding='utf-8')
    original = text
    text = text.replace('WildLandscape(', 'BookLandscape(')
    text = text.replace('WildAnimalIllustration(', 'BookAnimalIllustration(')
    text = text.replace('WildHero(', 'BookLegacyHero(')
    if text != original:
        import_line = "import 'book_widget.dart';\n"
        if import_line not in text:
            text = import_line + text
        path.write_text(text, encoding='utf-8')
        print(f'bookified {path}')
