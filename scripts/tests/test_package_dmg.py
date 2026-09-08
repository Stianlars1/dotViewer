import os
import subprocess
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(__file__).resolve().parents[1] / 'package-dmg.sh'

class PackageDMGTests(unittest.TestCase):
    def test_dropdmg_failure_never_creates_plain_fallback(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / 'dotViewer.app').mkdir()
            tool = root / 'dropdmg'
            tool.write_text('#!/bin/sh\necho "automation denied" >&2\nexit 17\n')
            tool.chmod(0o755)
            result = subprocess.run([str(SCRIPT), str(root / 'dotViewer.app'), str(root / 'out'), '1.5.4'], env={**os.environ, 'PATH': str(root)+':/usr/bin:/bin'}, capture_output=True, text=True)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn('no unstyled fallback', result.stderr)
            self.assertEqual(list(root.rglob('*.dmg')), [])

    def test_uses_named_layout_and_exact_output(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / 'dotViewer.app').mkdir()
            tool = root / 'dropdmg'
            tool.write_text('#!/bin/sh\n[ "$1" = "--config-name=dotviewer" ] || exit 3\nDEST=${2#--destination=}\nBASE=${3#--base-name=}\ntouch "$DEST/$BASE.dmg"\nprintf "%s\\n" "$DEST/$BASE.dmg"\n')
            tool.chmod(0o755)
            result = subprocess.run([str(SCRIPT), str(root / 'dotViewer.app'), str(root / 'out'), '1.5.4'], env={**os.environ, 'PATH': str(root)+':/usr/bin:/bin'}, capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(result.stdout.strip(), str(root / 'out/dotViewer-1.5.4.dmg'))

    def test_existing_installer_cannot_be_mistaken_for_new_output(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / 'dotViewer.app').mkdir()
            (root / 'out').mkdir()
            artifact = root / 'out/dotViewer-1.5.4.dmg'
            artifact.write_text('old installer')
            tool = root / 'dropdmg'
            tool.write_text('#!/bin/sh\nexit 0\n')
            tool.chmod(0o755)
            result = subprocess.run([str(SCRIPT), str(root / 'dotViewer.app'), str(root / 'out'), '1.5.4'], env={**os.environ, 'PATH': str(root)+':/usr/bin:/bin'}, capture_output=True, text=True)
            self.assertNotEqual(result.returncode, 0)
            self.assertEqual(artifact.read_text(), 'old installer')

if __name__ == '__main__':
    unittest.main()
