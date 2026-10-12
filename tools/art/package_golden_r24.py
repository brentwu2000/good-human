"""Replace the embedded image only. Every geometry/skin/animation byte retained."""
from pathlib import Path
import json,struct,hashlib
from reshape_pomeranian_r9 import unpack
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'build/golden_face_r24'
src=ROOT/'assets/art_previews/dogs/candidates/r24/golden_r6.glb'
doc,data=unpack(src);original=bytes(data)
blob=(OUT/'baked_0.png').read_bytes();data.extend(b'\0'*(-len(data)%4))
doc['bufferViews'].append({'buffer':0,'byteOffset':len(data),'byteLength':len(blob)});data.extend(blob)
doc['images'][0].update(bufferView=len(doc['bufferViews'])-1,mimeType='image/png')
data.extend(b'\0'*(-len(data)%4));doc['buffers'][0]['byteLength']=len(data)
assert bytes(data[:len(original)])==original
enc=json.dumps(doc,separators=(',',':')).encode();enc+=b' '*(-len(enc)%4)
raw=struct.pack('<III',0x46546c67,2,28+len(enc)+len(data))+struct.pack('<II',len(enc),0x4e4f534a)+enc+struct.pack('<II',len(data),0x004e4942)+data
(OUT/'golden.glb').write_bytes(raw)
report={'original_buffer_bytes_retained':True,'source_sha256':hashlib.sha256(src.read_bytes()).hexdigest(),'result_sha256':hashlib.sha256(raw).hexdigest()}
(OUT/'verification.json').write_text(json.dumps(report,indent=2));print(report)


