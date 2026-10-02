import hashlib, json, pathlib, re, subprocess, time, xml.etree.ElementTree as ET

apk = pathlib.Path('tested-apk/WildTrack-release.apk')
assert hashlib.sha256(apk.read_bytes()).hexdigest() == 'a7a6f0a80830936054073d0c6bdee520dd16898d8a1ad5ed8d9db24dfd1a69dc'
out = pathlib.Path('chat-results'); out.mkdir(exist_ok=True)
def adb(*args):
    return subprocess.run(['adb', *args], capture_output=True, text=True, check=True, timeout=40).stdout
def nodes():
    adb('shell', 'uiautomator', 'dump', '/sdcard/chat-ui.xml')
    xml = adb('shell', 'cat', '/sdcard/chat-ui.xml')
    (out / 'ui.xml').write_text(xml)
    return list(ET.fromstring(xml).iter('node'))
def exact(label):
    found = []
    for n in nodes():
        if n.get('text', '').strip() == label or n.get('content-desc', '').strip() == label:
            b = list(map(int, re.findall(r'\d+', n.get('bounds', ''))))
            if len(b) == 4 and b[3] > b[1] and b[2] > b[0]: found.append(b)
    return max(found, key=lambda b: b[1]) if found else None
def tap(label):
    for _ in range(8):
        b = exact(label)
        if b:
            adb('shell', 'input', 'tap', str((b[0]+b[2])//2), str((b[1]+b[3])//2)); time.sleep(2); return
        adb('shell', 'input', 'swipe', '20', '1450', '20', '600', '350')
        time.sleep(2)
    raise RuntimeError('Missing exact label: ' + label)
adb('install', '-r', str(apk))
adb('shell', 'am', 'start', '-W', '-n', 'it.wildtrack.preview/it.wildtrack.wildtrack_mvp.MainActivity')
time.sleep(12)
tap('Continua come ospite')
tap('Community')
assert exact('Avvistamenti'), 'Missing sightings tab'
for _ in range(18):
    title = exact('Chat'); empty = exact('Nessuna conversazione')
    if title and empty:
        assert title[1] < empty[1], 'Chat heading must precede empty state'
        (out / 'community-chat.png').write_bytes(subprocess.run(['adb','exec-out','screencap','-p'], capture_output=True, check=True, timeout=30).stdout)
        (out / 'result.json').write_text(json.dumps({'status':'PASS', 'apk_sha256': hashlib.sha256(apk.read_bytes()).hexdigest(), 'title_bounds':title, 'empty_bounds':empty}))
        print('PASS: exact Chat heading appears above Nessuna conversazione on signed APK', flush=True)
        break
    adb('shell', 'input', 'swipe', '20', '1450', '20', '950', '350'); time.sleep(1)
else:
    raise RuntimeError('Chat heading and empty inbox were not simultaneously visible')
