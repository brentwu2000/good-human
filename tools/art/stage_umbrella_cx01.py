"""Check umbrella grip/tip contracts, back up baseline, stage for runtime review."""
import hashlib, json, shutil
from pathlib import Path
import numpy as np
from audit_dog_motion_skin import matrix
from reshape_pomeranian_r9 import unpack, accessor
ROOT=Path(__file__).resolve().parents[2]
folder=ROOT/'assets/art_previews/props/umbrella_cx01'
runtime=ROOT/'assets/props/weapons/umbrella.glb'
sha=lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
allowed = [sha(folder/'before.glb'),sha(folder/'umbrella.glb')]
manifest = ROOT/'build/umbrella_cx01/preservation.json'
if manifest.exists(): allowed.append(json.loads(manifest.read_text())['after']['sha256'])
assert sha(runtime) in allowed, 'Runtime changed concurrently'
report={}
for label,name in [('before','before.glb'),('after','umbrella.glb')]:
    d,b=unpack(folder/name)
    parents={c:i for i,n in enumerate(d['nodes']) for c in n.get('children',[])}
    def world(i): return (world(parents[i]) if i in parents else np.eye(4))@matrix(d['nodes'][i])
    points=[]; triangles=0; names=[]
    for i,n in enumerate(d['nodes']):
        if 'mesh' not in n: continue
        names.append(n['name'])
        for p in d['meshes'][n['mesh']]['primitives']:
            v=accessor(d,b,p['attributes']['POSITION'])
            points.append((np.c_[v,np.ones(len(v))]@world(i).T)[:,:3])
            triangles+=len(accessor(d,b,p['indices']))//3
    points=np.concatenate(points)
    assert abs(points[:,1].max()-.6)<1e-5
    assert points[:,1].min()>-.101
    report[label]={'sha256':sha(folder/name),'triangles':triangles,'minimum':points.min(axis=0).tolist(),'maximum':points.max(axis=0).tolist(),'nodes':names}
assert 'Umbrella_JHook' in report['after']['nodes']
shutil.copy2(folder/'umbrella.glb',runtime)
(ROOT/'build/umbrella_cx01/preservation.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
print(json.dumps(report,indent=2))
