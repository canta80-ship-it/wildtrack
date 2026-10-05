"""Bundle verified Wikimedia sounds, source metadata and species photos."""
import json, re, hashlib, urllib.request, urllib.parse, time
from pathlib import Path
from PIL import Image
from io import BytesIO
BASE='https://commons.wikimedia.org/w/api.php?'
def fetch(url):
    for attempt in range(4):
        try:
            with urllib.request.urlopen(urllib.request.Request(url,headers={'User-Agent':'WildTrack/0.7.19 (wildlife field guide; https://github.com/canta80-ship-it/wildtrack)'}),timeout=30) as r:return r.read()
        except Exception:
            if attempt==3:raise
            time.sleep(2+attempt*2)
def query(params):return json.loads(fetch(BASE+urllib.parse.urlencode({'action':'query','format':'json',**params})))
def file(title):
    data=query({'prop':'imageinfo','iiprop':'url|extmetadata','titles':'File:'+title})
    return next(iter(data['query']['pages'].values()))['imageinfo'][0]
def clean(s):return re.sub('<[^>]+>','',s).strip()
folder=Path('assets/audio');folder.mkdir(parents=True,exist_ok=True)
manifest={}
source=Path('lib/screens/species_screen.dart') if Path('lib/screens/species_screen.dart').exists() else Path('species_screen.dart')
titles=re.findall(r"audio:\s*'([^']+)'",source.read_text())
for title in titles:
    # This misleading grizzly recording was removed from the app.
    if title.startswith('Yellowstone'):continue
    info=file(title);url=info['url'];meta=info.get('extmetadata',{})
    license=clean(meta.get('LicenseShortName',{}).get('value',''))
    if not license:raise ValueError('No license: '+title)
    ext=Path(urllib.parse.urlsplit(url).path).suffix
    name=hashlib.sha256(title.encode()).hexdigest()[:16]+ext
    (folder/name).write_bytes(fetch(url))
    manifest[title]={'asset':'assets/audio/'+name,'credit':clean(meta.get('Artist',{}).get('value','Autore nella fonte'))+' · '+license,'page':info['descriptionurl']}
    print('Bundled audio:',title,flush=True)
(folder/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2))
