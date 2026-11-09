"""Package rebaked r39 geometry without changing runtime bones or animation bytes."""
import bpy,json,struct,hashlib
from pathlib import Path
import numpy as np
ROOT=Path('C:/Users/b/Documents/good-human');OUT=ROOT/'build/poodle_budget_r39';SOURCE=ROOT/'assets/characters/dog/models/breeds/poodle.glb';TARGET=ROOT/'assets/art_previews/dogs/candidates/r39/poodle.glb';obj=bpy.data.objects['DogBody']
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
ii=len(d['images']);d['images'].append({'bufferView':view((OUT/'albedo.png').read_bytes()),'mimeType':'image/png','name':'Poodle_R39_Albedo'})
ti=len(d['textures']);d['textures'].append({'source':ii})
d['materials'].append({'name':'Poodle_R39_Baked','pbrMetallicRoughness':{'baseColorTexture':{'index':ti},'metallicFactor':0,'roughnessFactor':.85}})
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
report={'source_sha256':hashlib.sha256(raw).hexdigest(),'candidate_sha256':hashlib.sha256(result).hexdigest(),'triangles_before':50736,'triangles_after':len(obj.data.loop_triangles),'original_binary_prefix_retained':True,'bones':len(joint_map),'clips':[a['name'] for a in d['animations']],'method':'UV-seam weighted collapse with welded topology and source appearance rebake; not certified production retopology'}
(OUT/'build.json').write_text(json.dumps(report,indent=2))
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'poodle_06_packaged.blend'))
bpy.context.scene.render.filepath=str(OUT/'candidate.png');bpy.ops.render.render(write_still=True)
print(json.dumps(report))
