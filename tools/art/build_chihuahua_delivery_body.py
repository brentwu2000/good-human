"""Structural candidate only: adapt existing CC0 quadruped topology, retain r37 identity."""
import bpy,bmesh,sys,math
from mathutils import Vector
from pathlib import Path
ROOT=Path(r'C:/Users/b/Documents/good-human');OUT=ROOT/'build/dog_delivery'
# Load r37_inspection.blend in a separate bridge call before running.
old=bpy.data.objects['DogBody']; oldarm=old.parent
# Duplicate head before editing; leave published and source assets intact.
head=old.copy();head.data=old.data.copy();bpy.context.collection.objects.link(head);head.name='ChihuahuaHead'
bm=bmesh.new();bm.from_mesh(head.data)
bmesh.ops.delete(bm,geom=[v for v in bm.verts if v.co.z<.163],context='VERTS');bm.to_mesh(head.data);bm.free()
old.hide_render=True;old.hide_set(True)
before=set(bpy.data.objects);bpy.ops.import_scene.gltf(filepath=str(ROOT/'assets/_source/mesh2motion/fox-animations.glb'))
new=set(bpy.data.objects)-before
arm=next(o for o in new if o.type=='ARMATURE');body=next(o for o in new if o.type=='MESH' and len(o.data.vertices)>100)
for o in new:
 if o.type=='MESH' and o is not body:o.hide_render=True;o.hide_set(True)
arm.animation_data_clear()
for pb in arm.pose.bones:pb.matrix_basis.identity()
# Use clean shoulder/hip loops; remove fox face without replacing Chihuahua identity.
bm=bmesh.new();bm.from_mesh(body.data)
bmesh.ops.delete(bm,geom=[v for v in bm.verts if v.co.y<-.72 and v.co.z>1.05],context='VERTS')
bm.to_mesh(body.data);bm.free()
def shape(p):
 x,y,z=p
 # Narrow the fox tail and turn its rest centerline up into a Chihuahua sickle.
 if y>.84:
  t=min(1,(y-.84)/1.32);angle=t*1.8
  x*=.42;z=1.08+(z-1.08)*.42+.68*(1-math.cos(angle));y=.84+.68*math.sin(angle)
 return Vector((x*.18,y*.14+.025,z*.13))
for v in body.data.vertices:v.co=shape(v.co)
bpy.context.view_layer.objects.active=arm;arm.select_set(True)
bpy.ops.object.mode_set(mode='EDIT')
for bone in arm.data.edit_bones:
 bone.head=shape(bone.head);bone.tail=shape(bone.tail)
bpy.ops.object.mode_set(mode='OBJECT')
body.name='ChihuahuaBodyTopology'
bpy.context.view_layer.objects.active=body;bpy.ops.object.select_all(action='DESELECT');body.select_set(True)
mod=body.modifiers.new('OrganicSurface','SUBSURF');mod.levels=2;mod.render_levels=2
# Keep editable low-resolution control topology, evaluate subdivision at review.
for poly in body.data.polygons:poly.use_smooth=True
clay=bpy.data.materials.get('DeliveryClay') or bpy.data.materials.new('DeliveryClay')
clay.use_nodes=True;clay.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value=(.55,.55,.55,1)
clay.node_tree.nodes['Principled BSDF'].inputs['Roughness'].default_value=.7
scene=bpy.context.scene;scene.view_layers[0].material_override=clay
cam=scene.camera;cam.data.ortho_scale=.44
for name,loc in [('side',(1,0,.20)),('front',(0,-1,.20)),('threequarter',(.75,-.75,.35))]:
 cam.location=loc;cam.rotation_euler=(Vector((0,.01,.175))-cam.location).to_track_quat('-Z','Y').to_euler()
 scene.render.filepath=str(OUT/('body_candidate_'+name+'.png'));bpy.ops.render.render(write_still=True)
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'chihuahua_body_structure_01.blend'))
print('STRUCTURE_CANDIDATE',len(body.data.vertices),len(head.data.vertices))
