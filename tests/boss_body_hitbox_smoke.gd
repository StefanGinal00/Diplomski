extends "res://tests/boss_appearance_smoke.gd"
const Hurt := preload("res://CombatHurtbox.gd")
const Appearance := preload("res://BossAppearance.gd")

func _dimensions(shape: Shape2D) -> Vector2:
	if shape is RectangleShape2D: return shape.size
	if shape is CircleShape2D: return Vector2.ONE*shape.radius
	return Vector2(shape.radius,shape.height)

func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path="res://_tmp_boss_body_hitbox.json"
	state.start_new_game("normal")
	var template: Node=load("res://Game.tscn").instantiate()
	var player: Player=template.get_node("Player")
	template.remove_child(player);template.free()
	root.add_child(player)
	player.set_physics_process(false);player.test_invincible=true
	player.get_node("Camera2D").enabled=false
	var hits:=0
	var cases:=CASES.duplicate(true)
	cases.append(["AbyssWarden","abyss_warden",[],[]])
	for case_index in cases.size():
		var data: Array=cases[case_index]
		if case_index==7: state.defeated_bosses["abyss_warden"]=true
		state.set_current_room(preload("res://BossEncounterSafety.gd").ROOMS[data[1]])
		var boss: CharacterBody2D=load("res://%s.tscn"%data[0]).instantiate()
		boss.position=Vector2(1000,-2000)
		root.add_child(boss);boss.set_physics_process(false)
		boss.current_health=100;boss.max_health=100
		var navigation: CollisionShape2D=boss.get_node("CollisionShape2D")
		var navigation_size: Vector2=_dimensions(navigation.shape)
		var navigation_transform:=navigation.transform
		var hurt:=boss.get_node("CombatHurtbox")
		_check(hurt.collision_layer==2 and hurt.collision_mask==0 and not hurt.monitoring,"Hurtbox has gameplay monitoring/solid layer")
		_check(not hurt.is_processing() and not hurt.is_physics_processing(),"Hurtbox has individual processing")
		var h: float=Appearance.SCALES[data[1]]*Appearance.FRAME_BOUNDS[data[1]][0].size.y
		var foot: float=Appearance.FLOOR_OFFSETS[data[1]]
		if case_index==7: _check(boss.is_rematch,"Awakened Warden profile not tested")
		for part in ["feet","torso","head"]:
			var y: float=foot-h*(0.54 if part=="torso" else 0.9)
			if part=="feet": y=foot-12
			if data[1]=="echo_matriarch": y=-15 if part=="torso" else (-33 if part=="head" else 5)
			player.global_position=boss.global_position+Vector2(-24,y)
			player.facing_direction=1;player._update_attack_direction()
			await physics_frame;await physics_frame
			if part=="torso" and boss.has_node("ContactArea"):
				_check(boss.get_node("ContactArea").overlaps_body(player),"Central painted torso cannot contact player: "+str(data[1]))
			var before: int=boss.current_health
			player.attack_cooldown_timer.stop()
			player._try_melee_attack({"damage":1})
			_check(boss.current_health==before-1,"Sword misses/double-hits %s/%s"%[data[1],part]);hits+=1
			for weapon in ["PlayerArrow","PlayerMagicProjectile"]:
				var shot: Area2D=load("res://%s.tscn"%weapon).instantiate()
				root.add_child(shot);shot.set_physics_process(false)
				shot.global_position=boss.global_position+Vector2(-115,y)
				if weapon=="PlayerArrow": shot.setup(Vector2.RIGHT,player)
				else: shot.setup(Vector2.RIGHT,player,"arc_bolt",0,"apprentice_staff",1)
				before=boss.current_health
				await physics_frame;await physics_frame
				preload("res://ProjectileTravel.gd").advance(shot,145)
				# Repeated Area/body contacts must resolve to the same actor ID.
				shot._on_body_entered(hurt);shot._on_body_entered(boss)
				await process_frame;await process_frame
				_check(boss.current_health==before-1,"Projectile misses/double-hits %s/%s/%s"%[data[1],part,weapon]);hits+=1
		_check(_dimensions(navigation.shape)==navigation_size and navigation.transform==navigation_transform,"Hitbox moved/resized navigation collider")
		_check(player.collision_mask==1,"Player walks against hurtboxes")
		boss.queue_free();await process_frame
	player.queue_free();state.delete_save()
	print("BOSS BODY HITBOX TEST ","PASSED" if failures.is_empty() else "FAILED",": ",hits," feet/torso/head sword/arrow/magic contacts across seven boss types and Awakened Warden")
	quit(0 if failures.is_empty() else 1)
