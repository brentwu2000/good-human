extends SceneTree
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
	var folder="res://build/dog_motion_r33/skin_preview"
	DirAccess.make_dir_recursive_absolute(folder)
	for breed in ["chihuahua"]:
		var dog=load("res://assets/art_previews/dogs/candidates/r33/models/%s.glb"%breed).instantiate()
		room.add_child(dog)
		dog.position=room.dogs[1].position
		var motion=DogModelMotion3D.new()
		room.add_child(motion)
		motion.bind(dog)
		motion.set_process(false)
		var player=motion._player
		player.remove_animation_library("m2m")
		var source=load("res://assets/art_previews/dogs/candidates/r33/m2m/%s.glb"%breed).instantiate()
		var source_player=motion._find_player(source)
		var library=source_player.get_animation_library("").duplicate(true)
		var skeleton=motion._find_skeleton(dog)
		var to_skeleton=player.get_node(player.root_node).get_path_to(skeleton)
		for cname in library.get_animation_list():
			var c=library.get_animation(cname)
			for t in c.get_track_count():
				c.track_set_path(t,NodePath("%s:%s"%[to_skeleton,c.track_get_path(t).get_concatenated_subnames()]))
		player.add_animation_library("m2m",library)
		source.free()
		player.stop()
		var height={"chihuahua":0.35,"corgi":0.42,"golden":0.85,"frenchie":0.42,"pomeranian":0.38,"poodle":0.55,"shiba":0.60}[breed]
		room.camera.projection=Camera3D.PROJECTION_ORTHOGONAL
		room.camera.size=height*1.6
		var target=dog.position+Vector3(0,height*0.55,0)
		room.camera.position=target+Vector3(1.5,0.3,1.5)
		room.camera.look_at(target)
		for clip in ["REST","m2m/M2M_Run","m2m/M2M_Fetch","m2m/M2M_Howl"]:
			if clip!="REST":
				player.play(clip)
				player.seek(player.get_animation(clip).length*0.5,true)
				player.pause()
			room.label.text=breed+" / "+clip
			for i in 8: await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(folder+"/"+breed+"_"+clip.replace("/","_")+".png")
		dog.queue_free()
		motion.queue_free()
		await process_frame
	print("DOG_TEXTURE_INSPECT_OK")
	quit()