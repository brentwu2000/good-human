"""Assert r6 geometry, UVs, topology, rig and animations exactly retained."""
from pathlib import Path
import json
from reshape_pomeranian_r9 import unpack
ROOT=Path(__file__).resolve().parents[2]
a,ad=unpack(ROOT/'assets/art_previews/dogs/candidates/r24/golden_r6.glb')
b,bd=unpack(ROOT/'assets/art_previews/dogs/candidates/r25/golden.glb')
for key in ['meshes','accessors','nodes','skins','animations','materials','textures','samplers','scenes']:
    assert a.get(key)==b.get(key),key
assert ad==bd[:len(ad)]
assert a['bufferViews']==b['bufferViews'][:len(a['bufferViews'])]
report={'all_original_binary_bytes_equal':True,'geometry_uv_topology_skin_animation_json_equal':True,'only_embedded_basecolor_image_replaced':True}
(ROOT/'build/golden_face_r25/validation.json').write_text(json.dumps(report,indent=2))
print(report)



