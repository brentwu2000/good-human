"""Relax the joined cheek boundary while locking frontal facial landmarks."""
import pathlib,json,struct,hashlib,numpy as np
from scipy.sparse import coo_matrix,diags
from scipy.sparse.csgraph import dijkstra
from reshape_pomeranian_r9 import unpack,accessor,smooth
ROOT=pathlib.Path(__file__).resolve().parents[2]
SOURCE=ROOT/'assets/art_previews/dogs/candidates/r14/frenchie.glb'
OUT=ROOT/'build/frenchie_face_r15';OUT.mkdir(parents=True,exist_ok=True)
doc,data=unpack(SOURCE);primitives=doc['meshes'][0]['primitives']
positions=[accessor(doc,data,p['attributes']['POSITION']).copy() for p in primitives]
triangles=[accessor(doc,data,p['indices']).reshape(-1,3).copy() for p in primitives]
offsets=np.r_[0,np.cumsum([len(p) for p in positions])]
all_pos=np.concatenate(positions).astype(float)
_,first,inv=np.unique(np.round(all_pos,7),axis=0,return_index=True,return_inverse=True)
q=all_pos[first].copy();original=q.copy()
tris=np.concatenate([inv[t+offsets[i]] for i,t in enumerate(triangles)])
sets=[np.unique(inv[t+offsets[i]]) for i,t in enumerate(triangles)]
seam=np.intersect1d(*sets);assert len(seam)>150,len(seam)
edges=np.unique(np.sort(np.concatenate([tris[:,[0,1]],tris[:,[1,2]],tris[:,[2,0]]]),axis=1),axis=0)
length=np.linalg.norm(q[edges[:,0]]-q[edges[:,1]],axis=1)
row=np.r_[edges[:,0],edges[:,1]];col=np.r_[edges[:,1],edges[:,0]]
graph=coo_matrix((np.r_[length,length],(row,col)),shape=(len(q),len(q))).tocsr()
distance=dijkstra(graph,indices=seam,min_only=True,limit=.04)
mask=1-smooth(.005,.035,distance)
# Lock the central face (including both eyes, nose, mouth and tongue).
x=q[:,0]/.45+.009;z=q[:,1]/.45
rad=np.sqrt((x/.270)**2+((z-.63)/.25)**2)
temple=smooth(.07,.12,np.abs(x))*smooth(.73,.785,z)*(1-smooth(.84,.89,z))*smooth(.17,.24,q[:,2]/.45)
mask=np.maximum(mask,.95*temple)
mask*=smooth(.68,.88,rad)
mask*=smooth(.40,.46,z)*(1-smooth(.88,.94,z))
# Use uniform logical adjacency so UV splits cannot bias the relaxation.
adj=coo_matrix((np.ones(len(row)),(row,col)),shape=(len(q),len(q))).tocsr()
avg=diags(1/np.maximum(np.asarray(adj.sum(1)).ravel(),1))@adj
for _ in range(45):
    q+=(avg@q-q)*(.45*mask[:,None])
    q+=(avg@q-q)*(-.46*mask[:,None])
# A gentle final relaxation removes residual saw-tooth positions.
for _ in range(12):q+=(avg@q-q)*(.32*mask[:,None])
# The surviving brow shelf lies inside the radial face lock. Relax only its
# depth above the eyes; retain every central frontal X/Y coordinate.
brow=smooth(.752,.785,z)*(1-smooth(.845,.89,z))*(1-smooth(.17,.23,np.abs(x)))*smooth(.19,.25,original[:,2]/.45)
for _ in range(100):q[:,2]+=(avg@q[:,2]-q[:,2])*(.42*brow)
delta=np.linalg.norm(q-original,axis=1)
norm=np.zeros_like(q);fn=np.cross(q[tris[:,1]]-q[tris[:,0]],q[tris[:,2]]-q[tris[:,0]])
for j in range(3):np.add.at(norm,tris[:,j],fn)
norm/=np.maximum(np.linalg.norm(norm,axis=1,keepdims=True),1e-12)
for i,pr in enumerate(primitives):
    logical=inv[offsets[i]:offsets[i+1]]
    accessor(doc,data,pr['attributes']['POSITION'])[:]=q[logical]
    n=accessor(doc,data,pr['attributes']['NORMAL']);affected=np.maximum(mask,brow)[logical]>0
    n[affected]=norm[logical[affected]]
    ac=doc['accessors'][pr['attributes']['POSITION']];ac['min']=q[logical].min(0).tolist();ac['max']=q[logical].max(0).tolist()
enc=json.dumps(doc,separators=(',',':')).encode();enc+=b' '*(-len(enc)%4)
raw=struct.pack('<III',0x46546c67,2,28+len(enc)+len(data))+struct.pack('<II',len(enc),0x4e4f534a)+enc+struct.pack('<II',len(data),0x004e4942)+data
(OUT/'frenchie.glb').write_bytes(raw)
report={'shared_seam_vertices':len(seam),'moved_logical_vertices':int((delta>1e-7).sum()),'max_displacement_m':float(delta.max()),'central_face_frontal_coordinate_displacement_m':float(np.linalg.norm(q[rad<=.68,:2]-original[rad<=.68,:2],axis=1).max()),'eyes_nose_mouth_max_displacement_m':float(delta[(rad<=.68)&(z<=.752)].max()),'source_sha256':hashlib.sha256(SOURCE.read_bytes()).hexdigest(),'result_sha256':hashlib.sha256(raw).hexdigest()}
(OUT/'geometry_verification.json').write_text(json.dumps(report,indent=2));print(json.dumps(report,indent=2))
