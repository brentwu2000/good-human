import bpy
from pathlib import Path
OUT=Path(r'C:/Users/b/Documents/good-human/build/dog_delivery')
a=bpy.data.objects['Shiba_Rig_Delivery'];body=bpy.data.objects['DogBody_Delivery']
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'before_glb_export.blend'))
clips={name:bpy.data.actions['Refined_'+name].copy() for name in ['Idle','Walk','Sit']}
for name in ['Run','Sneak','Fetch','Bark','Alert','Jump','Howl','Sit','Idle']:clips['M2M_'+name]=bpy.data.actions['Refined_'+name].copy()
keep=set(clips.values())
for act in list(bpy.data.actions):
 if act not in keep:bpy.data.actions.remove(act)
for name,act in clips.items():act.name=name;act.use_fake_user=True;a.animation_data.action=act
for o in list(bpy.data.objects):
 if o not in [a,body]:bpy.data.objects.remove(o,do_unlink=True)
a.animation_data.action=None
for p in a.pose.bones:p.matrix_basis.identity()
bpy.context.scene.frame_set(0)
bpy.ops.object.select_all(action='SELECT');bpy.context.view_layer.objects.active=body
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'chihuahua_glb_scene_r38.blend'))
bpy.ops.export_scene.gltf(filepath=str(OUT/'chihuahua_candidate.glb'),export_format='GLB',use_selection=True,export_animation_mode='ACTIONS',export_skins=True,export_force_sampling=True,export_frame_range=False)
# Matching animation-only library for DogModelMotion3D's external M2M loader.
bpy.data.objects.remove(body,do_unlink=True)
for name in ['Idle','Walk','Sit']:bpy.data.actions.remove(clips[name])
mesh=bpy.data.meshes.new('Stub');mesh.from_pydata([(0,0,0),(.001,0,0),(0,0,.001)],[],[(0,1,2)]);stub=bpy.data.objects.new('Stub',mesh);bpy.context.scene.collection.objects.link(stub);stub.parent=a;g=stub.vertex_groups.new(name='pelvis');g.add([0,1,2],1,'REPLACE');stub.modifiers.new('Armature','ARMATURE').object=a
bpy.ops.object.select_all(action='SELECT');bpy.ops.export_scene.gltf(filepath=str(OUT/'chihuahua_m2m_candidate.glb'),export_format='GLB',use_selection=True,export_animation_mode='ACTIONS',export_skins=True,export_force_sampling=True,export_frame_range=False)
print('CANDIDATE_GLB_EXPORTED')
