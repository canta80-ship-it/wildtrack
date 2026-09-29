"""Resolve real public data at build time; no credentials or paid services."""
import concurrent.futures,json,time,urllib.request,urllib.parse,pathlib
NAMES=['Cervus elaphus','Capreolus capreolus','Vulpes vulpes','Rupicapra rupicapra','Capra ibex','Sus scrofa','Aquila chrysaetos','Buteo buteo','Strix aluco','Dryocopus martius','Gyps fulvus','Ardea cinerea','Anas platyrhynchos','Circus aeruginosus','Ursus arctos','Canis lupus','Canis aureus','Marmota marmota','Mustela erminea','Meles meles','Pyrrhocorax graculus','Bubo bubo','Tyto alba','Garrulus glandarius']
PLACES=[('Cansiglio',46.061,12.403),('Gran Paradiso',45.594,7.356),('Abruzzo',41.76,13.908),('Sila',39.38,16.54),('Etna',37.795,15.037),('Sardegna',40.12,9.25)]
def read(url,data=None):
 req=urllib.request.Request(url,data=data,headers={'User-Agent':'WildTrack/0.4 (https://github.com/canta80-ship-it/wildtrack)'})
 with urllib.request.urlopen(req,timeout=30) as r:return json.load(r)
def taxon(n):
 try:
  d=read('https://api.gbif.org/v1/species/match?strict=true&name='+urllib.parse.quote(n))
  assert d.get('matchType')=='EXACT'
  return n,d.get('acceptedUsageKey',d['usageKey'])
 except Exception as e: print('Taxon unavailable',n,str(e));return n,None
def trails(place):
 name,lat,lng=place
 q=f'[out:json][timeout:20];relation["route"~"^(hiking|foot)$"](around:5000,{lat},{lng});out tags geom;'
 try:
  d=read('https://overpass-api.de/api/interpreter',urllib.parse.urlencode({'data':q}).encode())
  if d.get('remark'):raise ValueError('Incomplete response')
  out=[]
  for e in d.get('elements',[]):
   if e['type']!='relation':continue
   segments=[[[p['lat'],p['lon']] for p in m['geometry'] if p and 'lat' in p] for m in e.get('members',[]) if m['type']=='way' and m.get('geometry')]
   segments=[s for s in segments if len(s)>1]
   if not segments:continue
   t=e.get('tags',{});out.append(dict(id=e['id'],name=t.get('name',t.get('ref',f'Itinerario {e["id"]}')),ref=t.get('ref',''),difficulty=t.get('sac_scale','Non indicata'),segments=segments,source=f'https://www.openstreetmap.org/relation/{e["id"]}',area=name))
  # Include compact, complete relation geometries; never draw synthetic joins.
  return sorted(out,key=lambda t:sum(len(s) for s in t['segments']))[:4]
 except Exception as e:print('Trails unavailable',name,str(e));return []
with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:taxa=dict(pool.map(taxon,NAMES))
all_trails=[]
# Respect the public Overpass service: serial bounded requests.
for place in PLACES:all_trails.extend(trails(place));time.sleep(1)
assert sum(v is not None for v in taxa.values())==24,'All catalogue taxa must resolve'
assert all_trails,'No real trail geometry acquired; do not ship an empty preset catalogue'
pathlib.Path('nature_assets.json').write_text(json.dumps({'taxa':taxa,'trails':all_trails,'source':'GBIF and © OpenStreetMap contributors · ODbL','fetchedAt':time.strftime('%Y-%m-%dT%H:%M:%SZ',time.gmtime())}))
print('Resolved taxa:',len(taxa),'Real bundled itineraries:',len(all_trails))
