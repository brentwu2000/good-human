import bpy
from pathlib import Path
OUT=Path(r'C:/Users/b/Documents/good-human/build/dog_delivery')
h=bpy.data.objects['ChihuahuaHead'];arm=h.parent
arm.animation_data.action=None
for pb in arm.pose.bones:pb.matrix_basis.identity()
bpy.context.view_layer.update()
mat=h.active_material;n=mat.node_tree.nodes;l=mat.node_tree.links;bs=next(n for n in n if n.type=='BSDF_PRINCIPLED');output=next(n for n in n if n.type=='OUTPUT_MATERIAL');color=bs.inputs['Base Color'].links[0].from_socket
bpy.ops.object.select_all(action='DESELECT');h.select_set(True);bpy.context.view_layer.objects.active=h
s=bpy.context.scene;s.render.engine='CYCLES';s.cycles.device='CPU';s.cycles.samples=1;s.render.bake.margin=16
im=bpy.data.images.new('ChihuahuaDeliveryHead_Albedo',width=2048,height=2048,alpha=False);target=n.new('ShaderNodeTexImage');target.image=im;n.active=target
em=n.new('ShaderNodeEmission');l.new(color,em.inputs['Color']);l.new(em.outputs[0],output.inputs['Surface']);bpy.ops.object.bake(type='EMIT');im.filepath_raw=str(OUT/'head_albedo.png');im.file_format='PNG';im.save();im.pack();l.new(bs.outputs[0],output.inputs['Surface']);l.new(target.outputs['Color'],bs.inputs['Base Color']);s.render.engine='BLENDER_EEVEE'
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'chihuahua_head_baked.blend'))
print('HEAD_BAKED')
