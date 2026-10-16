import tempfile
import unittest
from pathlib import Path
import xml.etree.ElementTree as ET

from check_android_policy import A, ROOT, check_manifest


class ManifestRegressionTest(unittest.TestCase):
    def setUp(self):
        self.manifest = ET.parse(ROOT / 'android/app/src/main/AndroidManifest.xml')
        self.root = self.manifest.getroot()
        self.root.find('application/activity').set(A + 'name', 'es.jvrlabs.surtio.MainActivity')
        ET.SubElement(self.root, 'uses-sdk', {A + 'targetSdkVersion': '36'})

    def check(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'AndroidManifest.xml'
            self.manifest.write(path)
            check_manifest(path, release=True)

    def test_profiling_receiver_requires_system_permission(self):
        receiver = ET.SubElement(self.root.find('application'), 'receiver', {
            A + 'name': 'androidx.profileinstaller.ProfileInstallReceiver',
            A + 'exported': 'true', A + 'permission': 'android.permission.DUMP',
        })
        self.check()
        del receiver.attrib[A + 'permission']
        with self.assertRaisesRegex(ValueError, 'Exported component'):
            self.check()

    def test_new_permissions_require_review(self):
        ET.SubElement(self.root, 'uses-permission', {A + 'name': 'android.permission.READ_CONTACTS'})
        with self.assertRaisesRegex(ValueError, 'Permissions require review'):
            self.check()

    def test_cleartext_is_rejected(self):
        self.root.find('application').set(A + 'usesCleartextTraffic', 'true')
        with self.assertRaisesRegex(ValueError, 'usesCleartextTraffic'):
            self.check()


if __name__ == '__main__':
    unittest.main()
