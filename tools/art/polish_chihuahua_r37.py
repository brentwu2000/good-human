"""Bounded cheek transition refinement; native Blender smoothing, immutable rig/UV."""
import bpy, sys, json, struct, hashlib
from pathlib import Path
import numpy as np
ROOT=Path(r'C:\Users\b\Documents\good-human')
sys.path.insert(0,str(ROOT/'tools/art'))
from reshape_pomeranian_r9 import unpack,accessor,smooth
OUT=ROOT/'build/dog_polish_r37';OUT.mkdir(parents=True,exist_ok=True)
SOURCE=ROOT/'assets/art_previews/dogs/candidates/r36/chihuahua.glb'
DEST=ROOT/'assets/art_previews/dogs/candidates/r37/chihuahua.glb'
DEST.parent.mkdir(parents=True,exist_ok=True)
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'chihuahua_01_before_refine.blend'))
d,b=unpack(SOURCE);before=bytes(b)
pr=max((p for m in d['meshes'] for p in m['primitives']),key=lambda p:d['accessors'][p['attributes']['POSITION']]['count'])
pos=accessor(d,b,pr['attributes']['POSITION']);old=pos.copy()
tri=accessor(d,b,pr['indices']).reshape(-1,3)
points=old[:,[0,2,1]].astype(float);points[:,1]*=-1
_,first,inv=np.unique(np.round(points,7),axis=0,return_index=True,return_inverse=True)
q=points[first].copy();faces=inv[tri];x,y,z=q.T
ear=smooth(.329,.340,z)
chin=smooth(.153,.168,z)*(1-smooth(.192,.205,z))*(1-smooth(-.035,-.010,y))
mask=ear
eye=np.zeros(len(q))
for side in [-1,1]:
    ellipse=np.sqrt(((x-side*.035)/.018)**2+((z-.244)/.019)**2)
    eye=np.maximum(eye,(1-smooth(.85,1.35,ellipse))*(1-smooth(-.095,-.073,y)))
nose=(1-smooth(.018,.030,np.abs(x)))*smooth(.199,.205,z)*(1-smooth(.226,.236,z))*(1-smooth(-.134,-.115,y))
mouth=(1-smooth(.024,.036,np.abs(x)))*(1-smooth(.202,.218,z))*(1-smooth(-.119,-.098,y))
mask*=1-np.maximum.reduce([eye,nose,mouth])
mesh=bpy.data.meshes.new('R37_LogicalSurface');mesh.from_pydata(q.tolist(),[],faces.tolist());mesh.update()
work=bpy.data.objects.new('R37_SmoothingWork',mesh);bpy.context.collection.objects.link(work)
group=work.vertex_groups.new(name='CheekTransitions')
for i in np.flatnonzero(mask>0):group.add([int(i)],float(mask[i]),'REPLACE')
modifier=work.modifiers.new('BoundedCheekRelax','SMOOTH');modifier.factor=.3;modifier.iterations=3;modifier.vertex_group=group.name
bpy.context.view_layer.update()
evaluated=work.evaluated_get(bpy.context.evaluated_depsgraph_get())
relaxed=np.array([v.co[:] for v in evaluated.data.vertices])
delta=relaxed-q
length=np.linalg.norm(delta,axis=1)
delta*=np.minimum(1,.0015/np.maximum(length,1e-12))[:,None]
result=q+delta
result[mask==0]=q[mask==0]
cross0=np.cross(q[faces[:,1]]-q[faces[:,0]],q[faces[:,2]]-q[faces[:,0]])
for _ in range(10):
    cross=np.cross(result[faces[:,1]]-result[faces[:,0]],result[faces[:,2]]-result[faces[:,0]])
    flips=(cross*cross0).sum(1)<-1e-15
    if not flips.any():break
    idx=np.unique(faces[flips]);result[idx]=q[idx]
assert not flips.any(), 'Unexpected face inversion'
bpy.data.objects.remove(work,do_unlink=True)
new=result[inv];new[:,1]*=-1;new=new[:,[0,2,1]]
moved=np.linalg.norm(new-old,axis=1)>1e-7
pos[:]=new
normal=accessor(d,b,pr['attributes']['NORMAL'])
sums=np.zeros((len(q),3));cross=np.cross(new[tri[:,1]]-new[tri[:,0]],new[tri[:,2]]-new[tri[:,0]])
for j in range(3):np.add.at(sums,inv[tri[:,j]],cross)
sums/=np.maximum(np.linalg.norm(sums,axis=1,keepdims=True),1e-12)
affected=np.zeros(len(pos),bool);affected[np.unique(tri[np.any(moved[tri],axis=1)])]=True
normal[affected]=sums[inv[affected]]
allowed=np.zeros(len(b),bool)
for key in ['POSITION','NORMAL']:
    ac=d['accessors'][pr['attributes'][key]];view=d['bufferViews'][ac['bufferView']]
    vals=accessor(d,b,pr['attributes'][key])
    if 'min' in ac:ac['min']=vals.min(0).tolist()
    if 'max' in ac:ac['max']=vals.max(0).tolist()
    start=view.get('byteOffset',0)+ac.get('byteOffset',0)
    for i in range(ac['count']):allowed[start+i*view.get('byteStride',12):start+i*view.get('byteStride',12)+12]=True
assert np.array_equal(np.frombuffer(before,dtype=np.uint8)[~allowed],np.frombuffer(b,dtype=np.uint8)[~allowed])
enc=json.dumps(d,separators=(',',':')).encode();enc+=b' '*(-len(enc)%4)
raw=struct.pack('<III',0x46546c67,2,28+len(enc)+len(b))+struct.pack('<II',len(enc),0x4e4f534a)+enc+struct.pack('<II',len(b),0x004e4942)+b
DEST.write_bytes(raw)
(OUT/'chihuahua_surface.glb').write_bytes(raw)
report={'source_sha256':hashlib.sha256(SOURCE.read_bytes()).hexdigest(),'candidate_sha256':hashlib.sha256(raw).hexdigest(),'moved_vertices':int(moved.sum()),'max_displacement_m':float(np.linalg.norm(new-old,axis=1).max()),'inverted_faces':int(flips.sum()),'unchanged_binary_except_position_normal':True,'triangle_count':len(tri),'core_eye_nose_mouth_displacement_m':float(np.linalg.norm(result-q,axis=1)[np.maximum.reduce([eye,nose,mouth])>.999].max())}
(OUT/'geometry_verification.json').write_text(json.dumps(report,indent=2),encoding='utf8')
for ob in list(bpy.data.objects):bpy.data.objects.remove(ob,do_unlink=True)
bpy.ops.import_scene.gltf(filepath=str(DEST))
for ob in bpy.context.scene.objects:
    if ob.animation_data:ob.animation_data_clear()
    if ob.type=='ARMATURE':
        for pb in ob.pose.bones:pb.matrix_basis.identity()
    if ob.name.startswith('Icosphere'):ob.hide_set(True)
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'chihuahua_02_surface.blend'))
print('R37_SURFACE_READY',json.dumps(report))
