extends SceneTree
const BREEDS=["chihuahua"]
const CLIPS=["M2M_Idle","M2M_Run","M2M_Fetch","M2M_Bark","M2M_Alert","M2M_Sneak","M2M_Jump","M2M_Howl","M2M_Sit"]
func _initialize():
	_run.call_deferred()
func _run():
	var room=load("res://assets/art_previews/dogs/dog_lineup.tscn").instantiate()
	root.add_child(room)
	room.set_process(false)
	for i in 8: await process_frame
	for d in room.dogs: d.visible=false
	for s in room.find_children("*","Label3D",true,false): s.visible=false
	for p in room.players: p.stop()
	var count=0
	for version in ["before","after"]:
		var folder="res://build/dog_polish_r37/captures/"+version
		if "--runtime" in OS.get_cmdline_user_args(): folder="res://build/dog_polish_r37/runtime_captures/"+version
		DirAccess.make_dir_recursive_absolute(folder)
		for breed in BREEDS:
			if "--smoke" in OS.get_cmdline_user_args() and breed!="chihuahua": continue
			var revision={"chihuahua":29,"corgi":21,"frenchie":18,"golden":25,"pomeranian":10,"poodle":28,"shiba":23}.get(breed,0)
			var path="res://assets/art_previews/dogs/candidates/r36/%s.glb"%breed
			if version=="after" and breed=="chihuahua": path="res://assets/art_previews/dogs/candidates/r37/%s.glb"%breed
			if breed=="shiba_01":path="res://assets/characters/dog/models/shiba_01/shiba_01.glb"
			elif version=="after" and "--runtime" in OS.get_cmdline_user_args(): path="res://assets/characters/dog/models/breeds/%s.glb"%breed
			var dog=load(path).instantiate()
			room.add_child(dog)
			dog.position=room.dogs[1].position
			var motion=DogModelMotion3D.new()
			room.add_child(motion)
			motion.bind(dog)
			motion.set_process(false)
			var player=motion._player
			player.stop()
			player.remove_animation_library("m2m")
			var motion_path="res://assets/art_previews/dogs/candidates/r34/m2m/%s.glb"%breed if version=="after" else "res://assets/art_previews/dogs/candidates/r34/m2m/%s.glb"%breed
			if version=="after" and "--runtime" in OS.get_cmdline_user_args(): motion_path="res://assets/characters/dog/animations/m2m/%s.glb"%breed
			var source=load(motion_path).instantiate()
			var library=motion._find_player(source).get_animation_library("").duplicate(true)
			var to_skeleton=player.get_node(player.root_node).get_path_to(motion._find_skeleton(dog))
			for cname in library.get_animation_list():
				var c=library.get_animation(cname)
				for t in c.get_track_count():
					c.track_set_path(t,NodePath("%s:%s"%[to_skeleton,c.track_get_path(t).get_concatenated_subnames()]))
			player.add_animation_library("m2m",library)
			source.free()
			var height={"shiba_01":0.60,"chihuahua":0.35,"corgi":0.42,"golden":0.85,"frenchie":0.42,"pomeranian":0.38,"poodle":0.55,"shiba":0.60}[breed]
			room.camera.projection=Camera3D.PROJECTION_ORTHOGONAL
			room.camera.size=height*1.7
			var target=dog.position+Vector3(0,height*0.6,0)
			room.camera.position=target+Vector3(1.5,0.25,1.5)
			room.camera.look_at(target)
			for clip in CLIPS:
				if "--smoke" in OS.get_cmdline_user_args() and clip!="M2M_Run": continue
				for fraction in [0.0,0.25,0.5,0.75,0.99]:
					player.stop()
					motion._find_skeleton(dog).reset_bone_poses()
					player.play("m2m/"+clip,0)
					player.seek(player.get_animation("m2m/"+clip).length*fraction,true)
					player.pause()
					room.label.text=breed+" / "+version+" / "+clip+" / "+str(fraction)
					for i in 3: await process_frame
					await RenderingServer.frame_post_draw
					assert(root.get_texture().get_image().save_png(folder+"/%s_%s_%d.png"%[breed,clip,roundi(fraction*100)])==OK)
					count+=1
			dog.queue_free()
			motion.queue_free()
			await process_frame
	print("DOG_R37_CAPTURE_OK count=",count)
	quit()
