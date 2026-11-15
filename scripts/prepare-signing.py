"""Validate signing profile and write ephemeral export configuration (macOS CI)."""
import datetime
import os
import pathlib
import plistlib
import shutil

root = pathlib.Path(os.environ['RUNNER_TEMP'])
with (root / 'profile.plist').open('rb') as f:
    profile = plistlib.load(f)
team = profile['TeamIdentifier'][0]
bundle = 'com.rejitokinko.cashcount'
entitlements = profile['Entitlements']
if entitlements.get('application-identifier') != profile['ApplicationIdentifierPrefix'][0] + '.' + bundle:
    raise SystemExit('Profile does not match com.rejitokinko.cashcount')
if profile.get('ProvisionedDevices') or profile.get('ProvisionsAllDevices') or entitlements.get('get-task-allow'):
    raise SystemExit('An App Store distribution profile is required')
if profile['ExpirationDate'] <= datetime.datetime.now(datetime.timezone.utc).replace(tzinfo=None):
    raise SystemExit('Provisioning profile has expired')
profile_dir = pathlib.Path.home() / 'Library/MobileDevice/Provisioning Profiles'
profile_dir.mkdir(parents=True, exist_ok=True)
installed = profile_dir / (profile['UUID'] + '.mobileprovision')
shutil.copyfile(root / 'profile.mobileprovision', installed)
with (root / 'ExportOptions.plist').open('wb') as f:
    plistlib.dump({'method':'app-store-connect', 'signingStyle':'manual', 'teamID':team,
                  'signingCertificate':'Apple Distribution',
                  'provisioningProfiles':{bundle:profile['UUID']},
                  'manageAppVersionAndBuildNumber':False}, f)
with open(os.environ['GITHUB_ENV'], 'a') as f:
    f.write(f'IOS_TEAM_ID={team}\nIOS_PROFILE_UUID={profile["UUID"]}\n')
