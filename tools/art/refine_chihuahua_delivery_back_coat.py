import bpy
from pathlib import Path
from mathutils import Vector
OUT=Path(r'C:/Users/b/Documents/good-human/build/dog_delivery')
h=bpy.data.objects['ChihuahuaHead'];a=h.parent;a.animation_data.action=None
for p in a.pose.bones:p.matrix_basis.identity()
bpy.context.scene.frame_set(0)
mat=h.active_material;n=mat.node_tree.nodes;l=mat.node_tree.links;bs=next(n for n in n if n.type=='BSDF_PRINCIPLED');old=bs.inputs['Base Color'].links[0].from_socket
geo=n.new('ShaderNodeNewGeometry');pos=n.new('ShaderNodeSeparateXYZ');nor=n.new('ShaderNodeSeparateXYZ');l.new(geo.outputs['Position'],pos.inputs[0]);l.new(geo.outputs['Normal'],nor.inputs[0])
def ramp(sock,lo,hi):
 r=n.new('ShaderNodeMapRange');r.interpolation_type='SMOOTHSTEP';r.clamp=True;l.new(sock,r.inputs['Value']);r.inputs['From Min'].default_value=lo;r.inputs['From Max'].default_value=hi;return r.outputs[0]
weight=n.new('ShaderNodeMath');weight.operation='MULTIPLY';l.new(ramp(pos.outputs['Y'],-.065,-.028),weight.inputs[0]);l.new(ramp(nor.outputs['Y'],.05,.65),weight.inputs[1])
noise=n.new('ShaderNodeTexNoise');noise.inputs['Scale'].default_value=650;noise.inputs['Detail'].default_value=2;l.new(geo.outputs['Position'],noise.inputs['Vector']);coat=n.new('ShaderNodeMixRGB');coat.inputs[1].default_value=(.60,.30,.105,1);coat.inputs[2].default_value=(.65,.34,.135,1);l.new(noise.outputs['Fac'],coat.inputs[0])
mix=n.new('ShaderNodeMixRGB');l.new(weight.outputs[0],mix.inputs[0]);l.new(old,mix.inputs[1]);l.new(coat.outputs[0],mix.inputs[2]);l.new(mix.outputs[0],bs.inputs['Base Color'])
s=bpy.context.scene;cam=s.camera;cam.data.ortho_scale=.46;cam.location=(0,1,.25);cam.rotation_euler=(Vector((0,.02,.17))-cam.location).to_track_quat('-Z','Y').to_euler();s.render.filepath=str(OUT/'back_coat_refined.png');bpy.ops.render.render(write_still=True)
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'chihuahua_back_coat_refined.blend'))
