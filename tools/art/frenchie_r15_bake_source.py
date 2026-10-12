"""Carry smoothed corner geometry onto the original r13 UV charts for rebaking."""
import pathlib,json,struct,numpy as np
from reshape_pomeranian_r9 import unpack,accessor
ROOT=pathlib.Path(__file__).resolve().parents[2];OUT=ROOT/'build/frenchie_face_r15'
doc,data=unpack(ROOT/'build/frenchie_face_r13/frenchie.glb')
shaped,sd=unpack(OUT/'frenchie.glb')
for original,new in zip(doc['meshes'][0]['primitives'],shaped['meshes'][0]['primitives']):
    oi=accessor(doc,data,original['indices']).reshape(-1)
    ni=accessor(shaped,sd,new['indices']).reshape(-1)
    for name in ['POSITION','NORMAL']:
        dst=accessor(doc,data,original['attributes'][name])
        vals=accessor(shaped,sd,new['attributes'][name])[ni]
        dst[oi]=vals
        assert np.array_equal(dst[oi],vals)
        if name=='POSITION':
            a=doc['accessors'][original['attributes'][name]];a['min']=dst.min(0).tolist();a['max']=dst.max(0).tolist()
enc=json.dumps(doc,separators=(',',':')).encode();enc+=b' '*(-len(enc)%4)
raw=struct.pack('<III',0x46546c67,2,28+len(enc)+len(data))+struct.pack('<II',len(enc),0x4e4f534a)+enc+struct.pack('<II',len(data),0x004e4942)+data
(OUT/'bake_source.glb').write_bytes(raw)
