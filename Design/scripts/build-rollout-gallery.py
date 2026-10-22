#!/usr/bin/env python3
"""Build a static review gallery from xcresulttool-exported screenshot manifests.

Usage: python3 Design/scripts/build-rollout-gallery.py --capture light=/tmp/exported
Repeat --capture for dark, compact, ipad. Requires Pillow in the artifact runtime only.
Export first: xcrun xcresulttool export attachments --path RUN.xcresult --output-path DIR
"""
import argparse
import html
import json
import re
from pathlib import Path
from PIL import Image, ImageChops

parser = argparse.ArgumentParser()
parser.add_argument('--capture', action='append', required=True, metavar='APPEARANCE=DIRECTORY')
args = parser.parse_args()
preview = Path(__file__).resolve().parents[1] / 'previews'
output = preview / 'screenshots' / 'design-rollout'
output.mkdir(parents=True, exist_ok=True)
items = []
for argument in args.capture:
    appearance, directory = argument.split('=', 1)
    directory = Path(directory)
    for test in json.loads((directory / 'manifest.json').read_text()):
        identifier = test['testIdentifier']
        scenario = appearance + ('-large' if 'LargerText' in identifier or 'WithLargerText' in identifier else '')
        for attachment in test['attachments']:
            suggested = attachment.get('suggestedHumanReadableName', '')
            if not suggested.endswith('.png') or attachment.get('isAssociatedWithFailure'):
                continue
            name = re.sub(r'_\d+_.*$', '', suggested.removesuffix('.png'))
            if not name.startswith(('rollout-', 'home-a1-', 'pilot-', 'remaining-')):
                continue
            source = directory / attachment['exportedFileName']
            image = Image.open(source).convert('RGB')
            device = attachment.get('deviceName', '')
            scale = 2 if 'iPad' in device or image.width <= 750 else 3
            width, height = round(image.width / scale), round(image.height / scale)
            image = image.resize((width, height), Image.Resampling.LANCZOS)
            destination = output / scenario / (name + '.png')
            destination.parent.mkdir(parents=True, exist_ok=True)
            image.save(destination, optimize=True)
            items.append(dict(name=name, scenario=scenario, test=identifier,
                              device=attachment.get('deviceName'), width=image.width, height=image.height,
                              path=str(destination.relative_to(preview))))
            if name == 'home-a1-top' and scenario == 'light':
                baseline = preview / 'screenshots/home-fidelity/native-light-top@3x.png'
                before = Image.open(baseline).convert('RGB')
                after = Image.open(source).convert('RGB')
                if before.size == after.size:
                    box = (0, 270, before.width, 2220)
                    a, b = before.crop(box), after.crop(box)
                    diff = ImageChops.difference(a, b)
                    compare = Image.new('RGB', (a.width * 2, a.height))
                    compare.paste(a, (0, 0)); compare.paste(b, (a.width, 0))
                    compare.resize((786, 650), Image.Resampling.LANCZOS).save(output / 'home-preservation.png')
                    Image.blend(a, b, 0.5).resize((393, 650), Image.Resampling.LANCZOS).save(output / 'home-overlay.png')
                    (output / 'home-preservation.json').write_text(json.dumps(dict(
                        comparison='Approved native Home vs rollout, app content only',
                        source_size=before.size, crop=box, identical=diff.getbbox() is None), indent=2))
# Unique stable entries if a repeated capture was exported.
items = list({(x['scenario'], x['name']): x for x in items}.values())
(output / 'manifest.json').write_text(json.dumps(items, indent=2))

def family(name):
    if 'pattern' in name: return 'Reusable patterns'
    if 'review-form' in name or 'selector' in name or 'instructor' in name: return 'Instructors and forms'
    if any(x in name for x in ['quiz', 'question', 'answer', 'deck', 'discussion', 'event']): return 'Events and study'
    if any(x in name for x in ['profile', 'notification', 'faq', 'feature', 'version', 'more', 'settings', 'premium', 'welcome', 'account', 'training']): return 'Account, settings and support'
    return 'Home, search and libraries'

cards = ''
for group in ['Home, search and libraries', 'Events and study', 'Instructors and forms', 'Account, settings and support', 'Reusable patterns']:
    entries = sorted((x for x in items if family(x['name']) == group), key=lambda x: (x['name'], x['scenario']))
    cards += '<section><h2>' + html.escape(group) + '</h2><div class="grid">'
    for item in entries:
        label = item['name'].replace('rollout-', '').replace('-', ' ').capitalize()
        cards += f'''<figure data-scenario="{html.escape(item['scenario'])}"><a href="{html.escape(item['path'])}" target="_blank"><img loading="lazy" src="{html.escape(item['path'])}" alt="{html.escape(label + ', ' + item['scenario'])}" width="{item['width']}" height="{item['height']}"></a><figcaption><strong>{html.escape(label)}</strong><span>{html.escape(item['scenario'])} · {item['width']} × {item['height']}</span></figcaption></figure>'''
    cards += '</div></section>'
scenarios = sorted(set(x['scenario'] for x in items))
options = ''.join(f'<option>{html.escape(x)}</option>' for x in scenarios)
page = '''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Primary Gouge — app-wide design rollout</title>
<style>*{box-sizing:border-box}body{margin:0;background:#f5f7fb;color:#18263b;font:15px/1.55 system-ui,sans-serif}main{max-width:1500px;margin:auto;padding:36px 28px}h1{font-size:32px;letter-spacing:-1px;line-height:1.15}h2{font-size:20px;margin:36px 0 16px}p{max-width:850px;color:#637086}a{color:#2867da}nav{display:flex;gap:20px;flex-wrap:wrap}label{display:block;margin:24px 0}select{padding:9px;border:1px solid #d3e1fc;border-radius:9px;font:inherit;background:white}.grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(240px,1fr));gap:24px;align-items:start}figure{margin:0;max-width:402px}figure img{display:block;width:100%;height:auto;border:1px solid #e0e6ee;border-radius:16px}figcaption{display:flex;flex-direction:column;padding:10px 2px}figcaption span{font-size:12px;color:#637086}[hidden]{display:none!important}.comparison{display:flex;gap:20px;align-items:start;flex-wrap:wrap}.comparison img{max-width:100%;height:auto}button{font:inherit}small{color:#637086}</style>
<main><small>PRIMARY GOUGE · NATIVE DESIGN SYSTEM</small><h1>App-wide rollout and reusable patterns</h1><p>Native screen extensions using the selected visual language. New extensions await visual review. Captures show fixture or actual test-account states; they do not establish live purchase, reminder delivery, or destructive-flow verification.</p><nav><a href="remaining-fidelity.html">Selected native comparisons</a><a href="pilot-fidelity.html">Approved event/study comparisons</a><a href="screenshots/design-rollout/manifest.json">Capture evidence</a></nav><label>Show captures: <select id="scenario"><option value="all">All appearances</option>'''+options+'''</select></label>
<details><summary>Home preservation comparison</summary><p>Approved native Home (left) and rollout (right), excluding system status and tab chrome. The overlay and JSON record preserve the same comparison region.</p><div class="comparison"><a href="screenshots/design-rollout/home-preservation.png"><img src="screenshots/design-rollout/home-preservation.png" width="786" height="650" alt="Approved Home and rollout side by side"></a><a href="screenshots/design-rollout/home-overlay.png"><img src="screenshots/design-rollout/home-overlay.png" width="393" height="650" alt="Home overlay comparison"></a></div><a href="screenshots/design-rollout/home-preservation.json">Comparison result</a></details>
'''+cards+'''<p>Review each page at full size by opening its image. Native system controls, document/media viewers and alerts remain native. See the repository’s Design/screen-audit.md for coverage and outstanding release checks.</p></main><script>const filter=document.querySelector('#scenario');function applyFilter(){document.querySelectorAll('figure').forEach(f=>f.hidden=filter.value!=='all'&&f.dataset.scenario!==filter.value);document.querySelectorAll('section').forEach(s=>s.hidden=!s.querySelector('figure:not([hidden])'));}filter.addEventListener('change',applyFilter);filter.value='light';applyFilter();</script></html>'''
(preview / 'design-rollout.html').write_text(page)
print(f'Wrote {len(items)} captures and design-rollout.html')
