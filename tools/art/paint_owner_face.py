"""Hand-painted face for the P-04 owner (Style Bible v1/v2, owner request).

  blender -b --factory-startup --python tools/art/paint_owner_face.py -- <in.glb> <out.glb> [--qa <png prefix>]

Run on the stylized owner (tools/art/stylize_rigged.py output):
1. Soften the sculpt: a volume-keeping smooth on the skin, away from the eyes,
   removes the realistic planes and creases (the painted texture carries the face).
2. Eyes: eyeballs ×EYE_SCALE about each eye's centre, irises darkened, so they
   read as simple dark painted eyes.
3. A painted skin texture in new UVs: clean skin, blush, brows, a soft smile
   line, a hint of nose shade — the same language as the grandma's face.
The skeleton, weights and clips are untouched (only positions within the face
mesh and its material change).
"""
import math
import os
import sys

import bmesh
import bpy
import numpy as np
from mathutils import Vector

EYE_SCALE = 1.3
SMOOTH_ITER = 14
SMOOTH_FACTOR = 0.5
TEX = 512


def args():
    a = sys.argv[sys.argv.index("--") + 1:]
    qa = a[a.index("--qa") + 1] if "--qa" in a else None
    return a[0], a[1], qa


def barycentric(p, xs, ys):
    (ax, ay), (bx, by), (cx, cy) = p
    den = (by - cy) * (ax - cx) + (cx - bx) * (ay - cy)
    if abs(den) < 1e-12:
        return None
    l1 = ((by - cy) * (xs - cx) + (cx - bx) * (ys - cy)) / den
    l2 = ((cy - ay) * (xs - cx) + (ax - cx) * (ys - cy)) / den
    return np.stack([l1, l2, 1 - l1 - l2], -1)


def main():
    src, out, qa = args()
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=src)
    arm = next(o for o in bpy.data.objects if o.type == "ARMATURE")
    for o in list(bpy.data.objects):
        if o.type == "MESH" and o.parent is not arm:
            bpy.data.objects.remove(o, do_unlink=True)
    face = bpy.data.objects["Face_Module"]
    me = face.data
    mw = face.matrix_world
    mat_idx = {m.name.split(".")[0].replace("_Vertex", ""): i for i, m in enumerate(me.materials) if m}
    skin_i = mat_idx["GH_Skin"]
    eye_is = {mat_idx[n] for n in ("GH_EyeWhite", "GH_Iris", "GH_Pupil") if n in mat_idx}

    # --- eyes -------------------------------------------------------------
    bm = bmesh.new()
    bm.from_mesh(me)
    eye_verts = {v for f in bm.faces if f.material_index in eye_is for v in f.verts}
    iris_verts = [v for f in bm.faces if f.material_index == mat_idx["GH_Iris"] for v in f.verts]
    centres = {}
    for sx in (-1, 1):
        pts = [mw @ v.co for v in eye_verts if (mw @ v.co).x * sx > 0]
        centres[sx] = sum(pts, Vector()) / len(pts)
    inv = mw.inverted()
    for v in eye_verts:
        w = mw @ v.co
        c = centres[1 if w.x > 0 else -1]
        v.co = inv @ (c + (w - c) * EYE_SCALE)
    bm.to_mesh(me)
    bm.free()
    for name in ("GH_Iris", "GH_Pupil"):
        m = me.materials[mat_idx[name]]
        mix = next(n for n in m.node_tree.nodes if n.type == "MIX")
        for i in mix.inputs:
            if i.name == "B" and getattr(i, "type", "") == "RGBA":
                i.default_value = (0.03, 0.02, 0.018, 1.0)

    # --- catchlights: a small white bead on each eye, riding the head bone ------------
    iris_pts = {sx: [mw @ v.co for v in me.vertices if (mw @ v.co).x * sx > 0] for sx in (-1, 1)}
    beads = []
    hl_mat = bpy.data.materials.new("GH_Catchlight")
    hl_mat.use_nodes = True
    hb = hl_mat.node_tree.nodes.get("Principled BSDF")
    hb.inputs["Base Color"].default_value = (1, 1, 1, 1)
    hb.inputs["Emission Color"].default_value = (1, 1, 1, 1)
    hb.inputs["Emission Strength"].default_value = 0.6
    me.materials.append(hl_mat)
    hl_i = len(me.materials) - 1
    bm = bmesh.new()
    bm.from_mesh(me)
    dl = bm.verts.layers.deform.verify()
    head_g = face.vertex_groups["head"].index
    iris_idx = mat_idx["GH_Iris"]
    for sx in (-1, 1):
        iris = [mw @ v.co for f in bm.faces if f.material_index == iris_idx for v in f.verts if (mw @ v.co).x * sx > 0]
        front_y = min(p.y for p in iris)
        c = centres[sx]
        pos = Vector((c.x - sx * 0.004, front_y - 0.002, c.z + 0.005))
        ret = bmesh.ops.create_icosphere(bm, subdivisions=1, radius=0.0038)
        for v in ret["verts"]:
            v.co = inv @ (Vector(v.co) + pos)
            v[dl][head_g] = 1.0
        for f in {f for v in ret["verts"] for f in v.link_faces}:
            f.material_index = hl_i
    bm.to_mesh(me)
    bm.free()

    # --- soften the sculpt ----------------------------------------------------
    skin_v = {v for p in me.polygons if p.material_index == skin_i for v in p.vertices}
    ey = np.array([list(c) for c in centres.values()])
    g = face.vertex_groups.new(name="_soften")
    # Open edges (the neck opening) must not move: smoothing pulled them into spikes.
    bmb = bmesh.new()
    bmb.from_mesh(me)
    edge_v = {v.index for v in bmb.verts if v.is_boundary}
    for v in bmb.verts:
        if v.index in edge_v:
            continue
    ring = set(edge_v)
    for _ in range(3):
        ring |= {n.index for v in bmb.verts if v.index in ring for e in v.link_edges for n in (e.other_vert(v),)}
    bmb.free()
    for vi in skin_v:
        if vi in ring:
            continue
        w = mw @ me.vertices[vi].co
        d = np.min(np.linalg.norm(ey - np.array(w), axis=1))
        weight = min(1.0, max(0.0, (d - 0.018) / 0.02))
        if weight > 0:
            g.add([vi], weight, "REPLACE")
    for o in bpy.context.scene.objects:
        o.select_set(o is face)
    bpy.context.view_layer.objects.active = face
    mods_before = [m.name for m in face.modifiers]
    sm = face.modifiers.new("Soften", "LAPLACIANSMOOTH")
    sm.iterations = SMOOTH_ITER
    sm.lambda_factor = SMOOTH_FACTOR
    sm.use_volume_preserve = True
    sm.vertex_group = "_soften"
    bpy.ops.object.modifier_move_to_index(modifier=sm.name, index=0)
    bpy.ops.object.modifier_apply(modifier=sm.name)
    face.vertex_groups.remove(face.vertex_groups["_soften"])

    # --- painted skin texture ---------------------------------------------------
    uv_name = "PaintUV"
    for p in me.polygons:
        p.select = p.material_index == skin_i
    uvl = me.uv_layers.new(name=uv_name)
    me.uv_layers.active = uvl
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.uv.smart_project(angle_limit=math.radians(66), island_margin=0.01)
    bpy.ops.object.mode_set(mode="OBJECT")
    # Keep only the new UV layer for export (the old one carried no texture).
    for layer in list(me.uv_layers):
        if layer.name != uv_name:
            me.uv_layers.remove(layer)
    me.calc_loop_triangles()
    co = np.array([mw @ v.co for v in me.vertices])
    nrm = np.array([(mw.to_3x3() @ t.normal).normalized()[:] for t in me.loop_triangles])
    uvs = np.array([d.uv[:] for d in me.uv_layers[uv_name].data])
    head = arm.matrix_world @ arm.data.bones["head"].head_local
    hx = (centres[1].x + centres[-1].x) / 2
    ez = (centres[1].z + centres[-1].z) / 2
    ex = abs(centres[1].x - centres[-1].x) / 2
    skin_node = me.materials[skin_i].node_tree
    mix = next(n for n in skin_node.nodes if n.type == "MIX")
    base = next(i.default_value for i in mix.inputs if i.name == "B" and getattr(i, "type", "") == "RGBA")
    skin = np.array(base[:3])
    brow = np.array([0.03, 0.02, 0.018])
    blush_c = np.array([0.62, 0.22, 0.17])
    tex = np.zeros((TEX, TEX, 3)) + skin
    for t in me.loop_triangles:
        if t.material_index != skin_i:
            continue
        uv3 = uvs[list(t.loops)] * TEX
        x0, y0 = np.floor(uv3.min(0)).astype(int)
        x1, y1 = np.ceil(uv3.max(0)).astype(int)
        x0, y0, x1, y1 = max(x0 - 1, 0), max(y0 - 1, 0), min(x1 + 1, TEX - 1), min(y1 + 1, TEX - 1)
        xs, ys = np.meshgrid(np.arange(x0, x1 + 1) + 0.5, np.arange(y0, y1 + 1) + 0.5)
        bc = barycentric(uv3, xs, ys)
        if bc is None:
            continue
        inside = (bc >= -0.08).all(-1)
        p = (bc[..., :, None] * co[list(t.vertices)][None, None]).sum(-2)
        front = nrm[t.index][1] < -0.25
        x, z = p[..., 0] - hx, p[..., 2] - ez
        col = np.broadcast_to(skin, p.shape).copy()
        if front:
            blush = np.exp(-(((np.abs(x) - ex * 1.25) / 0.014) ** 2 + ((z + 0.024) / 0.01) ** 2))
            col = col * (1 - 0.45 * blush[..., None]) + blush_c * 0.45 * blush[..., None]
            # The model has its own brows and mouth: only the blush is painted.
        region = tex[y0:y1 + 1, x0:x1 + 1]
        region[inside] = col[inside]
    img = bpy.data.images.new("owner_face_paint", TEX, TEX, alpha=False)
    # The material colours are linear; a byte image is sRGB.
    srgb = np.where(tex <= 0.0031308, tex * 12.92, 1.055 * np.power(np.clip(tex, 0, 1), 1 / 2.4) - 0.055)
    img.pixels = np.concatenate([srgb, np.ones((TEX, TEX, 1))], -1).astype(np.float32).ravel()
    img.pack()
    nt = skin_node
    bsdf = nt.nodes.get("Principled BSDF")
    tn = nt.nodes.new("ShaderNodeTexImage")
    tn.image = img
    for l in list(nt.links):
        if l.to_node == bsdf and l.to_socket.name == "Base Color":
            nt.links.remove(l)
    nt.links.new(tn.outputs["Color"], bsdf.inputs["Base Color"])
    bsdf.inputs["Roughness"].default_value = 0.9
    # Other materials on meshes that lost their UV layer: fine (no textures there).

    if arm.animation_data and bpy.data.actions.get("Idle"):
        arm.animation_data.action = bpy.data.actions["Idle"]
    for o in bpy.context.scene.objects:
        o.select_set(o.type in ("ARMATURE", "MESH"))
    bpy.ops.export_scene.gltf(filepath=out, export_format="GLB", use_selection=True,
                              export_animation_mode="ACTIONS", export_skins=True, export_image_format="AUTO")
    print("OWNER_FACE_OK", os.path.getsize(out), "eyes", [tuple(round(c, 3) for c in v) for v in centres.values()])


if __name__ == "__main__":
    main()
