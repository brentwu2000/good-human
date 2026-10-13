import bpy
from pathlib import Path
from mathutils import Vector
OUT=Path(r'C:/Users/b/Documents/good-human/build/dog_delivery')
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'before_body_material.blend'))
body=bpy.data.objects['ChihuahuaBodyTopology'];mat=bpy.data.materials.new('Chihuahua_ContinuousCoat');mat.use_nodes=True
body.data.materials.clear();body.data.materials.append(mat)
n=mat.node_tree.nodes;l=mat.node_tree.links;bs=n.get('Principled BSDF');bs.inputs['Roughness'].default_value=.78
geo=n.new('ShaderNodeNewGeometry');sep=n.new('ShaderNodeSeparateXYZ');l.new(geo.outputs['Position'],sep.inputs[0]);x,y,z=sep.outputs
noise=n.new('ShaderNodeTexNoise');noise.inputs['Scale'].default_value=115;noise.inputs['Detail'].default_value=2;l.new(geo.outputs['Position'],noise.inputs['Vector'])
def m(op,a,b):
 node=n.new('ShaderNodeMath');node.operation=op
 for i,v in enumerate([a,b]):
  if isinstance(v,(float,int)):node.inputs[i].default_value=v
  else:l.new(v,node.inputs[i])
 return node.outputs[0]
def ramp(a,lo,hi):
 node=n.new('ShaderNodeMapRange');node.interpolation_type='SMOOTHSTEP';node.clamp=True;l.new(a,node.inputs['Value']);node.inputs['From Min'].default_value=lo;node.inputs['From Max'].default_value=hi
 return node.outputs[0]
jitter=m('MULTIPLY',m('SUBTRACT',noise.outputs['Fac'],.5),.006)
chest=m('MULTIPLY',m('SUBTRACT',1,ramp(m('ADD',y,jitter),-.065,-.005)),m('SUBTRACT',1,ramp(z,.13,.185)))
paws=m('SUBTRACT',1,ramp(m('ADD',z,jitter),.027,.044))
belly=m('MULTIPLY',m('SUBTRACT',1,ramp(z,.08,.12)),m('SUBTRACT',1,ramp(m('ABSOLUTE',x,0),.018,.036)))
white=m('MAXIMUM',m('MAXIMUM',chest,paws),belly)
mix=n.new('ShaderNodeMixRGB');mix.blend_type='MIX';mix.inputs[1].default_value=(.61,.305,.105,1);mix.inputs[2].default_value=(.8,.72,.59,1);l.new(white,mix.inputs[0])
fur=n.new('ShaderNodeTexNoise');fur.inputs['Scale'].default_value=1250;fur.inputs['Detail'].default_value=2
mapping=n.new('ShaderNodeVectorMath');mapping.operation='MULTIPLY';mapping.inputs[1].default_value=(1,1,0.18);l.new(geo.outputs['Position'],mapping.inputs[0]);l.new(mapping.outputs[0],fur.inputs['Vector'])
shade=n.new('ShaderNodeMixRGB');shade.blend_type='MULTIPLY';shade.inputs[0].default_value=.14;l.new(mix.outputs[0],shade.inputs[1]);l.new(fur.outputs['Fac'],shade.inputs[2]);l.new(shade.outputs[0],bs.inputs['Base Color'])
bump=n.new('ShaderNodeBump');bump.inputs['Strength'].default_value=.18;bump.inputs['Distance'].default_value=.00012;l.new(fur.outputs['Fac'],bump.inputs['Height']);l.new(bump.outputs[0],bs.inputs['Normal'])
# Prepare a real UV atlas and portable color texture; retain editable procedural nodes.
bpy.ops.object.select_all(action='DESELECT');body.select_set(True);bpy.context.view_layer.objects.active=body
bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT');bpy.ops.uv.smart_project(angle_limit=1.0,island_margin=.02);bpy.ops.object.mode_set(mode='OBJECT')
scene=bpy.context.scene;scene.view_layers[0].material_override=None
cam=scene.camera;cam.location=(.75,-.75,.35);cam.rotation_euler=(Vector((0,.01,.175))-cam.location).to_track_quat('-Z','Y').to_euler()
scene.render.filepath=str(OUT/'body_coat_candidate.png');bpy.ops.render.render(write_still=True)
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'chihuahua_material_01.blend'))
print('COAT_MATERIAL_READY')
