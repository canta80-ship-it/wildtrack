"""Targeted reproduction of focused catalogue return on the shipped APK."""
import json,sys,hashlib
from pathlib import Path
exec(Path('tool/android_smoke.py').read_text().split('\ntry:\n    if len(sys.argv)>3:',1)[0])
def require(name,ok):
    result(name,'PASS' if ok else 'FAIL')
    if not ok:raise RuntimeError(name)
try:
    require('Exact shipped APK',hashlib.sha256(apk.read_bytes()).hexdigest()=='a75f754f6c8fa9a941adc0c237711ee79b25577d583282d4a5cd383582699019')
    adb('install','-r',str(apk))
    adb('shell','am','start','-W','-n',package+'/it.wildtrack.wildtrack_mvp.MainActivity');time.sleep(10)
    require('Guest entry',tap('Continua come ospite',scroll=True))
    require('Catalogue entry',tap('Vedi tutte',scroll=True) and 'tutte le specie' in visible_text())
    enter_field(0,'Milvus%smigrans',clear=True)
    require('Search opens new species',tap('Nibbio bruno') and 'milvus migrans' in visible_text())
    for _ in range(10):
        if 'periodo migliore' in visible_text():break
        adb('shell','input','swipe','20','1450','20','650','350');time.sleep(1)
    require('New species complete seasons','periodo migliore' in visible_text())
    adb('shell','input','keyevent','4');time.sleep(1)
    require('Return retains search catalogue','tutte le specie' in visible_text())
    if not tap('Back') and not tap('Indietro'):
        adb('shell','input','tap','72','135');time.sleep(1)
    require('Catalogue AppBar returns home','tutte le specie' not in visible_text())
    for _ in range(8):
        if 'lo sapevi che' in visible_text():break
        adb('shell','input','swipe','540','1450','540','800','350');time.sleep(1)
    require('Home curiosity carousel remains accessible','lo sapevi che' in visible_text());shot('verified-home-feed')
    for _ in range(8):
        if target('Diario'):break
        adb('shell','input','swipe','20','600','20','1450','350');time.sleep(1)
    require('Diary reachable after catalogue',tap('Diario') and 'diario e statistiche' in visible_text());shot('verified-diary')
except Exception as e:
    result('Navigation recheck','FAIL',str(e));shot('recheck-failure')
finally:
    (out/'navigation-results.json').write_text(json.dumps({'apk_sha256':hashlib.sha256(apk.read_bytes()).hexdigest(),'cases':results},ensure_ascii=False,indent=2))
    if any(r['status']=='FAIL' for r in results):sys.exit(1)
