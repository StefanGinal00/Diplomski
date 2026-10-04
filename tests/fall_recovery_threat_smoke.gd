extends "res://tests/boss_combat_presentation_smoke.gd"

class Survey extends Node:
	func _members(scope: Node) -> Array[Node]:
		var nodes: Array[Node] = []
		nodes.assign(scope.find_children("*", "", true, false))
		return nodes

func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_fall_recovery_threat.json"
	state.start_new_game("normal")
	var fixture := Node2D.new()
	fixture.position = Vector2(12000, -5000)
	var template: Node = load("res://Game.tscn").instantiate()
	var player: Player = template.get_node("Player")
	template.remove_child(player); template.free()
	player.set_physics_process(false)
	player.get_node("Camera2D").enabled = false
	fixture.add_child(player)
	var survey := Survey.new()
	survey.name = "WorldPresentationFinish"
	fixture.add_child(survey)
	var boss: CharacterBody2D = load("res://AbyssWarden.tscn").instantiate()
	boss.set_physics_process(false)
	fixture.add_child(boss)
	var floor_body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	shape.shape = RectangleShape2D.new()
	shape.shape.size = Vector2(500, 12)
	floor_body.add_child(shape)
	fixture.add_child(floor_body)
	var recovery := preload("res://WorldFallRecovery.gd").new()
	fixture.add_child(recovery)
	root.add_child(fixture)
	boss.set_physics_process(false)
	var height: float = preload("res://BossAppearance.gd").SCALES.abyss_warden * preload("res://BossAppearance.gd").FRAME_BOUNDS.abyss_warden[0].size.y
	var torso_y: float = preload("res://BossAppearance.gd").FLOOR_OFFSETS.abyss_warden - height * 0.54
	var feet: float = player.player_collision.shape.size.y * 0.5
	floor_body.position.y = torso_y + feet + 6
	player.position = Vector2(22, torso_y - 0.1)
	for tick in 4: await physics_frame
	recovery.refresh_room()
	var dangerous := player.global_position
	_check(boss.get_node("ContactArea").overlaps_body(player), "Recovery fixture misses the actual painted torso contact")
	_check(not recovery.is_safe(dangerous), "Fall recovery calls the painted boss torso safe ground")
	player.position.x = 180
	await physics_frame; await physics_frame
	var clear := player.global_position
	_check(recovery.is_safe(clear), "Clear floor was rejected as a recovery point")
	recovery.safe_positions["training_passage"] = dangerous
	var health: int = player.current_health
	var respawn := player.respawn_position
	player.position = Vector2(180, 800)
	_check(recovery.recover() and player.global_position.distance_to(dangerous) > 35,
		"Recovery reused a cached point that is now occupied by a boss torso")
	_check(recovery.is_safe(player.global_position) and player.current_health == health and player.respawn_position == respawn,
		"Threat-safe recovery changed health/checkpoint or selected another unsafe point")
	fixture.free()
	state.delete_save()
	print("FALL RECOVERY THREAT TEST PASSED: actual Warden torso, stale safe point, safe fallback, unchanged health/checkpoint" if failures.is_empty() else "FALL RECOVERY THREAT TEST FAILED: " + str(failures))
	quit(0 if failures.is_empty() else 1)
