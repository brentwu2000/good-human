import bpy
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=r"C:\Users\b\Documents\good-human\assets\characters\human\models\ai_grandma_research\grandma.glb")
print("OBJECTS", [(o.name, o.type, len(o.data.materials) if hasattr(o.data, 'materials') else 0) for o in bpy.data.objects])
print("MATERIALS", [m.name for m in bpy.data.materials])
for m in bpy.data.materials:
    print("MAT", m.name, "nodes", [(n.name, n.type) for n in m.node_tree.nodes] if m.use_nodes else [])
