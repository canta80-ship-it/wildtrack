from pathlib import Path
p = Path('android/app/src/main/AndroidManifest.xml')
text = p.read_text()
permissions = '''    <uses-permission android:name="android.permission.INTERNET" />\n    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />\n    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />\n    <uses-permission android:name="android.permission.CAMERA" />\n'''
if 'android.permission.ACCESS_FINE_LOCATION' not in text:
    text = text.replace('<manifest xmlns:android="http://schemas.android.com/apk/res/android">\n', '<manifest xmlns:android="http://schemas.android.com/apk/res/android">\n' + permissions)
text = text.replace('android:label="wildtrack_mvp"', 'android:label="WildTrack"')
p.write_text(text)
