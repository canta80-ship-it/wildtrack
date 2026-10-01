from pathlib import Path
import zipfile
required={'access_land2.jpg','welcome_scene.jpg','cervo_hero.jpg','cervo_thumb.jpg','capriolo_thumb.jpg','volpe_thumb.jpg','poiana_thumb.jpg','habitat.jpg','impronta.jpg','fatte.jpg','sfregamenti.jpg','palchi.jpg','outing_scene.jpg','kind_animal.jpg','kind_track.jpg','kind_feather.jpg','kind_unknown.jpg'}
with zipfile.ZipFile('approved_assets.zip') as z:
 assert z.testzip() is None,'Corrupt approved artwork archive'
 assert required <= set(z.namelist()),'Missing required approved artwork'
 for name in required:
  assert (Path('assets/approved')/name).read_bytes()==z.read(name),f'Artwork mismatch: {name}'
print('Verified all 17 approved reference artwork files and archive integrity')
