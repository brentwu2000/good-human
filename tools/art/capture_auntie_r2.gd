extends SceneTree
var names = ["market_auntie"]
var failures: Array = []
var poses := 0
func _initialize() -> void:
 run.call_deferred()
func run() -> void:
 root.size = Vector2i(640,640)
 var world := Node3D.new()
 root.add_child(world)
 var env := WorldEnvironment.new()
 env.environment = Environment.new()
 env.environment.background_mode = Environment.BG_COLOR
 env.environment.background_color = Color(.80,.84,.88)
 env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
 env.environment.ambient_light_color = Color(.9,.9,.95)
 env.environment.ambient_light_energy = .6
 world.add_child(env)
 var sun := DirectionalLight3D.new()
 sun.rotation_degrees = Vector3(-45,25,0)
 world.add_child(sun)
 var cam := Camera3D.new()
 cam.projection = Camera3D.PROJECTION_ORTHOGONAL
 world.add_child(cam)
 cam.make_current()
 for who in names:
  var bones_before: Array = []
  var clips_before: PackedStringArray
  for phase in ["before", "after"]:
   var path = "res://assets/art_previews/humans/" + ("refine_2026_10_15/" if phase == "before" else "market_auntie_r2/") + who + ".glb"
   var packed = load(path) as PackedScene
   if packed == null:
    failures.append(path+" load failed")
    continue
   var model = packed.instantiate() as Node3D
   world.add_child(model)
   var sk = model.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
   var ap = model.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
   var bone_names: Array = []
   for b in sk.get_bone_count(): bone_names.append(sk.get_bone_name(b))
   var clips = ap.get_animation_list()
   if phase == "before":
    bones_before = bone_names
    clips_before = clips
   else:
    if bone_names != bones_before: failures.append(who+" bone contract changed")
    if clips != clips_before: failures.append(who+" clips changed")
   var aabb := AABB()
   var first := true
   for m: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
    var box = m.global_transform * m.get_aabb()
    aabb = box if first else aabb.merge(box)
    first = false
   var centre = aabb.get_center()
   var size = maxf(aabb.size.y,maxf(aabb.size.x,aabb.size.z))
   cam.size = size*1.15
   var out = "res://build/market_auntie_refine_r2"
   for view in [["front",0.0],["back",180.0],["left",90.0],["right",-90.0],["three_quarter",45.0]]:
    var t = deg_to_rad(view[1])
    cam.position = centre+Vector3(sin(t),0,cos(t))*size*3.0
    cam.look_at(centre,Vector3.UP)
    for i in 4: await process_frame
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png(out+"/godot_"+phase+"_"+view[0]+".png")
   for clip in clips:
    ap.play(clip)
    var duration = ap.get_animation(clip).length
    for step in 9:
     ap.seek(duration*float(step)/8.0,true)
     sk.force_update_all_bone_transforms()
     for b in sk.get_bone_count():
      if not sk.get_bone_global_pose(b).is_finite(): failures.append(who+" invalid pose "+clip)
     poses += 1
    if true:
     ap.seek(duration*.4,true)
     cam.position=centre+Vector3(.5,.1,1).normalized()*size*3
     cam.look_at(centre,Vector3.UP)
     for i in 4: await process_frame
     await RenderingServer.frame_post_draw
     root.get_texture().get_image().save_png(out+"/motion_"+phase+"_"+clip.replace("/","_")+".png")
   model.queue_free()
   await process_frame
 var f = FileAccess.open("res://build/market_auntie_refine_r2/godot_validation.json",FileAccess.WRITE)
 f.store_string(JSON.stringify({"failures":failures,"evaluated_poses":poses},"  "))
 print("HUMAN_REFINEMENT_VALIDATION ",poses," poses, failures=",failures)
 quit(0 if failures.is_empty() else 1)
