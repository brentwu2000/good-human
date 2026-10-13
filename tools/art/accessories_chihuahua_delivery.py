import bpy,math
from pathlib import Path
from mathutils import Vector
OUT=Path(r'C:/Users/b/Documents/good-human/build/dog_delivery')
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'before_paw_details.blend'))
body=bpy.data.objects['ChihuahuaBodyTopology'];arm=body.parent
cream=bpy.data.materials.new('PawCream');cream.use_nodes=True;bs=cream.node_tree.nodes['Principled BSDF'];bs.inputs['Base Color'].default_value=(.74,.66,.53,1);bs.inputs['Roughness'].default_value=.85
gold=bpy.data.materials.new('TagBrass');gold.use_nodes=True;bs=gold.node_tree.nodes['Principled BSDF'];bs.inputs['Base Color'].default_value=(.65,.36,.09,1);bs.inputs['Metallic'].default_value=.72;bs.inputs['Roughness'].default_value=.38
def skin(ob,bone):
 ob.parent=arm;g=ob.vertex_groups.new(name=bone);g.add(list(range(len(ob.data.vertices))),1,'REPLACE');ob.modifiers.new('Rig','ARMATURE').object=arm
 for p in ob.data.polygons:p.use_smooth=True
for side,sign in [('L',1),('R',-1)]:
 for front in [True,False]:
  points=[v.co for v in body.data.vertices if v.co.z<.022 and v.co.x*sign>0 and (v.co.y<.02)==front]
  cx=sum(p.x for p in points)/len(points);cy=min(p.y for p in points)
  for toe in [-1,0,1]:
   bpy.ops.mesh.primitive_uv_sphere_add(segments=12,ring_count=6,location=(cx+toe*.0048,cy-.001,.007))
   ob=bpy.context.object;ob.name=('Front' if front else 'Rear')+'Toe_'+side+'_'+str(toe);ob.scale=(.0034,.007,.0055)
   bpy.ops.object.transform_apply(location=True,rotation=True,scale=True);ob.data.materials.append(cream)
   skin(ob,('Front_Leg_Foot_' if front else 'Back_Leg_Foot_1_')+side)
# A small physically thick identity tag, positioned under the strap.
bpy.ops.mesh.primitive_cylinder_add(vertices=24,radius=.009,depth=.0015,location=(0,-.095,.156),rotation=(math.pi/2,0,0))
tag=bpy.context.object;tag.name='ChihuahuaTag';bpy.ops.object.transform_apply(location=True,rotation=True,scale=True);tag.data.materials.append(gold);skin(tag,'neck')
bevel=tag.modifiers.new('TagRoundEdge','BEVEL');bevel.width=.0006;bevel.segments=2
# Neutral review floor, not part of export selection.
bpy.ops.mesh.primitive_plane_add(size=200,location=(0,0,-.0005));floor=bpy.context.object;floor.name='ReviewFloor'
mat=bpy.data.materials.new('ReviewFloorMat');mat.use_nodes=True;bs=mat.node_tree.nodes['Principled BSDF'];bs.inputs['Base Color'].default_value=(.18,.17,.15,1);bs.inputs['Roughness'].default_value=.9;floor.data.materials.append(mat)
scene=bpy.context.scene;cam=scene.camera;cam.data.ortho_scale=.5
for name,loc in [('front',(0,-1,.2)),('side',(1,0,.2)),('threequarter',(.75,-.75,.35))]:
 cam.location=loc;cam.rotation_euler=(Vector((0,.025,.17))-cam.location).to_track_quat('-Z','Y').to_euler();scene.render.filepath=str(OUT/('detail_review_'+name+'.png'));bpy.ops.render.render(write_still=True)
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'chihuahua_detail_02.blend'))
print('PAWS_TAG_REVIEW_READY')
