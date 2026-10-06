"""P-05 D5W-01: the three street weapons, modelled for runtime (Claude, at the
owner's request 2026-10-06 while Codex works on the dogs).

Run headless:  blender --background --python tools/art/build_p05_weapons.py

Each weapon is built along +Z from the grip (the fist) at the origin, which
exports as glTF +Y — the axis `WeaponProp3D` holds props along — and ends
exactly where `WeaponProp3D.TIP` and the P05-08 reach calibration say:
  umbrella  closed folding umbrella, tip at 0.60 m
  broom     grass broom held halfway up the handle, head ends at 0.79 m
  dumbbell  old cast-iron dumbbell, bar across the fist (X), centre at 0.04 m
Grounded, lived-in objects (ART_DIRECTION v0.2), plain PBR materials.
"""
import bpy, bmesh, math, os, random

ROOT = r"C:\Users\b\Documents\good-human"
OUT = os.path.join(ROOT, "assets", "props", "weapons")
SOURCE = r"C:\Users\b\Documents\good-human-3d-pipeline\blender\props\weapons"
os.makedirs(OUT, exist_ok=True)
os.makedirs(SOURCE, exist_ok=True)


def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def mat(name, color, roughness=0.7, metallic=0.0):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    bs = m.node_tree.nodes.get("Principled BSDF")
    bs.inputs["Base Color"].default_value = (*color, 1)
    bs.inputs["Roughness"].default_value = roughness
    bs.inputs["Metallic"].default_value = metallic
    m.diffuse_color = (*color, 1)
    return m


def active():
    return bpy.context.view_layer.objects.active


def cylinder(name, z0, z1, radius, material, verts=16, radius_top=None, x=0.0, y=0.0):
    depth = z1 - z0
    bpy.ops.mesh.primitive_cone_add(vertices=verts, radius1=radius, radius2=radius if radius_top is None else radius_top, depth=depth, location=(x, y, z0 + depth / 2))
    o = active()
    o.name = name
    o.data.materials.append(material)
    bpy.ops.object.shade_smooth()
    return o


def smooth_bevel(o, width=0.002, segments=2):
    mod = o.modifiers.new("bevel", "BEVEL")
    mod.width = width
    mod.segments = segments
    mod.limit_method = "ANGLE"


def export(name):
    for o in bpy.data.objects:
        o.select_set(True)
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(SOURCE, name + ".blend"))
    bpy.ops.export_scene.gltf(filepath=os.path.join(OUT, name + ".glb"), export_format="GLB", use_selection=True, export_yup=True, export_apply=True)
    print("EXPORTED", name, len(bpy.data.objects))


# --- Umbrella: a closed folding umbrella -------------------------------------------
def build_umbrella():
    reset()
    rubber = mat("Umbrella_Grip_Rubber", (0.05, 0.05, 0.055), 0.85)
    metal = mat("Umbrella_Shaft_Metal", (0.62, 0.63, 0.65), 0.35, 0.85)
    fabric = mat("Umbrella_Canopy_Navy", (0.07, 0.1, 0.2), 0.8)
    strap = mat("Umbrella_Strap", (0.05, 0.07, 0.15), 0.75)
    # The grip, a little fatter in the middle, in the fist.
    grip = cylinder("Umbrella_Grip", -0.1, 0.03, 0.016, rubber, 20, 0.014)
    smooth_bevel(grip)
    cylinder("Umbrella_Collar", 0.03, 0.045, 0.011, metal, 16)
    cylinder("Umbrella_Shaft", 0.045, 0.56, 0.0055, metal, 10)
    # The furled canopy: pleated (alternate radii), widest by the runner,
    # wound in towards the top.
    bm = bmesh.new()
    rings = 14
    sides = 16
    z0, z1 = 0.11, 0.53
    verts = []
    for r in range(rings + 1):
        t = r / rings
        z = z0 + (z1 - z0) * t
        base = 0.043 * (1 - t) ** 0.8 + 0.009
        swirl = t * 1.6
        ring = []
        for s in range(sides):
            a = math.tau * s / sides + swirl
            fold = 1.0 if s % 2 == 0 else 0.78
            radius = base * fold
            ring.append(bm.verts.new((math.cos(a) * radius, math.sin(a) * radius, z)))
        verts.append(ring)
    for r in range(rings):
        for s in range(sides):
            a, b = verts[r][s], verts[r][(s + 1) % sides]
            c, d = verts[r + 1][(s + 1) % sides], verts[r + 1][s]
            bm.faces.new((a, b, c, d))
    bm.faces.new(list(reversed(verts[0])))
    bm.faces.new(verts[-1])
    mesh = bpy.data.meshes.new("Umbrella_Canopy")
    bm.to_mesh(mesh)
    bm.free()
    canopy = bpy.data.objects.new("Umbrella_Canopy", mesh)
    bpy.context.collection.objects.link(canopy)
    canopy.data.materials.append(fabric)
    for p in canopy.data.polygons:
        p.use_smooth = True
    # The strap that keeps it closed, and its snap.
    band = cylinder("Umbrella_Strap", 0.29, 0.315, 0.036, strap, 20, 0.034)
    bpy.ops.mesh.primitive_uv_sphere_add(segments=10, ring_count=6, radius=0.007, location=(0.037, 0.0, 0.302))
    active().name = "Umbrella_Snap"
    active().data.materials.append(metal)
    # The tip (ferrule).
    cylinder("Umbrella_Tip", 0.53, 0.6, 0.007, metal, 12, 0.003)
    export("umbrella")


# --- Broom: a soft grass broom, held halfway up the handle ---------------------------
def build_broom():
    reset()
    random.seed(7)
    handle_mat = mat("Broom_Handle_Bamboo", (0.62, 0.5, 0.3), 0.55)
    node_mat = mat("Broom_Handle_Node", (0.5, 0.38, 0.2), 0.6)
    tape = mat("Broom_Binding_RedTape", (0.62, 0.1, 0.08), 0.6)
    straw = mat("Broom_Bristle_Grass", (0.72, 0.62, 0.38), 0.85)
    straw_dark = mat("Broom_Bristle_Grass_Dark", (0.58, 0.48, 0.27), 0.85)
    cylinder("Broom_Handle", -0.695, 0.43, 0.0135, handle_mat, 14)
    # Bamboo nodes along the handle.
    for z in (-0.55, -0.25, 0.05, 0.3):
        cylinder("Broom_Node", z, z + 0.012, 0.0155, node_mat, 14)
    # The binding where the head is tied on.
    cylinder("Broom_Binding", 0.40, 0.47, 0.024, tape, 18, 0.03)
    cylinder("Broom_Binding_Wire", 0.455, 0.462, 0.031, node_mat, 18)
    # The head: a soft grass broom — a dense, flat fan of stems bound at the
    # neck, splaying out and a little ragged at the ends. A flattened core
    # gives it mass; the stems give it its edge.
    bm = bmesh.new()
    rows = 8
    cols = 12
    z0, z1 = 0.465, 0.735
    grid = []
    for r in range(rows + 1):
        t = r / rows
        width = 0.026 + 0.085 * (t ** 0.8)
        thick = 0.014 + 0.009 * t
        z = z0 + (z1 - z0) * t
        ring = []
        for c in range(cols):
            a = math.tau * c / cols
            ring.append(bm.verts.new((math.cos(a) * width, math.sin(a) * thick, z)))
        grid.append(ring)
    for r in range(rows):
        for c in range(cols):
            bm.faces.new((grid[r][c], grid[r][(c + 1) % cols], grid[r + 1][(c + 1) % cols], grid[r + 1][c]))
    bm.faces.new(list(reversed(grid[0])))
    bm.faces.new(grid[-1])
    core_mesh = bpy.data.meshes.new("Broom_Head_Core")
    bm.to_mesh(core_mesh)
    bm.free()
    core = bpy.data.objects.new("Broom_Head_Core", core_mesh)
    bpy.context.collection.objects.link(core)
    core.data.materials.append(straw_dark)
    for p in core.data.polygons:
        p.use_smooth = True
    for i in range(110):
        u = random.uniform(-1.0, 1.0)
        length = random.uniform(0.25, 0.33)
        bpy.ops.mesh.primitive_cylinder_add(vertices=4, radius=random.uniform(0.0022, 0.0034), depth=length)
        o = active()
        o.name = "Broom_Bristle"
        o.data.materials.append(straw if random.random() < 0.7 else straw_dark)
        lean = u * 0.42 + random.uniform(-0.04, 0.04)
        tilt = random.uniform(-0.07, 0.07)
        o.rotation_euler = (tilt, lean, 0)
        # Hinged at the neck: the centre sits half a stem out along its lean.
        o.location = (math.sin(lean) * length / 2 + u * 0.012, -math.sin(tilt) * length / 2 + random.uniform(-0.01, 0.01), 0.47 + math.cos(lean) * length / 2)
    bpy.ops.object.select_all(action="DESELECT")
    for o in bpy.data.objects:
        if o.name.startswith("Broom_Bristle"):
            o.select_set(True)
            bpy.context.view_layer.objects.active = o
    bpy.ops.object.join()
    active().name = "Broom_Bristles"
    export("broom")


# --- Dumbbell: old cast iron, bar across the fist ------------------------------------
def build_dumbbell():
    reset()
    iron = mat("Dumbbell_Iron", (0.16, 0.16, 0.17), 0.55, 0.7)
    rust = mat("Dumbbell_Plate_Worn", (0.24, 0.18, 0.14), 0.75, 0.45)
    knurl = mat("Dumbbell_Handle_Knurl", (0.4, 0.4, 0.42), 0.45, 0.85)
    y = 0.04
    def along_x(name, x0, x1, radius, material, verts=24):
        bpy.ops.mesh.primitive_cylinder_add(vertices=verts, radius=radius, depth=x1 - x0, location=((x0 + x1) / 2, 0, y), rotation=(0, math.pi / 2, 0))
        o = active()
        o.name = name
        o.data.materials.append(material)
        bpy.ops.object.shade_smooth()
        return o
    along_x("Dumbbell_Handle", -0.065, 0.065, 0.016, knurl)
    for side in (-1, 1):
        def span(a, b):
            return (a, b) if side > 0 else (-b, -a)
        along_x("Dumbbell_Collar", *span(0.065, 0.077), 0.024, iron)
        smooth_bevel(along_x("Dumbbell_Plate_Inner", *span(0.077, 0.107), 0.08, rust, 32), 0.004)
        smooth_bevel(along_x("Dumbbell_Plate_Outer", *span(0.107, 0.132), 0.07, iron, 32), 0.004)
        along_x("Dumbbell_End_Nut", *span(0.132, 0.146), 0.022, knurl, 6)
    export("old_dumbbell")


build_umbrella()
build_broom()
build_dumbbell()
print("P05_WEAPONS_DONE")
