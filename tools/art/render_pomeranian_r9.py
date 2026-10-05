"""Background Blender visual inspection of the r9 GLB."""
import bpy,pathlib,math,os
from mathutils import Vector
r=pathlib.Path(r'C:\Users\b\Documents\good-human')
for o in list(bpy.data.objects):bpy.data.objects.remove(o,do_unlink=True)
bpy.ops.import_scene.gltf(filepath=str(r/'build/dogs_face_r9/pomeranian.glb'))
a=next(o for o in bpy.data.objects if o.type=='ARMATURE');a.data.pose_position='REST'
s=bpy.context.scene;s.render.engine='BLENDER_EEVEE';s.render.resolution_x=s.render.resolution_y=640;s.render.resolution_percentage=100;s.view_settings.view_transform='Standard'
w=bpy.data.worlds.new('Review');s.world=w;w.use_nodes=True;w.node_tree.nodes['Background'].inputs[0].default_value=(.48,.48,.48,1);w.node_tree.nodes['Background'].inputs[1].default_value=.8
sun=bpy.data.objects.new('Sun',bpy.data.lights.new('Sun','SUN'));s.collection.objects.link(sun);sun.data.energy=2;sun.rotation_euler=(.7,0,-.5)
c=bpy.data.objects.new('Camera',bpy.data.cameras.new('Camera'));s.collection.objects.link(c);s.camera=c;c.data.type='ORTHO';c.data.ortho_scale=.38*.7
t=Vector((0,-.38*.27,.38*.69))
for deg in [-45,0,45,90]:
    c.location=t+Vector((math.sin(math.radians(deg))*5,-math.cos(math.radians(deg))*5,.4));c.rotation_euler=(t-c.location).to_track_quat('-Z','Y').to_euler();s.render.filepath=str(r/'build/dogs_face_r9'/('shape_'+str(deg)+'.png'));bpy.ops.render.render(write_still=True)
for im in bpy.data.images:
    if im.source=='FILE':im.pack()
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(os.environ['TEMP'],'pomeranian_r9_01_shape.blend'))
print('R9_SHAPE_RENDER_OK')
