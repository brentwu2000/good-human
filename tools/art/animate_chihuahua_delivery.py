import bpy,sys,math
import numpy as np
from pathlib import Path
from mathutils import Vector
ROOT=Path(r'C:/Users/b/Documents/good-human');OUT=ROOT/'build/dog_delivery'
sys.path.insert(0,str(ROOT/'tools/art'))
from retarget_mesh2motion import DOG_MAP
source=bpy.data.objects['MotionSource'];target=bpy.data.objects['Shiba_Rig_Delivery']
meshes=[bpy.data.objects[n] for n in ['ChihuahuaBodyTopology','ChihuahuaHead','ChihuahuaCollar']]
mapping=dict(DOG_MAP);mapping.update({'root':'ROOT','Chin':'jaw','Chin_Tip':'jaw_tip'})
for b in source.data.bones:mapping.setdefault(b.name,b.name)
inverse={v:k for k,v in mapping.items() if v in target.data.bones}
# These are the newly imported 60-Hz source actions, not the earlier 24-Hz import.
names={'Run':'Run.001','Sneak':'Sneak.001','Fetch':'Fetch.001','Bark':'Bark.001','Alert':'Idle Alert.001','Jump':'Jump.001','Howl':'Howl.001','Sit':'Sit.005','Idle':'Idle.005','Walk':'Walk.005'}
rests={n:source.data.bones[n].matrix_local.to_3x3().normalized() for n in inverse.values()}
target.animation_data_create();source.animation_data_create();scene=bpy.context.scene;scene.render.fps=60
for pb in target.pose.bones:pb.rotation_mode='QUATERNION'
made=[]
for label,srcname in names.items():
 action=bpy.data.actions[srcname];source.animation_data.action=action
 if action.slots:source.animation_data.action_slot=action.slots[0]
 dest=bpy.data.actions.new('Delivery_'+label);target.animation_data.action=dest
 start,end=[int(v) for v in action.frame_range]
 for frame in range(start,end+1):
  scene.frame_set(frame)
  for pb in target.pose.bones:pb.matrix_basis.identity()
  bpy.context.view_layer.update()
  for bone in target.data.bones:
   if bone.name not in inverse:continue
   srcname2=inverse[bone.name];s=source.pose.bones[srcname2]
   delta=s.matrix.to_3x3().normalized()@rests[srcname2].inverted()
   pb=target.pose.bones[bone.name];m=(delta@bone.matrix_local.to_3x3().normalized()).to_4x4();m.translation=pb.head
   if bone.name=='pelvis':m.translation=bone.head_local+(s.head-source.data.bones[srcname2].head_local)*.13
   pb.matrix=m;bpy.context.view_layer.update()
  deps=bpy.context.evaluated_depsgraph_get();low=min((ob.matrix_world@v.co).z for ob in meshes for v in ob.evaluated_get(deps).data.vertices)
  correction=max(0,-low) if label=='Jump' else -low
  hips=target.pose.bones['pelvis'];m=hips.matrix.copy();m.translation.z+=correction;hips.matrix=m;bpy.context.view_layer.update()
  for pb in target.pose.bones:
   pb.keyframe_insert('rotation_quaternion',frame=frame-start);pb.keyframe_insert('location',frame=frame-start)
 for layer in dest.layers:
  for strip in layer.strips:
   for bag in strip.channelbags:
    for curve in bag.fcurves:
     for key in curve.keyframe_points:key.interpolation='LINEAR'
 made.append(dest.name);print('BAKED',label,end-start+1)
source.hide_render=True
scene.view_layers[0].material_override=None
cam=scene.camera;cam.data.ortho_scale=.52;cam.location=(.75,-.75,.35);cam.rotation_euler=(Vector((0,.015,.17))-cam.location).to_track_quat('-Z','Y').to_euler()
for label in ['Idle','Run','Sit','Howl','Jump']:
 action=bpy.data.actions['Delivery_'+label];target.animation_data.action=action
 if action.slots:target.animation_data.action_slot=action.slots[0]
 for pct in [0,25,50,75]:
  scene.frame_set(round(action.frame_range[1]*pct/100));scene.render.filepath=str(OUT/('motion_'+label+'_'+str(pct)+'.png'));bpy.ops.render.render(write_still=True)
scene.frame_set(0)
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'chihuahua_motion_01.blend'))
print('DELIVERY_MOTION_REVIEW_READY',made)
