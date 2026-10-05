"""Shape-only GLB revision: stable UVs, topology, weights, bones and clips.

All displacements are evaluated on original normalized Blender-space positions.
UV seam vertices share a logical adjacency graph without welding exported data.
"""
import json, struct, pathlib, hashlib
import numpy as np
ROOT=pathlib.Path(__file__).resolve().parents[2]
OUT=ROOT/'build/dogs_face_r9'
SOURCE=ROOT/'assets/art_previews/dogs/candidates/r8/pomeranian.glb'

def smooth(a,b,x):
    t=np.clip((x-a)/(b-a),0,1);return t*t*(3-2*t)

def unpack(path):
    raw=path.read_bytes(); n=struct.unpack_from('<I',raw,12)[0]
    return json.loads(raw[20:20+n]),bytearray(raw[28+n:])

def accessor(doc,data,index):
    a=doc['accessors'][index];v=doc['bufferViews'][a['bufferView']]
    dt={5126:'<f4',5125:'<u4',5123:'<u2',5121:'u1'}[a['componentType']]
    width={'SCALAR':1,'VEC2':2,'VEC3':3,'VEC4':4,'MAT4':16}[a['type']]
    offset=v.get('byteOffset',0)+a.get('byteOffset',0)
    return np.ndarray((a['count'],width),dtype=dt,buffer=data,offset=offset,
                      strides=(v.get('byteStride',np.dtype(dt).itemsize*width),np.dtype(dt).itemsize))

def deform(p,tri):
    original=p.copy();x,y,z=original.T
    eye=np.zeros(len(p))
    for side in [-1,1]:
        d=np.sqrt(((x-side*.116)/.051)**2+((z-.703)/.052)**2)
        eye=np.maximum(eye,1-smooth(.90,1.28,d))
    face=(1-smooth(-.32,-.26,y))
    # Lay the excessive brow shelf into a gently inclined nasal bridge.
    bridge=(1-smooth(.080,.190,np.abs(x)))*smooth(.635,.685,z)*(1-smooth(.920,.990,z))*face*(1-eye)
    target=-.422+(z-.675)*.42+x*x*1.2
    p[:,1]+=bridge*np.maximum(0,target-y)
    # Raise and shorten the hanging nose, blending into its muzzle attachment.
    nose=(1-smooth(.058,.100,np.abs(x)))*smooth(.50,.545,z)*(1-smooth(.655,.690,z))*(1-smooth(-.440,-.390,y))*(1-eye)
    p[:,1]+=nose*.030
    p[:,2]+=nose*(.018+(.620-z)*.24)
    p[:,0]-=nose*x*.04
    # Relax local ridges through a shared-position graph; preserve eye surfaces.
    _,first,inv=np.unique(np.round(original,6),axis=0,return_index=True,return_inverse=True)
    q=p[first].copy();adj=[set() for _ in q]
    for t in inv[tri]:
        for a,b in [(t[0],t[1]),(t[1],t[2]),(t[2],t[0])]:
            if a!=b:adj[a].add(b);adj[b].add(a)
    weight=np.maximum(bridge*.80,nose*.10)[first]
    for _ in range(28):
        out=q.copy()
        for i in np.flatnonzero(weight>.001):
            if adj[i]:out[i]+=weight[i]*.35*(q[list(adj[i])].mean(0)-q[i])
        q=out
    result=q[inv];result[eye>.999]=original[eye>.999]
    return result,eye

def main():
    OUT.mkdir(parents=True,exist_ok=True)
    doc,data=unpack(SOURCE);before=bytes(data)
    prim=max((p for m in doc['meshes'] for p in m['primitives']),key=lambda p:doc['accessors'][p['attributes']['POSITION']]['count'])
    pos=accessor(doc,data,prim['attributes']['POSITION']); normal=accessor(doc,data,prim['attributes']['NORMAL'])
    original=pos.copy();oldn=normal.copy();tri=accessor(doc,data,prim['indices']).reshape(-1,3)
    p=original[:,[0,2,1]].astype(float);p[:,1]*=-1
    H=np.ptp(p[:,2]);p/=H
    shaped,eye=deform(p.copy(),tri)
    new=shaped*H;new[:,1]*=-1;new=new[:,[0,2,1]]
    moved=np.linalg.norm(new-original,axis=1)>1e-7
    pos[:]=new
    # Recalculate only affected smooth normals, merging positions logically.
    _,inv=np.unique(np.round(new,7),axis=0,return_inverse=True)
    sums=np.zeros((inv.max()+1,3));cross=np.cross(new[tri[:,1]]-new[tri[:,0]],new[tri[:,2]]-new[tri[:,0]])
    for j in range(3):np.add.at(sums,inv[tri[:,j]],cross)
    sums/=np.maximum(np.linalg.norm(sums,axis=1,keepdims=True),1e-12)
    affected=np.zeros(len(pos),bool);affected[np.unique(tri[np.any(moved[tri],axis=1)])]=True
    normal[affected]=sums[inv[affected]]
    for key in ['POSITION','NORMAL']:
        a=doc['accessors'][prim['attributes'][key]]
        v=pos if key=='POSITION' else normal
        if 'min' in a:a['min']=v.min(0).tolist()
        if 'max' in a:a['max']=v.max(0).tolist()
    # Preserve every byte outside the two authorized attribute ranges.
    allowed=np.zeros(len(data),bool)
    for key in ['POSITION','NORMAL']:
        a=doc['accessors'][prim['attributes'][key]];v=doc['bufferViews'][a['bufferView']]
        start=v.get('byteOffset',0)+a.get('byteOffset',0);stride=v.get('byteStride',12)
        for i in range(a['count']):allowed[start+i*stride:start+i*stride+12]=True
    assert np.array_equal(np.frombuffer(before,dtype=np.uint8)[~allowed],np.frombuffer(data,dtype=np.uint8)[~allowed])
    enc=json.dumps(doc,separators=(',',':')).encode();enc+=b' '*(-len(enc)%4)
    raw=struct.pack('<III',0x46546c67,2,28+len(enc)+len(data))+struct.pack('<II',len(enc),0x4e4f534a)+enc+struct.pack('<II',len(data),0x004e4942)+data
    target=OUT/'pomeranian.glb';target.write_bytes(raw)
    np.savez_compressed(OUT/'shape_delta.npz',before=p,after=shaped,moved=moved,tri=tri)
    changed_faces=np.any(moved[tri],axis=1)
    cross0=np.cross(original[tri[:,1]]-original[tri[:,0]],original[tri[:,2]]-original[tri[:,0]])
    flips=(cross0*cross).sum(1)<0
    report={'source_sha256':hashlib.sha256(SOURCE.read_bytes()).hexdigest(),'result_sha256':hashlib.sha256(raw).hexdigest(),
      'vertices':len(pos),'triangles':len(tri),'moved_vertices':int(moved.sum()),'max_displacement_m':float(np.linalg.norm(new-original,axis=1).max()),
      'eye_core_moved_vertices':int((moved&(eye>.999)).sum()),'changed_face_normal_over_90_degrees':int((flips&changed_faces).sum()),
      'unchanged_other_binary_data':True,'bones':len(doc['skins'][0]['joints']),'clips':[a['name'] for a in doc['animations']]}
    (OUT/'verification.json').write_text(json.dumps(report,indent=2));print(json.dumps(report,indent=2))

if __name__=='__main__':main()
