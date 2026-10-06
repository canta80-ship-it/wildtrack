"""Resolve real public data at build time; no credentials or paid services."""
import concurrent.futures,json,time,urllib.request,urllib.parse,pathlib,sys
if pathlib.Path("nature_assets.json").exists():
 d=json.loads(pathlib.Path("nature_assets.json").read_text())
 expected_new=["Lynx lynx","Ichthyosaura alpestris","Bufo bufo","Salamandra salamandra","Erinaceus europaeus","Tetrao urogallus","Lyrurus tetrix","Lepus europaeus","Sciurus vulgaris","Upupa epops","Falco tinnunculus","Otus scops","Milvus milvus","Milvus migrans"]
 for name in expected_new:
  if name not in d["taxa"]:
   req=urllib.request.Request("https://api.gbif.org/v1/species/match?strict=true&name="+urllib.parse.quote(name),headers={"User-Agent":"WildTrack/0.7.12"})
   with urllib.request.urlopen(req,timeout=20) as response: match=json.load(response)
   assert match.get("matchType")=="EXACT" and match.get("rank")=="SPECIES",name
   d["taxa"][name]=match.get("acceptedUsageKey",match["usageKey"])
 pathlib.Path("nature_assets.json").write_text(json.dumps(d))
 assert len(d["taxa"])==38 and all(isinstance(v,int) for v in d["taxa"].values())
 assert d["trails"] and all(t["segments"] for t in d["trails"])
 print("Verified bundled catalogue:",len(d["taxa"]),"taxa,",len(d["trails"]),"trails")
 sys.exit(0)
NAMES=['Lynx lynx','Ichthyosaura alpestris','Bufo bufo','Salamandra salamandra','Erinaceus europaeus','Tetrao urogallus','Lyrurus tetrix','Cervus elaphus','Capreolus capreolus','Vulpes vulpes','Rupicapra rupicapra','Capra ibex','Sus scrofa','Aquila chrysaetos','Buteo buteo','Strix aluco','Dryocopus martius','Gyps fulvus','Ardea cinerea','Anas platyrhynchos','Circus aeruginosus','Ursus arctos','Canis lupus','Canis aureus','Marmota marmota','Mustela erminea','Meles meles','Pyrrhocorax graculus','Bubo bubo','Tyto alba','Garrulus glandarius','Lepus europaeus','Sciurus vulgaris','Upupa epops','Falco tinnunculus','Otus scops','Milvus milvus','Milvus migrans']
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
 q=f'[out:json][timeout:60];relation["route"~"^(hiking|foot)$"]({lat-.05},{lng-.07},{lat+.05},{lng+.07});out body geom;'
 try:
  d=None
  for endpoint in ['https://overpass.private.coffee/api/interpreter','https://overpass-api.de/api/interpreter']:
   try:
    d=read(endpoint,urllib.parse.urlencode({'data':q}).encode())
    if d.get('remark'):raise ValueError(d['remark'])
    break
   except Exception as e:print('Provider unavailable',name,str(e),flush=True)
  if d is None:raise ValueError('No provider returned data')
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
assert sum(v is not None for v in taxa.values())==38,'All catalogue taxa must resolve'
assert all_trails,'No real trail geometry acquired; do not ship an empty preset catalogue'
pathlib.Path('nature_assets.json').write_text(json.dumps({'taxa':taxa,'trails':all_trails,'source':'GBIF and © OpenStreetMap contributors · ODbL','fetchedAt':time.strftime('%Y-%m-%dT%H:%M:%SZ',time.gmtime())}))
print('Resolved taxa:',len(taxa),'Real bundled itineraries:',len(all_trails))

