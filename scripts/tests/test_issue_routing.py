"""Shipped declarations must reach both Quick Look pipelines."""
import json
import plistlib
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]

class IssueRoutingTests(unittest.TestCase):
    def test_gpx_vendor_alias_is_in_each_extension(self):
        for directory in ("QuickLookExtension", "QuickLookThumbnailExtension"):
            with self.subTest(extension=directory):
                data = plistlib.loads((ROOT / 'dotViewer' / directory / 'Info.plist').read_bytes())
                types = data['NSExtension']['NSExtensionAttributes']['QLSupportedContentTypes']
                self.assertIn('com.topografix.gpx', types)
                self.assertIn('com.stianlars1.dotviewer.gpx', types)

    def test_gap_exports_are_supported_by_each_extension(self):
        app = plistlib.loads((ROOT / 'dotViewer/App/Info.plist').read_bytes())
        exports = {str(ext): item['UTTypeIdentifier'] for item in app['UTExportedTypeDeclarations']
                   for ext in item['UTTypeTagSpecification'].get('public.filename-extension', [])}
        for ext in ('g', 'gi', 'gd', 'tst'):
            with self.subTest(extension=ext):
                self.assertIn(ext, exports)
                for directory in ('QuickLookExtension', 'QuickLookThumbnailExtension'):
                    data = plistlib.loads((ROOT / 'dotViewer' / directory / 'Info.plist').read_bytes())
                    self.assertIn(exports[ext], data['NSExtension']['NSExtensionAttributes']['QLSupportedContentTypes'])

    def test_generator_preserves_vendor_alias(self):
        import importlib.util
        spec = importlib.util.spec_from_file_location('gen_utis', ROOT / 'scripts/dotviewer-gen-utis.py')
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        self.assertIn('com.topografix.gpx', module.BASE_CONTENT_TYPES)

if __name__ == '__main__':
    unittest.main()
