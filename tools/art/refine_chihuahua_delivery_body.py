"""WIP continuation: run after build_chihuahua_delivery_body.py, before rig stage."""
import bpy,bmesh,math
from mathutils import Vector
from pathlib import Path
OUT=Path(r'C:/Users/b/Documents/good-human/build/dog_delivery')
body=bpy.data.objects['ChihuahuaBodyTopology'];head=bpy.data.objects['ChihuahuaHead']
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'before_neck_bridge.blend'))
bm=bmesh.new();bm.from_mesh(body.data)
bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=.00001)
bound=[e for e in bm.edges if e.is_boundary];adj={}
for e in bound:
 for v in e.verts:adj.setdefault(v,[]).append(e.other_vert(v))
start=next(iter(adj));loop=[start];prev=None;cur=start
while True:
 nxt=next(v for v in adj[cur] if v is not prev)
 if nxt is start:break
 loop.append(nxt);prev,cur=cur,nxt
assert len(loop)==len(bound)
old=loop
for frac in [.5,1.0]:
 ring=[]
 for v in loop:
  a=math.atan2(v.co.x/.043,(v.co.z-.16)/.032)
  target=Vector((.034*math.sin(a),-.058+.026*math.cos(a),.18))
  ring.append(bm.verts.new(v.co.lerp(target,frac)))
 for i in range(len(loop)):
  j=(i+1)%len(loop);bm.faces.new((old[i],old[j],ring[j],ring[i]))
 old=ring
bm.faces.new(tuple(reversed(old)));bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(body.data);bm.free()
for p in body.data.polygons:p.use_smooth=True
bm=bmesh.new();bm.from_mesh(head.data)
bmesh.ops.delete(bm,geom=[v for v in bm.verts if v.co.y>-.01 and v.co.z<.196],context='VERTS');bm.to_mesh(head.data);bm.free()
body.modifiers['OrganicSurface'].levels=1;body.modifiers['OrganicSurface'].render_levels=1
bpy.context.view_layer.objects.active=body
mod=body.modifiers.new('BodySurfaceRelax','SMOOTH');mod.factor=.45;mod.iterations=4
bpy.ops.object.modifier_move_up(modifier=mod.name)
dec=head.modifiers.new('HeadBudget','DECIMATE');dec.ratio=.48;dec.use_collapse_triangulate=True
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'chihuahua_body_structure_04.blend'))
print('STRUCTURE_REFINEMENT_WIP_READY')
