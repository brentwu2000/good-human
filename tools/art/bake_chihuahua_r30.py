import bpy,os
from pathlib import Path
OUT=Path(r'C:\Users\b\Documents\good-human\build\chihuahua_mouth_r30')
dog=bpy.data.objects['DogBody'];scene=bpy.context.scene
bpy.ops.object.select_all(action='DESELECT');dog.select_set(True);bpy.context.view_layer.objects.active=dog
mat=dog.active_material;nt=mat.node_tree
bs=next(n for n in nt.nodes if n.type=='BSDF_PRINCIPLED');group=bs.inputs['Base Color'].links[0].from_node
assert group.type=='GROUP' and group.node_tree.yp.is_ypaint_node
assert not group.node_tree.yp.halt_update and len(group.node_tree.yp.layers)==2
output=next(n for n in nt.nodes if n.type=='OUTPUT_MATERIAL' and n.is_active_output)
scene.render.engine='CYCLES';scene.cycles.device='CPU';scene.cycles.samples=1
im=bpy.data.images.new('Chihuahua_R30_Ucupaint_baked',width=2048,height=2048,alpha=False)
target=nt.nodes.new('ShaderNodeTexImage');target.image=im;nt.nodes.active=target
em=nt.nodes.new('ShaderNodeEmission');nt.links.new(group.outputs['Color'],em.inputs['Color']);nt.links.new(em.outputs[0],output.inputs['Surface'])
scene.render.bake.margin=12;scene.render.bake.use_clear=True;bpy.ops.object.bake(type='EMIT')
im.filepath_raw=str(OUT/'body_baked.png');im.file_format='PNG';im.save();im.pack()
nt.links.new(bs.outputs[0],output.inputs['Surface']);scene.render.engine='BLENDER_EEVEE'
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(os.environ['TEMP'],'chihuahua_r30_03_ucupaint_baked.blend'))
print('R30_UCUPAINT_BAKE_COMPLETE')
