"""R28 continuous local ear material over r27 geometry."""
import bpy,os
from pathlib import Path
ROOT=Path(r'C:\Users\b\Documents\good-human');OUT=ROOT/'build/poodle_ears_r28';OUT.mkdir(parents=True,exist_ok=True)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(os.environ['TEMP'],'poodle_r28_00_before.blend'))
dog=bpy.data.objects['DogBody']
ref=bpy.data.images.load(r'C:\Users\b\Documents\good_human_stylized_factory\references\dogs\poodle_front.png',check_existing=True)
for ob in [dog]+[o for o in bpy.data.objects if o.name.startswith('EarFill_R27')]:
 for mat in ob.data.materials:
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
  side=m('GREATER_THAN',x,0)
  left=m('ADD',235,m('MULTIPLY',m('ADD',x,.102),900))
  right=m('ADD',535,m('MULTIPLY',m('SUBTRACT',x,.108),900))
  px=m('ADD',m('MULTIPLY',left,m('SUBTRACT',1,side)),m('MULTIPLY',right,side))
  py=m('SUBTRACT',310,m('MULTIPLY',m('SUBTRACT',z,.340),1100))
  uv=n.new('ShaderNodeCombineXYZ');l.new(m('DIVIDE',px,768),uv.inputs['X']);l.new(m('SUBTRACT',1,m('DIVIDE',py,768)),uv.inputs['Y'])
  tex=n.new('ShaderNodeTexImage');tex.image=ref;l.new(uv.outputs[0],tex.inputs['Vector'])
  mix=n.new('ShaderNodeMixRGB');mix.name='R28_EAR_COLOR'
  if ob==dog:
   ax=m('ABSOLUTE',x)
   mask=ramp(ax,.087,.098)
   for factor in [m('SUBTRACT',1,ramp(ax,.119,.139)),ramp(z,.263,.284),m('SUBTRACT',1,ramp(z,.365,.395)),m('SUBTRACT',1,ramp(y,-.08,-.045))]:mask=m('MULTIPLY',mask,factor)
   # Keep the original flower on the left outer ear.
   dx=m('DIVIDE',m('ADD',x,.132),.025);dz=m('DIVIDE',m('SUBTRACT',z,.360),.024)
   dist=m('ADD',m('MULTIPLY',dx,dx),m('MULTIPLY',dz,dz))
   mask=m('MULTIPLY',mask,ramp(dist,.55,1.35))
   l.new(mask,mix.inputs[0])
  else:mix.inputs[0].default_value=1
  l.new(old,mix.inputs[1]);l.new(tex.outputs[0],mix.inputs[2]);l.new(mix.outputs[0],bs.inputs['Base Color'])
# Patches share their material; both use the same world-coordinate projection.
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(os.environ['TEMP'],'poodle_r28_01_projection.blend'))
print('R28_PROJECTION_READY')

