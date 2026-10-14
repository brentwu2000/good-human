import bpy,math
from pathlib import Path
OUT=Path(r'C:/Users/b/Documents/good-human/build/dog_delivery')
h=bpy.data.objects['ChihuahuaHead'];arm=bpy.data.objects['Shiba_Rig_Delivery']
mat=h.data.materials[0];n=mat.node_tree.nodes;l=mat.node_tree.links;bs=next(n for n in n if n.type=='BSDF_PRINCIPLED');orig=bs.inputs['Base Color'].links[0].from_socket
geo=n.new('ShaderNodeNewGeometry');sep=n.new('ShaderNodeSeparateXYZ');l.new(geo.outputs['Position'],sep.inputs[0]);x,y,z=sep.outputs
rgb=n.new('ShaderNodeSeparateColor');l.new(orig,rgb.inputs[0])
def m(op,a,b=0):
 node=n.new('ShaderNodeMath');node.operation=op
 for i,v in enumerate([a,b]):
  if isinstance(v,(float,int)):node.inputs[i].default_value=v
  else:l.new(v,node.inputs[i])
 return node.outputs[0]
def ramp(a,lo,hi):
 node=n.new('ShaderNodeMapRange');node.interpolation_type='SMOOTHSTEP';node.clamp=True;l.new(a,node.inputs['Value']);node.inputs['From Min'].default_value=lo;node.inputs['From Max'].default_value=hi;return node.outputs[0]
mask=m('MULTIPLY',ramp(m('DIVIDE',rgb.outputs[0],m('MAXIMUM',rgb.outputs[1],.001)),1.5,2.2),ramp(m('ABSOLUTE',x),.031,.022))
mask=m('MULTIPLY',mask,ramp(y,-.110,-.130));mask=m('MULTIPLY',mask,ramp(z,.160,.172));mask=m('MULTIPLY',mask,ramp(z,.210,.204))
mix=n.new('ShaderNodeMixRGB');mix.inputs[2].default_value=(.008,.0015,.001,1);l.new(mask,mix.inputs[0]);l.new(orig,mix.inputs[1]);l.new(mix.outputs[0],bs.inputs['Base Color'])
# One continuous tongue surface, seated inside the existing lip contour.
bpy.ops.mesh.primitive_uv_sphere_add(segments=24,ring_count=12,location=(0,-.148,.189))
t=bpy.context.object;t.name='ChihuahuaTongue';t.scale=(.012,.004,.011);bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
for v in t.data.vertices:
 v.co.y+=.0005*math.exp(-(v.co.x/.002)**2)*max(0,min(1,(v.co.z-.182)/.012))
mat=bpy.data.materials.new('ChihuahuaTongueMat');mat.use_nodes=True;p=mat.node_tree.nodes['Principled BSDF'];p.inputs['Base Color'].default_value=(.38,.075,.085,1);p.inputs['Roughness'].default_value=.65;t.data.materials.append(mat)
for p in t.data.polygons:p.use_smooth=True
t.parent=arm;g=t.vertex_groups.new(name='jaw');g.add(list(range(len(t.data.vertices))),1,'REPLACE');t.modifiers.new('Rig','ARMATURE').object=arm
# Tongue root darkens toward the mouth; the rounded tip stays warm pink.
ns=mat.node_tree.nodes;ls=mat.node_tree.links;p=ns.get('Principled BSDF');tex=ns.new('ShaderNodeTexCoord');se=ns.new('ShaderNodeSeparateXYZ');ls.new(tex.outputs['Generated'],se.inputs[0]);r=ns.new('ShaderNodeValToRGB');r.color_ramp.elements[0].position=.1;r.color_ramp.elements[0].color=(.43,.11,.12,1);r.color_ramp.elements[1].position=.95;r.color_ramp.elements[1].color=(.15,.018,.025,1);ls.new(se.outputs['Z'],r.inputs[0]);ls.new(r.outputs['Color'],p.inputs['Base Color'])
def sm(t):
 t=max(0,min(1,t));return t*t*(3-2*t)
g=h.vertex_groups.get('jaw') or h.vertex_groups.new(name='jaw')
for v in h.data.vertices:
 x,y,z=v.co;w=.85*sm((.196-z)/.017)*sm((-y-.105)/.028)*sm((.034-abs(x))/.016)
 if w>.001:
  old=[(a.group,a.weight) for a in v.groups if a.group!=g.index]
  for idx,weight in old:h.vertex_groups[idx].add([v.index],weight*(1-w),'REPLACE')
  g.add([v.index],w,'REPLACE')
# The source fox's idle chin is closed by 38 degrees. Offset this neutral
# before transferring expression to the Chihuahua's already near-closed jaw.
from mathutils import Quaternion
for act in [a for a in bpy.data.actions if a.name.startswith('Delivery_')]:
 curves=[f for layer in act.layers for strip in layer.strips for bag in strip.channelbags for f in bag.fcurves if f.data_path=='pose.bones["jaw"].rotation_quaternion'];curves.sort(key=lambda f:f.array_index)
 if len(curves)!=4:continue
 for j in range(len(curves[0].keyframe_points)):
  q=Quaternion(tuple(f.keyframe_points[j].co.y for f in curves));e=q.to_euler();e.x=max(0,min(math.radians(22),(e.x+math.radians(38))*.7));e.y*=.3;e.z*=.3;q=e.to_quaternion()
  for i,f in enumerate(curves):f.keyframe_points[j].co.y=q[i]
 for f in curves:f.update()
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'chihuahua_mouth_weighted.blend'))
