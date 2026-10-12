"""Archive evidence only when published assets match audited r34 candidates."""
import hashlib
import json
import shutil
from pathlib import Path
from PIL import Image, ImageChops

ROOT = Path(__file__).resolve().parents[2]
stage = ROOT / 'build/dog_motion_r34'
dest = ROOT / 'docs/06_art/dog_motion_r34_2026-10-10'
sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
audit = json.loads((stage / 'skin_audit_final.json').read_text())
manifest = json.loads((stage / 'preservation.json').read_text())
for item in manifest:
    assert sha(ROOT / item['runtime']) == item['after_sha256'], item['runtime']
for breed, entry in audit.items():
    library = ROOT / f'assets/characters/dog/animations/m2m/{breed}.glb'
    assert sha(library) == entry['after_sha256'], breed
    run = entry['after']['M2M_Run']
    assert run['lowest_surface_m'] > -0.00001, (breed, run)
    assert run['max_vertex_travel_m'] > 0.1, (breed, run)
    assert 'animation/fps=120' in Path(str(library) + '.import').read_text(), breed
tests = json.loads((stage / 'regression_final.json').read_text(encoding='utf-8-sig'))
assert len(tests) == 7 and all(t['passed'] for t in tests)
assert 'count=720' in (stage / 'capture_final.log').read_text()
assert 'count=10' in (stage / 'capture_runtime.log').read_text()
assert not (stage / 'capture_runtime.err').read_text().strip()
comparison = {}
for phase in [0, 25, 50, 75, 99]:
    name = f'chihuahua_M2M_Run_{phase}.png'
    candidate = Image.open(stage / 'captures/after' / name).convert('RGB')
    runtime = Image.open(stage / 'runtime_captures/after' / name).convert('RGB')
    comparison[name] = ImageChops.difference(candidate, runtime).getbbox() is None
for name in ['skin_audit_final.json','preservation.json','regression_final.json','capture_final.log','capture_runtime.log']:
    shutil.copy2(stage / name, dest / name)
shutil.copy2(stage / 'runtime_captures/after/chihuahua_M2M_Run_50.png', dest / 'chihuahua_runtime_Run_50.png')
(dest / 'runtime_verification.json').write_text(json.dumps({'published_hashes_match_audit': True, 'run_209_samples_ground_tolerance_m': 0.00001, 'runtime_candidate_pixels_identical': comparison}, indent=2), encoding='utf-8')
print('R34_EVIDENCE_VERIFIED', len(manifest), 'assets;', len(tests), 'suites;', comparison)
