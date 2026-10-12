"""Replace only the base-color image of the r37 geometry candidate."""
from pathlib import Path
import copy,json,struct,hashlib
from reshape_pomeranian_r9 import unpack
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'build/dog_polish_r37'
src=OUT/'chihuahua_surface.glb';dest=ROOT/'assets/art_previews/dogs/candidates/r37/chihuahua.glb'
d,b=unpack(src);old=copy.deepcopy(d);before=bytes(b)
png=(OUT/'body_baked.png').read_bytes();b.extend(b'\0'*(-len(b)%4))
d['bufferViews'].append({'buffer':0,'byteOffset':len(b),'byteLength':len(png)});b.extend(png)
d['images'][0].update(bufferView=len(d['bufferViews'])-1,mimeType='image/png')
b.extend(b'\0'*(-len(b)%4));d['buffers'][0]['byteLength']=len(b)
assert bytes(b[:len(before)])==before
for k in ['accessors','meshes','nodes','skins','animations','materials','textures','samplers','scenes','scene']:assert d.get(k)==old.get(k),k
enc=json.dumps(d,separators=(',',':')).encode();enc+=b' '*(-len(enc)%4)
raw=struct.pack('<III',0x46546c67,2,28+len(enc)+len(b))+struct.pack('<II',len(enc),0x4e4f534a)+enc+struct.pack('<II',len(b),0x004e4942)+b
dest.write_bytes(raw)
report={'source_sha256':hashlib.sha256(src.read_bytes()).hexdigest(),'candidate_sha256':hashlib.sha256(raw).hexdigest(),'surface_binary_prefix_retained':True,'geometry_uv_skin_rig_animations_unchanged_by_texture_packaging':True}
(OUT/'texture_verification.json').write_text(json.dumps(report,indent=2));print(json.dumps(report,indent=2))
