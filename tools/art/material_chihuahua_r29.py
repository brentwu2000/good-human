"""Chihuahua r29: local nose/bridge registration on immutable r6 geometry."""
import bpy,os
from pathlib import Path
ROOT=Path(r'C:\Users\b\Documents\good-human');OUT=ROOT/'build/chihuahua_nose_r29';OUT.mkdir(parents=True,exist_ok=True)
dog=bpy.data.objects['DogBody']
ref=bpy.data.images.load(r'C:\Users\b\Documents\good_human_stylized_factory\references\dogs\chihuahua_front.png',check_existing=True)
for mat in dog.data.materials:
 nt=mat.node_tree;n=nt.nodes;l=nt.links
 bs=next(a for a in n if a.type=='BSDF_PRINCIPLED');old=bs.inputs['Base Color'].links[0].from_socket
 def m(op,a,b=0):
  node=n.new('ShaderNodeMath');node.operation=op
  for i,v in enumerate([a,b]):
   if isinstance(v,(int,float)):node.inputs[i].default_value=v
   else:l.new(v,node.inputs[i])
  return node.outputs[0]
 def ramp(a,lo,hi):
  node=n.new('ShaderNodeMapRange');node.interpolation_type='SMOOTHSTEP';node.clamp=True
  l.new(a,node.inputs['Value']);node.inputs['From Min'].default_value=lo;node.inputs['From Max'].default_value=hi
  return node.outputs[0]
 geo=n.new('ShaderNodeNewGeometry');sep=n.new('ShaderNodeSeparateXYZ');l.new(geo.outputs['Position'],sep.inputs[0]);x,y,z=sep.outputs
 px=m('ADD',394,m('MULTIPLY',x,2000))
 py=m('SUBTRACT',m('SUBTRACT',285,m('MULTIPLY',m('SUBTRACT',z,.215),1800)),m('MULTIPLY',m('ADD',y,.157),700))
 uv=n.new('ShaderNodeCombineXYZ');l.new(m('DIVIDE',px,768),uv.inputs['X']);l.new(m('SUBTRACT',1,m('DIVIDE',py,768)),uv.inputs['Y'])
 tex=n.new('ShaderNodeTexImage');tex.image=ref;l.new(uv.outputs[0],tex.inputs['Vector'])
 mask=m('SUBTRACT',1,ramp(m('ABSOLUTE',x),.014,.029))
 for factor in [ramp(z,.202,.210),m('SUBTRACT',1,ramp(z,.237,.247)),m('SUBTRACT',1,ramp(y,-.100,-.085))]:mask=m('MULTIPLY',mask,factor)
 mix=n.new('ShaderNodeMixRGB');mix.name='R29_NOSE_COLOR';l.new(mask,mix.inputs[0]);l.new(old,mix.inputs[1]);l.new(tex.outputs[0],mix.inputs[2]);l.new(mix.outputs[0],bs.inputs['Base Color'])
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(os.environ['TEMP'],'chihuahua_r29_01_material.blend'))
print('R29_MATERIAL_READY')
