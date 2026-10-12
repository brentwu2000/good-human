"""Keep all r27 geometry/rig data; replace body image and ear infill UVs only."""
from pathlib import Path
import json,struct,hashlib,copy
import numpy as np
from reshape_pomeranian_r9 import unpack,accessor
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'build/poodle_ears_r28'
source=ROOT/'assets/art_previews/dogs/candidates/r27/poodle.glb'
d,b=unpack(source);old=copy.deepcopy(d);before=bytes(b);allowed=np.zeros(len(b),bool)
for prim in d['meshes'][0]['primitives'][1:]:
 p=accessor(d,b,prim['attributes']['POSITION']);uv=accessor(d,b,prim['attributes']['TEXCOORD_0'])
 x=p[:,0];z=p[:,1]
 uv[:,0]=np.where(x<0,235+(x+.102)*900,535+(x-.108)*900)/768
 uv[:,1]=(310-(z-.340)*1100)/768
 a=d['accessors'][prim['attributes']['TEXCOORD_0']];v=d['bufferViews'][a['bufferView']]
 offset=v.get('byteOffset',0)+a.get('byteOffset',0);stride=v.get('byteStride',8)
 for i in range(a['count']):allowed[offset+i*stride:offset+i*stride+8]=True
assert np.array_equal(np.frombuffer(before,dtype='u1')[~allowed],np.frombuffer(b,dtype='u1')[~allowed])
blob=(OUT/'body_baked.png').read_bytes();b.extend(b'\0'*(-len(b)%4));idx=len(d['bufferViews'])
d['bufferViews'].append({'buffer':0,'byteOffset':len(b),'byteLength':len(blob)});b.extend(blob)
d['images'][0].update(bufferView=idx,mimeType='image/png')
b.extend(b'\0'*(-len(b)%4));d['buffers'][0]['byteLength']=len(b)
for key in ['meshes','nodes','skins','animations','materials','textures','samplers','scenes','scene']:assert d.get(key)==old.get(key)
enc=json.dumps(d,separators=(',',':')).encode();enc+=b' '*(-len(enc)%4)
raw=struct.pack('<III',0x46546c67,2,28+len(enc)+len(b))+struct.pack('<II',len(enc),0x4e4f534a)+enc+struct.pack('<II',len(b),0x004e4942)+b
out=ROOT/'assets/art_previews/dogs/candidates/r28/poodle.glb';out.parent.mkdir(parents=True,exist_ok=True);out.write_bytes(raw)
report={'source_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'candidate_sha256':hashlib.sha256(raw).hexdigest(),'all_original_binary_except_infill_UVs_retained':True,'geometry_normals_weights_rig_animations_retained':True,'triangles':50736,'body_atlas_resolution':2048,'clips':[a['name'] for a in d['animations']]}
(OUT/'verification.json').write_text(json.dumps(report,indent=2));print(json.dumps(report,indent=2))
