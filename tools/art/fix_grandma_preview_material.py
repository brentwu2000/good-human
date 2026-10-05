import bpy, os, shutil

source = r"C:\Users\b\Documents\good-human\assets\characters\human\models\ai_grandma_research\grandma.glb"
backup = r"C:\Users\b\Documents\good-human\assets\characters\human\models\ai_grandma_research\grandma_mosaic_backup.glb"
work = r"C:\Users\b\Documents\good-human-3d-pipeline\blender\human\grandma\grandma_texturefix_01.blend"
output = source
os.makedirs(os.path.dirname(work), exist_ok=True)
if not os.path.exists(backup):
    shutil.copy2(source, backup)

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=source)

def material(name, color, roughness=0.78):
    m = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    m.use_nodes = True
    bs = m.node_tree.nodes.get("Principled BSDF")
    for node in list(m.node_tree.nodes):
        if node != bs and node.type == "TEX_IMAGE":
            m.node_tree.nodes.remove(node)
    bs.inputs["Base Color"].default_value = (*color, 1.0)
    bs.inputs["Roughness"].default_value = roughness
    return m

skin = material("Grandma_Skin_Clean", (0.42, 0.18, 0.12), 0.86)
hair = material("Grandma_Hair_Silver", (0.56, 0.53, 0.52), 0.92)
cardigan = material("Grandma_Cardigan_Plum", (0.16, 0.05, 0.12), 0.9)
shirt = material("Grandma_Shirt_Cream", (0.72, 0.58, 0.40), 0.88)
pants = material("Grandma_Trousers_Charcoal", (0.07, 0.07, 0.08), 0.93)
shoes = material("Grandma_Shoes_Oat", (0.48, 0.36, 0.23), 0.9)
tote = material("Grandma_Tote_Canvas", (0.68, 0.59, 0.43), 0.92)

body = bpy.data.objects.get("Character")
if body:
    body.data.materials.clear()
    for m in (skin, hair, cardigan, shirt, pants, shoes):
        body.data.materials.append(m)
    for poly in body.data.polygons:
        c = poly.center
        z, y = c.z, c.y
        if z < 0.14:
            idx = 5
        elif z < 0.78:
            idx = 4
        elif z < 1.26:
            idx = 0 if abs(c.x) > 0.22 else 2
        elif z > 1.46 and y > 0.03:
            idx = 1
        elif z > 1.30 and y > 0.03:
            idx = 0
        else:
            idx = 2
        poly.material_index = idx

bag = bpy.data.objects.get("Tote")
if bag:
    bag.data.materials.clear()
    bag.data.materials.append(tote)

bpy.ops.wm.save_as_mainfile(filepath=work)
for o in bpy.data.objects:
    o.select_set(True)
bpy.ops.export_scene.gltf(filepath=output, export_format="GLB", use_selection=True, export_yup=True)
print("GRANDMA_TEXTUREFIX_EXPORTED", output)
