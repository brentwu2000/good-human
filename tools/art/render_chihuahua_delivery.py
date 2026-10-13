import bpy, math
from pathlib import Path
from mathutils import Vector
OUT=Path(r'C:/Users/b/Documents/good-human/build/dog_delivery');OUT.mkdir(parents=True,exist_ok=True)
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'before_delivery.blend'))
scene=bpy.context.scene
for o in list(scene.objects):
 if o.type in {'CAMERA','LIGHT'}:
  bpy.data.objects.remove(o,do_unlink=True);continue
 if o.name.startswith('Icosphere'):o.hide_render=True
 if o.type=='ARMATURE':
  if o.animation_data:o.animation_data_clear()
  for b in o.pose.bones:b.matrix_basis.identity()
world=bpy.data.worlds.new('DeliveryNeutral');scene.world=world;world.use_nodes=True
world.node_tree.nodes['Background'].inputs[0].default_value=(.22,.22,.22,1)
world.node_tree.nodes['Background'].inputs[1].default_value=.6
for name,location,power,size in [('Key',(-.5,-.8,.8),4,.7),('Fill',(.5,-.3,.5),2,.6),('Rim',(0,.6,.6),3,.5)]:
 data=bpy.data.lights.new(name,'AREA');data.energy=power;data.shape='DISK';data.size=size
 ob=bpy.data.objects.new(name,data);scene.collection.objects.link(ob);ob.location=location
 ob.rotation_euler=(Vector((0,0,.18))-ob.location).to_track_quat('-Z','Y').to_euler()
cam=bpy.data.objects.new('DeliveryCamera',bpy.data.cameras.new('DeliveryCamera'));scene.collection.objects.link(cam);scene.camera=cam
cam.data.type='ORTHO';cam.data.ortho_scale=.43
scene.render.engine='BLENDER_EEVEE';scene.render.resolution_x=900;scene.render.resolution_y=900;scene.render.resolution_percentage=100
scene.view_settings.view_transform='AgX';scene.render.image_settings.file_format='PNG'
clay=bpy.data.materials.new('DeliveryClay');clay.diffuse_color=(.55,.55,.55,1);clay.use_nodes=True
clay.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value=(.55,.55,.55,1)
clay.node_tree.nodes['Principled BSDF'].inputs['Roughness'].default_value=.7
for mode in ['clay','paint']:
 scene.view_layers[0].material_override=clay if mode=='clay' else None
 for name,loc in [('front',(0,-1,.20)),('side',(1,0,.20)),('threequarter',(.75,-.75,.35))]:
  cam.location=loc;cam.rotation_euler=(Vector((0,0,.175))-cam.location).to_track_quat('-Z','Y').to_euler()
  scene.render.filepath=str(OUT/(mode+'_'+name+'.png'));bpy.ops.render.render(write_still=True)
scene.view_layers[0].material_override=None
print('DELIVERY_BASELINE_RENDERED')
