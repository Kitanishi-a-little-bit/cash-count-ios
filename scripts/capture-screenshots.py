"""Capture the real app on fresh iPhone/iPad simulators using synthetic cash data."""
import json
import pathlib
import plistlib
import subprocess
import time


def run(*args):
    return subprocess.check_output(args, text=True).strip()


bundle = 'com.rejitokinko.cashcount'
app = pathlib.Path('build/screenshots/Build/Products/Release-iphonesimulator/CashCount.app').resolve()
output = pathlib.Path('screenshots')
output.mkdir(exist_ok=True)
runtimes = json.loads(run('xcrun', 'simctl', 'list', 'runtimes', '-j'))['runtimes']
ios = [r for r in runtimes if r.get('isAvailable') and r['identifier'].startswith('com.apple.CoreSimulator.SimRuntime.iOS-')]
if not ios:
    raise SystemExit('No iOS simulator runtime available')
runtime = max(ios, key=lambda r: tuple(map(int, r['version'].split('.'))))
types = json.loads(run('xcrun', 'simctl', 'list', 'devicetypes', '-j'))['devicetypes']
# Store screenshot sizes: large iPhone and 13-inch iPad.
choices = {
    'iphone': ['iPhone 17 Pro Max', 'iPhone 16 Pro Max'],
    'ipad': ['iPad Pro 13-inch (M5)', 'iPad Pro 13-inch (M4)'],
}
metadata = {}
for category, names in choices.items():
    device = next((d for name in names for d in types if d['name'] == name), None)
    if not device:
        raise SystemExit(f'No supported large-screen simulator for {category}')
    udid = run('xcrun', 'simctl', 'create', f'CashCount screenshots {category}', device['identifier'], runtime['identifier'])
    try:
        run('xcrun', 'simctl', 'boot', udid)
        run('xcrun', 'simctl', 'bootstatus', udid, '-b')
        run('xcrun', 'simctl', 'ui', udid, 'appearance', 'light')
        run('xcrun', 'simctl', 'status_bar', udid, 'override', '--time', '9:41', '--dataNetwork', 'wifi', '--wifiMode', 'active', '--wifiBars', '3', '--batteryState', 'charged', '--batteryLevel', '100')
        run('xcrun', 'simctl', 'install', udid, str(app))
        container = pathlib.Path(run('xcrun', 'simctl', 'get_app_container', udid, bundle, 'data'))
        preferences = container / 'Library/Preferences'
        preferences.mkdir(parents=True, exist_ok=True)
        cash = {'loose': {'10000': 3, '5000': 2, '2000': 0, '1000': 12, '500': 8, '100': 24, '50': 12, '10': 32, '5': 8, '1': 25},
                'rolls': {'500': 1, '100': 2, '50': 1, '10': 2, '5': 1, '1': 1}}
        with (preferences / (bundle + '.plist')).open('wb') as f:
            plistlib.dump({'cash-count.accounts.v1': json.dumps([cash, {'loose': {}, 'rolls': {}}]).encode()}, f)
        run('xcrun', 'simctl', 'launch', udid, bundle, '-AppleLanguages', '(ja)', '-AppleLocale', 'ja_JP')
        # Allow the initial SwiftUI layout and launch transition to finish.
        time.sleep(5)
        destination = output / (category + '-cash-count.png')
        run('xcrun', 'simctl', 'io', udid, 'screenshot', str(destination))
        if not destination.is_file() or destination.stat().st_size < 10000:
            raise SystemExit(f'Screenshot missing or empty: {destination}')
        metadata[category] = {'device': device['name'], 'runtime': runtime['version'], 'file': destination.name, 'expected_total_yen': sum(int(value) * (count + cash['rolls'].get(value, 0) * 50) for value, count in cash['loose'].items())}
    finally:
        subprocess.run(['xcrun', 'simctl', 'shutdown', udid], check=False)
        subprocess.run(['xcrun', 'simctl', 'delete', udid], check=False)
(output / 'capture-info.json').write_text(json.dumps(metadata, ensure_ascii=False, indent=2))
