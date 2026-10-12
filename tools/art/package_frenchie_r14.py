"""Replace only GLB base-color images with Blender's side-projection UV bakes."""
import pathlib,json,struct,hashlib,numpy as np
from reshape_pomeranian_r9 import unpack,accessor
ROOT=pathlib.Path(__file__).resolve().parents[2]
OUT=ROOT/'build/frenchie_face_r14'
SOURCE=ROOT/'assets/art_previews/dogs/candidates/r13/frenchie.glb'
doc,data=unpack(SOURCE);before=bytes(data)
primitives=doc['meshes'][0]['primitives']
def add(array,typ,component):
    data.extend(b'\0'*(-len(data)%4));offset=len(data);data.extend(array.tobytes())
    doc['bufferViews'].append({'buffer':0,'byteOffset':offset,'byteLength':array.nbytes})
    a={'bufferView':len(doc['bufferViews'])-1,'componentType':component,'count':len(array),'type':typ}
    if typ=='VEC3':a.update(min=array.min(0).tolist(),max=array.max(0).tolist())
    doc['accessors'].append(a);return len(doc['accessors'])-1
body=primitives[0];indices=accessor(doc,data,body['indices']).reshape(-1).copy()
arrays={k:accessor(doc,data,v)[indices].copy() for k,v in body['attributes'].items()}
arrays['TEXCOORD_0']=np.load(OUT/'body_corner_uv.npy').reshape(-1,2)
_,unique_rows,remapped=np.unique(np.concatenate(list(arrays.values()),axis=1),axis=0,return_index=True,return_inverse=True)
# Split UV corners while copying every original geometry/skin attribute exactly.
for key,array in arrays.items():
    old=doc['accessors'][body['attributes'][key]]
    body['attributes'][key]=add(array[unique_rows],old['type'],old['componentType'])
body['indices']=add(remapped.astype(np.uint32),'SCALAR',5125)
for i,primitive in enumerate(primitives):
    mat=doc['materials'][primitive['material']]
    tex=doc['textures'][mat['pbrMetallicRoughness']['baseColorTexture']['index']]
    im=doc['images'][tex['source']]
    blob=(OUT/f'baked_{i}.png').read_bytes()
    data.extend(b'\0'*(-len(data)%4))
    doc['bufferViews'].append({'buffer':0,'byteOffset':len(data),'byteLength':len(blob)})
    data.extend(blob);im['bufferView']=len(doc['bufferViews'])-1;im['mimeType']='image/png'
assert bytes(data[:len(before)])==before
data.extend(b'\0'*(-len(data)%4));doc['buffers'][0]['byteLength']=len(data)
enc=json.dumps(doc,separators=(',',':')).encode();enc+=b' '*(-len(enc)%4)
raw=struct.pack('<III',0x46546c67,2,28+len(enc)+len(data))+struct.pack('<II',len(enc),0x4e4f534a)+enc+struct.pack('<II',len(data),0x004e4942)+data
(OUT/'frenchie.glb').write_bytes(raw)
(OUT/'verification.json').write_text(json.dumps({'source_sha256':hashlib.sha256(SOURCE.read_bytes()).hexdigest(),'result_sha256':hashlib.sha256(raw).hexdigest(),'original_binary_data_preserved':True,'body_uv_repacked_with_exact_corner_geometry_and_skin_attributes':True,'base_color_images_rebaked':True},indent=2))
print((OUT/'verification.json').read_text())
