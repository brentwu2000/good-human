"""Smooth inherited breed-skin discontinuities without changing geometry/UVs/rig."""
import json,struct,hashlib,argparse
from pathlib import Path
import numpy as np
from scipy.sparse import coo_matrix,diags
from reshape_pomeranian_r9 import unpack,accessor
ROOT=Path(__file__).resolve().parents[2]
def build(breed,iterations=360):
 revision={'chihuahua':29,'corgi':21,'frenchie':18,'golden':25,'pomeranian':10,'poodle':28,'shiba':23}[breed]
 src=ROOT/f'assets/art_previews/dogs/candidates/r{revision}/{breed}.glb';d,b=unpack(src)
 def append(arr,kind,ctype):
  b.extend(b'\0'*(-len(b)%4));offset=len(b);blob=arr.tobytes();b.extend(blob);view=len(d['bufferViews']);d['bufferViews'].append({'buffer':0,'byteOffset':offset,'byteLength':len(blob)})
  index=len(d['accessors']);d['accessors'].append({'bufferView':view,'componentType':ctype,'count':len(arr),'type':kind});return index
 for m in d['meshes']:
  for p in m['primitives']:
   a=p['attributes']
   if 'WEIGHTS_0' not in a:continue
   # Copy views before growing the binary buffer.
   pos=accessor(d,b,a['POSITION']).copy();j=accessor(d,b,a['JOINTS_0']).copy();w=accessor(d,b,a['WEIGHTS_0']).copy();tri=accessor(d,b,p['indices']).reshape(-1,3).copy()
   q,first,inv=np.unique(np.round(pos,6),axis=0,return_index=True,return_inverse=True)
   dense=np.zeros((len(pos),len(d['skins'][0]['joints'])))
   for k in range(4):dense[np.arange(len(pos)),j[:,k]]+=w[:,k]
   weights=dense[first];t=inv[tri];edges=np.concatenate([t[:,[0,1]],t[:,[1,2]],t[:,[2,0]]]);edges=np.unique(np.concatenate([edges,edges[:,::-1]]),axis=0)
   A=coo_matrix((np.ones(len(edges)),(edges[:,0],edges[:,1])),shape=(len(q),len(q))).tocsr();deg=np.asarray(A.sum(1)).ravel();A=diags(1/np.maximum(deg,1))@A
   for k in range(iterations):weights=.5*weights+.5*(A@weights)
   weights[deg==0]=dense[first][deg==0]
   top=np.argsort(weights,axis=1)[:,-8:];values=np.take_along_axis(weights,top,axis=1);values/=values.sum(1)[:,None]
   ji=top[inv].astype('<u2');wi=values[inv].astype('<f4')
   a['JOINTS_0']=append(ji[:,:4].copy(),'VEC4',5123);a['WEIGHTS_0']=append(wi[:,:4].copy(),'VEC4',5126)
   a['JOINTS_1']=append(ji[:,4:].copy(),'VEC4',5123);a['WEIGHTS_1']=append(wi[:,4:].copy(),'VEC4',5126)
 b.extend(b'\0'*(-len(b)%4));d['buffers'][0]['byteLength']=len(b)
 enc=json.dumps(d,separators=(',',':')).encode();enc+=b' '*(-len(enc)%4)
 raw=struct.pack('<III',0x46546c67,2,28+len(enc)+len(b))+struct.pack('<II',len(enc),0x4e4f534a)+enc+struct.pack('<II',len(b),0x004e4942)+b
 out=ROOT/f'assets/art_previews/dogs/candidates/r33/models/{breed}.glb';out.parent.mkdir(parents=True,exist_ok=True);out.write_bytes(raw);print(breed,hashlib.sha256(raw).hexdigest())
if __name__=='__main__':
 parser=argparse.ArgumentParser();parser.add_argument('breeds',nargs='+');parser.add_argument('--iterations',type=int,default=360);args=parser.parse_args()
 for breed in args.breeds:build(breed,args.iterations)
