#!/usr/bin/env bash
set -euo pipefail
# Real-APK visual QA: capture the installed release, not design mockups.

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

find_center_mode() {
  local needle="$1"
  local mode="${2:-contains}"
  dump_ui
  python3 - "$needle" "$mode" <<'PY'
import re, sys, xml.etree.ElementTree as ET
needle=sys.argv[1].strip().lower()
mode=sys.argv[2]
try:
    root=ET.parse('/tmp/window.xml').getroot()
except Exception:
    sys.exit(1)
for node in root.iter('node'):
    text=(node.attrib.get('text') or '').strip()
    desc=(node.attrib.get('content-desc') or '').strip()
    candidates=[text.lower(), desc.lower()]
    ok = needle in (' '.join(candidates)) if mode == 'contains' else needle in candidates
    if ok:
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
  local tries="${2:-10}"
  local mode="${3:-contains}"
  for _ in $(seq 1 "$tries"); do
    if xy=$(find_center_mode "$needle" "$mode" 2>/dev/null); then
      read -r x y <<<"$xy"
      adb shell input tap "$x" "$y"
      sleep 1
      return 0
    fi
    sleep 1
  done
  echo "WARN: text not found: $needle ($mode)" >&2
  return 1
}

wait_text() {
  local needle="$1"
  local tries="${2:-12}"
  local mode="${3:-contains}"
  for _ in $(seq 1 "$tries"); do
    if find_center_mode "$needle" "$mode" >/dev/null 2>&1; then return 0; fi
    sleep 1
  done
  return 1
}

scroll_up() { adb shell input swipe 540 1960 540 620 450; sleep 1; }
scroll_down() { adb shell input swipe 540 620 540 1960 450; sleep 1; }
scroll_top() { for _ in 1 2 3 4; do scroll_down; done; }

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

# Accesso e registrazione
if tap_text "Accedi" 8 exact; then
  wait_text "Bentornato" 10 || true
  capture "02_accesso"
  if tap_text "Registrati" 6 exact; then
    capture "03_registrazione"
  fi
  adb shell input keyevent 4
  sleep 2
fi

# Home
if tap_text "Continua come ospite" 8 exact; then
  wait_text "Buongiorno" 15 || true
  capture "04_home_top"
  scroll_up
  scroll_up
  capture "05_home_basso"
  scroll_top
fi

# Esplora / mappa
if tap_text "Esplora zona" 8 contains; then
  wait_text "Cerca sentieri" 15 || true
  capture "06_esplora_mappa"
  if tap_text "Radar" 5 exact; then capture "07_esplora_radar"; fi
  if tap_text "Specie" 5 exact; then capture "08_mappa_specie"; fi

  # Ricerca locale della specie Cervo, per aprire la scheda reale.
  adb shell input tap 500 355
  adb shell input text Cervo
  adb shell input keyevent 66
  sleep 4
  if wait_text "Cervus elaphus" 8; then
    capture "09_scheda_cervo_top"
    scroll_up
    scroll_up
    capture "10_scheda_cervo_basso"
    adb shell input keyevent 4
    sleep 2
  else
    capture "09_ricerca_cervo_non_aperta"
  fi
  adb shell input keyevent 4
  sleep 2
fi

# Bottom navigation, usando coordinate del Pixel 7 1080x2400 per evitare collisioni con testi omonimi.
# Avvista
adb shell input tap 405 2285
sleep 3
capture "11_avvistamento"
if tap_text "Non so" 4 contains; then
  capture "12_aiuto_identificazione"
  adb shell input keyevent 4
  sleep 1
fi
if tap_text "Cervo" 4 exact; then
  capture "13_selettore_specie"
  adb shell input keyevent 4
  sleep 1
fi

# Diario / statistiche
adb shell input tap 650 2285
sleep 3
capture "14_diario_statistiche"

# Community
adb shell input tap 900 2285
sleep 3
capture "15_community"

# Torna alla home
adb shell input tap 145 2285
sleep 3
scroll_top
capture "16_home_ritorno"

# Uscita GPS
if tap_text "Avvia uscita" 5 contains; then
  capture "17_uscita_gps"
  if tap_text "Avvia registrazione" 4 exact; then
    sleep 3
    capture "18_uscita_gps_attiva"
  fi
  adb shell input keyevent 4
  sleep 2
fi

# Impostazioni: icona campanella nella home.
scroll_top
adb shell input tap 865 215
sleep 3
if wait_text "Privacy e" 6; then
  capture "19_impostazioni_top"
  scroll_up
  scroll_up
  scroll_up
  capture "20_impostazioni_basso"

  if tap_text "Backup cloud" 5 exact; then
    capture "21_backup"
    adb shell input keyevent 4
    sleep 2
  fi

  scroll_up
  if tap_text "Guida sul campo" 5 exact; then
    capture "22_guida_sul_campo"
    if tap_text "Osservare" 4 exact; then
      capture "23_guida_osservare_aperta"
    fi
    adb shell input keyevent 4
    sleep 2
  fi
else
  capture "19_impostazioni_non_aperta"
fi

printf '\nGenerated screenshots:\n'
ls -1 "$OUT"/*.png
