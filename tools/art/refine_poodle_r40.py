"""R40 local ear union and surface cleanup over the saved r39 checkpoint."""
import bpy,bmesh,json,math
from pathlib import Path
from mathutils import Vector
ROOT=Path('C:/Users/b/Documents/good-human');OUT=ROOT/'build/poodle_refine_r40';OUT.mkdir(parents=True,exist_ok=True)
obj=bpy.data.objects['DogBody']
assert len(obj.data.vertices)==7358,'Restore r40_00_before checkpoint first'
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'poodle_r40_01_before_union.blend'))
# Immutable low-mesh surface for color/weight comparison and rebake.
source=obj.copy();source.data=obj.data.copy();source.name='R40_SurfaceSource';bpy.context.collection.objects.link(source);source.hide_render=True;source.hide_set(True)
bm=bmesh.new();bm.from_mesh(obj.data);bm.verts.ensure_lookup_table();remaining=set(bm.verts);components=[]
while remaining:
    v=remaining.pop();comp={v};stack=[v]
    while stack:
        for e in stack.pop().link_edges:
            for q in e.verts:
                if q in remaining:remaining.remove(q);comp.add(q);stack.append(q)
    components.append({v.index for v in comp})
bm.free();components.sort(key=len,reverse=True)
assert len(components)==3
original=obj.data.copy();ears=[]
for i,ids in enumerate(components):
    m=original.copy();bm=bmesh.new();bm.from_mesh(m);bm.verts.ensure_lookup_table()
    bmesh.ops.delete(bm,geom=[v for v in bm.verts if v.index not in ids],context='VERTS');bm.to_mesh(m);bm.free()
    if i==0:obj.data=m
    else:
        ear=obj.copy();ear.data=m;ear.name='R40_EarUnion_'+str(i);bpy.context.collection.objects.link(ear);ears.append(ear)
bpy.ops.object.select_all(action='DESELECT');obj.select_set(True);bpy.context.view_layer.objects.active=obj
for ear in ears:
    mod=obj.modifiers.new('R40_Union','BOOLEAN');mod.operation='UNION';mod.solver='EXACT';mod.object=ear
    bpy.ops.object.modifier_apply(modifier=mod.name);bpy.data.objects.remove(ear,do_unlink=True)
# Remove sliver debris; use only tiny tolerance compared with a 0.45m dog.
bm=bmesh.new();bm.from_mesh(obj.data);bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=1e-7)
bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(obj.data);bm.free()
# Ear blends: smooth within the ear volume, fade at cheek and neck. Forehead
# excludes the eyes, nose and mouth; only the brow cap is relaxed.
def smoothstep(a,b,x):
    t=max(0,min(1,(x-a)/(b-a)));return t*t*(3-2*t)
adj=[set() for v in obj.data.vertices]
for e in obj.data.edges:
    a,b=e.vertices;adj[a].add(b);adj[b].add(a)
original_coords=[v.co.copy() for v in obj.data.vertices]
for iteration in range(20):
    coords=[v.co.copy() for v in obj.data.vertices]
    for v in obj.data.vertices:
        co=coords[v.index];x,y,z=co;ear=smoothstep(.080,.110,abs(x))*smoothstep(.245,.285,z)*(1-smoothstep(.415,.450,z))
        brow=smoothstep(.355,.385,z)*(1-smoothstep(.420,.450,z))*(1-smoothstep(.075,.115,abs(x)))*(1-smoothstep(-.075,-.015,y))
        if not adj[v.index] or max(ear,brow)==0:continue
        avg=sum((coords[j] for j in adj[v.index]),Vector())/len(adj[v.index]);delta=avg-co
        move=delta*(.28*ear+.30*brow)
        # Cap cumulative displacement; core facial landmarks are outside the mask.
        target=co+move;offset=target-original_coords[v.index]
        limit=.006 if ear>.1 else .003
        if offset.length>limit:offset.normalize();target=original_coords[v.index]+offset*limit
        v.co=target
for p in obj.data.polygons:p.use_smooth=True
for e in obj.data.edges:e.use_edge_sharp=False
obj.data.normals_split_custom_set([(0,0,0)]*len(obj.data.loops));obj.data.update();obj.data.calc_loop_triangles()
bm=bmesh.new();bm.from_mesh(obj.data)
report={'vertices':len(obj.data.vertices),'triangles':len(obj.data.loop_triangles),'nonmanifold_edges':sum(not e.is_manifold for e in bm.edges),'max_smoothing_displacement_m':max((v.co-original_coords[v.index]).length for v in obj.data.vertices)};bm.free()
(OUT/'geometry.json').write_text(json.dumps(report,indent=2));print(report)
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'poodle_r40_02_union.blend'))
