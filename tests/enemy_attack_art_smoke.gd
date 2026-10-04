extends SceneTree

const Art = preload("res://EnemyAttackArt.gd")
const Burst = preload("res://BossBurst.gd")
const CASES := [["Enemy", "enemy"], ["AshFiend", "fiend"], ["NeutralCreature", "neutral"], ["ShaftCrawler", "crawler"], ["ShaftWisp", "wisp"], ["EchoShade", "shade"], ["EchoBroodling", "broodling"], ["RootStalker", "root"]]
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)

func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_enemy_attack_art.json"
	state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	game.process_mode = Node.PROCESS_MODE_DISABLED
	var player: Player = game.get_node("Player")
	var image := Art.ATLAS.get_image()
	_check(image.has_mipmaps() and image.get_size() == Vector2i(1280, 1600), "Atlas dimensions/mipmaps")
	var hashes := {}
	for index in range(20):
		var cell := image.get_region(Rect2i(index % 4 * 320, index / 4 * 320, 320, 320))
		_check(cell.get_pixel(0, 0).a == 0 and not cell.is_invisible(), "Cell missing alpha/paint: %d" % index)
		var bounds: Rect2 = preload("res://EnemyAttackBounds.gd").CELLS[index]
		_check(bounds.size.x > 0 and bounds.size.y > 0 and Rect2(index % 4 * 320, index / 4 * 320, 320, 320).encloses(bounds), "Grounded frame escaped its cell")
		hashes[hash(cell.get_data())] = true
	_check(hashes.size() == 20, "Attack materials must be distinct")
	var room := Node2D.new()
	root.add_child(room)
	room.process_mode = Node.PROCESS_MODE_DISABLED
	for data in CASES:
		var actor: Node2D = load("res://%s.tscn" % data[0]).instantiate()
		room.add_child(actor)
		var effects := actor.get_node("AttackPresentation")
		_check(effects.style == data[1], data[0] + " identity")
		var hp: int = actor.current_health
		var shape = actor.get_node("CollisionShape2D").shape
		var properties := {}
		for property in actor.get_property_list():
			properties[property.name] = true
		if data[1] in ["crawler", "wisp", "broodling"]:
			actor.state = 1
		elif data[1] == "shade":
			actor.telegraph_remaining = 0.3
		elif data[1] == "root":
			actor.phase = "warning"
		effects._physics_process(0.016)
		if data[1] in ["crawler", "wisp", "broodling", "shade", "root"]:
			_check(effects.preparing and not effects.attacking, data[0] + " preparation")
		if data[1] in ["crawler", "wisp", "broodling"]:
			actor.state = 2
		elif data[1] == "shade":
			actor.telegraph_remaining = 0
			actor.dash_remaining = 0.3
		elif data[1] == "root":
			actor.phase = "burst"
		effects._physics_process(0.016)
		if data[1] in ["crawler", "wisp", "broodling", "shade", "root"]:
			_check(effects.attacking and not effects.preparing, data[0] + " release")
		if data[1] == "neutral":
			var before := get_nodes_in_group("boss_cosmetic_effect").size()
			_check(not actor._damage_player_if_possible(player), "Passive animal must not attack")
			_check(get_nodes_in_group("boss_cosmetic_effect").size() == before, "Passive animal emitted contact")
		else:
			effects.contact(player)
		_check(actor.current_health == hp and actor.get_node("CollisionShape2D").shape == shape, "Presentation changed combat")
		actor.hide()
		_check(not effects.attacking and not effects.preparing, "Hidden room retained attack")
		actor.free()
	for identity in ["RangedEnemy", "ShaftSentry", "AshSentry"]:
		var actor: Node2D = load("res://%s.tscn" % identity).instantiate()
		room.add_child(actor)
		actor.target_player = player
		if identity != "RangedEnemy":
			actor.zone_tier = 1
			actor.aim_direction = Vector2.LEFT
			actor._fire()
		else:
			actor._shoot_at_player()
		var count := 0
		for bolt in get_nodes_in_group("enemy_projectile"):
			if bolt.source != actor:
				continue
			count += 1
			var effect := bolt.get_node("BossProjectileArt")
			_check(effect.style == {"ShaftSentry": "sentry", "AshSentry": "ash_sentry", "RangedEnemy": "ranged"}[identity], "Projectile identity")
			_check(not bolt.get_node("Core").visible and bolt.get_node("CollisionShape2D").shape.radius == 4, "Projectile collider/core")
			if identity != "RangedEnemy":
				_check(effect.awakened and bolt.speed == 185, "Awakened fan mechanics changed")
			effect.impact()
			bolt.free()
		_check(count == (1 if identity == "RangedEnemy" else 3), "Projectile count changed")
		actor.free()
	# Finite cosmetic budget under a deliberately dense volley.
	for index in range(100):
		Burst.spawn(room, Vector2.ZERO, Color.WHITE, "contact", Vector2(12, 12), 0.18, index % 20)
	_check(get_nodes_in_group("boss_cosmetic_effect").size() <= 64, "Unbounded cosmetic effects")
	for effect in get_nodes_in_group("boss_cosmetic_effect"):
		if effect.get_script() == Burst:
			effect._process(1.0)
	await process_frame
	_check(get_nodes_in_group("boss_cosmetic_effect").is_empty(), "Effects leaked after expiry")
	room.free()
	game.free()
	state.delete_save()
	if failures.is_empty():
		print("TEST PASSED: 20 textured materials; 10 mob classes; timing, alpha, hitboxes, neutrality, fan and cleanup")
	quit(0 if failures.is_empty() else 1)
