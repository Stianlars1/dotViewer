#!/usr/bin/env python3
"""Explicit recovery for a blocked Xcode export; sign a freshly built dotViewer bundle."""
import argparse
import os
import plistlib
import re
import subprocess
import tempfile
from pathlib import Path


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('source', type=Path)
    parser.add_argument('destination', type=Path)
    parser.add_argument('--identity', required=True, help='Developer ID certificate SHA-1 from security find-identity')
    args = parser.parse_args()
    if not re.fullmatch(r'[0-9A-Fa-f]{40}', args.identity):
        parser.error('Use an exact certificate SHA-1, not an ambiguous identity name')
    info = plistlib.loads((args.source / 'Contents/Info.plist').read_bytes())
    if info.get('CFBundleIdentifier') != 'com.stianlars1.dotViewer':
        parser.error('Source must be a built dotViewer.app bundle')
    if args.source.resolve() in args.destination.resolve().parents:
        parser.error("Destination must not be inside the source bundle")
    if args.destination.exists():
        parser.error('Destination already exists; preserve it and choose a clean destination')
    args.destination.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run(['/usr/bin/ditto', str(args.source), str(args.destination)], check=True)
    bundles = [args.destination]
    for directory, directories, files in os.walk(args.destination, followlinks=False):
        for name in directories:
            path = Path(directory) / name
            if not path.is_symlink() and path.suffix in ('.framework', '.appex', '.xpc'):
                bundles.append(path)
        for name in files:
            if name == 'embedded.provisionprofile':
                (Path(directory) / name).unlink()
    with tempfile.TemporaryDirectory(prefix='dotviewer-sign-') as temporary:
        for index, bundle in enumerate(sorted(bundles, key=lambda path: len(path.parts), reverse=True)):
            result = subprocess.run(['/usr/bin/codesign', '-d', '--entitlements', ':-', str(bundle)], capture_output=True, check=True)
            entitlements = plistlib.loads(result.stdout) if result.stdout.strip() else {}
            entitlements.pop('com.apple.security.get-task-allow', None)
            command = ['/usr/bin/codesign', '--force', '--sign', args.identity, '--options', 'runtime', '--timestamp', '--preserve-metadata=identifier']
            if entitlements:
                path = Path(temporary) / f'{index}.plist'
                path.write_bytes(plistlib.dumps(entitlements))
                command += ['--entitlements', str(path)]
            # communicate() drains both streams while codesign is running.
            result = subprocess.run(command + [str(bundle)], capture_output=True)
            if result.returncode:
                raise RuntimeError(result.stderr.decode(errors='replace'))
    subprocess.run(['/usr/bin/codesign', '--verify', '--deep', '--strict', str(args.destination)], check=True)
    signing = subprocess.run(['/usr/bin/codesign', '-dvv', str(args.destination)], capture_output=True, text=True, check=True).stderr
    if 'Authority=Developer ID Application:' not in signing or 'TeamIdentifier=7F5ZSQFCQ4' not in signing:
        raise RuntimeError('Expected a Developer ID Application signature for the dotViewer team')
    print(f"Signed and verified {args.destination}: {info['CFBundleShortVersionString']} ({info['CFBundleVersion']})")


if __name__ == '__main__':
    main()
