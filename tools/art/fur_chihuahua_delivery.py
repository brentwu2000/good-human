import bpy
from pathlib import Path
from mathutils import Vector
OUT=Path(r'C:/Users/b/Documents/good-human/build/dog_delivery')
body=bpy.data.objects['ChihuahuaBodyTopology'];mat=body.active_material;n=mat.node_tree.nodes;l=mat.node_tree.links
bs=n.get('Principled BSDF');original=bs.inputs['Base Color'].links[0].from_socket
geo=n.new('ShaderNodeNewGeometry');sep=n.new('ShaderNodeSeparateXYZ');l.new(geo.outputs['Position'],sep.inputs[0]);x,y,z=sep.outputs
normal=n.new('ShaderNodeSeparateXYZ');l.new(geo.outputs['Normal'],normal.inputs[0])
def m(op,a,b):
 node=n.new('ShaderNodeMath');node.operation=op
 for i,v in enumerate([a,b]):
  if isinstance(v,(float,int)):node.inputs[i].default_value=v
  else:l.new(v,node.inputs[i])
 return node.outputs[0]
def ramp(a,lo,hi):
 node=n.new('ShaderNodeMapRange');node.interpolation_type='SMOOTHSTEP';node.clamp=True;l.new(a,node.inputs['Value']);node.inputs['From Min'].default_value=lo;node.inputs['From Max'].default_value=hi
 return node.outputs[0]
uv=n.new('ShaderNodeCombineXYZ');l.new(m('DIVIDE',m('ADD',350,m('MULTIPLY',m('SUBTRACT',y,.04),900)),768),uv.inputs['X']);l.new(m('SUBTRACT',1,m('DIVIDE',m('SUBTRACT',525,m('MULTIPLY',m('SUBTRACT',z,.105),900)),768)),uv.inputs['Y'])
image=n.new('ShaderNodeTexImage');image.image=bpy.data.images.load(r'C:/Users/b/Documents/good_human_stylized_factory/references/dogs/chihuahua_side.png',check_existing=True);l.new(uv.outputs[0],image.inputs['Vector'])
mask=m('MULTIPLY',ramp(m('ABSOLUTE',normal.outputs['X'],0),.25,.65),ramp(z,.067,.10));mask=m('MULTIPLY',mask,ramp(y,-.02,.01));mask=m('MULTIPLY',mask,m('SUBTRACT',1,ramp(y,.12,.17)))
mix=n.new('ShaderNodeMixRGB');l.new(m('MULTIPLY',mask,.3),mix.inputs[0]);l.new(original,mix.inputs[1]);l.new(image.outputs['Color'],mix.inputs[2]);l.new(mix.outputs[0],bs.inputs['Base Color'])
arm=bpy.data.objects['Shiba_Rig_Delivery'];arm.animation_data.action=None
for pb in arm.pose.bones:pb.matrix_basis.identity()
scene=bpy.context.scene;scene.camera.data.ortho_scale=.5;scene.render.filepath=str(OUT/'fur_detail_candidate.png');bpy.ops.render.render(write_still=True)
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'chihuahua_material_02.blend'))
print('FUR_DETAIL_CANDIDATE')
