"""Render the exported r18 in Blender, including neutral clay review."""
from pathlib import Path
import bpy,os
script=Path(r'C:\Users\b\Documents\good-human\tools\art\frenchie_side_material_r14.py')
source=script.read_text(encoding='utf-8-sig').replace('build/frenchie_face_r13/frenchie.glb','build/frenchie_face_r18/frenchie.glb').replace('r14','r18').replace('R14','R18')
start=source.index('side=bpy.data.images.load')
end=source.index('s=bpy.context.scene',start)
source=source[:start]+source[end:]
exec(compile(source,str(script),'exec'))
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(os.environ['TEMP'],'frenchie_r18_01_geometry.blend'))
for mat in dog.data.materials:
    bs=next(n for n in mat.node_tree.nodes if n.type=='BSDF_PRINCIPLED')
    for link in list(bs.inputs['Base Color'].links):mat.node_tree.links.remove(link)
    bs.inputs['Base Color'].default_value=(.5,.5,.5,1)
for deg in [-90,90]:
    c.location=t+Vector((math.sin(math.radians(deg))*5,-math.cos(math.radians(deg))*5,.4))
    c.rotation_euler=(t-c.location).to_track_quat('-Z','Y').to_euler()
    s.render.filepath=str(OUT/f'clay_{deg}.png');bpy.ops.render.render(write_still=True)
