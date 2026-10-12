"""Prove retained rig/skin/UV/animations and audit the edited surface in motion."""
from pathlib import Path
import json, hashlib, numpy as np
from reshape_pomeranian_r9 import unpack,accessor
from audit_dog_motion_skin import audit
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'build/dog_polish_r36'
before=ROOT/'assets/art_previews/dogs/candidates/r35/chihuahua.glb'
after=ROOT/'assets/art_previews/dogs/candidates/r36/chihuahua.glb'
d,b=unpack(before);e,c=unpack(after)
for key in ['nodes','skins','animations','meshes','materials','textures','samplers','scenes','scene']:
    assert d.get(key)==e.get(key),key
changed={p['attributes'][key] for m in d['meshes'] for p in m['primitives'] for key in ['POSITION','NORMAL']}
for i in range(len(d['accessors'])):
    if i not in changed:assert np.array_equal(accessor(d,b,i),accessor(e,c,i)),i
library=ROOT/'assets/characters/dog/animations/m2m/chihuahua.glb'
report={'all_uv_indices_eight_influence_skin_bind_rig_animations_retained':True,
        'source_sha256':hashlib.sha256(before.read_bytes()).hexdigest(),
        'candidate_sha256':hashlib.sha256(after.read_bytes()).hexdigest(),
        'library_sha256':hashlib.sha256(library.read_bytes()).hexdigest()}
for version,model in [('before',before),('after',after)]:
    values=audit(model,library,sample_count=33)
    values['M2M_Run']=audit(model,library,sample_count=209,clips=['M2M_Run'])['M2M_Run']
    report[version]=values
    print(version,values,flush=True)
for clip,value in report['after'].items():
    original=report['before'][clip]
    assert value['lowest_surface_m']>=original['lowest_surface_m']-.0001,(clip,value)
    assert value['max_edge_stretch_p99']<=original['max_edge_stretch_p99']*1.05,(clip,value)
(OUT/'validation.json').write_text(json.dumps(report,indent=2),encoding='utf8')
print('R36_PRESERVATION_AND_MOTION_PASS')
