import bpy,pathlib,math,sys,os
from mathutils import Vector
ROOT=pathlib.Path(r'C:\Users\b\Documents\good-human\build\dogs_face_r7')
for breed in sys.argv[sys.argv.index('--')+1:]:
    bpy.ops.wm.open_mainfile(filepath=str(ROOT/breed/'01_sockets.blend'))
    sc=bpy.context.scene
    for o in bpy.data.objects:
        if o.type=='ARMATURE':o.data.pose_position='REST'
    body=bpy.data.objects['DogBody'];pts=[body.matrix_world@v.co for v in body.data.vertices];H=max(p.z for p in pts)-min(p.z for p in pts)
    sc.render.engine='BLENDER_EEVEE';sc.render.resolution_x=sc.render.resolution_y=800;sc.render.resolution_percentage=100
    sc.view_settings.view_transform='AgX'
    w=bpy.data.worlds.new('Studio');w.use_nodes=True;w.node_tree.nodes['Background'].inputs[0].default_value=(.20,.23,.28,1);w.node_tree.nodes['Background'].inputs[1].default_value=.5;sc.world=w
    target=Vector((0,-H*.30,H*.71))
    for name,location,power,size in [('Key',(-1,-2,2),180,1.4),('Fill',(1,-1,.6),70,1.0),('Rim',(0,1,1.5),130,1.0)]:
        ob=bpy.data.objects.new(name,bpy.data.lights.new(name,'AREA'));sc.collection.objects.link(ob);ob.location=location;ob.data.energy=power;ob.data.shape='DISK';ob.data.size=size;ob.rotation_euler=(target-ob.location).to_track_quat('-Z','Y').to_euler()
    cam=bpy.data.objects.new('Camera',bpy.data.cameras.new('Camera'));sc.collection.objects.link(cam);sc.camera=cam;cam.data.type='ORTHO';cam.data.ortho_scale=H*.70
    clay=bpy.data.materials.new('Clay');clay.diffuse_color=(.35,.35,.35,1)
    dest=ROOT/breed/'studio';dest.mkdir(exist_ok=True)
    for mode in ['color','clay']:
        sc.view_layers[0].material_override=clay if mode=='clay' else None
        for angle in [-45,0,45]:
            direction=Vector((math.sin(math.radians(angle)),-math.cos(math.radians(angle)),.07));cam.location=target+direction*3;cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler()
            sc.render.filepath=str(dest/f'{mode}_{angle:+03d}.png');bpy.ops.render.render(write_still=True)
