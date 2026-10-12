"""Append skinned ear infills while retaining the complete r26 binary prefix."""
from pathlib import Path
import json,struct,hashlib,copy
import numpy as np
from reshape_pomeranian_r9 import unpack,accessor

ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'build/poodle_ears_r27'
SOURCE=ROOT/'assets/art_previews/dogs/candidates/r26/poodle.glb'
TARGET=ROOT/'assets/art_previews/dogs/candidates/r27/poodle.glb'
d,b=unpack(SOURCE); original=bytes(b); old=copy.deepcopy(d)
def view(blob):
    b.extend(b'\0'*(-len(b)%4));idx=len(d['bufferViews'])
    d['bufferViews'].append({'buffer':0,'byteOffset':len(b),'byteLength':len(blob)})
    b.extend(blob);return idx
def attr(values,typ,dt,component):
    a=np.array(values,dtype=dt);idx=len(d['accessors'])
    info={'bufferView':view(a.tobytes()),'componentType':component,'count':len(a),'type':typ}
    if typ=='VEC3':info.update(min=a.min(axis=0).tolist(),max=a.max(axis=0).tolist())
    d['accessors'].append(info);return idx
ref=Path(r'C:\Users\b\Documents\good_human_stylized_factory\references\dogs\poodle_front.png')
image_idx=len(d['images']);d['images'].append({'bufferView':view(ref.read_bytes()),'mimeType':'image/png','name':'Owner_Poodle_Front_Ear_Fur'})
tex_idx=len(d['textures']);d['textures'].append({'source':image_idx})
mat_idx=len(d['materials']);d['materials'].append({'name':'R27_Ear_Fur','pbrMetallicRoughness':{'baseColorTexture':{'index':tex_idx},'metallicFactor':0,'roughnessFactor':.85}})
records=json.loads((OUT/'ear_meshes.json').read_text())
for r in records:
    p=np.array(r['positions']);p=p[:,[0,2,1]];p[:,2]*=-1
    n=np.array(r['normals']);n=n[:,[0,2,1]];n[:,2]*=-1
    uv=np.array(r['uv']);uv[:,1]=1-uv[:,1]
    joints=[];weights=[]
    for influences in r['weights']:
        influences=sorted(influences,key=lambda v:-v[1])[:4]
        total=sum(w for _,w in influences)
        joints.append([i for i,_ in influences]+[0]*(4-len(influences)))
        weights.append([w/total for _,w in influences]+[0]*(4-len(influences)))
    attributes={'POSITION':attr(p,'VEC3','<f4',5126),'NORMAL':attr(n,'VEC3','<f4',5126),
        'TEXCOORD_0':attr(uv,'VEC2','<f4',5126),'JOINTS_0':attr(joints,'VEC4','<u2',5123),
        'WEIGHTS_0':attr(weights,'VEC4','<f4',5126)}
    d['meshes'][0]['primitives'].append({'attributes':attributes,'indices':attr(np.array(r['triangles']).reshape(-1),'SCALAR','<u2',5123),'material':mat_idx})
b.extend(b'\0'*(-len(b)%4));d['buffers'][0]['byteLength']=len(b)
assert b[:len(original)]==original
for key in ['nodes','skins','animations','scenes','scene']:assert d.get(key)==old.get(key)
assert d['meshes'][0]['primitives'][0]==old['meshes'][0]['primitives'][0]
for prim in d['meshes'][0]['primitives'][1:]:
    w=accessor(d,b,prim['attributes']['WEIGHTS_0']);j=accessor(d,b,prim['attributes']['JOINTS_0'])
    assert np.allclose(w.sum(axis=1),1) and j.max()<len(d['skins'][0]['joints'])
    p=accessor(d,b,prim['attributes']['POSITION']);idx=accessor(d,b,prim['indices']).reshape(-1,3)
    assert np.isfinite(p).all() and idx.max()<len(p)
    assert np.all(np.linalg.norm(np.cross(p[idx[:,1]]-p[idx[:,0]],p[idx[:,2]]-p[idx[:,0]]),axis=1)>1e-10)
enc=json.dumps(d,separators=(',',':')).encode();enc+=b' '*(-len(enc)%4)
raw=struct.pack('<III',0x46546c67,2,28+len(enc)+len(b))+struct.pack('<II',len(enc),0x4e4f534a)+enc+struct.pack('<II',len(b),0x004e4942)+b
TARGET.parent.mkdir(parents=True,exist_ok=True);TARGET.write_bytes(raw)
report={'source_sha256':hashlib.sha256(SOURCE.read_bytes()).hexdigest(),'candidate_sha256':hashlib.sha256(raw).hexdigest(),
 'original_binary_prefix_retained':True,'original_mesh_primitive_retained':True,'nodes_skins_animations_retained':True,
 'added_vertices':sum(len(r['positions']) for r in records),'added_triangles':sum(len(r['triangles']) for r in records),
 'total_triangles':sum(d['accessors'][p['indices']]['count']//3 for p in d['meshes'][0]['primitives']),
 'clips':[a['name'] for a in d['animations']],'normalized_weights_valid':True,'nondegenerate_added_triangles':True}
(OUT/'verification.json').write_text(json.dumps(report,indent=2));print(json.dumps(report,indent=2))
