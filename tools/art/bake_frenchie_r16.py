"""Rebake r15 geometry with a fur-only temple sampling region (Blender)."""
from pathlib import Path
import bpy, os
scripts=Path(r'C:\Users\b\Documents\good-human\tools\art')
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(os.environ['TEMP'],'frenchie_r16_00_before.blend'))
for filename in ['frenchie_side_material_r14.py','unwrap_frenchie_r14.py','bake_frenchie_r14.py']:
    source=(scripts/filename).read_text(encoding='utf-8-sig')
    source=source.replace('build/frenchie_face_r13/frenchie.glb','build/frenchie_face_r15/bake_source.glb')
    source=source.replace('r14','r16').replace('R14','R16')
    # The old sample touched the inner-ear edge of the side reference.
    source=source.replace("mathnode('MINIMUM',u,265)","mathnode('MINIMUM',u,235)")
    source=source.replace("z,600)),220)","z,600)),235)")
    source=source.replace("ramp(y,-.035,.055)","ramp(y,.04,.12)")
    source=source.replace("bpy.ops.object.bake(type='EMIT')","bpy.ops.object.bake(type='EMIT', uv_layer='R16Bake')")
    exec(compile(source,filename,'exec'))
