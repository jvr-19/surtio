#!/usr/bin/env python3
"""Check source policy; optionally check a merged release manifest after a build."""
import argparse
from pathlib import Path
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
A = '{http://schemas.android.com/apk/res/android}'
ALLOWED = {
    'android.permission.INTERNET',
    'android.permission.ACCESS_COARSE_LOCATION',
    'android.permission.ACCESS_FINE_LOCATION',
    'android.permission.ACCESS_NETWORK_STATE',
    'android.permission.ACCESS_WIFI_STATE',
    'es.jvrlabs.surtio.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION',
}

def check_manifest(path, release=False):
    root = ET.parse(path).getroot()
    app = root.find('application')
    if app is None:
        raise ValueError('Application is missing')
    required = {'allowBackup': 'false', 'usesCleartextTraffic': 'false',
                'fullBackupContent': '@xml/backup_rules',
                'dataExtractionRules': '@xml/data_extraction_rules'}
    for name, expected in required.items():
        if app.get(A + name) != expected:
            raise ValueError(f'Unexpected application setting: {name}')
    permissions = {node.get(A + 'name') for node in root.findall('uses-permission')}
    if permissions - ALLOWED:
        raise ValueError(f'Permissions require review: {sorted(permissions - ALLOWED)}')
    if release:
        sdk = root.find('uses-sdk')
        if sdk is None or int(sdk.get(A + 'targetSdkVersion', '0')) < 36:
            raise ValueError('Google Play requires target SDK 36 or higher as of this review')
        if app.get(A + 'debuggable') == 'true':
            raise ValueError('Release must not be debuggable')
        for node in app:
            if node.tag in {'activity', 'service', 'receiver', 'provider'}:
                if node.get(A + 'exported') != 'true':
                    continue
                launcher = node.tag == 'activity' and node.get(A + 'name') == 'es.jvrlabs.surtio.MainActivity'
                protected_profiler = (node.tag == 'receiver'
                    and node.get(A + 'name') == 'androidx.profileinstaller.ProfileInstallReceiver'
                    and node.get(A + 'permission') == 'android.permission.DUMP')
                if not launcher and not protected_profiler:
                    raise ValueError(f'Exported component requires review: {node.get(A + "name")}')

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--release-manifest', type=Path)
    args = parser.parse_args()
    check_manifest(ROOT / 'android/app/src/main/AndroidManifest.xml')
    domains = {'root', 'file', 'database', 'sharedpref', 'external', 'device_root',
               'device_file', 'device_database', 'device_sharedpref'}
    res = ROOT / 'android/app/src/main/res/xml'
    backup = ET.parse(res / 'backup_rules.xml').getroot()
    extraction = ET.parse(res / 'data_extraction_rules.xml').getroot()
    for section in [backup, extraction.find('cloud-backup'), extraction.find('device-transfer')]:
        if section is None or {n.get('domain') for n in section.findall('exclude') if n.get('path') == '.'} != domains:
            raise ValueError('Backup/transfer exclusions are incomplete')
    if args.release_manifest:
        check_manifest(args.release_manifest, release=True)
    print('Android privacy and permission checks passed.' + (' Merged release verified.' if args.release_manifest else ' Release manifest not inspected.'))

if __name__ == '__main__':
    main()
