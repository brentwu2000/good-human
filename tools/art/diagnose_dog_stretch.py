"""Locate the upper one percent of stretched edges in a selected dog pose."""
import sys
import numpy as np
from audit_dog_motion_skin import skin_setup, unpack, accessor, sample, matrix, ROOT

breed = sys.argv[1]
d, names, parents, prims = skin_setup(ROOT / f'assets/characters/dog/models/breeds/{breed}.glb')
ld, lb = unpack(ROOT / f'assets/art_previews/dogs/candidates/r34/m2m/{breed}.glb')
anim = next(a for a in ld['animations'] if a['name'] == 'M2M_Run')
tracks = []
for c in anim['channels']:
    name = ld['nodes'][c['target']['node']].get('name')
    if name not in names: continue
    s = anim['samplers'][c['sampler']]
    tracks.append((names[name], c['target']['path'], (accessor(ld,lb,s['input']).ravel(), accessor(ld,lb,s['output']).copy())))
duration = max(t[-1][0][-1] for t in tracks)
worst = (0, None)
for time in np.linspace(0,duration,33):
    nodes = [dict(n) for n in d['nodes']]
    for idx,key,values in tracks: nodes[idx][key] = sample(values,time)
    world = {}
    def get(i):
        if i not in world: world[i] = (get(parents[i]) if i in parents else np.eye(4)) @ matrix(nodes[i])
        return world[i]
    for pos,j,w,joints,ibm,edges,rest_len in prims:
        mats = np.array([get(i) for i in joints]) @ ibm
        result = sum(np.einsum('nij,nj->ni',mats[j[:,k]],pos)*w[:,k,None] for k in range(j.shape[1]))[:,:3]
        ratio = np.linalg.norm(result[edges[:,0]]-result[edges[:,1]],axis=1)/rest_len
        q = np.quantile(ratio,.99)
        if q <= worst[0]: continue
        ids = np.unique(edges[ratio>=q])
        influence = np.bincount(j[ids].ravel(),weights=w[ids].ravel(),minlength=len(joints)) / len(ids)
        worst = (q, {'time':float(time),'rest_bounds':[pos[ids,:3].min(0).tolist(),pos[ids,:3].max(0).tolist()], 'centre':pos[ids,:3].mean(0).tolist(),'influences':{d['nodes'][joints[k]]['name']:round(float(influence[k]),3) for k in np.argsort(influence)[-6:]}})
print(breed,worst)
