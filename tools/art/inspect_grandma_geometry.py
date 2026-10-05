import bpy
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=r"C:\Users\b\Documents\good-human\assets\characters\human\models\ai_grandma_research\grandma.glb")
o=bpy.data.objects['Character']
print('BOUNDS',[(round(min((o.matrix_world @ v.co)[i] for v in o.data.vertices),3),round(max((o.matrix_world @ v.co)[i] for v in o.data.vertices),3)) for i in range(3)])
for p in o.data.polygons[:12]: print('POLY',p.index,tuple(round(x,3) for x in p.center),tuple(round(x,3) for x in p.normal))
