"""Exercise the signed APK using native GPS emulation and process restarts."""
from pathlib import Path
import threading
exec(Path('tool/android_smoke.py').read_text().split('\ntry:\n    if len(sys.argv)>3:')[0])
position=[13.0,46.0];stop=threading.Event()
def gps_loop():
    while not stop.is_set():
        adb('emu','geo','fix',str(position[0]),str(position[1]),check=False)
        stop.wait(2)
def require(name,ok,detail=''):
    result(name,'PASS' if ok else 'FAIL',detail)
    if not ok:shot('failure');raise AssertionError(name+' '+detail)
def launch():
    adb('shell','am','start','-W','-n',package+'/it.wildtrack.wildtrack_mvp.MainActivity');time.sleep(7)
    if 'continua come ospite' in visible_text():require('Ingresso ospite',tap('Continua come ospite',scroll=True))
def back_home():
    if not tap('Back'):adb('shell','input','keyevent','4');time.sleep(2)
try:
    adb('install','-r',str(apk))
    for perm in ['ACCESS_COARSE_LOCATION','ACCESS_FINE_LOCATION']:
        adb('shell','pm','grant',package,'android.permission.'+perm)
    adb('shell','settings','put','secure','location_mode','3')
    threading.Thread(target=gps_loop,daemon=True).start()
    launch();require('Home apre checklist premium',tap('Prepara l’uscita',scroll=True))
    require('Selettore attività',tap('Attività'))
    require('Checklist fotografia',tap('Fotografia'))
    require('Spunta meteo',tap('Meteo e avvisi locali',scroll=True))
    text=visible_text();require('Progresso checklist aggiornato',bool(re.search(r'1/\d+ completati',text)),text[-500:]);shot('preparation-premium')
    adb('shell','am','force-stop',package);launch();require('Checklist riaperta',tap('Prepara l’uscita',scroll=True))
    text=visible_text();require('Attività e progresso persistono dopo arresto', 'fotografia' in text and bool(re.search(r'1/\d+ completati',text)),text[-700:]);shot('preparation-reopened')
    back_home();require('Home apre ritorno premium',tap('Torna al mio punto',scroll=True))
    require('Salva auto apre nome',tap('Salva auto'));enter_field(0,'AutoTest',clear=True);require('Salvataggio punto GPS',tap('Salva qui'))
    time.sleep(8);text=visible_text();require('Punto salvato e arrivo', 'autotest' in text and 'sei nell’area del punto' in text,text[-800:]);shot('return-saved')
    position[0]=13.001;time.sleep(18)
    text=visible_text();require('Spostamento GPS aggiorna distanza e direzione',bool(re.search(r'circa (?:7\d|8\d) m',text)) and 'dal nord' in text and 'sei nell’area' not in text,text[-1000:]);shot('return-moving')
    adb('shell','am','force-stop',package);launch();require('Ritorno riaperto',tap('Torna al mio punto',scroll=True));time.sleep(8)
    text=visible_text();require('Auto e guida persistono dopo riavvio', 'autotest' in text and 'dal nord' in text,text[-800:]);shot('return-reopened')
    require('Eliminazione richiede conferma',tap('Elimina AutoTest',scroll=True));require('Annullamento eliminazione',tap('Annulla'));require('Auto conservata dopo annullamento','autotest' in visible_text())
    require('Seconda eliminazione apre conferma',tap('Elimina AutoTest',scroll=True));require('Conferma eliminazione',tap('Elimina'));require('Archivio punti vuoto','nessun punto salvato' in visible_text());shot('return-deleted')
except Exception as e:
    result('Native scenario completed','FAIL',str(e));shot('exception')
finally:
    stop.set();logs=adb('logcat','-d','-t','2500',check=False)
    (out/'app-logcat.txt').write_text(logs)
    fatal='FATAL EXCEPTION' in logs and package in logs
    payload={'apk_sha256':hashlib.sha256(apk.read_bytes()).hexdigest(),'package':package,'android_api':35,'cases':results,'fatal_detected':fatal,'scope':'GPS simulated on Android emulator; physical compass and outdoor satellite reception are not certified.'}
    (out/'results.json').write_text(json.dumps(payload,ensure_ascii=False,indent=2))
    sys.exit(1 if fatal or any(r['status']!='PASS' for r in results) else 0)
