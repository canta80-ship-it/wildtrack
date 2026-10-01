"""Only GET requests with an isolated test token. Never publishes content or messages."""
import json,secrets,time,urllib.request,urllib.error
from pathlib import Path
token=secrets.token_hex(32)
root='https://wildtrack-community.canta80.chatgpt.site/api/'
cases=[]
for name,path in [('Feed avvistamenti','sightings?offset=0'),('Persone community','community'),('Mappe private del profilo test','maps'),('Lettura chat pubblica','messages')]:
    started=time.monotonic()
    try:
        req=urllib.request.Request(root+path,headers={'Authorization':'Bearer '+token,'Accept':'application/json','User-Agent':'WildTrack-functional-readonly'})
        with urllib.request.urlopen(req,timeout=20) as response:
            code=response.status; data=json.load(response)
        ok=code==200 and isinstance(data,dict)
        cases.append({'name':name,'status':'PASS' if ok else 'FAIL','http':code,'json_object':isinstance(data,dict),'seconds':round(time.monotonic()-started,2)})
    except urllib.error.HTTPError as e:
        cases.append({'name':name,'status':'BLOCKED' if e.code in [401,403] else 'FAIL','http':e.code,'detail':'Autenticazione richiesta' if e.code in [401,403] else 'Errore HTTP'})
    except Exception as e:
        cases.append({'name':name,'status':'BLOCKED','detail':type(e).__name__+': '+str(e)})
    print(cases[-1]['name']+': '+cases[-1]['status'],flush=True)
Path('online-results.json').write_text(json.dumps({'scope':'GET only; no account registration, invitations, messages or public sightings created. Response bodies and test token are not retained. This validates read endpoints, not write permissions or push delivery.','cases':cases},ensure_ascii=False,indent=2))
