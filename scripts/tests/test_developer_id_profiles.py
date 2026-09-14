import datetime
import importlib.util
import sys
import unittest
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from developer_id_profiles import profile_error

class DeveloperIDProfileTests(unittest.TestCase):
    def setUp(self):
        self.claims = {'com.apple.application-identifier': '7F5ZSQFCQ4.com.stianlars1.dotViewer', 'com.apple.developer.team-identifier': '7F5ZSQFCQ4', 'com.apple.security.application-groups': ['group.stianlars1.dotViewer.shared']}
        self.profile = {'ProvisionsAllDevices': True, 'ExpirationDate': datetime.datetime(2040, 1, 1), 'Entitlements': self.claims.copy()}
    def test_matching_distribution_profile(self):
        self.assertIsNone(profile_error(self.profile, self.claims))
    def test_development_profile_rejected(self):
        self.profile.pop('ProvisionsAllDevices')
        self.assertIsNotNone(profile_error(self.profile, self.claims))
    def test_wrong_app_group_rejected(self):
        self.profile['Entitlements']['com.apple.security.application-groups'] = ['group.other']
        self.assertIsNotNone(profile_error(self.profile, self.claims))
    def test_wrong_certificate_rejected(self):
        self.assertIsNotNone(profile_error(self.profile, self.claims, 'A'*40))
    def test_expired_profile_rejected(self):
        self.profile['ExpirationDate'] = datetime.datetime(2000, 1, 1)
        self.assertIsNotNone(profile_error(self.profile, self.claims))
    def test_other_bundle_rejected(self):
        self.profile['Entitlements']['com.apple.application-identifier'] += '.other'
        self.assertIsNotNone(profile_error(self.profile, self.claims))
