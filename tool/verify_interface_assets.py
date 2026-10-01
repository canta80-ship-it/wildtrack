from pathlib import Path
import zipfile
required={'access_land2.jpg','welcome_scene.jpg','cervo_hero.jpg','cervo_thumb.jpg','capriolo_thumb.jpg','volpe_thumb.jpg','poiana_thumb.jpg','habitat.jpg','impronta.jpg','fatte.jpg','sfregamenti.jpg','palchi.jpg','outing_scene.jpg','kind_animal.jpg','kind_track.jpg','kind_feather.jpg','kind_unknown.jpg'}
import json
heroes=json.loads(Path('docs/SPECIES_ARTWORK.json').read_text())
assert len(heroes)==24
required.update(v['file'] for v in heroes.values())
with zipfile.ZipFile('approved_assets.zip') as z:
 assert z.testzip() is None,'Corrupt approved artwork archive'
 assert required <= set(z.namelist()),'Missing required approved artwork'
 for name in required:
  assert (Path('assets/approved')/name).read_bytes()==z.read(name),f'Artwork mismatch: {name}'
print('Verified reference artwork and 24 distinct species heroes; archive integrity passed')

with zipfile.ZipFile('editorial_fonts.zip') as z:
 assert z.testzip() is None
 for name in ['editorial_serif.ttf','editorial_serif_italic.ttf','editorial_serif_OFL.txt','interface_sans.ttf','interface_sans_OFL.txt']:
  assert (Path('assets/approved')/name).read_bytes()==z.read(name)
print('Verified bundled editorial serif family and license')
