"""Blender five-angle review, using the same setup for source and candidate."""
from pathlib import Path
import bpy,os
script=Path(r'C:\Users\b\Documents\good-human\tools\art\frenchie_side_material_r14.py')
for version,path in [('r6','assets/art_previews/dogs/candidates/r19/corgi_r6.glb'),('r19','build/corgi_face_r19/corgi.glb')]:
    source=script.read_text(encoding='utf-8-sig').replace('build/frenchie_face_r13/frenchie.glb',path).replace('frenchie_face_r14','corgi_face_r19')
    start=source.index('side=bpy.data.images.load');end=source.index('s=bpy.context.scene',start)
    source=source[:start]+source[end:]
    source=source.replace("f'shape_{deg}.png'", "f'"+version+"_{deg}.png'")
    source=source.replace('frenchie_r14_01_side_material.blend','corgi_'+version+'_review.blend')
    exec(compile(source,str(script),'exec'))
