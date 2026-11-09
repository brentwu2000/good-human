"""Compare evaluated r39/r40 skin at 65 samples per runtime clip."""
from pathlib import Path
import json,hashlib
import numpy as np
from audit_dog_motion_skin import audit
from reshape_pomeranian_r9 import unpack,accessor
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'build/poodle_refine_r40'
baseline=ROOT/'assets/art_previews/dogs/candidates/r39/poodle.glb';candidate=ROOT/'assets/art_previews/dogs/candidates/r40/poodle.glb';library=ROOT/'assets/characters/dog/animations/m2m/poodle.glb'
a,ab=unpack(baseline);b,bb=unpack(candidate)
for key in ['nodes','skins','animations','scenes','scene']:assert a.get(key)==b.get(key),key
# Compare every referenced animation and inverse-bind accessor exactly.
for anim in a['animations']:
    for sampler in anim['samplers']:
        for key in ['input','output']:
            idx=sampler[key];assert np.array_equal(accessor(a,ab,idx),accessor(b,bb,idx))
for skin in a['skins']:
    idx=skin['inverseBindMatrices'];assert np.array_equal(accessor(a,ab,idx),accessor(b,bb,idx))
triangles=0
for p in b['meshes'][0]['primitives']:
    attrs=p['attributes'];pos=accessor(b,bb,attrs['POSITION']);idx=accessor(b,bb,p['indices']);triangles+=len(idx)//3
    assert np.isfinite(pos).all() and idx.max()<len(pos)
    w=np.c_[accessor(b,bb,attrs['WEIGHTS_0']),accessor(b,bb,attrs['WEIGHTS_1'])]
    j=np.c_[accessor(b,bb,attrs['JOINTS_0']),accessor(b,bb,attrs['JOINTS_1'])]
    assert np.isfinite(w).all() and (w>=0).all() and np.allclose(w.sum(axis=1),1,atol=1e-6) and j.max()<23
assert triangles<=15000
report={'triangles':triangles,'rig_animation_and_bind_values_retained':True,'source_sha256':hashlib.sha256(baseline.read_bytes()).hexdigest(),'candidate_sha256':hashlib.sha256(candidate.read_bytes()).hexdigest(),'before':audit(baseline,library,65),'after':audit(candidate,library,65)}
failures=[]
for clip,new in report['after'].items():
    old=report['before'][clip]
    assert all(np.isfinite(v) for v in new.values())
    if new['lowest_surface_m']<old['lowest_surface_m']-.001:failures.append(clip+' ground regression')
    if new['max_edge_stretch_p99']>max(old['max_edge_stretch_p99']*1.1,old['max_edge_stretch_p99']+.1):failures.append(clip+' stretch regression')
    if old['max_vertex_travel_m']>.01 and new['max_vertex_travel_m']<old['max_vertex_travel_m']*.90:failures.append(clip+' motion lost')
report['regression_failures']=failures;report['evaluated_poses']=2*65*len(report['after'])
(OUT/'verification.json').write_text(json.dumps(report,indent=2))
print(json.dumps({'triangles':triangles,'evaluated_poses':report['evaluated_poses'],'failures':failures},indent=2),flush=True)
assert not failures
