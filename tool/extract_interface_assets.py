"""Extract unlabelled artwork from the ten user-supplied interface references.
Run with the attachment directory as the first argument. No generative substitutes.
"""
from pathlib import Path
from PIL import Image
import hashlib,json,sys,zipfile
source=Path(sys.argv[1]); out=Path('assets/approved'); out.mkdir(parents=True,exist_ok=True)
def crop(file,box,name):
    image=Image.open(source/file).convert('RGB')
    image.crop(box).save(out/name,quality=96,subsampling=0)
    return {'source':file,'box':box,'output':name,'source_sha256':hashlib.sha256((source/file).read_bytes()).hexdigest()}
rows=[]
for args in [
 ('09-1000270525.png',(88,272,776,489),'access_land2.jpg'),
 ('08-1000270526.png',(88,326,776,834),'welcome_scene.jpg'),
 ('10-1000270523.png',(111,736,251,860),'cervo_thumb.jpg'),
 ('10-1000270523.png',(284,736,422,860),'capriolo_thumb.jpg'),
 ('10-1000270523.png',(450,736,589,860),'volpe_thumb.jpg'),
 ('10-1000270523.png',(618,736,752,860),'poiana_thumb.jpg'),
 ('10-1000270523.png',(110,1017,403,1210),'outing_scene.jpg'),
 ('02-1000270528.png',(425,170,765,474),'cervo_hero.jpg'),
 ('02-1000270528.png',(110,679,395,783),'habitat.jpg'),
 ('02-1000270528.png',(110,913,258,1028),'impronta.jpg'),
 ('02-1000270528.png',(280,913,422,1028),'fatte.jpg'),
 ('02-1000270528.png',(448,913,590,1028),'sfregamenti.jpg'),
 ('02-1000270528.png',(616,913,755,1028),'palchi.jpg'),
 ('07-1000270533.png',(115,315,250,426),'kind_animal.jpg'),
 ('07-1000270533.png',(278,315,415,426),'kind_track.jpg'),
 ('07-1000270533.png',(446,315,584,426),'kind_feather.jpg'),
 ('07-1000270533.png',(616,315,752,426),'kind_unknown.jpg'),
]: rows.append(crop(*args))
Path('docs/INTERFACE_ASSETS.json').write_text(json.dumps(rows,ensure_ascii=False,indent=2)+'\n')
with zipfile.ZipFile('approved_assets.zip','w',zipfile.ZIP_DEFLATED) as z:
    for p in sorted(out.glob('*.jpg')): z.write(p,p.name)
print(f'Extracted {len(rows)} exact reference artwork elements; valid asset archive: {Path("approved_assets.zip").stat().st_size} bytes')
