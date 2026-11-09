"""Round lower ear lobes with bounded skinned union volumes."""
import bpy,bmesh,json
from mathutils import Vector
from mathutils.kdtree import KDTree
from pathlib import Path
OUT=Path('C:/Users/b/Documents/good-human/build/poodle_refine_r40')
obj=bpy.data.objects['DogBody'];donor=bpy.data.objects['R40_SurfaceSource']
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'poodle_r40_05_before_lobes.blend'))
kd=KDTree(len(donor.data.vertices))
for v in donor.data.vertices:kd.insert(v.co,v.index)
kd.balance()
for sign in [-1,1]:
    center=Vector((sign*.112,-.096 if sign<0 else -.069,.333))
    radius=Vector((.039,.040,.071))
    bpy.ops.mesh.primitive_uv_sphere_add(segments=24,ring_count=16,location=(0,0,0));ear=bpy.context.object;ear.name='R40_RoundLobe'
    for v in ear.data.vertices:v.co=center+Vector((v.co.x*radius.x,v.co.y*radius.y,v.co.z*radius.z))
    for g in obj.vertex_groups:ear.vertex_groups.new(name=g.name)
    for v in ear.data.vertices:
        ws={};near=kd.find_n(v.co,4)
        for _,idx,dist in near:
            factor=1/max(dist,.001)**2
            for g in donor.data.vertices[idx].groups:ws[g.group]=ws.get(g.group,0)+g.weight*factor
        total=sum(ws.values())
        for i,w in ws.items():ear.vertex_groups[i].add([v.index],w/total,'REPLACE')
    ear.data.materials.append(obj.data.materials[0]);bpy.context.view_layer.objects.active=obj
    mod=obj.modifiers.new('R40_RoundUnion','BOOLEAN');mod.operation='UNION';mod.solver='EXACT';mod.object=ear
    bpy.ops.object.modifier_apply(modifier=mod.name);bpy.data.objects.remove(ear,do_unlink=True)
# Round only the narrow transition into the old ear skirt.
bm=bmesh.new();bm.from_mesh(obj.data)
for i in range(10):
    updates={}
    for v in bm.verts:
        x,y,z=v.co
        if .087<abs(x)<.152 and .250<z<.305 and v.link_edges:
            weight=max(0,1-abs(z-.278)/.028)*max(0,1-abs(abs(x)-.119)/.033)
            avg=sum((e.other_vert(v).co for e in v.link_edges),Vector())/len(v.link_edges)
            updates[v]=v.co.lerp(avg,.28*weight)
    for v,co in updates.items():v.co=co
bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(obj.data);bm.free()
for p in obj.data.polygons:p.use_smooth=True
for e in obj.data.edges:e.use_edge_sharp=False
obj.data.normals_split_custom_set([(0,0,0)]*len(obj.data.loops));obj.data.update();obj.data.calc_loop_triangles()
print({'triangles_after_lobes':len(obj.data.loop_triangles)})
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'poodle_r40_06_lobes.blend'))
