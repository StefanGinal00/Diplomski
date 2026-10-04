extends "res://tests/preview_characters.gd"
## Actual projectile/burst presenters. Material matrix, not a gameplay scene.
const Art = preload("res://EnemyAttackArt.gd")
func _render() -> void:
	root.size = Vector2i(960, 540)
	root.content_scale_size = Vector2i(960, 540)
	root.canvas_transform = Transform2D(Vector2(2.5, 0), Vector2(0, 2.5), Vector2.ZERO)
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_enemy_contacts_preview.json"
	state.start_new_game("normal")
	var host := Node2D.new()
	root.add_child(host)
	host.process_mode = Node.PROCESS_MODE_DISABLED
	var bg := Polygon2D.new()
	bg.polygon = PackedVector2Array([Vector2.ZERO, Vector2(384, 0), Vector2(384, 216), Vector2(0, 216)])
	bg.color = Color("101c29")
	bg.z_index = -5
	host.add_child(bg)
	var source := Node2D.new()
	host.add_child(source)
	var labels := CanvasLayer.new()
	root.add_child(labels)
	var shots: Array[Area2D] = []
	var index := 0
	for identity in Art.PROJECTILES:
		var origin := Vector2((index % 2) * 192, (index / 2) * 43)
		_label(labels, identity + " / R  L  NE  SW", origin * 2.5 + Vector2(10, 3), 13)
		var column := 0
		for aim in [Vector2.RIGHT, Vector2.LEFT, Vector2(1, -1).normalized(), Vector2(-1, 1).normalized()]:
			var shot: Area2D = load("res://EnemyProjectile.tscn").instantiate()
			host.add_child(shot)
			shot.position = origin + Vector2(24 + column * 45, 27)
			shot.setup(aim, source)
			var paint := shot.get_node("BossProjectileArt")
			paint.style = identity
			paint.tint = preload("res://BossCombatPresentation.gd").COLORS.get(identity, Color("e66b69"))
			if identity == "sentry": paint.tint = Color(0.22, 0.98, 0.88)
			elif identity == "ash_sentry": paint.tint = Color(1.0, 0.42, 0.14)
			paint._process(0.09)
			shots.append(shot)
			column += 1
		index += 1
	await _capture("enemy_contacts_flight")
	for shot in shots:
		shot._on_body_entered(host)
	await _capture("enemy_contacts_breakup")
	for burst in get_nodes_in_group("boss_cosmetic_effect"):
		burst._process(0.1)
	await _capture("enemy_contacts_particles")
	host.queue_free()
	labels.queue_free()
	await process_frame
	state.delete_save()
	quit(0)
