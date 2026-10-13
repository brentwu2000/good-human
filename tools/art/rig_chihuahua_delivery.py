import bpy,sys
from mathutils import Vector
from pathlib import Path
ROOT=Path(r'C:/Users/b/Documents/good-human');OUT=ROOT/'build/dog_delivery'
sys.path.insert(0,str(ROOT/'tools/art'))
from retarget_mesh2motion import DOG_MAP
body=bpy.data.objects['ChihuahuaBodyTopology'];head=bpy.data.objects['ChihuahuaHead'];arm=body.parent
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'before_rig.blend'))
# Apply the inspected surface modifiers, preserving deform groups.
bpy.ops.object.select_all(action='DESELECT');body.select_set(True);bpy.context.view_layer.objects.active=body
for m in list(body.modifiers):
 if m.type!='ARMATURE':bpy.ops.object.modifier_apply(modifier=m.name)
head.select_set(True);bpy.context.view_layer.objects.active=head
for m in list(head.modifiers):
 if m.type!='ARMATURE':bpy.ops.object.modifier_apply(modifier=m.name)
mapping=dict(DOG_MAP);mapping['root']='ROOT';mapping['Chin']='jaw';mapping['Chin_Tip']='jaw_tip'
for old,new in mapping.items():
 if old in arm.data.bones:arm.data.bones[old].name=new
 if old in body.vertex_groups:body.vertex_groups[old].name=new
arm.name='Shiba_Rig_Delivery'
bpy.context.view_layer.objects.active=arm;bpy.ops.object.mode_set(mode='EDIT')
def setbone(name,h,t):
 b=arm.data.edit_bones[name];b.head=h;b.tail=t
setbone('neck',(0,-.055,.156),(0,-.071,.203))
setbone('head',(0,-.071,.203),(0,-.128,.222))
setbone('jaw',(0,-.116,.198),(0,-.150,.188))
setbone('jaw_tip',(0,-.150,.188),(0,-.163,.184))
for side,sign in [('L',1),('R',-1)]:
 setbone('ear_'+side,(sign*.051,-.039,.268),(sign*.077,-.039,.323))
 setbone('Ear_Tip_'+side,(sign*.077,-.039,.323),(sign*.086,-.041,.349))
bpy.ops.object.mode_set(mode='OBJECT')
# Head retains prior facial/ear skin identity; lower cut is blended to the new neck.
for m in head.modifiers:
 if m.type=='ARMATURE':m.object=arm
head.parent=arm
for v in head.data.vertices:
 ear={head.vertex_groups[g.group].name:g.weight for g in v.groups if head.vertex_groups[g.group].name in ['ear_L','ear_R']}
 for g in head.vertex_groups:g.remove([v.index])
 total=sum(ear.values())
 for name,w in ear.items():head.vertex_groups[name].add([v.index],w,'REPLACE')
 neck=max(0,min(1,(.195-v.co.z)/.032))*(1-total)
 head.vertex_groups['neck'].add([v.index],neck,'REPLACE')
 head.vertex_groups['head'].add([v.index],1-total-neck,'REPLACE')
# Generated neck loop had no groups; supply explicit neck weight, normalize all.
for v in body.data.vertices:
 total=sum(g.weight for g in v.groups)
 if total<1e-7:body.vertex_groups['neck'].add([v.index],1,'REPLACE')
 elif abs(total-1)>1e-6:
  values=[(g.group,g.weight/total) for g in v.groups]
  for i,w in values:body.vertex_groups[i].add([v.index],w,'REPLACE')
for ob in [body,head]:
 for p in ob.data.polygons:p.use_smooth=True
scene=bpy.context.scene;scene.view_layers[0].material_override=None
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'chihuahua_body_rig_01.blend'))
print('RIG_CANDIDATE',len(arm.data.bones),'body',len(body.data.vertices),'head',len(head.data.vertices))
