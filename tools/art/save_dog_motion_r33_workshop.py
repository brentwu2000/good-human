"""Save editable, packed model + all clips outside the game repository."""
import bpy
from pathlib import Path
ROOT=Path(r'C:/Users/b/Documents/good-human')
OUT=ROOT.parent/'good-human-3d-pipeline/blender/dog/motion_r33'
OUT.mkdir(parents=True,exist_ok=True)
for breed in ['shiba_01','chihuahua','corgi','frenchie','golden','pomeranian','poodle','shiba']:
 bpy.ops.wm.read_factory_settings(use_empty=True)
 bpy.context.scene.render.fps=30
 model=ROOT/'assets/characters/dog/models'/('shiba_01/shiba_01.glb' if breed=='shiba_01' else f'breeds/{breed}.glb')
 bpy.ops.import_scene.gltf(filepath=str(model))
 rig=next(o for o in bpy.data.objects if o.type=='ARMATURE')
 before=set(bpy.data.objects);old=set(bpy.data.actions)
 bpy.ops.import_scene.gltf(filepath=str(ROOT/f'assets/characters/dog/animations/m2m/{breed}.glb'))
 actions={a.name:a for a in set(bpy.data.actions)-old}
 for obj in set(bpy.data.objects)-before:bpy.data.objects.remove(obj,do_unlink=True)
 for action in bpy.data.actions:action.use_fake_user=True
 rig.animation_data_create();rig.animation_data.action=actions['M2M_Idle'];rig.animation_data.action_slot=actions['M2M_Idle'].slots[0]
 bpy.context.scene.frame_set(0)
 bpy.context.view_layer.objects.active=rig
 rig.select_set(True)
 bpy.ops.file.pack_all()
 bpy.ops.wm.save_as_mainfile(filepath=str(OUT/f'{breed}_motion_r33.blend'))
 print('WORKSHOP_SAVED',breed,flush=True)
