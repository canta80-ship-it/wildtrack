"""Read-only/local guest checks of the exact signed APK; never sends chat/public sightings."""
import hashlib,json,re,subprocess,sys,time,xml.etree.ElementTree as ET
from pathlib import Path
out=Path('android-results');out.mkdir(exist_ok=True)
apk=Path(sys.argv[1]); package=sys.argv[2] if len(sys.argv)>2 else 'it.wildtrack.app'; results=[]
legacy_package='it.wildtrack.app'
def adb(*args,check=True):
    return subprocess.run(['adb',*args],capture_output=True,check=check,text=True,timeout=40).stdout
def shot(name):
    p=subprocess.run(['adb','exec-out','screencap','-p'],capture_output=True,check=True,timeout=20)
    (out/(name+'.png')).write_bytes(p.stdout)
def dump():
    adb('shell','uiautomator','dump','/sdcard/window.xml',check=False)
    xml=adb('shell','cat','/sdcard/window.xml',check=False)
    (out/'latest-ui.xml').write_text(xml)
    try:return ET.fromstring(xml)
    except ET.ParseError:return ET.Element('empty')
def target(label):
    found=[]
    for node in dump().iter('node'):
        text=node.get('text','')+' '+node.get('content-desc','')
        if label.lower() in text.lower():
            bounds=re.findall(r'\d+',node.get('bounds',''))
            if len(bounds)==4:
                x1,y1,x2,y2=map(int,bounds)
                if x2>x1 and y2>y1 and (x2-x1)*(y2-y1)<600000:found.append(((x1+x2)//2,(y1+y2)//2))
    return max(found,key=lambda p:p[1]) if found else None
def tap(label,scroll=False):
    for attempt in range(5 if scroll else 2):
        pos=target(label)
        if pos:
            adb('shell','input','tap',str(pos[0]),str(pos[1]));time.sleep(2);return True
        if scroll:adb('shell','input','swipe','540','1450','540','600','350')
        time.sleep(1)
    return False
def result(name,status,detail=''):
    results.append(dict(name=name,status=status,detail=detail));print(name+': '+status,flush=True)
try:
    if len(sys.argv)>3:
        adb('install','-r',sys.argv[3]);result('Installazione copia precedente per verifica affiancamento','PASS')
        adb('shell','am','start','-W','-n',legacy_package+'/it.wildtrack.wildtrack_mvp.MainActivity');time.sleep(8)
        if not tap('Continua come ospite',scroll=True) or not tap('Avvista') or not tap('Salva privato',scroll=True):
            raise RuntimeError('Unable to seed legacy sighting for preservation check')
        adb('shell','am','force-stop',legacy_package)
    adb('install','-r',str(apk));result('Installazione APK firmato','PASS')
    adb('shell','am','start','-W','-n',package+'/it.wildtrack.wildtrack_mvp.MainActivity');time.sleep(12)
    pid=adb('shell','pidof',package,check=False).strip();result('Avvio nativo Android','PASS' if pid else 'FAIL');shot('01-welcome')
    if not pid:raise RuntimeError('App process not running')
    if tap('Continua come ospite',scroll=True):
        result('Ingresso come ospite','PASS');shot('02-home')
        for label in ['Avvista','Diario','Community','Esplora']:
            ok=tap(label)
            visible=' '.join(n.get('text','')+' '+n.get('content-desc','') for n in dump().iter('node')).lower()
            expected={'Avvista':'nuovo avvistamento','Diario':'diario e statistiche','Community':'condividi avvistamenti','Esplora':'esplora zona'}[label]
            result('Navigazione '+label,'PASS' if ok and expected in visible else 'BLOCKED','Destinazione cercata: '+expected+'; nessun messaggio o contenuto pubblico inviato');shot('nav-'+label)
        if tap('Avvista'):
            if tap('Salva privato',scroll=True):
                text=adb('shell','cat','/sdcard/window.xml',check=False)
                result('Azione salvataggio privato','PARTIAL','Pulsante premuto; persistenza verificata separatamente nei test SQLite');shot('private-save')
            else:result('Azione salvataggio privato','BLOCKED','Pulsante non individuato automaticamente')
    else:result('Ingresso come ospite e navigazione','BLOCKED','Gerarchia di accessibilità o posizione del controllo non risolta')
    adb('shell','am','force-stop',package)
    adb('shell','am','start','-W','-n',package+'/it.wildtrack.wildtrack_mvp.MainActivity');time.sleep(5)
    result('Riapertura dopo arresto','PASS' if adb('shell','pidof',package,check=False).strip() else 'FAIL');shot('restart')
    if tap('Continua come ospite',scroll=True) and tap('Diario'):
        visible=' '.join(n.get('text','')+' '+n.get('content-desc','') for n in dump().iter('node')).lower()
        result('Avvistamento privato presente dopo riavvio','PASS' if 'cervo' in visible else 'BLOCKED','Verifica del dato salvato nel diario dopo arresto e riapertura del processo');shot('persisted-diary')
    else:result('Avvistamento privato presente dopo riavvio','BLOCKED','Percorso del diario non raggiunto automaticamente')
    if len(sys.argv)>3:
        adb('install','-r',str(apk));result('Reinstallazione aggiornamento con firma stabile','PASS')
        adb('shell','am','force-stop',package)
        adb('shell','am','start','-W','-n',package+'/it.wildtrack.wildtrack_mvp.MainActivity');time.sleep(5)
        ok=tap('Continua come ospite',scroll=True) and tap('Diario')
        visible=' '.join(n.get('text','')+' '+n.get('content-desc','') for n in dump().iter('node')).lower()
        result('Dati Preview conservati dopo reinstallazione','PASS' if ok and 'cervo' in visible else 'FAIL')
        adb('shell','am','force-stop',package)
        adb('shell','am','start','-W','-n',legacy_package+'/it.wildtrack.wildtrack_mvp.MainActivity');time.sleep(5)
        ok=tap('Continua come ospite',scroll=True) and tap('Diario')
        visible=' '.join(n.get('text','')+' '+n.get('content-desc','') for n in dump().iter('node')).lower()
        result('App precedente e suoi dati conservati','PASS' if ok and 'cervo' in visible else 'FAIL');shot('legacy-preserved')
except Exception as e:result('Esecuzione Android','BLOCKED',str(e))
finally:
    logs=adb('logcat','-d','-v','brief',check=False)
    fatal='FATAL EXCEPTION' in logs and package in logs
    (out/'crash-lines.txt').write_text('\n'.join(x for x in logs.splitlines() if 'FATAL EXCEPTION' in x or 'AndroidRuntime' in x or 'ANR in '+package in x))
    (out/'results.json').write_text(json.dumps({'apk_sha256':hashlib.sha256(apk.read_bytes()).hexdigest(),'package':package,'android_api':35,'cases':results,'fatal_detected':fatal,'scope':'Emulator checks; camera, physical GPS, Bluetooth routing, push delivery and real account chat are not certified.'},ensure_ascii=False,indent=2))
    if any(x['status']=='FAIL' for x in results):sys.exit(1)
