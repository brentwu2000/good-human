import bpy, math
from mathutils import Vector, Matrix
WORK=r'C:\Users\b\Documents\good-human-3d-pipeline\blender\human\p04_owner'
bpy.ops.wm.save_as_mainfile(filepath=WORK+'/owner_05_before_animation.blend')
rig=bpy.data.objects['OwnerSkeleton'];rig.hide_set(False)
# Pull loose trim back onto jacket and smooth cut cuff edges.
hem=bpy.data.objects.get('Jacket_Hem')
if hem:
 for v in hem.data.vertices:v.co.x*=.83;v.co.z-=.024
for o in bpy.context.scene.objects:
 if o.type=='MESH' and o.name.startswith(('Top_','Bottom_')):
  sm=o.modifiers.new('Seam relax','SMOOTH');sm.factor=.45;sm.iterations=2

def reset():
 for p in rig.pose.bones:p.matrix_basis=Matrix.Identity(4);p.rotation_mode='QUATERNION'
 bpy.context.view_layer.update()
def point_bone(name,start,end):
 p=rig.pose.bones[name];b=p.bone;start=Vector(start);end=Vector(end)
 q=(b.tail_local-b.head_local).normalized().rotation_difference((end-start).normalized())
 m=(q@b.matrix_local.to_quaternion()).to_matrix().to_4x4();m.translation=start;p.matrix=m
 bpy.context.view_layer.update()
def arm(side,target,pole):
 upper=rig.pose.bones['upperarm_'+side];lower=rig.pose.bones['lowerarm_'+side]
 root=upper.head.copy();target=Vector(target);pole=Vector(pole)
 l1=upper.bone.length;l2=lower.bone.length;d=target-root;dist=min(d.length,l1+l2-.002);n=d.normalized()
 along=(l1*l1-l2*l2+dist*dist)/(2*dist);h=math.sqrt(max(.00001,l1*l1-along*along))
 perp=(pole-root)-n*(pole-root).dot(n);perp.normalize();elbow=root+n*along+perp*h
 point_bone('upperarm_'+side,root,elbow);point_bone('lowerarm_'+side,elbow,root+n*dist)
 hand=rig.pose.bones['hand_'+side];m=hand.matrix.copy();m.translation=root+n*dist;hand.matrix=m
def leg(side,target,pole):
 upper=rig.pose.bones['thigh_'+side];lower=rig.pose.bones['calf_'+side];root=upper.head.copy();target=Vector(target);n=(target-root).normalized();dist=min((target-root).length,upper.bone.length+lower.bone.length-.001)
 a=(upper.bone.length**2-lower.bone.length**2+dist**2)/(2*dist);h=math.sqrt(max(.00001,upper.bone.length**2-a*a));perp=Vector(pole)-root;perp-=n*perp.dot(n);perp.normalize();knee=root+n*a+perp*h
 point_bone('thigh_'+side,root,knee);point_bone('calf_'+side,knee,target)
 foot=rig.pose.bones['foot_'+side];m=foot.bone.matrix_local.copy();m.translation=target;foot.matrix=m
def pose(kind,phase):
 reset();t=phase
 # Hands form a readable civilian guard. Leave shoulders loose.
 left=Vector((.24,-.30,1.40));right=Vector((-.22,-.27,1.43))
 if kind=='Idle_Untrained':left=Vector((.29,-.24,1.46));right=Vector((-.26,-.22,1.30))
 if kind=='Idle_Scrapper':left=Vector((.28,-.34,1.39));right=Vector((-.24,-.25,1.47))
 if kind=='Idle_Calm':left=Vector((.17,-.23,1.40));right=Vector((-.18,-.22,1.42))
 peak=math.sin(math.pi*t)**2
 if kind=='Jab':left=left.lerp(Vector((.17,-.52,1.36)),peak)
 if kind=='HeavyHook':right=Vector((-.26+.20*peak,-.26-.03*peak,1.39));rig.pose.bones['spine_03'].rotation_mode='XYZ';rig.pose.bones['spine_03'].rotation_euler.y=.35*math.sin(math.tau*t)
 if kind=='Block':left=Vector((.105,-.24,1.56));right=Vector((-.105,-.23,1.55))
 if kind=='Dodge':rig.pose.bones['pelvis'].location.x=.11*peak;rig.pose.bones['spine_03'].rotation_mode='XYZ';rig.pose.bones['spine_03'].rotation_euler.z=.16*peak
 if kind in ['HitLight','HitHeavy','Stumble']:
  amount={'HitLight':.06,'HitHeavy':.15,'Stumble':.23}[kind]*peak
  rig.pose.bones['pelvis'].location.z=amount
  rig.pose.bones['spine_03'].rotation_mode='XYZ';rig.pose.bones['spine_03'].rotation_euler.x=-amount
 bpy.context.view_layer.update()
 arm('l',left,(.5,-.05,1.22));arm('r',right,(-.5,-.05,1.22))
 for side in ['l','r']:
  for finger in ['index','middle','ring','pinky']:
   for k in [1,2,3]:
    pb=rig.pose.bones[f'{finger}_0{k}_{side}'];pb.rotation_mode='XYZ';pb.rotation_euler.x=.65
 # In-place walking authored independently from simulation/root travel.
 if kind in ['Walk','Approach','Circle','Backstep']:
  for side,sgn in [('l',1),('r',-1)]:
   a=math.sin(math.tau*t)*sgn;foot=rig.data.bones['foot_'+side].head_local.copy()
   foot.y+=a*(.14 if kind!='Backstep' else -.11);foot.z+=max(0,a)*.055
   if kind=='Circle':foot.x+=a*.05
   leg(side,foot,(foot.x,-.35,.5))
 if kind=='Kick':
  foot=rig.data.bones['foot_r'].head_local.copy();foot.y-=.68*peak;foot.z+=.52*peak;leg('r',foot,(-.2,-.7,.9))
 if kind=='Stumble':
  foot=rig.data.bones['foot_l'].head_local.copy();foot.y+=.19*peak;leg('l',foot,(.3,-.15,.55))
 if kind=='Down':
  # A bent side fall: pelvis lowers before root rolls, knees then fold.
  rig.pose.bones['Root'].rotation_mode='XYZ';rig.pose.bones['Root'].rotation_euler.y=1.36*t
  rig.pose.bones['Root'].location.z=.22*t
  for side in ['l','r']:
   rig.pose.bones['calf_'+side].rotation_mode='XYZ';rig.pose.bones['calf_'+side].rotation_euler.x=1.0*t
 bpy.context.view_layer.update()
def key(frame):
 for p in rig.pose.bones:
  p.rotation_mode='QUATERNION'
  p.keyframe_insert('location',frame=frame)
  p.keyframe_insert('rotation_quaternion',frame=frame)

rig.animation_data_create()
clips={'Idle':60,'Idle_Untrained':60,'Idle_Scrapper':60,'Idle_Calm':60,'Walk':30,'Approach':30,'Circle':36,'Backstep':36,'Jab':24,'HeavyHook':36,'Kick':36,'Block':24,'Dodge':24,'HitLight':18,'HitHeavy':30,'Stumble':36,'Down':42}
for name,length in clips.items():
 rig.animation_data.action=None;a=bpy.data.actions.new(name);rig.animation_data.action=a
 for f in range(0,length+1,3):pose(name,f/length);key(f+1)
 a.use_fake_user=True
rig.animation_data.action=bpy.data.actions['Idle'];bpy.context.scene.frame_set(1)
bpy.context.scene.render.fps=30
bpy.ops.wm.save_as_mainfile(filepath=WORK+'/owner_06_animation.blend')
print('ANIMATIONS',list(clips))
