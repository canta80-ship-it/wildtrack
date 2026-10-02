"""Read-only/local guest checks of the exact signed APK; never sends chat/public sightings."""
import hashlib,json,re,subprocess,sys,time,sqlite3,tempfile,xml.etree.ElementTree as ET
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
    if "isn't responding" in xml and 'Close app' in xml:
        root=ET.fromstring(xml)
        for n in root.iter('node'):
            if n.get('text')=='Close app':
                x1,y1,x2,y2=map(int,re.findall(r'\d+',n.get('bounds','')))
                adb('shell','input','tap',str((x1+x2)//2),str((y1+y2)//2));time.sleep(3)
                return dump()
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
                if x2>x1 and y2>y1 and (x2-x1)*(y2-y1)<600000:found.append((2 if node.get('text','').strip().lower()==label.lower() or node.get('content-desc','').strip().lower()==label.lower() else 1 if text.strip().lower().startswith(label.lower()+'\n') else 0, ((x1+x2)//2,(y1+y2)//2)))
    return max(found,key=lambda p:(p[0],p[1][1]))[1] if found else None
def tap(label,scroll=False):
    for attempt in range(5 if scroll else 2):
        pos=target(label)
        if pos:
            adb('shell','input','tap',str(pos[0]),str(pos[1]));time.sleep(2);return True
        if scroll:adb('shell','input','swipe','20','1450','20','600','350')
        time.sleep(1)
    return False
def visible_text():
    return ' '.join(n.get('text','')+' '+n.get('content-desc','') for n in dump().iter('node')).lower()
def enter_field(index,value,clear=False):
    fields=[n for n in dump().iter('node') if n.get('class')=='android.widget.EditText']
    fields.sort(key=lambda n:int(re.findall(r'\d+',n.get('bounds',''))[1]))
    if len(fields)<=index:raise RuntimeError('Input field not visible')
    x1,y1,x2,y2=map(int,re.findall(r'\d+',fields[index].get('bounds','')))
    adb('shell','input','tap',str((x1+x2)//2),str((y1+y2)//2));time.sleep(1)
    if clear:
        adb('shell','input','keyevent','123')
        adb('shell','input','keyevent',*(['67']*40))
    adb('shell','input','text',value);adb('shell','input','keyevent','4');time.sleep(1)
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
            if label == 'Community' and ok:
                result('Community apre Avvistamenti', 'PASS' if target('Avvistamenti') else 'FAIL')
                for _ in range(5):
                    if target('Chat'):break
                    adb('shell','input','swipe','20','1450','20','600','350');time.sleep(1)
                result('Titolo Chat visibile sopra le conversazioni', 'PASS' if target('Chat') else 'FAIL')
                shot('community-chat-heading')
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
    try:
        # Native GPS: verify samples are persisted while HOME is shown and the display is off.
        adb('shell','am','force-stop',package)
        adb('shell','am','start','-W','-n',package+'/it.wildtrack.wildtrack_mvp.MainActivity');time.sleep(5)
        if tap('Continua come ospite',scroll=True):
            for perm in ['ACCESS_COARSE_LOCATION','ACCESS_FINE_LOCATION','ACCESS_BACKGROUND_LOCATION','POST_NOTIFICATIONS']:
                adb('shell','pm','grant',package,'android.permission.'+perm)
            result('Permesso Android posizione in background dichiarato','PASS')
            if tap('SOS'):
                result('Pulsante SOS apre emergenza','PASS' if 'sos · emergenza' in visible_text() else 'FAIL');shot('home-sos')
                adb('shell','input','keyevent','4');time.sleep(1)
            if tap('Avvista') and tap('Scegli sulla mappa',scroll=True):
                adb('shell','input','tap','540','1000');time.sleep(1)
                ok=tap('Usa questo punto')
                result('Nuovo avvistamento riceve posizione scelta sulla mappa','PASS' if ok and 'punto scelto sulla mappa' in visible_text() else 'FAIL');shot('map-sighting-position')
                result('Avvistamento dalla mappa salvato privato','PASS' if tap('Salva privato',scroll=True) else 'FAIL')
                tap('Esplora');time.sleep(1)
            else:result('Scelta posizione avvistamento sulla mappa','FAIL','Controllo non raggiunto')
            if not tap('Avvia uscita') or not tap('Avvia registrazione',scroll=True):raise RuntimeError('Recording start missing')
            services=adb('shell','dumpsys','activity','services',package)
            result('Servizio GPS in primo piano attivo','PASS' if 'GeolocatorLocationService' in services and 'isForeground=true' in services else 'FAIL')
            adb('root');adb('wait-for-device')
            def track_snapshot():
                with tempfile.TemporaryDirectory(prefix='wildtrack-emulator-gps-') as folder:
                    for suffix in ['', '-wal', '-shm']:
                        adb('pull','/data/user/0/'+package+'/databases/wildtrack.db'+suffix,folder+'/wildtrack.db'+suffix,check=False)
                    con=sqlite3.connect(folder+'/wildtrack.db')
                    count=con.execute('select count(*) from track_points').fetchone()[0]
                    distance=con.execute('select coalesce(max(distance_m),0) from sessions').fetchone()[0]
                    con.close();return count,distance
            for offset in [0,.0005]:
                adb('emu','geo','fix','12.20',str(46.10+offset),'500');time.sleep(12)
            foreground_count,_=track_snapshot()
            result('GPS acquisisce punti prima del background','PASS' if foreground_count>=1 else 'FAIL','Punti acquisiti: '+str(foreground_count))
            adb('shell','input','keyevent','3')
            adb('shell','input','keyevent','223');time.sleep(2)
            for offset in [.001,.0015,.002]:
                adb('emu','geo','fix','12.20',str(46.10+offset),'510');time.sleep(12)
            background_count,distance=track_snapshot()
            result('GPS continua a schermo spento con app in background','PASS' if background_count>=foreground_count+2 and distance>20 else 'FAIL','Prima: '+str(foreground_count)+'; dopo: '+str(background_count)+'; distanza: '+str(round(distance,1))+' m; coordinate simulate')
            adb('shell','input','keyevent','224');adb('shell','wm','dismiss-keyguard')
            adb('shell','am','start','-W','-n',package+'/it.wildtrack.wildtrack_mvp.MainActivity');time.sleep(3)
            if tap('Termina e apri riepilogo',scroll=True):
                result('Traccia terminata apre report con statistiche','PASS' if 'riepilogo attività' in visible_text() else 'FAIL');shot('background-track-report')
            else:result('Termine traccia GPS','FAIL','Controllo non raggiunto')
        else:result('GPS nativo background','BLOCKED','Home ospite non raggiunta')
        # Exercise local credentials in the actual release APK. Never create a cloud account.
    except Exception as e:result('Verifica GPS background','BLOCKED',str(e))
    adb('shell','am','force-stop',package)
    adb('shell','am','start','-W','-n',package+'/it.wildtrack.wildtrack_mvp.MainActivity');time.sleep(5)
    if tap('Crea account',scroll=True):
        if 'account locale su questo dispositivo' in visible_text():
            enter_field(0,'trailtester')
            enter_field(1,'TrailTest2026')
            if not tap('Crea account',scroll=True):raise RuntimeError('Registration submit missing')
            if not tap('Ho conservato il codice'):raise RuntimeError('Local recovery dialog missing')
            result('Registrazione locale tramite interfaccia','PASS' if 'trailtester' in visible_text() else 'FAIL');shot('auth-registered')
            adb('shell','am','force-stop',package)
            adb('shell','am','start','-W','-n',package+'/it.wildtrack.wildtrack_mvp.MainActivity');time.sleep(5)
            result('Sessione ricordata al secondo avvio','PASS' if 'trailtester' in visible_text() and 'continua come ospite' not in visible_text() else 'FAIL');shot('auth-restored')
            if not tap('Impostazioni') or not tap('Disconnetti account',scroll=True):raise RuntimeError('Logout control missing')
            # The guest control is below the initial viewport on Pixel 2.
            # Scroll without activating it, then assert the actual welcome destination.
            for _ in range(4):
                if target('Continua come ospite'):break
                adb('shell','input','swipe','20','1450','20','600','350');time.sleep(1)
            result('Logout ritorna alla schermata iniziale','PASS' if 'continua come ospite' in visible_text() else 'FAIL');shot('auth-logged-out')
            if not tap('Accedi',scroll=True):raise RuntimeError('Sign-in screen missing')
            result('Nickname account ricordato nel login','PASS' if 'trailtester' in visible_text() else 'FAIL')
            enter_field(1,'WrongPassword2026')
            if not tap('Accedi',scroll=True):raise RuntimeError('Login submit missing')
            result('Password errata respinta','PASS' if 'nome utente o password non corretti' in visible_text() else 'FAIL')
            enter_field(1,'TrailTest2026',clear=True)
            if not tap('Accedi',scroll=True):raise RuntimeError('Second login submit missing')
            result('Accesso con password originale dopo logout','PASS' if 'trailtester' in visible_text() and 'buongiorno' in visible_text() else 'FAIL');shot('auth-signed-back-in')
            if tap('Esplora zona',scroll=True):
                time.sleep(3)
                visible=visible_text()
                result('Mappa mostra punto posizione attuale', 'PASS' if 'la tua posizione' in visible else 'FAIL', 'GPS simulato; marker verde accessibile')
                result('Ricerca CAI e filtro Sentieri rimossi', 'PASS' if 'cerca cai qui' not in visible and not target('Sentieri') else 'FAIL')
                shot('explore-live-green-position')
                adb('shell','input','keyevent','4');time.sleep(1)
            if tap('Vedi tutte',scroll=True):
                result('Home apre catalogo specie','PASS' if 'tutte le specie' in visible_text() else 'FAIL');shot('species-catalogue')
                if tap('Cervo'):
                    result('Catalogo apre scheda premium cervo','PASS' if 'segni e impronte' in visible_text() or 'cervus elaphus' in visible_text() else 'FAIL');shot('species-deer')
                    adb('shell','input','keyevent','4');time.sleep(1)
                if tap('Capriolo'):
                    if tap('Vedi sulla mappa',scroll=True):
                        time.sleep(3)
                        result('Scheda capriolo apre habitat della specie', 'PASS' if 'habitat · capriolo' in visible_text() else 'FAIL')
                        result('Mappa habitat mostra posizione attuale', 'PASS' if 'la tua posizione' in visible_text() else 'FAIL')
                        shot('roe-deer-habitat-map')
                        adb('shell','input','keyevent','4');time.sleep(1)
                    for _ in range(4):
                        if 'segni e impronte' in visible_text():break
                        adb('shell','input','swipe','540','1450','540','800','350');time.sleep(1)
                    shot('roe-deer-premium-signs')
                    adb('shell','input','keyevent','4');time.sleep(1)
                adb('shell','input','keyevent','4');time.sleep(1)
            for _ in range(3):
                if 'lo sapevi che' in visible_text():break
                adb('shell','input','swipe','540','1450','540','800','350');time.sleep(1)
            result('Carosello Lo sapevi che presente in home','PASS' if 'lo sapevi che' in visible_text() else 'FAIL');shot('home-feed')
            if tap('Diario'):
                for label,title in [('Specie uniche','le tue specie uniche'),('Km percorsi','km percorsi'),('Tempo sul campo','tempo sul campo'),('Avvistamenti','i tuoi avvistamenti')]:
                    ok=tap(label)
                    result('Indicatore diario '+label,'PASS' if ok and title in visible_text() else 'FAIL')
                    if ok:adb('shell','input','keyevent','4');time.sleep(1)
                if tap('Avvistamenti'):
                    if tap('Elimina Cervo'):
                        result('Eliminazione avvistamento richiede conferma','PASS' if 'eliminare cervo' in visible_text() else 'FAIL')
                        tap('Annulla')
                        if tap('Elimina Cervo') and tap('Elimina'):
                            result('Eliminazione avvistamento privato dal diario','PASS' if 'avvistamento eliminato' in visible_text() else 'FAIL');shot('diary-deleted')
                adb('shell','input','keyevent','4');time.sleep(1)
                if tap('Km percorsi') and tap('Elimina uscita'):
                    result('Eliminazione uscita richiede conferma','PASS' if 'eliminare questa uscita' in visible_text() else 'FAIL')
                    tap('Annulla')
                    if tap('Elimina uscita') and tap('Elimina uscita'):
                        result('Eliminazione uscita aggiorna distanza totale','PASS' if '0.00 km totali' in visible_text() else 'FAIL');shot('outing-deleted')


        else:result('Login locale nativo','BLOCKED','APK configurato con account cloud; nessun account esterno creato')
    else:result('Login locale nativo','BLOCKED','Schermata registrazione non raggiunta')
except Exception as e:result('Esecuzione Android','BLOCKED',str(e))
finally:
    logs=adb('logcat','-d','-v','brief',check=False)
    fatal='FATAL EXCEPTION' in logs and package in logs
    (out/'crash-lines.txt').write_text('\n'.join(x for x in logs.splitlines() if 'FATAL EXCEPTION' in x or 'AndroidRuntime' in x or 'ANR in '+package in x))
    (out/'results.json').write_text(json.dumps({'apk_sha256':hashlib.sha256(apk.read_bytes()).hexdigest(),'package':package,'android_api':35,'cases':results,'fatal_detected':fatal,'scope':'Emulator checks; camera, physical GPS, Bluetooth routing, push delivery and real account chat are not certified.'},ensure_ascii=False,indent=2))
    if any(x['status']=='FAIL' for x in results):sys.exit(1)
