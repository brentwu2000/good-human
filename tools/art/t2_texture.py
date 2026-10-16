"""Trellis2 texture pass, step 2: multi-view texture, colours baked on vertices (no nvdiffrast rasterising).
  <trellis2 venv python> tools/art/t2_texture.py <mesh.glb> <out.npz> front=<png> [back=<png>]
                   [--guidance 3.0] [--steps 25] [--res 1024]
Guidance 3.0: the extension's default 1.0 lets the colours drift (LESSONS 6.23).
Writes positions in the input GLB's own space plus RGB per vertex.
Runs in the Modly Trellis2 extension venv (C:/Users/b/tools/modly). Claude, 2026-10-17."""
import sys, time
from pathlib import Path
import numpy as np
from PIL import Image

MODLY = Path(r"C:\Users\b\tools\modly")
sys.path.insert(0, str(MODLY / "modly" / "api"))
sys.path.insert(0, str(MODLY / "data" / "extensions" / "trellis2"))
from generator import Trellis2GGUFGenerator  # noqa: E402

args = sys.argv[1:]
mesh_path, out = Path(args[0]), Path(args[1])
opts = {"guidance": 3.0, "steps": 25, "res": 1024}
views = {}
i = 2
while i < len(args):
    a = args[i]
    if a.startswith("--"): opts[a[2:]] = args[i + 1]; i += 1
    else:
        k, v = a.split("=", 1); views[k] = v
    i += 1
if out.exists():
    sys.exit(f"refusing to overwrite {out}")

g = Trellis2GGUFGenerator(MODLY / "data" / "models" / "trellis2" / "refine", out.parent / "trellis2_work" / "Agent")
g.hf_repo = "Aero-Ex/Trellis2-GGUF"
g.load()
pipe = g._model

def fit(im, ratio=0.85, size=1024):
    """Re-frame on the non-white subject: a near-white sheet background (grandma) survives
    background removal and the subject stays small (37 % of the frame), losing colour."""
    a = np.asarray(im.convert("RGB")).astype(int)
    ys, xs = np.nonzero(np.abs(a - 255).sum(-1) > 30)
    y0, y1, x0, x1 = ys.min(), ys.max(), xs.min(), xs.max()
    side = int(max(y1 - y0, x1 - x0) / ratio)
    cy, cx = (y0 + y1) // 2, (x0 + x1) // 2
    canvas = Image.new("RGB", (side, side), (255, 255, 255))
    canvas.paste(im.convert("RGB").crop((x0, y0, x1 + 1, y1 + 1)),
                 (x0 - (cx - side // 2), y0 - (cy - side // 2)))
    return canvas.resize((size, size), Image.LANCZOS)

imgs = {k: fit(g._preprocess(Path(v).read_bytes(), 0.85, force_cpu=True)) for k, v in views.items()}
for k, im in imgs.items():
    im.save(out.with_name(out.stem + f"_in_{k}.png"))

import trimesh, torch  # noqa: E402
mesh = trimesh.load(mesh_path, force="mesh", process=False)
src_v = np.asarray(mesh.vertices).copy()
# The sampler weighs "front"/"back" by the voxel grid's first axis (+X of the input) and
# "left"/"right" by the vertical one, so only front/back views are usable and the
# character (glTF front +Z) is turned to face +X: x' = z, z' = -x.
rot = np.array([[0, 0, 1], [0, 1, 0], [-1, 0, 0]], dtype=float)
mesh.vertices = src_v @ rot.T
t0 = time.time()
with torch.no_grad():
    res_mesh, _, _ = pipe.texture_mesh_multiview(
        mesh=mesh, front=imgs["front"], back=imgs.get("back"), left=None, right=None,
        seed=1, tex_slat_sampler_params={"steps": int(opts["steps"]), "guidance_strength": float(opts["guidance"])},
        resolution=int(opts["res"]), bake_on_vertices=True, front_axis="z")
print(f"[t2] texture took {time.time() - t0:.0f}s", flush=True)

# Output vertices are the normalised mesh with the pipeline's y/z swap undone:
# (v - center) * scale in the input's own axes. Map back to the input space.
rv = src_v @ rot.T
lo, hi = rv.min(0), rv.max(0)
center, scale = (lo + hi) / 2, 0.99999 / (hi - lo).max()
ov = (np.asarray(res_mesh.vertices) / scale + center) @ rot  # back to the input axes
oc = np.asarray(res_mesh.visual.vertex_colors)[:, :3]
err = np.abs(ov - src_v).max() if len(ov) == len(src_v) else float("nan")
print(f"[t2] {len(ov)} verts (input {len(src_v)}), max position error {err:.2e}")
np.savez(out, pos=ov.astype(np.float32), col=oc.astype(np.uint8))
print(f"[t2] wrote {out}")
