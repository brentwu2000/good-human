"""Compare r33/r34 skin and densely sample Run contact between baked keys."""
import hashlib
import json
from audit_dog_motion_skin import ROOT, audit

report = {}
for breed in ['shiba_01', 'chihuahua', 'corgi', 'frenchie', 'golden', 'pomeranian', 'poodle', 'shiba']:
    report[breed] = {}
    for version, revision in [('before', 33), ('after', 34)]:
        model = ROOT / f'assets/art_previews/dogs/candidates/r33/models/{breed}.glb'
        if breed == 'shiba_01':
            model = ROOT / 'assets/characters/dog/models/shiba_01/shiba_01.glb'
        elif revision == 34 and breed == 'chihuahua':
            model = ROOT / 'assets/art_previews/dogs/candidates/r34/models/chihuahua.glb'
        library = ROOT / f'assets/art_previews/dogs/candidates/r{revision}/m2m/{breed}.glb'
        values = audit(model, library, sample_count=17)
        values['M2M_Run'] = audit(model, library, sample_count=209, clips=['M2M_Run'])['M2M_Run']
        report[breed][version] = values
        report[breed][version + '_sha256'] = hashlib.sha256(library.read_bytes()).hexdigest()
    print(breed, {v: report[breed][v]['M2M_Run'] for v in ['before','after']}, flush=True)
    (ROOT / 'build/dog_motion_r34/skin_audit_final.json').write_text(json.dumps(report, indent=2), encoding='utf-8')
