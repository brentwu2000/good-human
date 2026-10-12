"""Blender temple chart over r15, with continuous coordinates and feature masks."""
from pathlib import Path
import bpy, os
scripts=Path(r'C:\Users\b\Documents\good-human\tools\art')
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(os.environ['TEMP'],'frenchie_r17_00_before.blend'))
source=(scripts/'frenchie_side_material_r14.py').read_text(encoding='utf-8-sig')
source=source.replace('build/frenchie_face_r13/frenchie.glb','assets/art_previews/dogs/candidates/r15/frenchie.glb').replace('r14','r17').replace('R14','R17')
start=source.index('    # Side chart')
end=source.index("    mix=n.new",start)
source=source[:start]+'''    # A separate, continuous temple chart: never clamp either texture axis.
    u=mathnode('DIVIDE',mathnode('ADD',mathnode('MULTIPLY',y,80),248),768)
    v=mathnode('DIVIDE',mathnode('SUBTRACT',768,mathnode('SUBTRACT',560,mathnode('MULTIPLY',z,400))),768)
    uv=n.new('ShaderNodeCombineXYZ');l.new(u,uv.inputs['X']);l.new(v,uv.inputs['Y'])
    tex=n.new('ShaderNodeTexImage');tex.image=side;tex.extension='EXTEND';l.new(uv.outputs[0],tex.inputs['Vector'])
    normal=n.new('ShaderNodeSeparateXYZ');l.new(geo.outputs['Normal'],normal.inputs[0])
    mask=ramp(mathnode('ABSOLUTE',x),.095,.18)
    for factor in [ramp(z,.71,.77),mathnode('SUBTRACT',1,ramp(z,.865,.935)),ramp(mathnode('ABSOLUTE',normal.outputs['X']),.35,.75),mathnode('SUBTRACT',1,ramp(y,.015,.10))]:
        mask=mathnode('MULTIPLY',mask,factor)
''' + source[end:]
exec(compile(source,'temple_r17','exec'))
for filename in ['unwrap_frenchie_r14.py','bake_frenchie_r14.py']:
    source=(scripts/filename).read_text(encoding='utf-8-sig')
    source=source.replace('build/frenchie_face_r13/frenchie.glb','assets/art_previews/dogs/candidates/r15/frenchie.glb').replace('r14','r17').replace('R14','R17')
    source=source.replace("bpy.ops.object.bake(type='EMIT')","bpy.ops.object.bake(type='EMIT', uv_layer='R17Bake')")
    exec(compile(source,filename,'exec'))
