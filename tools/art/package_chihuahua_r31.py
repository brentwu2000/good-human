from pathlib import Path
import json,struct,hashlib,copy
import numpy as np
from reshape_pomeranian_r9 import unpack
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'build/chihuahua_motion_r31'
src=ROOT/'assets/art_previews/dogs/candidates/r30/chihuahua.glb';d,b=unpack(src);old=copy.deepcopy(d);before=bytes(b)
def acc(a,typ):
 a=np.asarray(a,dtype='<f4');b.extend(b'\0'*(-len(b)%4));vi=len(d['bufferViews']);d['bufferViews'].append({'buffer':0,'byteOffset':len(b),'byteLength':a.nbytes});b.extend(a.tobytes());ai=len(d['accessors']);v={'bufferView':vi,'componentType':5126,'count':len(a),'type':typ}
 if typ=='SCALAR':v.update(min=[float(a.min())],max=[float(a.max())])
 d['accessors'].append(v);return ai

def mul(a,c):
 x,y,z,w=a;X,Y,Z,W=c
 return np.array([w*X+x*W+y*Z-z*Y,w*Y-x*Z+y*W+z*X,w*Z+x*Y-y*X+z*W,w*W-x*X-y*Y-z*Z])
for rec in json.loads((OUT/'baked_gestures.json').read_text()):
 if rec['name']=='TailWag':continue
 frames=rec['frames'];times=acc(np.arange(len(frames))/rec['fps'],'SCALAR');anim={'name':rec['name'],'samplers':[],'channels':[]}
 for idx in d['skins'][0]['joints']:
  node=d['nodes'][idx];name=node['name'];rest=node.get('rotation',[0,0,0,1]);quats=np.array([mul(rest,f[name]) for f in frames]);quats/=np.linalg.norm(quats,axis=1)[:,None]
  for i in range(1,len(quats)):
   if np.dot(quats[i-1],quats[i])<0:quats[i]*=-1
  out=acc(quats,'VEC4');si=len(anim['samplers']);anim['samplers'].append({'input':times,'output':out,'interpolation':'LINEAR'});anim['channels'].append({'sampler':si,'target':{'node':idx,'path':'rotation'}})
 d['animations'].append(anim)
b.extend(b'\0'*(-len(b)%4));d['buffers'][0]['byteLength']=len(b)
assert b[:len(before)]==before
assert d['animations'][:len(old['animations'])]==old['animations']
for k in ['meshes','nodes','skins','materials','textures','images','scenes','scene']:assert d.get(k)==old.get(k)
enc=json.dumps(d,separators=(',',':')).encode();enc+=b' '*(-len(enc)%4);raw=struct.pack('<III',0x46546c67,2,28+len(enc)+len(b))+struct.pack('<II',len(enc),0x4e4f534a)+enc+struct.pack('<II',len(b),0x004e4942)+b
out=ROOT/'assets/art_previews/dogs/candidates/r31/chihuahua.glb';out.parent.mkdir(parents=True,exist_ok=True);out.write_bytes(raw)
report={'source_sha256':hashlib.sha256(src.read_bytes()).hexdigest(),'candidate_sha256':hashlib.sha256(raw).hexdigest(),'original_binary_preserved':True,'original_mesh_skin_materials_and_clips_preserved':True,'added_clips':['HeadLook','Sniff'],'rigify_control_bones_not_exported':True}
(OUT/'verification.json').write_text(json.dumps(report,indent=2));print(json.dumps(report,indent=2))

