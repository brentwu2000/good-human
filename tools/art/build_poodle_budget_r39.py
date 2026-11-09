"""CX-07 poodle budget candidate; run in the imported r39 Blender review scene.
Keeps original GLB rig/animation/material binary data. Never publishes runtime.
"""
import bpy, json, struct, hashlib
from pathlib import Path
import numpy as np
ROOT=Path('C:/Users/b/Documents/good-human')
OUT=ROOT/'build/poodle_budget_r39'
SOURCE=ROOT/'assets/characters/dog/models/breeds/poodle.glb'
TARGET=ROOT/'assets/art_previews/dogs/candidates/r39/poodle.glb'
obj=bpy.data.objects['DogBody']
assert sum(len(p.vertices)-2 for p in obj.data.polygons)==50736, 'Reload baseline before rebuilding'
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'poodle_02_before_reduce.blend'))
bpy.ops.object.select_all(action='DESELECT'); obj.select_set(True); bpy.context.view_layer.objects.active=obj
# Weld coincident physical vertices before collapse; retain per-corner UVs.
import bmesh
bm=bmesh.new();bm.from_mesh(obj.data)
bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=0.000001)
bm.verts.index_update()
ul=bm.loops.layers.uv.active
seamverts=set()
for e in bm.edges:
    if len(e.link_loops)!=2: continue
    a,c=e.link_loops
    if (a[ul].uv-c.link_loop_next[ul].uv).length>1e-5 or (a.link_loop_next[ul].uv-c[ul].uv).length>1e-5:
        seamverts.update(v.index for v in e.verts)
bm.to_mesh(obj.data);bm.free();obj.data.update()
# Protect face, ear borders and areas where two limb segments share skin weight.
vg=obj.vertex_groups.new(name='R39_KeepDetail')
names={g.index:g.name for g in obj.vertex_groups}
for v in obj.data.vertices:
    influences=[(names[g.group],g.weight) for g in v.groups if g.weight>0.02]
    joint=sum(w for n,w in influences if any(s in n for s in ('leg','shin','paw')))
    head=sum(w for n,w in influences if n=='head')
    blend=1-max((w for n,w in influences),default=1)
    protect=min(1.0, head*.85 + joint*blend*2)
    vg.add([v.index],1.0 if v.index in seamverts else protect*.01,'REPLACE')
mod=obj.modifiers.new('R39_budget','DECIMATE');mod.ratio=.29
mod.vertex_group=vg.name;mod.vertex_group_factor=1000.0;mod.use_collapse_triangulate=True
bpy.ops.object.modifier_apply(modifier=mod.name)
obj.vertex_groups.remove(obj.vertex_groups['R39_KeepDetail'])
obj.data.normals_split_custom_set([(0,0,0)]*len(obj.data.loops))
obj.data.calc_loop_triangles()
raw=SOURCE.read_bytes();jl=struct.unpack_from('<I',raw,12)[0]
d=json.loads(raw[20:20+jl]);b=bytearray(raw[28+jl:]);original=bytes(b)
joint_map={d['nodes'][n]['name']:i for i,n in enumerate(d['skins'][0]['joints'])}
def view(blob):
    b.extend(b'\0'*(-len(b)%4));i=len(d['bufferViews']);d['bufferViews'].append({'buffer':0,'byteOffset':len(b),'byteLength':len(blob)});b.extend(blob);return i
def acc(values,typ,dtype,component):
    a=np.asarray(values,dtype=dtype);i=len(d['accessors']);info={'bufferView':view(a.tobytes()),'componentType':component,'count':len(a),'type':typ}
    if typ=='VEC3': info.update(min=a.min(axis=0).tolist(),max=a.max(axis=0).tolist())
    d['accessors'].append(info);return i
primitives=[]
for material in sorted(set(p.material_index for p in obj.data.polygons)):
    pos=[];norm=[];uv=[];js=[];ws=[];indices=[];lookup={}
    for tri in obj.data.loop_triangles:
        if tri.material_index!=material: continue
        for li in tri.loops:
            loop=obj.data.loops[li];v=obj.data.vertices[loop.vertex_index]
            co=v.co;no=obj.data.corner_normals[li].vector;tex=obj.data.uv_layers.active.data[li].uv
            influences=sorted([(joint_map[obj.vertex_groups[g.group].name],g.weight) for g in v.groups if obj.vertex_groups[g.group].name in joint_map and g.weight>1e-8],key=lambda q:-q[1])[:8]
            total=sum(w for _,w in influences);assert total>0
            jj=tuple([j for j,w in influences]+[0]*(8-len(influences)));ww=tuple([w/total for j,w in influences]+[0]*(8-len(influences)))
            point=(co.x,co.z,-co.y);normal=(no.x,no.z,-no.y);t=(tex.x,1-tex.y)
            key=(point,normal,t,jj,ww)
            if key not in lookup:
                lookup[key]=len(pos);pos.append(point);norm.append(normal);uv.append(t);js.append(jj);ws.append(ww)
            indices.append(lookup[key])
    j=np.array(js);w=np.array(ws)
    attrs={'POSITION':acc(pos,'VEC3','<f4',5126),'NORMAL':acc(norm,'VEC3','<f4',5126),'TEXCOORD_0':acc(uv,'VEC2','<f4',5126)}
    for k in range(2):
        attrs['JOINTS_'+str(k)]=acc(j[:,k*4:k*4+4],'VEC4','<u2',5123)
        attrs['WEIGHTS_'+str(k)]=acc(w[:,k*4:k*4+4],'VEC4','<f4',5126)
    matname=obj.data.materials[material].name
    mi=next(i for i,m in enumerate(d['materials']) if m['name']==matname or matname.startswith(m['name']+'.'))
    primitives.append({'attributes':attrs,'indices':acc(indices,'SCALAR','<u4',5125),'material':mi})
d['meshes'][0]['primitives']=primitives
b.extend(b'\0'*(-len(b)%4));d['buffers'][0]['byteLength']=len(b)
assert b[:len(original)]==original
enc=json.dumps(d,separators=(',',':')).encode();enc+=b' '*(-len(enc)%4)
result=struct.pack('<III',0x46546c67,2,28+len(enc)+len(b))+struct.pack('<II',len(enc),0x4e4f534a)+enc+struct.pack('<II',len(b),0x004e4942)+b
TARGET.parent.mkdir(parents=True,exist_ok=True);TARGET.write_bytes(result)
report={'source_sha256':hashlib.sha256(raw).hexdigest(),'candidate_sha256':hashlib.sha256(result).hexdigest(),'triangles_before':50736,'triangles_after':len(obj.data.loop_triangles),'original_binary_prefix_retained':True,'bones':len(joint_map),'clips':[a['name'] for a in d['animations']],'method':'weighted collapse trial; face and mixed limb weights protected; not certified production retopology'}
(OUT/'build.json').write_text(json.dumps(report,indent=2))
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'poodle_03_candidate.blend'))
bpy.context.scene.render.filepath=str(OUT/'candidate.png');bpy.ops.render.render(write_still=True)
print(json.dumps(report))
