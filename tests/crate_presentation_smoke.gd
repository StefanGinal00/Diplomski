extends "res://tests/shaft_hollow_smoke.gd"

const CRATE := preload("res://DestructibleCrate.tscn")
const IMPACT := preload("res://ProjectileImpact.gd")
var broken := 0


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_crate_presentation_save.json"
	state.start_new_game("normal")
	for family in ["TravelCamp", "EchoGrotto", "CinderHearth", "StarfallCitadel"]:
		var room := Node2D.new()
		room.name = family
		room.position = Vector2(100, 60)
		room.scale = Vector2(1.5, 1.5)
		root.add_child(room)
		var crate = CRATE.instantiate()
		crate.max_health = 4
		crate.random_seed = 17
		room.add_child(crate)
		var art = crate.get_node("Visual")
		_check(art.family == {"TravelCamp": "travel", "EchoGrotto": "echo", "CinderHearth": "ash", "StarfallCitadel": "starfall"}[family], "Wrong family " + family)
		_check(not art.is_processing() and not art.is_physics_processing(), "Idle crate art processes every frame")
		for leaf in ["Box", "Border", "Mark"]:
			_check(not art.get_node(leaf).visible, "Legacy icon still visible")
		var collider: CollisionShape2D = crate.get_node("CollisionShape2D")
		var transform := collider.global_transform
		var rng_state: int = crate.rng.state
		crate.take_damage(0)
		crate.take_damage(-1)
		_check(crate.current_health == 4 and art.damage_fraction == 0, "Invalid hit damages crate")
		crate.take_damage(1)
		crate.take_damage(1)
		_check(crate.current_health == 2 and art.damage_fraction == 0.5, "Damage cracks missing")
		_check(crate.rng.state == rng_state, "Appearance consumed loot RNG")
		_check(collider.global_transform == transform and collider.shape.size == Vector2(24, 24) and not collider.disabled, "Hit changes collision")
		for tick in range(20):
			await process_frame
		_check(art.modulate.is_equal_approx(Color.WHITE), "Repeated hits leave flash stuck")
		# Same path used by WorldPopulation snapshot restore, without a hit.
		crate.current_health = 1
		_check(art.damage_fraction == 0.75 and art.modulate == Color.WHITE, "Restored health does not restore cracks quietly")
		crate.current_health = 4
		_check(art.damage_fraction == 0, "Fresh health keeps old cracks")
		room.queue_free()
		await process_frame
	# Compare exactly with the original loot algorithm, including empty drops.
	var layout = load("res://WorldLayout.gd")
	for room_id in layout.ROOM_NODES:
		var room := Node2D.new()
		room.name = layout.ROOM_NODES[room_id]
		root.add_child(room)
		var crate = CRATE.instantiate()
		room.add_child(crate)
		var expected_family := "starfall" if String(room_id).begins_with("starfall_") else ("ash" if String(room_id).begins_with("ash_") else "echo")
		_check(crate.get_node("Visual").family == expected_family, "Wrong mapped biome: " + room_id)
		room.free()
	for sample in range(32):
		var host := Node2D.new()
		root.add_child(host)
		var crate = CRATE.instantiate()
		crate.random_seed = sample + 1
		crate.empty_drop_chance = 1.0 if sample == 0 else (0.0 if sample < 3 else 0.3)
		crate.item_drop_chance = 1.0 if sample == 1 else (0.0 if sample == 2 else 0.5)
		crate.position = Vector2(80, 40)
		host.add_child(crate)
		crate.destroyed.connect(func(): broken += 1)
		var oracle := RandomNumberGenerator.new()
		oracle.seed = sample + 1
		var expected := "empty"
		var gold := 0
		var item := ""
		if oracle.randf() >= crate.empty_drop_chance:
			if oracle.randf() < crate.item_drop_chance:
				expected = "item_pickup"
				item = crate.common_item_ids[oracle.randi_range(0, crate.common_item_ids.size() - 1)]
			else:
				expected = "gold_pickup"
				gold = oracle.randi_range(crate.min_gold, crate.max_gold)
		crate.take_damage(1)
		crate.take_damage(99)
		crate.take_damage(99)
		_check(broken == sample + 1 and crate.rng.state == oracle.state, "Destruction duplicated or loot RNG changed")
		var bursts := get_nodes_in_group(IMPACT.GROUP)
		_check(bursts.size() == 1, "Crate break effect missing/duplicated")
		if bursts.size() == 1:
			var burst = bursts[0]
			burst.set_process(false)
			_check(burst.style == "crate_break" and burst.global_position == Vector2(80, 40), "Break effect misaligned")
			_check(not burst is CollisionObject2D and burst.get_child_count() == 0, "Debris adds physical objects")
		await process_frame
		var drops := get_nodes_in_group("gold_pickup") + get_nodes_in_group("item_pickup")
		_check(drops.size() == (0 if expected == "empty" else 1), "Wrong drop count")
		if drops.size() == 1:
			_check(drops[0].is_in_group(expected), "Wrong drop kind")
			_check(drops[0].get("gold_value" if expected == "gold_pickup" else "item_id") == (gold if expected == "gold_pickup" else item), "Loot value changed")
		if bursts.size() == 1:
			bursts[0]._process(IMPACT.DURATION + 0.01)
			_check(bursts[0].is_queued_for_deletion(), "Debris never expires")
		host.queue_free()
		await process_frame
	state.delete_save()
	if failures.is_empty():
		print("CRATE PRESENTATION TEST PASSED: four styles, damage/restore, unchanged collision, repeated hit flash, 32 deterministic loot cases, dedup and debris expiry")
		quit(0)
	else:
		quit(1)
