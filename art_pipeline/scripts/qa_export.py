"""Texturing v5, stages F + G: QA and GLB validation.

  blender -b --factory-startup --python art_pipeline/scripts/qa_export.py -- \
      --config art_pipeline/config/characters/grandma.json \
      --baked art_pipeline/assets/work/grandma_E_baked.blend \
      --export art_pipeline/assets/export/grandma.glb \
      --report art_pipeline/reports/grandma

F: fixed cameras (front/back/left/right/top/three-quarter, same light and scale).
Checks: blank/black texels inside painted UV area; ID check (every face's texture
colour at its UV centre must come from its own region's palette, compared by
region id, not by look); silhouette of the exported model against the source
(IoU per view); missing textures. Writes qa_report.json with PASS/WARN/FAIL.
G: the exported GLB is re-imported into a clean scene: skin, bones, clips,
materials (draw calls), images and their colour spaces, triangles, file size.
"""
import argparse
import json
import math
import os
import sys

import bpy
import numpy as np
from mathutils import Vector

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import inspect_asset as ia  # noqa: E402

VIEWS = (("front", 0, 0), ("back", 180, 0), ("left", 90, 0), ("right", -90, 0), ("three_quarter", 45, 0), ("top", 0, 89))


def args():
    argv = sys.argv[sys.argv.index("--") + 1:]
    p = argparse.ArgumentParser()
    for k in ("config", "baked", "export", "report"):
        p.add_argument("--" + k, required=True)
    p.add_argument("--size", type=int, default=480)
    return p.parse_args(argv)


def render_masks(path, prefix, out_dir, size):
    """Renders the six views of a GLB and returns the alpha silhouettes."""
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=path)
    for o in bpy.context.scene.objects:
        if o.type == "ARMATURE":
            o.data.pose_position = "REST"
        if o.type == "MESH" and not ia.is_character_mesh(o):
            o.hide_render = True
    meshes = [o for o in bpy.context.scene.objects if o.type == "MESH" and ia.is_character_mesh(o)]
    pts = np.array([o.matrix_world @ Vector(c) for o in meshes for c in o.bound_box])
    lo, hi = pts.min(0), pts.max(0)
    centre = Vector(((lo + hi) / 2).tolist())
    height = float(hi[2] - lo[2])
    scn = bpy.context.scene
    scn.render.engine = "BLENDER_EEVEE_NEXT" if "BLENDER_EEVEE_NEXT" in [e.identifier for e in bpy.types.RenderSettings.bl_rna.properties["engine"].enum_items] else "BLENDER_EEVEE"
    scn.render.resolution_x = scn.render.resolution_y = size
    scn.render.film_transparent = True
    scn.view_settings.view_transform = "Standard"
    scn.view_settings.exposure = 0.0
    world = bpy.data.worlds.new("neutral")
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.78, 0.78, 0.80, 1)
    scn.world = world
    for name, rot, energy in (("key", (math.radians(50), 0, math.radians(30)), 3.0), ("fill", (math.radians(60), 0, math.radians(200)), 1.2)):
        ld = bpy.data.lights.new(name, "SUN")
        ld.energy = energy
        lo_ = bpy.data.objects.new(name, ld)
        lo_.rotation_euler = rot
        scn.collection.objects.link(lo_)
    cam_d = bpy.data.cameras.new("qa")
    cam_d.type = "ORTHO"
    cam_d.ortho_scale = height * 1.12
    cam = bpy.data.objects.new("qa", cam_d)
    scn.collection.objects.link(cam)
    scn.camera = cam
    masks, files = {}, {}
    for view, yaw, pitch in VIEWS:
        t, ph = math.radians(yaw), math.radians(pitch)
        d = Vector((math.sin(t) * math.cos(ph), -math.cos(t) * math.cos(ph), math.sin(ph)))
        cam.location = centre + d * 10.0
        cam.rotation_euler = (-d).to_track_quat("-Z", "Y").to_euler()
        fp = os.path.abspath(os.path.join(out_dir, f"{prefix}_{view}.png"))
        scn.render.filepath = fp
        bpy.ops.render.render(write_still=True)
        img = bpy.data.images.load(fp)
        px = np.array(img.pixels[:], dtype=np.float32).reshape(size, size, 4)
        masks[view] = px[..., 3] > 0.5
        files[view] = fp
    return masks, files


def main():
    a = args()
    cfg = json.load(open(a.config, encoding="utf-8"))
    rep = {"stage": "F_G_qa", "checks": [], "export": os.path.abspath(a.export)}

    def check(name, status, detail):
        rep["checks"].append({"check": name, "status": status, "detail": detail})

    # ---- F1/F2 on the baked checkpoint: blank texels, ID check by region id.
    bpy.ops.wm.open_mainfile(filepath=os.path.abspath(a.baked))
    body = bpy.data.objects["Character"]
    me = body.data
    rid = np.zeros(len(me.polygons), dtype=np.int32)
    me.attributes["region_id"].data.foreach_get("value", rid)
    pb = json.load(open(os.path.join(a.report, "paint_bake.json"), encoding="utf-8"))
    pal = {r["id"]: np.array(pb["regions"][r["name"]]["palette"]) for r in cfg["regions"] if r["name"] in pb["regions"]}
    img = next(n.image for n in body.material_slots[0].material.node_tree.nodes if n.type == "TEX_IMAGE" and "basecolor" in n.image.name)
    W, H = img.size
    px = np.array(img.pixels[:], dtype=np.float32).reshape(H, W, img.channels)[..., :3]
    uv = np.array([d.uv[:] for d in me.uv_layers.active.data])
    # A boundary face may legitimately show its edge neighbour's region (paint_regions
    # resolves boundaries at texel level); anything else is a bleed.
    import bmesh
    bmw = bmesh.new()
    bmw.from_mesh(me)
    bmesh.ops.remove_doubles(bmw, verts=bmw.verts, dist=1e-5)
    bmw.faces.ensure_lookup_table()
    allowed = [{int(rid[f.index])} | {int(rid[g.index]) for e in f.edges for g in e.link_faces} for f in bmw.faces]
    bmw.free()
    bad, black = [], 0
    for f in me.polygons:
        c = uv[list(f.loop_indices)].mean(0)
        x, y = min(int(c[0] * W), W - 1), min(int(c[1] * H), H - 1)
        col = px[y, x]
        if col.sum() < 0.02:
            black += 1
        dist_own = min(np.sqrt(((pal[r] - col) ** 2).sum(1)).min() for r in allowed[f.index] if r in pal)
        if dist_own > 0.03:
            bad.append(f.index)
    share = len(bad) / len(me.polygons)
    check("blank_or_black_faces", "PASS" if black == 0 else "FAIL", f"{black} faces sample black at their UV centre")
    check("region_id_colour", "PASS" if share < 0.005 else ("WARN" if share < 0.02 else "FAIL"),
          f"{len(bad)} of {len(me.polygons)} faces ({share:.2%}) show a colour outside their own and their edge neighbours' region palettes (a bleed)")
    used = {i.name: {"size": list(i.size), "colourspace": i.colorspace_settings.name, "packed": i.packed_file is not None}
            for i in bpy.data.images if i.users and i.size[0]}
    rep["baked_images"] = used

    # ---- G: re-import the GLB into a clean scene.
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=os.path.abspath(a.export))
    arms = [o for o in bpy.context.scene.objects if o.type == "ARMATURE"]
    ms = [o for o in bpy.context.scene.objects if o.type == "MESH" and ia.is_character_mesh(o)]
    tris = sum(sum(len(p.vertices) - 2 for p in o.data.polygons) for o in ms)
    mats = sorted({s.material.name for o in ms for s in o.material_slots if s.material})
    imgs = {i.name: {"size": list(i.size), "colourspace": i.colorspace_settings.name} for i in bpy.data.images if i.size[0]}
    g = {"armatures": len(arms), "bones": len(arms[0].data.bones) if arms else 0, "actions": len(bpy.data.actions),
         "meshes": [o.name for o in ms], "skinned": all(any(m.type == "ARMATURE" for m in o.modifiers) for o in ms),
         "triangles": tris, "materials": mats, "draw_calls_estimate": sum(len(o.material_slots) for o in ms),
         "images": imgs, "file_bytes": os.path.getsize(a.export)}
    rep["glb"] = g
    exp = cfg.get("expect", {})
    check("glb_skeleton_and_clips", "PASS" if g["armatures"] == 1 and g["skinned"] and g["actions"] >= exp.get("actions", 1) else "FAIL",
          f"{g['bones']} bones, {g['actions']} actions, skinned={g['skinned']}")
    rough_ok = any("rough" in k.lower() and v["colourspace"] == "Non-Color" for k, v in imgs.items())
    base_ok = any("base" in k.lower() and v["colourspace"] == "sRGB" for k, v in imgs.items())
    check("texture_colour_spaces", "PASS" if base_ok and rough_ok else "WARN", f"base sRGB={base_ok}, roughness Non-Color={rough_ok}")
    # ---- F3: silhouettes, source vs export, six views.
    out_dir = os.path.abspath(a.report)
    m_new, f_new = render_masks(os.path.abspath(a.export), "qa_after", out_dir, a.size)
    m_old, f_old = render_masks(os.path.abspath(cfg["source"]), "qa_before", out_dir, a.size)
    ious = {v: round(float((m_new[v] & m_old[v]).sum() / max((m_new[v] | m_old[v]).sum(), 1)), 4) for v in m_new}
    worst = min(ious.values())
    check("silhouette_vs_source", "PASS" if worst > 0.98 else ("WARN" if worst > 0.95 else "FAIL"), f"IoU per view {ious}")
    rep["renders"] = {"after": f_new, "before": f_old}
    order = {"PASS": 0, "WARN": 1, "FAIL": 2}
    rep["result"] = max((c["status"] for c in rep["checks"]), key=order.get)
    json.dump(rep, open(os.path.join(a.report, "qa_report.json"), "w", encoding="utf-8"), indent=1)
    print("QA_RESULT", rep["result"], json.dumps([(c["check"], c["status"]) for c in rep["checks"]]))


if __name__ == "__main__":
    main()
