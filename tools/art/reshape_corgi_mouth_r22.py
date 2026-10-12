"""Retract the cheek-to-tongue web locally; preserve the original Corgi head."""
from pathlib import Path
import json,struct,hashlib,numpy as np
from reshape_pomeranian_r9 import unpack,accessor,smooth
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'build/corgi_face_r22';OUT.mkdir(parents=True,exist_ok=True)
SOURCE=ROOT/'assets/art_previews/dogs/candidates/r21/corgi.glb'
doc,data=unpack(SOURCE);pr=doc['meshes'][0]['primitives'][0]
p=accessor(doc,data,pr['attributes']['POSITION']);original=p.copy()
t=accessor(doc,data,pr['indices']).reshape(-1,3)
x=p[:,0]/.45;z=p[:,1]/.45;y=-p[:,2]/.45
mask=smooth(-.448,-.418,y)*(1-smooth(-.335,-.28,y))
mask*=smooth(.495,.54,z)*(1-smooth(.597,.635,z))
mask*=1-smooth(.10,.16,np.abs(x))
# Tuck the membrane towards the cheek and lift its low edge; keep tongue front fixed.
p[:,2]-=.45*.012*mask
p[:,1]+=.45*.003*mask
_,first,inv=np.unique(np.round(original,7),axis=0,return_index=True,return_inverse=True)
q=p[first];tri=inv[t];norm=np.zeros_like(q)
fn=np.cross(q[tri[:,1]]-q[tri[:,0]],q[tri[:,2]]-q[tri[:,0]])
for j in range(3):np.add.at(norm,tri[:,j],fn)
norm/=np.maximum(np.linalg.norm(norm,axis=1,keepdims=True),1e-12)
affected=np.unique(inv[t[np.any(mask[t]>0,axis=1)]])
change=np.isin(inv,affected);accessor(doc,data,pr['attributes']['NORMAL'])[change]=norm[inv[change]]
a=doc['accessors'][pr['attributes']['POSITION']];a['min']=p.min(0).tolist();a['max']=p.max(0).tolist()
enc=json.dumps(doc,separators=(',',':')).encode();enc+=b' '*(-len(enc)%4)
raw=struct.pack('<III',0x46546c67,2,28+len(enc)+len(data))+struct.pack('<II',len(enc),0x4e4f534a)+enc+struct.pack('<II',len(data),0x004e4942)+data
(OUT/'corgi.glb').write_bytes(raw)
report={'moved_logical_vertices':int((mask[first]>0).sum()),'max_displacement_m':float(np.linalg.norm(p-original,axis=1).max()),'result_sha256':hashlib.sha256(raw).hexdigest()}
(OUT/'geometry_verification.json').write_text(json.dumps(report,indent=2));print(report)
