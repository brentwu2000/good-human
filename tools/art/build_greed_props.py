import bpy, math, os

bpy.ops.wm.read_factory_settings(use_empty=True)
os.makedirs(r"C:\Users\b\Documents\good-human-3d-pipeline\blender\environment\greed", exist_ok=True)
os.makedirs(r"C:\Users\b\Documents\good-human\assets\environment\territory\models\greed", exist_ok=True)

def active():
    return bpy.context.view_layer.objects.active

def mat(name, color, emission=0.0):
    m = bpy.data.materials.new(name)
    m.diffuse_color = (*color, 1)
    m.use_nodes = True
    bs = m.node_tree.nodes.get("Principled BSDF")
    bs.inputs["Base Color"].default_value = (*color, 1)
    bs.inputs["Roughness"].default_value = 0.7
    if emission:
        bs.inputs["Emission Color"].default_value = (*color, 1)
        bs.inputs["Emission Strength"].default_value = emission
    return m

teal = mat("Greed_Teal", (0.08, 0.62, 0.55), 0.8)
coral = mat("Greed_Coral", (0.92, 0.23, 0.25), 0.5)
violet = mat("Greed_Violet", (0.42, 0.18, 0.72), 1.4)
cream = mat("Greed_BagCanvas", (0.72, 0.58, 0.37))
dark = mat("Greed_Charcoal", (0.08, 0.1, 0.11))
metal = mat("Greed_SignMetal", (0.42, 0.48, 0.48))

def cube(name, loc, scale, material, bevel=0.04):
    bpy.ops.mesh.primitive_cube_add(location=loc)
    o = active(); o.name = name; o.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if bevel:
        mod = o.modifiers.new("Soft edges", "BEVEL"); mod.width = bevel; mod.segments = 2
    o.data.materials.append(material)

def cylinder(name, loc, radius, depth, material):
    bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=radius, depth=depth, location=loc)
    o = active(); o.name = name; o.data.materials.append(material)

cylinder("Greed_BusStop_Pole", (-3.4, 1.2, 0), 0.055, 2.4, metal)
cube("Greed_BusStop_Sign", (-3.4, 2.35, 0), (0.42, 0.28, 0.06), teal, 0.05)
cube("Greed_BusStop_Bench", (-3.4, 0.35, 0.25), (0.75, 0.12, 0.25), dark, 0.06)
cube("Greed_FullBag", (-1.1, 0.62, 0.1), (0.32, 0.26, 0.22), cream, 0.12)
for x in (-1.34, -0.86):
    bpy.ops.mesh.primitive_torus_add(major_radius=0.18, minor_radius=0.025, major_segments=16, minor_segments=6, location=(x, 0.9, 0.1), rotation=(math.pi / 2, 0, 0))
    active().name = "Greed_Bag_Handle"; active().data.materials.append(cream)
bpy.ops.mesh.primitive_torus_add(major_radius=0.3, minor_radius=0.07, major_segments=20, minor_segments=8, location=(1.35, 0.72, -1.1), rotation=(math.pi / 2, 0, 0))
active().name = "Greed_Rival_Neckerchief"; active().scale.z = 0.55; active().data.materials.append(coral)
for i in range(6):
    x = 1.15 - i * 0.34; z = -0.86 - i * 0.22
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2, radius=0.08 + (0.02 if i % 2 else 0), location=(x, 0.1, z))
    active().name = f"Greed_ScentTrail_{i:02d}"; active().data.materials.append(violet)
cube("Greed_SafeExit_Plaque", (-3.4, 0.08, 0.02), (0.55, 0.03, 0.2), teal, 0.02)

bpy.ops.wm.save_as_mainfile(filepath=r"C:\Users\b\Documents\good-human-3d-pipeline\blender\environment\greed\greed_props_01.blend")
for o in bpy.data.objects:
    o.select_set(True)
bpy.ops.export_scene.gltf(filepath=r"C:\Users\b\Documents\good-human\assets\environment\territory\models\greed\greed_props.glb", export_format="GLB", use_selection=True, export_yup=True)
print("GREED_PROPS_EXPORTED", len(bpy.data.objects))
