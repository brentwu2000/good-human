import bpy, math, os

source = r"C:\Users\b\Documents\good-human-3d-pipeline\blender\human\p04_owner\owner_10_surface_fix.blend"
work = r"C:\Users\b\Documents\good-human-3d-pipeline\blender\human\p04_owner\owner_11_hair_fix.blend"
output = r"C:\Users\b\Documents\good-human\assets\characters\human\models\p04_owner\p04_owner_hairfix.glb"
bpy.ops.wm.open_mainfile(filepath=source)

old = bpy.data.objects.get("Hair_Module")
if old:
    old.hide_render = True
    old.hide_set(True)

hair = bpy.data.materials.get("GH_Hair") or bpy.data.materials.new("GH_Hair")
hair.diffuse_color = (0.035, 0.025, 0.02, 1.0)
hair.use_nodes = True
bs = hair.node_tree.nodes.get("Principled BSDF")
bs.inputs["Base Color"].default_value = (0.035, 0.025, 0.02, 1.0)
bs.inputs["Roughness"].default_value = 0.48

def add_cap():
    bpy.ops.mesh.primitive_uv_sphere_add(segments=24, ring_count=12, radius=0.13, location=(0.0, -0.025, 1.695))
    cap = bpy.context.view_layer.objects.active
    cap.name = "Hair_Cap_Refined"
    cap.scale = (0.9, 0.92, 0.58)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    cap.data.materials.append(hair)
    bevel = cap.modifiers.new("Soft cap", "BEVEL"); bevel.width = 0.008; bevel.segments = 2

def add_fringe(index, x, z, sx):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=16, ring_count=8, radius=0.04, location=(x, -0.135, z))
    fringe = bpy.context.view_layer.objects.active
    fringe.name = f"Hair_Fringe_{index:02d}"
    fringe.scale = (sx, 0.55, 0.75)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    fringe.data.materials.append(hair)

add_cap()
add_fringe(0, -0.07, 1.685, 1.0)
add_fringe(1, 0.0, 1.675, 1.05)
add_fringe(2, 0.07, 1.685, 0.92)

# Skin the new hair rigidly to the head bone so it follows every clip
# (head snaps, Down) instead of floating at its rest position.
rig = bpy.data.objects["OwnerSkeleton"]
for o in [o for o in bpy.data.objects if o.name.startswith(("Hair_Cap_Refined", "Hair_Fringe_"))]:
    world = o.matrix_world.copy()
    o.parent = rig
    o.matrix_world = world
    group = o.vertex_groups.new(name="head")
    group.add(list(range(len(o.data.vertices))), 1.0, "REPLACE")
    skin = o.modifiers.new("Armature", "ARMATURE")
    skin.object = rig

bpy.ops.wm.save_as_mainfile(filepath=work)
for o in bpy.data.objects:
    o.select_set(True)
bpy.ops.export_scene.gltf(filepath=output, export_format="GLB", use_selection=True, export_yup=True)
print("OWNER_HAIR_FIX_EXPORTED", output)
