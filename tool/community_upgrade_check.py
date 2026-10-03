"""Verify the delivered APK over 0.7.14 using isolated emulator fixtures only."""
import base64,hashlib,json,re,sqlite3,subprocess,sys,tempfile,time,xml.etree.ElementTree as ET
from pathlib import Path
old,new=map(Path,sys.argv[1:3]); package='it.wildtrack.preview'
root=f'/data/user/0/{package}/databases'; out=Path('upgrade-results');out.mkdir(exist_ok=True)
checks=[]
def adb(*args):
 return subprocess.run(['adb','-s','emulator-5554',*args],check=True,capture_output=True,text=True,timeout=60).stdout.strip()
def check(name,ok):
 checks.append({'name':name,'status':'PASS' if ok else 'FAIL'});print(name,checks[-1]['status'],flush=True)
 if not ok:raise AssertionError(name)
def start():
 adb('shell','am','start','-W','-n',package+'/it.wildtrack.wildtrack_mvp.MainActivity');time.sleep(8)
def ui():
 adb('shell','uiautomator','dump','/sdcard/window.xml');return ET.fromstring(adb('shell','cat','/sdcard/window.xml'))
def tap(label):
 for node in ui().iter('node'):
  if label.lower() in (node.get('text','')+' '+node.get('content-desc','')).lower():
   bounds=list(map(int,re.findall(r'\d+',node.get('bounds',''))))
   if len(bounds)==4:
    x1,y1,x2,y2=bounds
    if x2>x1 and y2>y1:adb('shell','input','tap',str((x1+x2)//2),str((y1+y2)//2));time.sleep(2);return True
 return False
def read(name):return json.loads(adb('shell','cat',root+'/'+name))
try:
 for attempt in range(3):
  result=subprocess.run(['adb','-s','emulator-5554','root'],capture_output=True,text=True,timeout=60)
  print('Emulator preparation:',result.stdout.strip(),result.stderr.strip(),flush=True)
  time.sleep(3);adb('wait-for-device')
  if adb('shell','id','-u')=='0':break
 else:raise RuntimeError('Emulator does not allow local fixture preparation')
 adb('install','-r',str(old));start()
 for _ in range(4):
  if tap('Continua come ospite'):break
  adb('shell','input','swipe','20','1450','20','600','350')
 check('0.7.14 creates its original persisted identity',len(read('wildtrack_preferences.json')['token'])==64)
 token=read('wildtrack_preferences.json')['token'];adb('shell','am','force-stop',package)
 uid=adb('shell','stat','-c','%u',root)
 with tempfile.TemporaryDirectory() as work:
  folder=Path(work);dbfile=folder/'wildtrack.db';adb('pull',root+'/wildtrack.db',str(dbfile))
  photo=root+'/wildtrack_media/upgrade-volpe.png'
  png=base64.b64decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+a3ioAAAAASUVORK5CYII=')
  (folder/'photo.png').write_bytes(png)
  con=sqlite3.connect(dbfile)
  con.execute("INSERT OR REPLACE INTO sightings (id,species,count,notes,latitude,longitude,timestamp,photo_path,kind,position_source,publication_state) VALUES (?,?,?,?,?,?,?,?,?,?,?)",('upgrade-volpe-fixture','Volpe',2,'Solo test locale',46.1,13.2,'2026-10-03T08:00:00',photo,'Animale','manual','public'))
  con.execute('INSERT INTO sighting_photos(sighting_id,path,position) VALUES(?,?,0)',('upgrade-volpe-fixture',photo));con.commit();con.close()
  user='upgradetester';salt='emulator-local-fixture-salt'
  account={'username':user,'salt':salt,'hash':hashlib.sha256(f'{salt}:{user}:fixture-password'.encode()).hexdigest(),'signedIn':True}
  (folder/'account.json').write_text(json.dumps(account))
  adb('shell','mkdir','-p',root+'/wildtrack_media')
  adb('push',str(dbfile),root+'/wildtrack.db');adb('push',str(folder/'photo.png'),photo)
  adb('push',str(folder/'account.json'),root+'/wildtrack_local_account.json')
  adb('shell','chown','-R',uid+':'+uid,root)
  for name,apk in [('Aggiornamento 0.7.14 → 0.7.15',new),('Reinstallazione senza disinstallare',new)]:
   adb('install','-r',str(apk));start()
   check(name+': identità originale conservata',read('wildtrack_preferences.json')['token']==token)
   check(name+': identità separata migrata',read('wildtrack_identity.json')['token']==token)
   check(name+': account e sessione conservati',read('wildtrack_local_account.json')==account)
   check(name+': foto invariata',hashlib.sha256(subprocess.run(['adb','-s','emulator-5554','exec-out','cat',photo],check=True,capture_output=True).stdout).digest()==hashlib.sha256(png).digest())
   check(name+': diario visibile',tap('Diario'))
   text=' '.join(n.get('text','')+' '+n.get('content-desc','') for n in ui().iter('node')).lower()
   check(name+': Volpe presente nel diario','volpe' in text)
   (out/('diary-'+str(len(checks))+'.png')).write_bytes(subprocess.run(['adb','-s','emulator-5554','exec-out','screencap','-p'],check=True,capture_output=True).stdout)
   adb('shell','am','force-stop',package)
   adb('pull',root+'/wildtrack.db',str(dbfile));con=sqlite3.connect(dbfile)
   check(name+': specie, conteggio e foto nel database',con.execute('SELECT species,count,photo_path,publication_state FROM sightings WHERE id=?',('upgrade-volpe-fixture',)).fetchone()==('Volpe',2,photo,'public'))
   check(name+': foto multipla collegata',con.execute('SELECT path FROM sighting_photos WHERE sighting_id=?',('upgrade-volpe-fixture',)).fetchall()==[(photo,)])
   con.close()
 check('Firma stabile: entrambi gli aggiornamenti accettati da Android',True)
finally:
 (out/'results.json').write_text(json.dumps({'apk_sha256':hashlib.sha256(new.read_bytes()).hexdigest(),'checks':checks},indent=2))
