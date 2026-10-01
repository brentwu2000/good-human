"""Fixed Blender review views; shares handoff light/camera convention."""
import bpy,pathlib,math,sys
from mathutils import Vector
OUT=pathlib.Path(r'C:\Users\b\Documents\good-human\build\dogs_texture_codex')
F=pathlib.Path(r'C:\Users\b\Documents\good_human_stylized_factory')
argv=sys.argv[sys.argv.index('--')+1:]
for breed in argv:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    dest=OUT/breed/'renders';dest.mkdir(exist_ok=True)
    src=OUT/breed/f'{breed}_game_codex.glb'
    bpy.ops.import_scene.gltf(filepath=str(src))
    arm=next(o for o in bpy.data.objects if o.type=='ARMATURE')
    for o in list(bpy.data.objects):
        if o.type=='MESH' and o.parent is not arm:bpy.data.objects.remove(o,do_unlink=True)
    meshes=[o for o in bpy.data.objects if o.type=='MESH']
    pts=[o.matrix_world@v.co for o in meshes for v in o.data.vertices]
    lo=Vector(tuple(min(p[i] for p in pts) for i in range(3)));hi=Vector(tuple(max(p[i] for p in pts) for i in range(3)))
    c=(lo+hi)/2;size=max(hi-lo)
    sc=bpy.context.scene;sc.render.engine='BLENDER_EEVEE';sc.view_settings.view_transform='Standard'
    sc.render.resolution_x=sc.render.resolution_y=640;sc.render.resolution_percentage=100
    w=bpy.data.worlds.new('Review');sc.world=w;w.use_nodes=True
    w.node_tree.nodes['Background'].inputs[0].default_value=(1,1,1,1);w.node_tree.nodes['Background'].inputs[1].default_value=1
    sun=bpy.data.objects.new('ReviewSun',bpy.data.lights.new('ReviewSun','SUN'));sc.collection.objects.link(sun)
    sun.data.energy=2.5;sun.rotation_euler=(math.radians(50),0,math.radians(-30))
    cam=bpy.data.objects.new('ReviewCamera',bpy.data.cameras.new('ReviewCamera'));sc.collection.objects.link(cam);sc.camera=cam
    cam.data.type='ORTHO';cam.data.ortho_scale=size*1.15
    for view,angle,lift in [('front',0,.25),('34',-40,.25),('side',-90,.25),('back',180,.25),('low',-30,-.35)]:
        d=Vector((math.sin(math.radians(angle)),-math.cos(math.radians(angle)),lift)).normalized()*5
        cam.location=c+d;cam.rotation_euler=(c-cam.location).to_track_quat('-Z','Y').to_euler()
        sc.render.filepath=str(dest/f'{breed}_{view}.png');bpy.ops.render.render(write_still=True)
    # Textured side clip review, framed to this breed instead of fixed-size camera.
    cam.location=c+Vector((-5,0,.12));cam.rotation_euler=(c-cam.location).to_track_quat('-Z','Y').to_euler()
    cam.data.ortho_scale=size*1.35
    for clip in ['Idle','Walk','Sit']:
        act=bpy.data.actions.get(clip);assert act,clip
        arm.animation_data.action=act
        if hasattr(arm.animation_data,'action_slot') and len(act.slots):arm.animation_data.action_slot=act.slots[0]
        sc.frame_set(int(sum(act.frame_range)/2))
        dg=bpy.context.evaluated_depsgraph_get()
        posed=[o.matrix_world@v.co for o in meshes for v in o.evaluated_get(dg).data.vertices]
        pl=Vector(tuple(min(p[i] for p in posed) for i in range(3)));ph=Vector(tuple(max(p[i] for p in posed) for i in range(3)))
        pc=(pl+ph)/2
        cam.location=pc+Vector((-5,0,.12));cam.rotation_euler=(pc-cam.location).to_track_quat('-Z','Y').to_euler()
        cam.data.ortho_scale=max(ph-pl)*1.35
        sc.render.filepath=str(dest/f'{breed}_{clip}.png');bpy.ops.render.render(write_still=True)
    print('DOG_RENDER_COMPLETE',breed,flush=True)
