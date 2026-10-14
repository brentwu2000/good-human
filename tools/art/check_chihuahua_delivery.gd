extends SceneTree
const OUT = "res://build/dog_delivery/"
const CLIPS = ["Idle", "Walk", "Sit", "M2M_Run", "M2M_Sneak", "M2M_Fetch", "M2M_Bark", "M2M_Alert", "M2M_Jump", "M2M_Howl", "M2M_Sit", "M2M_Idle"]
func _initialize():
 _run.call_deferred()
func import_candidate(path):
 var doc = GLTFDocument.new()
 var state = GLTFState.new()
 assert(doc.append_from_file(path, state) == OK, path)
 return doc.generate_scene(state)
func _run():
 var runtime = "--runtime" in OS.get_cmdline_user_args()
 var folder = OUT + ("godot_runtime/" if runtime else "godot/")
 var dog = load("res://assets/characters/dog/models/breeds/chihuahua.glb").instantiate() if runtime else import_candidate(OUT + "chihuahua_candidate.glb")
 root.add_child(dog)
 var skeleton = dog.find_children("*", "Skeleton3D", true, false)[0]
 var player = dog.find_children("*", "AnimationPlayer", true, false)[0]
 assert(skeleton.get_bone_count() == 49)
 var triangles = 0
 var surfaces = 0
 var textured = 0
 for ob in dog.find_children("*", "MeshInstance3D", true, false):
  for i in ob.mesh.get_surface_count():
   var arrays = ob.mesh.surface_get_arrays(i)
   triangles += arrays[Mesh.ARRAY_INDEX].size() / 3
   surfaces += 1
   var mat = ob.get_active_material(i)
   if mat is BaseMaterial3D and mat.albedo_texture != null: textured += 1
 assert(triangles == 14969 and triangles <= 15000)
 assert(textured >= 3)
 for clip in CLIPS:
  assert(player.has_animation(clip), clip)
  player.play(clip)
  player.seek(player.get_animation(clip).length * 0.5, true)
  player.pause()
  for i in skeleton.get_bone_count(): assert(skeleton.get_bone_global_pose(i).origin.is_finite())
 var lib = load("res://assets/characters/dog/animations/m2m/chihuahua.glb").instantiate() if runtime else import_candidate(OUT + "chihuahua_m2m_candidate.glb")
 root.add_child(lib)
 var ls = lib.find_children("*", "Skeleton3D", true, false)[0]
 var lp = lib.find_children("*", "AnimationPlayer", true, false)[0]
 for i in skeleton.get_bone_count():
  var idx = ls.find_bone(skeleton.get_bone_name(i))
  assert(idx >= 0)
  assert(ls.get_bone_rest(idx).is_equal_approx(skeleton.get_bone_rest(i)))
 for clip in CLIPS:
  if clip.begins_with("M2M_"): assert(lp.has_animation(clip))
 var extra = lp.get_animation_library("").duplicate(true)
 var target_path = player.get_node(player.root_node).get_path_to(skeleton)
 for cname in extra.get_animation_list():
  var anim = extra.get_animation(cname)
  for track in anim.get_track_count():
   anim.track_set_path(track, NodePath("%s:%s" % [target_path, anim.track_get_path(track).get_concatenated_subnames()]))
 player.add_animation_library("m2m", extra)
 var motion = DogModelMotion3D.new()
 root.add_child(motion)
 motion.bind(dog)
 motion.update_motion(0.016, 5.5, true)
 assert(player.current_animation == DogModelMotion3D.RUN_CLIP)
 motion.play_sniff()
 motion.update_motion(0.016, 0, false)
 assert(player.current_animation == DogModelMotion3D.SNIFF_CLIP)
 motion._sniff_left = 0
 motion.play_bark()
 motion.update_motion(0.016, 0, false)
 assert(player.current_animation == DogModelMotion3D.BARK_CLIP)
 motion._bark_left = 0
 motion.set_alert(true)
 motion.update_motion(0.016, 0, false)
 assert(player.current_animation == DogModelMotion3D.ALERT_CLIP)
 lib.free()
 var result = {"triangles": triangles, "bones": skeleton.get_bone_count(), "surfaces": surfaces, "textured_surfaces": textured, "clips": CLIPS, "matching_library_bind_rest": true}
 var file = FileAccess.open(OUT + ("godot_runtime_check.json" if runtime else "godot_candidate_check.json"), FileAccess.WRITE)
 file.store_string(JSON.stringify(result, "  "))
 file.close()
 print("CHIHUAHUA_DELIVERY_GODOT_CHECK_OK ", JSON.stringify(result))
 if "--check" in OS.get_cmdline_user_args():
  quit()
  return
 dog.get_parent().remove_child(dog)
 var room = load("res://assets/art_previews/dogs/dog_lineup.tscn").instantiate()
 root.add_child(room)
 room.set_process(false)
 for i in 8: await process_frame
 for d in room.dogs: d.visible = false
 for p in room.players: p.stop()
 for label in room.find_children("*", "Label3D", true, false): label.visible = false
 room.add_child(dog)
 dog.position = room.dogs[1].position
 var target = dog.position + Vector3(0, 0.19, 0)
 room.camera.projection = Camera3D.PROJECTION_ORTHOGONAL
 room.camera.size = 0.56
 room.camera.position = target + Vector3(1.5, 0.3, 1.5)
 room.camera.look_at(target)
 DirAccess.make_dir_recursive_absolute(folder)
 for angle in range(0, 360, 45):
  player.play("Idle", 0)
  player.seek(0, true)
  player.pause()
  room.camera.position = target + Vector3(sin(deg_to_rad(angle)) * 1.5, 0.18, cos(deg_to_rad(angle)) * 1.5)
  room.camera.look_at(target)
  for i in 3: await process_frame
  await RenderingServer.frame_post_draw
  assert(root.get_texture().get_image().save_png(folder + "view_%03d.png" % angle) == OK)
 room.camera.position = target + Vector3(1.5, 0.3, 1.5)
 room.camera.look_at(target)
 for clip in CLIPS:
  for fraction in [0.0, 0.25, 0.5, 0.75, 0.99]:
   skeleton.reset_bone_poses()
   var playback = "m2m/" + clip if clip.begins_with("M2M_") else clip
   player.play(playback, 0)
   player.seek(player.get_animation(playback).length * fraction, true)
   player.pause()
   for i in 3: await process_frame
   await RenderingServer.frame_post_draw
   assert(root.get_texture().get_image().save_png(folder + "%s_%02d.png" % [clip, roundi(fraction * 100)]) == OK)
 print("CHIHUAHUA_DELIVERY_GODOT_CAPTURE_OK views=8 poses=60 runtime_controller=true")
 quit()
