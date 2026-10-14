import bpy,sys,json,math
from pathlib import Path
from mathutils import Vector
ROOT=Path(r'C:/Users/b/Documents/good-human');OUT=ROOT/'build/dog_delivery'
sys.path.insert(0,str(ROOT/'tools/art'));from retarget_mesh2motion import DOG_MAP
src=bpy.data.objects['MotionSource'];a=bpy.data.objects['Shiba_Rig_Delivery'];s=bpy.context.scene
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'before_contact_refine.blend'))
mp=dict(DOG_MAP);mp['root']='ROOT'
for b in src.data.bones:mp.setdefault(b.name,b.name)
inv={new:old for old,new in mp.items() if new in a.data.bones and (new in ['ROOT','pelvis','spine','chest'] or 'Spine' in old or 'Leg' in old)}
names={'Run':'Run.001','Sneak':'Sneak.001','Fetch':'Fetch.001','Bark':'Bark.001','Alert':'Idle Alert.001','Jump':'Jump.001','Howl':'Howl.001','Sit':'Sit.005','Idle':'Idle.005','Walk':'Walk.005'}
meshes=[o for o in bpy.data.objects if o.type=='MESH' and o.parent==a]
report={}
for label,srcname in names.items():
 old=bpy.data.actions['Delivery_'+label];dest=bpy.data.actions.new('Refined_'+label);dest.use_fake_user=True;src.animation_data.action=bpy.data.actions[srcname];end=int(old.frame_range[1]);mins=[]
 for frame in range(end+1):
  a.animation_data.action=old;s.frame_set(frame);bpy.context.view_layer.update();world={b.name:b.matrix.copy() for b in a.pose.bones}
  s.frame_set(frame+2);heads={b.name:b.head.copy() for b in src.pose.bones}
  a.animation_data.action=None
  desired={}
  for bone in a.data.bones:
   name=bone.name
   if name in inv:
    oldname=inv[name];d=heads[oldname]-src.data.bones[oldname].head_local;m=world[name].copy();m.translation=bone.head_local+Vector((d.x*.18,d.y*.14,d.z*.13))
   elif bone.parent:m=desired[bone.parent.name]@world[bone.parent.name].inverted()@world[name]
   else:m=world[name].copy()
   if label in ['Sit','Howl'] and name.startswith('Back_Leg_Foot_1_'):
    direction=m.to_3x3().col[1].normalized();flat=Vector((direction.x,direction.y,0)).normalized();q=direction.rotation_difference(flat);rot=q.to_matrix()@m.to_3x3();pos=m.translation.copy();m=rot.to_4x4();m.translation=pos
   desired[name]=m
   kwargs={} if not bone.parent else dict(parent_matrix=desired[bone.parent.name],parent_matrix_local=bone.parent.matrix_local)
   pb=a.pose.bones[name];pb.rotation_mode='QUATERNION';pb.matrix_basis=bone.convert_local_to_pose(m,bone.matrix_local,invert=True,**kwargs)
  bpy.context.view_layer.update();dg=bpy.context.evaluated_depsgraph_get();low=min((o.matrix_world@v.co).z for o in meshes for v in o.evaluated_get(dg).data.vertices);correction=max(0,-low) if label=='Jump' else -low
  pb=a.pose.bones['pelvis'];m=pb.matrix.copy();m.translation.z+=correction;pb.matrix=m;bpy.context.view_layer.update()
  values={p.name:(p.location.copy(),p.rotation_quaternion.copy(),p.scale.copy()) for p in a.pose.bones}
  a.animation_data.action=dest
  for name,(loc,rot,scale) in values.items():
   pb=a.pose.bones[name];pb.location=loc;pb.rotation_quaternion=rot;pb.scale=scale;pb.keyframe_insert('location',frame=frame);pb.keyframe_insert('rotation_quaternion',frame=frame)
  mins.append(float(low+correction))
 for layer in dest.layers:
  for strip in layer.strips:
   for bag in strip.channelbags:
    for f in bag.fcurves:
     for k in f.keyframe_points:k.interpolation='LINEAR'
 report[label]={'frames':end+1,'min_contact':min(mins),'max_contact':max(mins)};print('CONTACT_REFINED',label);(OUT/'contact_progress.json').write_text(json.dumps(report,indent=2))
a.animation_data.action=None
for b in a.pose.bones:b.matrix_basis.identity()
s.frame_set(0);bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'chihuahua_contact_refined.blend'))
print('CONTACT_REFINE_DONE')
