"""Blender-native side projection shared by the retained head and face patch."""
import bpy, pathlib, math, os
from mathutils import Vector
ROOT=pathlib.Path(r'C:\Users\b\Documents\good-human')
OUT=ROOT/'build/frenchie_face_r14';OUT.mkdir(parents=True,exist_ok=True)
for o in list(bpy.data.objects):bpy.data.objects.remove(o,do_unlink=True)
bpy.ops.import_scene.gltf(filepath=str(ROOT/'build/frenchie_face_r13/frenchie.glb'))
dog=next(o for o in bpy.data.objects if o.type=='MESH')
ear_ids={g.index for g in dog.vertex_groups if g.name in ['ear_L','ear_R']}
ear_attribute=dog.data.attributes.new('R14_ear_weight','FLOAT','POINT')
for vertex in dog.data.vertices:
    ear_attribute.data[vertex.index].value=sum(g.weight for g in vertex.groups if g.group in ear_ids)
next(o for o in bpy.data.objects if o.type=='ARMATURE').data.pose_position='REST'
side=bpy.data.images.load(r'C:\Users\b\Documents\good_human_stylized_factory\references\dogs\frenchie_side.png',check_existing=True)
for mat in dog.data.materials:
    nt=mat.node_tree;n=nt.nodes;l=nt.links
    bs=next(a for a in n if a.type=='BSDF_PRINCIPLED')
    original=bs.inputs['Base Color'].links[0].from_socket
    def mathnode(op,a,b=0):
        node=n.new('ShaderNodeMath');node.operation=op
        for i,v in enumerate([a,b]):
            if isinstance(v,(int,float)):node.inputs[i].default_value=v
            else:l.new(v,node.inputs[i])
        return node.outputs[0]
    def ramp(a,lo,hi):
        node=n.new('ShaderNodeMapRange');node.interpolation_type='SMOOTHSTEP';node.clamp=True
        l.new(a,node.inputs['Value']);node.inputs['From Min'].default_value=lo;node.inputs['From Max'].default_value=hi
        return node.outputs[0]
    geo=n.new('ShaderNodeNewGeometry');sep=n.new('ShaderNodeSeparateXYZ');l.new(geo.outputs['Position'],sep.inputs[0])
    x=mathnode('ADD',mathnode('DIVIDE',sep.outputs['X'],.45),.009)
    y=mathnode('DIVIDE',sep.outputs['Y'],.45);z=mathnode('DIVIDE',sep.outputs['Z'],.45)
    # Side chart excludes its eye: only fur is used outside the frontal features.
    u=mathnode('MAXIMUM',mathnode('ADD',mathnode('MULTIPLY',y,460),317),190)
    u=mathnode('DIVIDE',mathnode('MINIMUM',u,265),768)
    side_v=mathnode('MAXIMUM',mathnode('SUBTRACT',665,mathnode('MULTIPLY',z,600)),220)
    v=mathnode('DIVIDE',mathnode('SUBTRACT',768,side_v),768)
    uv=n.new('ShaderNodeCombineXYZ');l.new(u,uv.inputs['X']);l.new(v,uv.inputs['Y'])
    tex=n.new('ShaderNodeTexImage');tex.image=side;tex.extension='EXTEND';l.new(uv.outputs[0],tex.inputs['Vector'])
    mask=ramp(mathnode('ABSOLUTE',x),.125,.215)
    temple=mathnode('MULTIPLY',ramp(mathnode('ABSOLUTE',x),.055,.13),ramp(z,.745,.80))
    mask=mathnode('MAXIMUM',mask,temple)
    ear_node=n.new('ShaderNodeAttribute');ear_node.attribute_name='R14_ear_weight'
    ear=mathnode('MULTIPLY',ramp(ear_node.outputs['Fac'],.05,.65),ramp(z,.79,.88))
    for factor in [ramp(z,.44,.51),mathnode('SUBTRACT',1,ramp(z,.88,.93)),mathnode('SUBTRACT',1,ramp(y,-.035,.055)),mathnode('SUBTRACT',1,ear)]:
        mask=mathnode('MULTIPLY',mask,factor)
    mix=n.new('ShaderNodeMixRGB');mix.name='R14_SIDE_COLOR';l.new(mask,mix.inputs[0]);l.new(original,mix.inputs[1]);l.new(tex.outputs['Color'],mix.inputs[2]);l.new(mix.outputs[0],bs.inputs['Base Color'])
s=bpy.context.scene;s.render.engine='BLENDER_EEVEE';s.render.resolution_x=s.render.resolution_y=640;s.render.resolution_percentage=100;s.view_settings.view_transform='Standard'
w=bpy.data.worlds.new('R14Review');s.world=w;w.use_nodes=True;w.node_tree.nodes['Background'].inputs[0].default_value=(.48,.48,.48,1);w.node_tree.nodes['Background'].inputs[1].default_value=.8
sun=bpy.data.objects.new('Sun',bpy.data.lights.new('Sun','SUN'));s.collection.objects.link(sun);sun.data.energy=2;sun.rotation_euler=(.7,0,-.5)
c=bpy.data.objects.new('Camera',bpy.data.cameras.new('Camera'));s.collection.objects.link(c);s.camera=c;c.data.type='ORTHO';c.data.ortho_scale=.315
t=Vector((0,-.1215,.3105))
for deg in [-90,-45,0,45,90]:
    c.location=t+Vector((math.sin(math.radians(deg))*5,-math.cos(math.radians(deg))*5,.4));c.rotation_euler=(t-c.location).to_track_quat('-Z','Y').to_euler();s.render.filepath=str(OUT/f'shape_{deg}.png');bpy.ops.render.render(write_still=True)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(os.environ['TEMP'],'frenchie_r14_01_side_material.blend'))
