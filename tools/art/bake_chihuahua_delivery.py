import bpy
from pathlib import Path
OUT=Path(r'C:/Users/b/Documents/good-human/build/dog_delivery')
body=bpy.data.objects['ChihuahuaBodyTopology'];arm=body.parent
arm.animation_data.action=None
for pb in arm.pose.bones:pb.matrix_basis.identity()
bpy.context.view_layer.update()
mat=body.active_material;nt=mat.node_tree;n=nt.nodes;l=nt.links;bs=n.get('Principled BSDF');output=n.get('Material Output');color=bs.inputs['Base Color'].links[0].from_socket
bpy.ops.object.select_all(action='DESELECT');body.select_set(True);bpy.context.view_layer.objects.active=body
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.device='CPU';scene.cycles.samples=1;scene.render.bake.margin=16
im=bpy.data.images.new('ChihuahuaBody_Albedo',width=2048,height=2048,alpha=False)
target=n.new('ShaderNodeTexImage');target.image=im;n.active=target
em=n.new('ShaderNodeEmission');l.new(color,em.inputs['Color']);l.new(em.outputs[0],output.inputs['Surface']);bpy.ops.object.bake(type='EMIT')
im.filepath_raw=str(OUT/'body_albedo.png');im.file_format='PNG';im.save();im.pack();l.new(bs.outputs[0],output.inputs['Surface'])
# Tangent normal bake freezes the fine procedural fur response in rest space.
normal=bpy.data.images.new('ChihuahuaBody_Normal',width=2048,height=2048,alpha=False);normal.colorspace_settings.name='Non-Color'
ntarget=n.new('ShaderNodeTexImage');ntarget.image=normal;n.active=ntarget
scene.render.bake.normal_space='TANGENT';bpy.ops.object.bake(type='NORMAL');normal.filepath_raw=str(OUT/'body_normal.png');normal.file_format='PNG';normal.save();normal.pack()
normalmap=n.new('ShaderNodeNormalMap');l.new(ntarget.outputs['Color'],normalmap.inputs['Color']);l.new(normalmap.outputs['Normal'],bs.inputs['Normal']);l.new(target.outputs['Color'],bs.inputs['Base Color'])
scene.render.engine='BLENDER_EEVEE'
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'chihuahua_baked_01.blend'))
print('BODY_MATERIAL_BAKED')
