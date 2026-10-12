import bpy,os
from pathlib import Path
OUT=Path(r'C:\Users\b\Documents\good-human\build\chihuahua_nose_r29')
dog=bpy.data.objects['DogBody'];scene=bpy.context.scene
bpy.ops.object.select_all(action='DESELECT');dog.select_set(True);bpy.context.view_layer.objects.active=dog
scene.render.engine='CYCLES';scene.cycles.device='CPU';scene.cycles.samples=1
mat=dog.data.materials[0];nt=mat.node_tree
im=bpy.data.images.new('Chihuahua_R29_body_bake',width=2048,height=2048,alpha=False)
node=nt.nodes.new('ShaderNodeTexImage');node.image=im;nt.nodes.active=node
output=next(n for n in nt.nodes if n.type=='OUTPUT_MATERIAL');emission=nt.nodes.new('ShaderNodeEmission')
nt.links.new(nt.nodes['R29_NOSE_COLOR'].outputs[0],emission.inputs['Color']);nt.links.new(emission.outputs[0],output.inputs['Surface'])
scene.render.bake.margin=12;scene.render.bake.use_clear=True
bpy.ops.object.bake(type='EMIT')
im.filepath_raw=str(OUT/'body_baked.png');im.file_format='PNG';im.save()
bs=next(n for n in nt.nodes if n.type=='BSDF_PRINCIPLED');nt.links.new(bs.outputs[0],output.inputs['Surface'])
scene.render.engine='BLENDER_EEVEE'
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(os.environ['TEMP'],'chihuahua_r29_02_baked.blend'))
print('R29_BAKE_COMPLETE')

