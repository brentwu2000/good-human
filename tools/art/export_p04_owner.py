import bpy, os, json
WORK=r'C:\Users\b\Documents\good-human-3d-pipeline\blender\human\p04_owner'
OUT=r'C:\Users\b\Documents\good-human\assets\characters\human\models\p04_owner'
os.makedirs(OUT,exist_ok=True)
rig=bpy.data.objects['OwnerSkeleton'];rig.animation_data.action=None
for p in rig.pose.bones:
 p.rotation_mode='QUATERNION';p.rotation_quaternion=(1,0,0,0);p.location=(0,0,0);p.scale=(1,1,1)
bpy.context.view_layer.update()
for v in bpy.data.objects['Top_Jacket'].data.vertices:
 if v.co.z<1.12:v.co.x*=1.1;v.co.y*=1.12
# Reduce only anatomical face/hand base. Clothing joint loops remain authored quads.
body=bpy.data.objects['Body_HeadHands'];dec=body.modifiers.new('Surface budget','DECIMATE');dec.ratio=.65
meshes=[o for o in bpy.context.scene.objects if o.type=='MESH' and not o.hide_render]
for o in meshes:
 bpy.ops.object.select_all(action='DESELECT');o.select_set(True);bpy.context.view_layer.objects.active=o
 for m in list(o.modifiers):
  if m.type=='SOLIDIFY':m.use_rim_only=True
  if m.type!='ARMATURE':bpy.ops.object.modifier_apply(modifier=m.name)
# Consolidate small trim meshes into clothing/hair modules to reduce draw calls.
sets={
 'Hair_Module':['Hair_Short','Hair_Lock','Eyebrow'],
 'Top_Module':['Top_','Jacket_','Pocket_','Collar_','Cuff_'],
 'Shoes_Module':['Shoes_','Soles_'],
 'Face_Module':['Body_','Eye_','Iris_','Pupil_'],
}
for name,prefixes in sets.items():
 meshes=[o for o in bpy.context.scene.objects if o.type=='MESH' and not o.hide_render]
 obs=[o for o in meshes if any(o.name.startswith(p) for p in prefixes)]
 bpy.ops.object.select_all(action='DESELECT')
 for o in obs:o.select_set(True)
 bpy.context.view_layer.objects.active=obs[0];bpy.ops.object.join();obs[0].name=name
meshes=[o for o in bpy.context.scene.objects if o.type=='MESH' and not o.hide_render]
bpy.ops.object.select_all(action='DESELECT');rig.select_set(True)
for o in meshes:o.select_set(True)
bpy.context.view_layer.objects.active=rig
bpy.ops.wm.save_as_mainfile(filepath=WORK+'/owner_07_export.blend')
bpy.ops.export_scene.gltf(filepath=OUT+'/p04_owner.glb',export_format='GLB',use_selection=True,export_animations=True,export_animation_mode='ACTIONS',export_skins=True,export_yup=True,export_apply=False)
report={'height_m':1.76,'grade':'B - implementation candidate, not S final art','meshes':{o.name:sum(len(p.vertices)-2 for p in o.data.polygons) for o in meshes},'animations':[a.name for a in bpy.data.actions]}
with open(OUT+'/build_manifest.json','w') as f:json.dump(report,f,indent=2)
print(report)
