"""Run in Blender: rebuild side material and rebake against relaxed geometry."""
from pathlib import Path
scripts=Path(r'C:\Users\b\Documents\good-human\tools\art')
for filename in ['frenchie_side_material_r14.py','unwrap_frenchie_r14.py','bake_frenchie_r14.py']:
    source=(scripts/filename).read_text(encoding='utf-8-sig')
    source=source.replace('build/frenchie_face_r13/frenchie.glb','build/frenchie_face_r15/bake_source.glb')
    source=source.replace('r14','r15').replace('R14','R15')
    source=source.replace("bpy.ops.object.bake(type='EMIT')","bpy.ops.object.bake(type='EMIT', uv_layer='R15Bake')")
    exec(compile(source,filename,'exec'))
