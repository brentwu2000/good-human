from pathlib import Path
import json,struct,hashlib,copy
from reshape_pomeranian_r9 import unpack
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'build/chihuahua_mouth_r30'
src=ROOT/'assets/art_previews/dogs/candidates/r29/chihuahua.glb'
d,b=unpack(src);old=copy.deepcopy(d);before=bytes(b)
blob=(OUT/'body_baked.png').read_bytes();b.extend(b'\0'*(-len(b)%4))
d['bufferViews'].append({'buffer':0,'byteOffset':len(b),'byteLength':len(blob)});b.extend(blob)
d['images'][0].update(bufferView=len(d['bufferViews'])-1,mimeType='image/png')
b.extend(b'\0'*(-len(b)%4));d['buffers'][0]['byteLength']=len(b)
assert bytes(b[:len(before)])==before
for k in ['accessors','meshes','nodes','skins','animations','materials','textures','samplers','scenes','scene']:assert d.get(k)==old.get(k)
enc=json.dumps(d,separators=(',',':')).encode();enc+=b' '*(-len(enc)%4)
raw=struct.pack('<III',0x46546c67,2,28+len(enc)+len(b))+struct.pack('<II',len(enc),0x4e4f534a)+enc+struct.pack('<II',len(b),0x004e4942)+b
out=ROOT/'assets/art_previews/dogs/candidates/r30/chihuahua.glb';out.parent.mkdir(parents=True,exist_ok=True);out.write_bytes(raw)
report={'source_sha256':hashlib.sha256(src.read_bytes()).hexdigest(),'candidate_sha256':hashlib.sha256(raw).hexdigest(),'original_binary_prefix_retained':True,'all_geometry_UVs_normals_weights_rig_animation_descriptors_retained':True,'clips':[a['name'] for a in d['animations']]}
(OUT/'verification.json').write_text(json.dumps(report,indent=2));print(json.dumps(report,indent=2))

