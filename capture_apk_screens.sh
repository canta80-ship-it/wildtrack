#!/usr/bin/env bash
set -euo pipefail

PKG="it.wildtrack.app"
APK="${APK_PATH:-WildTrack-release.apk}"
OUT="${SCREENSHOT_DIR:-apk-screens}"
mkdir -p "$OUT"

capture() {
  local name="$1"
  sleep 2
  adb exec-out screencap -p > "$OUT/${name}.png"
  echo "captured $name"
}

dump_ui() {
  adb shell uiautomator dump /sdcard/window.xml >/dev/null 2>&1 || true
  adb shell cat /sdcard/window.xml 2>/dev/null > /tmp/window.xml || true
}

find_center() {
  local needle="$1"
  dump_ui
  python3 - "$needle" <<'PY'
import re, sys, xml.etree.ElementTree as ET
needle=sys.argv[1].strip().lower()
try:
    root=ET.parse('/tmp/window.xml').getroot()
except Exception:
    sys.exit(1)
for node in root.iter('node'):
    text=(node.attrib.get('text') or '').strip()
    desc=(node.attrib.get('content-desc') or '').strip()
    hay=(text+' '+desc).strip().lower()
    if needle and needle in hay:
        m=re.match(r'\[(\d+),(\d+)\]\[(\d+),(\d+)\]', node.attrib.get('bounds',''))
        if m:
            x1,y1,x2,y2=map(int,m.groups())
            print((x1+x2)//2, (y1+y2)//2)
            sys.exit(0)
sys.exit(1)
PY
}

tap_text() {
  local needle="$1"
  local tries="${2:-12}"
  for _ in $(seq 1 "$tries"); do
    if xy=$(find_center "$needle" 2>/dev/null); then
      read -r x y <<<"$xy"
      adb shell input tap "$x" "$y"
      sleep 1
      return 0
    fi
    sleep 1
  done
  echo "WARN: text not found: $needle" >&2
  return 1
}

wait_text() {
  local needle="$1"
  local tries="${2:-15}"
  for _ in $(seq 1 "$tries"); do
    if find_center "$needle" >/dev/null 2>&1; then return 0; fi
    sleep 1
  done
  return 1
}

scroll_up() {
  adb shell input swipe 540 1960 540 620 450
  sleep 1
}

scroll_down() {
  adb shell input swipe 540 620 540 1960 450
  sleep 1
}

adb install -r "$APK"
adb shell pm clear "$PKG" >/dev/null || true
adb shell pm grant "$PKG" android.permission.ACCESS_FINE_LOCATION || true
adb shell pm grant "$PKG" android.permission.ACCESS_COARSE_LOCATION || true
adb shell pm grant "$PKG" android.permission.CAMERA || true
adb shell pm grant "$PKG" android.permission.POST_NOTIFICATIONS || true
adb emu geo fix 12.403 46.061 >/dev/null 2>&1 || true
adb shell am force-stop "$PKG"
adb shell monkey -p "$PKG" -c android.intent.category.LAUNCHER 1 >/dev/null
sleep 5

capture "01_intro"

if tap_text "Accedi"; then
  wait_text "Bentornato" || true
  capture "02_accesso"
  if tap_text "Registrati"; then
    capture "03_registrazione"
  fi
  adb shell input keyevent 4
  sleep 2
fi

if tap_text "Continua come ospite"; then
  wait_text "Buongiorno" 20 || true
  capture "04_home"
fi

if tap_text "Esplora zona"; then
  wait_text "Cerca sentieri" 20 || true
  capture "05_esplora_mappa"
  if tap_text "Radar"; then
    capture "06_esplora_radar"
  fi
  if tap_text "Cerca sentieri, specie, luoghi"; then
    adb shell input text Cervo
    adb shell input keyevent 66
    wait_text "Cervo" 15 || true
    capture "07_scheda_cervo"
    adb shell input keyevent 4
    sleep 2
  fi
  adb shell input keyevent 4
  sleep 2
fi

if tap_text "Avvista"; then
  wait_text "Avvist" 15 || true
  capture "08_avvistamento"
fi

if tap_text "Diario"; then
  capture "09_diario_statistiche"
fi

if tap_text "Community"; then
  capture "10_community"
fi

if tap_text "Esplora"; then
  wait_text "Buongiorno" 15 || true
  capture "11_home_ritorno"
fi

if tap_text "Avvia uscita"; then
  capture "12_uscita_gps"
  adb shell input keyevent 4
  sleep 2
fi

# Impostazioni: il pulsante in home usa l'icona notifiche. Proviamo coordinate note del layout reale.
adb shell input tap 880 155
sleep 2
if ! wait_text "Privacy e permessi" 5; then
  adb shell input keyevent 4 || true
  adb shell input tap 925 155
  sleep 2
fi
capture "13_impostazioni_top"

scroll_up
scroll_up
capture "14_impostazioni_basso"

if tap_text "Backup cloud" 4; then
  capture "15_backup"
  adb shell input keyevent 4
  sleep 2
fi

scroll_up
if tap_text "Guida sul campo" 5; then
  capture "16_guida_sul_campo"
  if tap_text "Osservare" 3; then
    capture "17_guida_osservare_aperta"
  fi
  adb shell input keyevent 4
  sleep 2
fi

# Torna alla home e cattura di nuovo la mappa con filtro specie, se raggiungibile.
adb shell input keyevent 4 || true
sleep 1
if tap_text "Esplora" 4; then
  sleep 1
fi
if tap_text "Esplora zona" 4; then
  wait_text "Cerca sentieri" 12 || true
  if tap_text "Specie" 5; then
    capture "18_mappa_specie"
  fi
fi

printf '\nGenerated screenshots:\n'
ls -1 "$OUT"/*.png
