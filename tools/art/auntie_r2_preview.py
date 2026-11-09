import bpy,math,os
from mathutils import Vector
ROOT=r'C:/Users/b/Documents/good-human';OUT=ROOT+'/build/market_auntie_refine_r2'
def preview(tag):
 s=bpy.context.scene
 for ob in list(bpy.data.objects):
  if ob.type in ('CAMERA','LIGHT'):bpy.data.objects.remove(ob,do_unlink=True)
 for ob in bpy.data.objects:
  if ob.type=='MESH' and ob.name=='Icosphere':ob.hide_render=True
 s.render.engine='CYCLES';s.cycles.samples=24;s.render.resolution_percentage=100
 s.view_settings.view_transform='AgX';s.view_settings.look='AgX - Medium High Contrast'
 w=bpy.data.worlds.new('Review');w.use_nodes=True;w.node_tree.nodes['Background'].inputs[0].default_value=(.35,.40,.47,1);w.node_tree.nodes['Background'].inputs[1].default_value=.45;s.world=w
 for loc,power,size in [((-3,-4,5),420,4),((3,-2,3),240,3),((1,3,4),330,3)]:
  d=bpy.data.lights.new('softbox','AREA');d.energy=power;d.shape='DISK';d.size=size;o=bpy.data.objects.new('softbox',d);s.collection.objects.link(o);o.location=loc;o.rotation_euler=(Vector((0,0,.8))-o.location).to_track_quat('-Z','Y').to_euler()
 d=bpy.data.cameras.new('review');d.type='ORTHO';cam=bpy.data.objects.new('review',d);s.collection.objects.link(cam);s.camera=cam
 for name,target,scale,angle in [('front',(0,0,.75),1.7,0),('quarter',(0,0,.75),1.7,40),('head',(0,-.04,1.23),.65,0),('side',(0,0,.75),1.7,90),('back',(0,0,.75),1.7,180)]:
  t=math.radians(angle);cam.location=Vector(target)+Vector((math.sin(t),-math.cos(t),0))*4;cam.rotation_euler=(Vector(target)-cam.location).to_track_quat('-Z','Y').to_euler();d.ortho_scale=scale
  s.render.resolution_x=s.render.resolution_y=768;s.render.filepath=OUT+'/'+tag+'_'+name+'.png';bpy.ops.render.render(write_still=True)
