"""Measure animated skin (not bone markers) for CX-04 dog retarget reviews."""
from pathlib import Path
import json,sys
import numpy as np
from scipy.spatial.transform import Rotation
from reshape_pomeranian_r9 import unpack,accessor
ROOT=Path(__file__).resolve().parents[2]

def matrix(node):
 if 'matrix' in node:return np.array(node['matrix']).reshape(4,4).T
 m=np.eye(4);m[:3,:3]=Rotation.from_quat(node.get('rotation',[0,0,0,1])).as_matrix()@np.diag(node.get('scale',[1,1,1]));m[:3,3]=node.get('translation',[0,0,0]);return m

def skin_setup(path):
 d,b=unpack(path);names={n.get('name'):i for i,n in enumerate(d['nodes'])};parents={c:i for i,n in enumerate(d['nodes']) for c in n.get('children',[])}
 primitives=[]
 for n in d['nodes']:
  if 'mesh' not in n or 'skin' not in n:continue
  skin=d['skins'][n['skin']];ibm=accessor(d,b,skin['inverseBindMatrices']).reshape(-1,4,4).transpose(0,2,1)
  for p in d['meshes'][n['mesh']]['primitives']:
   a=p['attributes'];pos=accessor(d,b,a['POSITION']).copy();j=accessor(d,b,a['JOINTS_0']).copy();w=accessor(d,b,a['WEIGHTS_0']).copy()
   if 'JOINTS_1' in a:
    j=np.c_[j,accessor(d,b,a['JOINTS_1'])];w=np.c_[w,accessor(d,b,a['WEIGHTS_1'])]
   tri=accessor(d,b,p['indices']).reshape(-1,3);edges=np.unique(np.sort(np.concatenate([tri[:,[0,1]],tri[:,[1,2]],tri[:,[2,0]]]),axis=1),axis=0)
   lengths=np.linalg.norm(pos[edges[:,0]]-pos[edges[:,1]],axis=1);keep=lengths>1e-5
   primitives.append((np.c_[pos,np.ones(len(pos))],j,w,skin['joints'],ibm,edges[keep],lengths[keep]))
 return d,names,parents,primitives

def sample(ch,time):
 times,vals=ch
 i=int(np.searchsorted(times,time,side='right')-1);i=max(0,min(i,len(times)-1))
 if i==len(times)-1:return vals[i]
 f=(time-times[i])/max(times[i+1]-times[i],1e-8)
 v1,v2=vals[i],vals[i+1]
 if vals.shape[1]==4 and np.dot(v1,v2)<0:v2=-v2
 v=v1*(1-f)+v2*f
 return v/np.linalg.norm(v) if vals.shape[1]==4 else v

def audit(model,library,sample_count=17,clips=None):
 d,names,parents,prims=skin_setup(model);ld,lb=unpack(library);out={}
 for anim in ld['animations']:
  if clips and anim['name'] not in clips:continue
  tracks=[];duration=0
  for c in anim['channels']:
   name=ld['nodes'][c['target']['node']].get('name')
   if name not in names:continue
   sampler=anim['samplers'][c['sampler']];times=accessor(ld,lb,sampler['input']).ravel();vals=accessor(ld,lb,sampler['output']).copy();duration=max(duration,float(times[-1]))
   tracks.append((names[name],c['target']['path'],(times,vals)))
  lows=[];p99=[];tops=[];moving=[];nose=[]
  for time in np.linspace(0,duration,sample_count):
   nodes=[dict(n) for n in d['nodes']]
   for idx,key,values in tracks:nodes[idx][key]=sample(values,time)
   world={}
   def get(i):
    if i not in world:world[i]=(get(parents[i]) if i in parents else np.eye(4))@matrix(nodes[i])
    return world[i]
   low=1e9;top=-1e9;ratios=[];centre=[]
   for pos,j,w,joints,ibm,edges,rest_len in prims:
    matrices=np.array([get(i) for i in joints])@ibm
    result=sum(np.einsum('nij,nj->ni',matrices[j[:,k]],pos)*w[:,k,None] for k in range(j.shape[1]))[:,:3]
    low=min(low,float(result[:,1].min()));top=max(top,float(result[:,1].max()));centre.append(result)
    ratios.extend(np.linalg.norm(result[edges[:,0]]-result[edges[:,1]],axis=1)/rest_len)
   lows.append(low);tops.append(top);p99.append(float(np.quantile(ratios,.99)));moving.append(np.concatenate(centre))
  displacement=float(np.max(np.linalg.norm(np.stack(moving)-moving[0],axis=2)))
  out[anim['name']]={'lowest_surface_m':min(lows),'highest_low_surface_m':max(lows),'max_edge_stretch_p99':max(p99),'max_vertex_travel_m':displacement,'duration_s':duration,'sample_count':sample_count}
 return out

if __name__=='__main__':
 report={}
 for breed in ['shiba_01','chihuahua','corgi','frenchie','golden','pomeranian','poodle','shiba']:
  revision={'chihuahua':29,'corgi':21,'frenchie':18,'golden':25,'pomeranian':10,'poodle':28,'shiba':23}.get(breed)
  model=ROOT/'assets/characters/dog/models/shiba_01/shiba_01.glb' if breed=='shiba_01' else ROOT/f'assets/art_previews/dogs/candidates/r{revision}/{breed}.glb'
  report[breed]={}
  for version,folder in [('before','assets/art_previews/dogs/candidates/r33/before_m2m'),('after','assets/art_previews/dogs/candidates/r33/m2m')]:
   candidate=ROOT/f'assets/art_previews/dogs/candidates/r33/models/{breed}.glb'
   mesh=candidate if version=='after' and candidate.exists() else model
   report[breed][version]=audit(mesh,ROOT/folder/(breed+'.glb'))
  print(breed,[(clip,round(report[breed]['before'][clip]['max_edge_stretch_p99'],2),round(values['max_edge_stretch_p99'],2),round(values['lowest_surface_m'],3)) for clip,values in report[breed]['after'].items()],flush=True)
 dest=ROOT/'build/dog_motion_r33/skin_audit.json';dest.write_text(json.dumps(report,indent=2),encoding='utf-8')
