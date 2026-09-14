"""Validate the provisioning claims required by dotViewer's Developer ID bundles."""
import datetime
import fnmatch
import hashlib
import plistlib
import subprocess
import tempfile
from pathlib import Path

TEAM = '7F5ZSQFCQ4'

def read_profile(path):
    result = subprocess.run(['security', 'cms', '-D', '-i', str(path)], capture_output=True, check=True)
    return plistlib.loads(result.stdout)

def profile_error(profile, entitlements, certificate_sha1=None):
    if not profile.get('ProvisionsAllDevices'):
        return 'not a Developer ID distribution profile'
    if profile.get('ExpirationDate', datetime.datetime.min) <= datetime.datetime.now(datetime.timezone.utc).replace(tzinfo=None):
        return 'expired profile'
    if certificate_sha1 and certificate_sha1.upper() not in [hashlib.sha1(c).hexdigest().upper() for c in profile.get('DeveloperCertificates', [])]:
        return 'signing certificate is not authorized by profile'
    allowed = profile.get('Entitlements', {})
    for key, value in entitlements.items():
        if key not in ('com.apple.application-identifier', 'com.apple.developer.team-identifier', 'com.apple.security.application-groups', 'keychain-access-groups'):
            continue
        values = value if isinstance(value, list) else [value]
        patterns = allowed.get(key, [])
        patterns = patterns if isinstance(patterns, list) else [patterns]
        if not all(any(fnmatch.fnmatchcase(v, pattern) for pattern in patterns) for v in values):
            return f'profile does not authorize {key}'
    if allowed.get('com.apple.developer.team-identifier') != TEAM:
        return 'wrong developer team'
    return None

def read_entitlements(bundle):
    result = subprocess.run(['codesign', '-d', '--entitlements', ':-', str(bundle)], capture_output=True, check=True)
    return plistlib.loads(result.stdout) if result.stdout.strip() else {}

def needs_profile(entitlements):
    return bool(entitlements.get('com.apple.application-identifier') or entitlements.get('com.apple.security.application-groups') or entitlements.get('keychain-access-groups'))

def find_profile(entitlements, certificate_sha1):
    roots = [Path.home() / 'Library/Developer/Xcode/UserData/Provisioning Profiles', Path.home() / 'Library/MobileDevice/Provisioning Profiles']
    for root in roots:
        for path in sorted(root.glob('*.provisionprofile')):
            profile = read_profile(path)
            if profile_error(profile, entitlements, certificate_sha1) is None:
                return path
    raise RuntimeError(f'No matching Developer ID profile for {entitlements.get("com.apple.application-identifier")}')

def validate_app(app):
    bundles = [app] + [p for p in app.rglob('*') if p.suffix in ('.appex', '.xpc') and p.is_dir()]
    for bundle in bundles:
        entitlements = read_entitlements(bundle)
        if not needs_profile(entitlements):
            continue
        path = bundle / 'Contents/embedded.provisionprofile'
        if not path.is_file():
            raise RuntimeError(f'Missing provisioning profile: {bundle}')
        with tempfile.TemporaryDirectory(prefix='dotviewer-cert-') as temporary:
            prefix = str(Path(temporary) / 'signer')
            subprocess.run(['codesign', '-d', '--extract-certificates=' + prefix, str(bundle)], capture_output=True, check=True)
            certificate = hashlib.sha1(Path(prefix + '0').read_bytes()).hexdigest()
        error = profile_error(read_profile(path), entitlements, certificate)
        if error:
            raise RuntimeError(f'{bundle}: {error}')
    print(f'Validated Developer ID provisioning for {len(bundles)} bundles')

if __name__ == '__main__':
    import sys
    validate_app(Path(sys.argv[1]))
