"""Texturing v5, stage C: one named Principled BSDF per region, flat colour.

  blender -b --factory-startup --python art_pipeline/scripts/assign_materials.py -- \
      --config art_pipeline/config/characters/grandma.json \
      --regions art_pipeline/assets/work/grandma_B_regions.blend \
      --work art_pipeline/assets/work/grandma_C_materials.blend \
      --report art_pipeline/reports/grandma

Opens the stage-B checkpoint, builds `M_<region>` materials from the config
(colour, roughness by role; no texture, no AI paint), sets each face's
material_index from its `region_id`, and renders front/back/left/right/
three-quarter. Faces still at region 0 (NEEDS_REVIEW) get a magenta
`M_NEEDS_REVIEW` material: they are shown, never painted over (v5 §4: any
bleeding goes back to stage B). Saves a stage-C checkpoint; the source is untouched.
"""
import argparse
import json
import os
import sys

import bpy
import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import inspect_asset as ia  # noqa: E402


def args():
    argv = sys.argv[sys.argv.index("--") + 1:]
    p = argparse.ArgumentParser()
    for k in ("config", "regions", "work", "report"):
        p.add_argument("--" + k, required=True)
    p.add_argument("--size", type=int, default=640)
    return p.parse_args(argv)


def to_linear(c):
    """Config colours are sRGB (picked from images); Principled Base Color is linear."""
    return tuple((x / 12.92) if x <= 0.04045 else ((x + 0.055) / 1.055) ** 2.4 for x in c)


def main():
    a = args()
    cfg = json.load(open(a.config, encoding="utf-8"))
    bpy.ops.wm.open_mainfile(filepath=os.path.abspath(a.regions))
    rough = cfg.get("roughness", {})
    mats = {}
    for r in cfg["regions"]:
        m = bpy.data.materials.new(f"M_{r['name']}")
        m.use_nodes = True
        b = m.node_tree.nodes.get("Principled BSDF")
        b.inputs["Base Color"].default_value = (*to_linear(r["colour"]), 1)
        b.inputs["Roughness"].default_value = rough.get(r["role"], 0.8)
        b.inputs["Specular IOR Level"].default_value = 0.3
        b.inputs["Metallic"].default_value = 0.0
        m.diffuse_color = (*r["colour"], 1)
        mats[r["id"]] = m
    rv = bpy.data.materials.new("M_NEEDS_REVIEW")
    rv.use_nodes = True
    rv.node_tree.nodes.get("Principled BSDF").inputs["Base Color"].default_value = (1, 0, 1, 1)
    mats[0] = rv
    rep = {"stage": "C_materials", "materials": {}, "objects": {}}
    for o in [x for x in bpy.context.scene.objects if x.type == "MESH" and ia.is_character_mesh(x)]:
        me = o.data
        attr = me.attributes.get("region_id")
        if attr is None:
            sys.exit(f"ASSIGN_FAIL: {o.name} has no region_id (run stage B first)")
        rid = np.zeros(len(me.polygons), dtype=np.int32)
        attr.data.foreach_get("value", rid)
        used = sorted(set(rid.tolist()))
        me.materials.clear()
        for u in used:
            me.materials.append(mats[u])
        me.polygons.foreach_set("material_index", np.array([used.index(int(x)) for x in rid], dtype=np.int32))
        me.update()
        rep["objects"][o.name] = {mats[u].name: int((rid == u).sum()) for u in used}
    for r in cfg["regions"]:
        rep["materials"][f"M_{r['name']}"] = {"colour": r["colour"], "roughness": rough.get(r["role"], 0.8), "role": r["role"]}
    for o in bpy.context.scene.objects:
        if o.type == "ARMATURE":
            o.data.pose_position = "REST"
    for o in list(bpy.context.scene.objects):
        if o.type in ("LIGHT", "CAMERA"):
            bpy.data.objects.remove(o)
    rep["renders"] = ia.render_views(a.report, a.size, prefix="solid")
    bpy.ops.wm.save_as_mainfile(filepath=os.path.abspath(a.work))
    rep["checkpoint"] = os.path.abspath(a.work)
    with open(os.path.join(a.report, "materials.json"), "w", encoding="utf-8") as f:
        json.dump(rep, f, indent=1, ensure_ascii=False)
    print("ASSIGN_OK", rep["objects"])


if __name__ == "__main__":
    main()
