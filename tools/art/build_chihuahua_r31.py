"""Rigify quadruped control study; bake subtle new gestures to original deform bones."""
import bpy,os,math,json,importlib
from pathlib import Path
from mathutils import Vector
ROOT=Path(r'C:\Users\b\Documents\good-human');OUT=ROOT/'build/chihuahua_motion_r31';OUT.mkdir(parents=True,exist_ok=True)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(os.environ['TEMP'],'chihuahua_r31_before_rebuild.blend'))
for o in list(bpy.data.objects):bpy.data.objects.remove(o,do_unlink=True)
bpy.ops.import_scene.gltf(filepath=str(ROOT/'assets/art_previews/dogs/candidates/r30/chihuahua.glb'))
r=next(o for o in bpy.data.objects if o.type=='ARMATURE');r.name='Chihuahua_Deform';r.animation_data_clear()
for p in r.pose.bones:p.matrix_basis.identity()
bpy.ops.object.armature_add();meta=bpy.context.object;meta.name='R31_Quadruped_Metarig'
importlib.import_module('rigify.metarigs.Basic.basic_quadruped').create(meta)
if bpy.context.mode!='OBJECT':bpy.ops.object.mode_set(mode='OBJECT')
bpy.context.view_layer.objects.active=meta;bpy.ops.object.mode_set(mode='EDIT');eb=meta.data.edit_bones
if eb.get('Bone'):eb.remove(eb['Bone'])
for b in eb:b.head*=.27;b.tail*=.27
start=r.data.bones['pelvis'].head_local.copy();end=r.data.bones['neck'].head_local.copy()
for i,name in enumerate(['spine.004','spine.005','spine.006','spine.007','spine.008']):
 eb[name].head=start.lerp(end,i/5);eb[name].tail=start.lerp(end,(i+1)/5)
a=r.data.bones['neck'];mid=a.head_local.lerp(a.tail_local,.5)
eb['spine.009'].head=a.head_local;eb['spine.009'].tail=mid;eb['spine.010'].head=mid;eb['spine.010'].tail=a.tail_local
a=r.data.bones['head'];eb['spine.011'].head=a.head_local;eb['spine.011'].tail=a.tail_local
for name,target in [('spine.003','tail_01'),('spine.002','tail_02'),('spine.001','tail_03')]:
 a=r.data.bones[target];eb[name].head=a.head_local;eb[name].tail=a.tail_local
# The inherited tail origin is offset from the pelvis; do not force a merged chain.
eb['spine'].head=eb['spine.001'].tail;eb['spine'].tail=eb['spine'].head+Vector((0,-.008,-.003))
bpy.ops.object.mode_set(mode='OBJECT');meta.pose.bones['spine.003'].rigify_parameters.connect_chain=False
bpy.ops.pose.rigify_generate();g=bpy.context.object;g.name='R31_Rigify_Controls'
for name,target in [('head','head'),('neck','neck'),('tail_01','spine_master.003')]:
 c=r.pose.bones[name].constraints.new('COPY_ROTATION');c.name='R31_Rigify_Drive';c.target=g;c.subtarget=target;c.owner_space='LOCAL';c.target_space='LOCAL'
controls=['head','neck','spine_master.003']
for name in controls:g.pose.bones[name].rotation_mode='XYZ'
scene=bpy.context.scene;scene.render.fps=30
records=[];dog=bpy.data.objects['DogBody'];stats=[]
for clip,duration in [('HeadLook',3),('Sniff',2),('TailWag',3)]:
 g.animation_data_create();action=bpy.data.actions.new('R31_'+clip+'_Rigify');g.animation_data.action=action;action.use_fake_user=True
 rec={'name':clip,'fps':30,'frames':[]}
 for frame in range(duration*30+1):
  t=frame/(duration*30);scene.frame_set(frame+1)
  for name in controls:g.pose.bones[name].rotation_euler=(0,0,0)
  if clip=='HeadLook':g.pose.bones['head'].rotation_euler.z=math.radians(12)*math.sin(2*math.pi*t)
  if clip=='Sniff':
   env=math.sin(math.pi*t)**2
   g.pose.bones['head'].rotation_euler.x=math.radians(5)*env*(1+.18*math.sin(6*math.pi*t))
   g.pose.bones['neck'].rotation_euler.x=math.radians(2)*env
  if clip=='TailWag':g.pose.bones['spine_master.003'].rotation_euler.z=math.radians(8)*math.sin(math.pi*t)**2*math.sin(8*math.pi*t)
  for name in controls:g.pose.bones[name].keyframe_insert('rotation_euler',frame=frame+1,group=name)
  bpy.context.view_layer.update()
  pose={}
  for p in r.pose.bones:
   local=p.bone.matrix_local.inverted() @ p.parent.bone.matrix_local @ p.parent.matrix.inverted() @ p.matrix if p.parent else p.bone.matrix_local.inverted() @ p.matrix
   q=local.to_quaternion().normalized();pose[p.name]=[q.x,q.y,q.z,q.w]
  rec['frames'].append(pose)
  if frame in [0,duration*30//4,duration*30//2,3*duration*30//4,duration*30]:
   evaluated=dog.evaluated_get(bpy.context.evaluated_depsgraph_get());mesh=evaluated.to_mesh();pts=[v.co for v in mesh.vertices]
   stats.append({'clip':clip,'frame':frame,'min':[min(p[i] for p in pts) for i in range(3)],'max':[max(p[i] for p in pts) for i in range(3)]});evaluated.to_mesh_clear()
 records.append(rec)
(OUT/'baked_gestures.json').write_text(json.dumps(records));(OUT/'pose_bounds.json').write_text(json.dumps(stats,indent=2))
g.animation_data.action=action
scene.frame_start=1;scene.frame_end=91;scene.frame_set(1)
meta.hide_set(True);g.hide_set(True);r.hide_set(True)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(os.environ['TEMP'],'chihuahua_r31_04_rigify_gestures.blend'))
print('R31_RIGIFY_BAKED',len(g.data.bones),[(r['name'],len(r['frames'])) for r in records])

