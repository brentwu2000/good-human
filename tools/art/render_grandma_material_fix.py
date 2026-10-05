import bpy
from mathutils import Vector
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=r"C:\Users\b\Documents\good-human\assets\characters\human\models\ai_grandma_research\grandma.glb")
for o in bpy.context.scene.objects:
    if o.type == 'ARMATURE':
        o.hide_render = True
bpy.ops.object.select_all(action='DESELECT')
bpy.ops.object.camera_add(location=(2.1, -3.4, 1.45))
cam = bpy.context.object
cam.data.lens = 58
cam.rotation_euler = (Vector((0, 0, 0.82)) - cam.location).to_track_quat('-Z', 'Y').to_euler()
bpy.context.scene.camera = cam
bpy.ops.object.light_add(type='AREA', location=(1.5, -2.5, 3.2))
bpy.context.object.data.energy = 900
bpy.context.object.data.shape = 'DISK'
bpy.context.object.data.size = 3.0
bpy.ops.object.light_add(type='AREA', location=(-2, 1, 1.8))
bpy.context.object.data.energy = 500
bpy.context.object.data.size = 2.5
bpy.context.scene.render.engine = 'BLENDER_EEVEE'
bpy.context.scene.render.resolution_x = 600
bpy.context.scene.render.resolution_y = 800
bpy.context.scene.render.resolution_percentage = 100
bpy.context.scene.render.filepath = r"C:\Users\b\Documents\good-human\assets\characters\human\models\ai_grandma_research\grandma_texturefix_preview.png"
bpy.context.scene.world = bpy.data.worlds.new("GrandmaPreviewWorld")
bpy.context.scene.world.color = (0.055, 0.07, 0.08)
bpy.ops.render.render(write_still=True)
