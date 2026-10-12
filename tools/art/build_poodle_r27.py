"""Blender ear-volume study over r26; untouched source retained."""
import bpy, math, json, os
from pathlib import Path
from mathutils import Vector
from mathutils.kdtree import KDTree

ROOT=Path(r'C:\Users\b\Documents\good-human')
OUT=ROOT/'build/poodle_ears_r27'
OUT.mkdir(parents=True,exist_ok=True)
dog=bpy.data.objects['DogBody']
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(os.environ['TEMP'],'poodle_r27_01_pre_ears.blend'))
for ob in list(bpy.data.objects):
    if ob.name.startswith('EarFill_R27'):
        bpy.data.objects.remove(ob,do_unlink=True)
ref=bpy.data.images.load(r'C:\Users\b\Documents\good_human_stylized_factory\references\dogs\poodle_front.png',check_existing=True)
mat=bpy.data.materials.get('EarFill_R27') or bpy.data.materials.new('EarFill_R27')
mat.use_nodes=True
nt=mat.node_tree; nt.nodes.clear()
out=nt.nodes.new('ShaderNodeOutputMaterial'); bs=nt.nodes.new('ShaderNodeBsdfPrincipled')
bs.inputs['Roughness'].default_value=.85
tex=nt.nodes.new('ShaderNodeTexImage');tex.image=ref
nt.links.new(tex.outputs['Color'],bs.inputs['Base Color']);nt.links.new(bs.outputs[0],out.inputs[0])
kd=KDTree(len(dog.data.vertices))
for v in dog.data.vertices:kd.insert(v.co,v.index)
kd.balance()
records=[]
for side in [-1,1]:
    center=Vector((side*(.102 if side<0 else .108),-.110 if side<0 else -.077,.338))
    radius=Vector((.036,.023,.073))
    bpy.ops.mesh.primitive_uv_sphere_add(segments=32,ring_count=20,location=(0,0,0))
    ob=bpy.context.object;ob.name='EarFill_R27_'+str(side)
    for v in ob.data.vertices:
        q=v.co.copy();v.co=center+Vector((q.x*radius.x,q.y*radius.y,q.z*radius.z))
    ob.data.materials.clear();ob.data.materials.append(mat)
    for g in dog.vertex_groups:ob.vertex_groups.new(name=g.name)
    for v in ob.data.vertices:
        nearest=kd.find_n(v.co,4)
        weights={};total=0
        for _,idx,dist in nearest:
            factor=1/max(dist,.001)**2;total+=factor
            for g in dog.data.vertices[idx].groups:weights[g.group]=weights.get(g.group,0)+factor*g.weight
        for idx,w in weights.items():
            if w/total>1e-6:ob.vertex_groups[idx].add([v.index],w/total,'REPLACE')
    for p in ob.data.polygons:p.use_smooth=True
    uv=ob.data.uv_layers.active
    for loop in ob.data.loops:
        x,y,z=ob.data.vertices[loop.vertex_index].co
        # Reuse fur from the matching ear on the owner's reference.
        px=(235 if side<0 else 535)+(x-center.x)*650
        py=305-(z-.340)*600
        uv.data[loop.index].uv=(px/768,1-py/768)
    mod=ob.modifiers.new('Armature','ARMATURE');mod.object=dog.parent
    ob.parent=dog.parent
    ob.data.calc_loop_triangles()
    records.append({'name':ob.name,'positions':[list(v.co) for v in ob.data.vertices],
        'normals':[list(v.normal) for v in ob.data.vertices],
        'uv':[[0,0] for v in ob.data.vertices],
        'weights':[[[g.group,g.weight] for g in v.groups] for v in ob.data.vertices],
        'triangles':[list(t.vertices) for t in ob.data.loop_triangles]})
    for loop in ob.data.loops:records[-1]['uv'][loop.vertex_index]=list(uv.data[loop.index].uv)
(OUT/'ear_meshes.json').write_text(json.dumps(records))
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(os.environ['TEMP'],'poodle_r27_02_ear_volume.blend'))
print('R27_EARS_READY',[(r['name'],len(r['positions']),len(r['triangles'])) for r in records])
