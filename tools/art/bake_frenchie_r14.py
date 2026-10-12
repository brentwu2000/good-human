"""Bake the continuous Blender material to existing UVs; no mesh/rig export."""
import bpy,pathlib,os
OUT=pathlib.Path(r'C:\Users\b\Documents\good-human\build\frenchie_face_r14')
dog=bpy.data.objects['DogBody'];scene=bpy.context.scene
bpy.ops.object.select_all(action='DESELECT');dog.select_set(True);bpy.context.view_layer.objects.active=dog
scene.render.engine='CYCLES';scene.cycles.device='CPU';scene.cycles.samples=1
targets=[]
for i,mat in enumerate(dog.data.materials):
    nt=mat.node_tree
    size=2048 if i==0 else 1024
    im=bpy.data.images.new(f'Frenchie_R14_baked_{i}',width=size,height=size,alpha=False)
    target=nt.nodes.new('ShaderNodeTexImage');target.image=im;nt.nodes.active=target
    output=next(n for n in nt.nodes if n.type=='OUTPUT_MATERIAL')
    emission=nt.nodes.new('ShaderNodeEmission')
    nt.links.new(nt.nodes['R14_SIDE_COLOR'].outputs[0],emission.inputs['Color'])
    nt.links.new(emission.outputs[0],output.inputs['Surface']);targets.append((im,mat,output))
scene.render.bake.margin=12;scene.render.bake.use_clear=True
bpy.ops.object.bake(type='EMIT')
for i,(im,mat,output) in enumerate(targets):
    im.filepath_raw=str(OUT/f'baked_{i}.png');im.file_format='PNG';im.save()
    bs=next(n for n in mat.node_tree.nodes if n.type=='BSDF_PRINCIPLED')
    mat.node_tree.links.new(bs.outputs[0],output.inputs['Surface'])
scene.render.engine='BLENDER_EEVEE'
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(os.environ['TEMP'],'frenchie_r14_02_baked.blend'))
print('R14_BAKE_COMPLETE')
