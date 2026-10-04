extends "res://tests/preview_characters.gd"
## Staged native actors in the real grotto at the project's 960x540 / 2.5 zoom.
## This is a repeatable visual review, not a recording of a complete fight.

func _render() -> void:
	root.size = Vector2i(960, 540)
	root.content_scale_size = Vector2i(960, 540)
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_combat_readability_preview.json"
	state.start_new_game("normal")
	var room: Node2D = load("res://EchoGrotto.tscn").instantiate()
	root.add_child(room)
	room.process_mode = Node.PROCESS_MODE_DISABLED
	var template: Node = load("res://Game.tscn").instantiate()
	var player: Player = template.get_node("Player")
	template.remove_child(player)
	template.free()
	root.add_child(player)
	player.process_mode = Node.PROCESS_MODE_DISABLED
	player.get_node("Camera2D").enabled = false
	player.position = Vector2(480, 148)
	player.get_node("Appearance")._apply_pose(0, false, false)
	root.canvas_transform = Transform2D(Vector2(2.5, 0), Vector2(0, 2.5), Vector2(480, 270) - Vector2(470, 82) * 2.5)
	var actors: Array[Node2D] = []
	for entry in [["RootStalker", 355], ["Enemy", 433], ["AshFiend", 524], ["ShaftSentry", 607]]:
		var actor: Node2D = load("res://%s.tscn" % entry[0]).instantiate()
		room.add_child(actor)
		var shape := actor.get_node("CollisionShape2D") as CollisionShape2D
		actor.position = Vector2(entry[1], 157 - shape.position.y - shape.shape.size.y * 0.5)
		actors.append(actor)
	var wisp: Node2D = load("res://ShaftWisp.tscn").instantiate()
	room.add_child(wisp)
	wisp.position = Vector2(505, 48)
	wisp.dive_direction = Vector2(-0.3, 1).normalized()
	var root_mob := actors[0]
	root_mob.target_player = player
	root_mob._begin_warning()
	actors[3].windup_remaining = 0.5
	actors[3].aim_direction = Vector2.LEFT
	actors[3]._update_warning_rays()
	actors[3].warning_ray.show()
	wisp.state = 1
	wisp.state_time = 0.48
	for actor in actors:
		actor.get_node("PaintedMobAppearance")._process(0)
	root_mob.get_node("AttackPresentation")._physics_process(0)
	wisp.get_node("AttackPresentation")._physics_process(0)
	wisp.get_node("Appearance")._apply_pose(2, wisp.dive_direction, Vector2.ONE, Color.WHITE)
	await _capture("combat_readability_warning")
	root_mob._begin_burst()
	root_mob.get_node("AttackPresentation")._physics_process(0)
	actors[1].get_node("PaintedMobAppearance").contact()
	actors[2].get_node("PaintedMobAppearance").contact()
	actors[3].windup_remaining = 0
	actors[3]._fire()
	wisp.state = 2
	wisp.get_node("AttackPresentation")._physics_process(0)
	wisp.get_node("Appearance")._apply_pose(3, wisp.dive_direction, Vector2.ONE, Color.WHITE)
	for actor in actors:
		actor.get_node("PaintedMobAppearance")._process(0)
	for index in range(6):
		preload("res://BossBurst.gd").spawn(room, Vector2(405 + index * 25, 144 - (index % 2) * 22), Color.WHITE, "contact", Vector2(13, 13), 0.18, [8, 18, 9, 10, 16, 7][index])
	await _capture("combat_readability_release")
	root_mob.get_node("AttackPresentation")._physics_process(0.3)
	actors[1].max_health = 10
	actors[1].current_health = 10
	actors[1].take_damage(1, Vector2(-80, -40))
	actors[1].get_node("PaintedMobAppearance")._process(0)
	for fx in get_nodes_in_group("boss_cosmetic_effect"):
		fx._process(0.2)
	await _capture("combat_readability_late_active")
	root_mob._begin_recovery()
	root_mob.get_node("AttackPresentation")._physics_process(0)
	root_mob.get_node("AttackPresentation")._physics_process(0.08)
	root_mob.get_node("PaintedMobAppearance")._process(0)
	await _capture("combat_readability_recovery")
	room.queue_free()
	player.queue_free()
	await process_frame
	state.delete_save()
	quit(0)
