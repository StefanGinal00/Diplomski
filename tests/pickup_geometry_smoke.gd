extends "res://tests/pickup_motion_smoke.gd"
## Real Area contacts, not injected reward callbacks. A collider overlap alone
## must not collect treasure through cover; an initially embedded foot must not
## drop a reward through the very floor it is meant to rest on.

func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_pickup_geometry.json"
	state.start_new_game("normal")
	player = _player()
	player.get_node("Camera2D").enabled = false
	for kind in ["GoldPickup", "XPOrb", "ItemPickup"]:
		for center_y in [198.0, 201.5]:
			player.position = Vector2(-1000, -1000)
			var floor_body := _surface(Vector2(0, 206), Vector2(240, 12))
			var pickup: Area2D = load("res://%s.tscn" % kind).instantiate()
			pickup.position = Vector2(0, center_y)
			root.add_child(pickup)
			for tick in 40: await physics_frame
			_check(is_instance_valid(pickup) and absf(pickup.position.y - 193) < 0.1 and pickup.travel.grounded,
				kind + " escaped through a partially embedded support at " + str(center_y))
			if is_instance_valid(pickup): pickup.free()
			floor_body.free()
			await physics_frame

	for kind in ["GoldPickup", "XPOrb", "ItemPickup"]:
		player.position = Vector2(10.5, 100)
		player.xp = 0
		var wall := _surface(Vector2(0, 100), Vector2(1, 100))
		var pickup: Area2D = load("res://%s.tscn" % kind).instantiate()
		pickup.position = Vector2(-2.5, 100)
		pickup.set_physics_process(false) # Keep actual overlap while testing cover.
		root.add_child(pickup)
		var before_gold: int = state.gold
		var before_item: int = state.inventory.get("healing_herb", 0)
		for tick in 20: await physics_frame
		_check(is_instance_valid(pickup) and not pickup.claimed,
			kind + " collected through a one-pixel wall by native Area overlap")
		_check(state.gold == before_gold and int(state.inventory.get("healing_herb", 0)) == before_item and player.xp == 0,
			kind + " awarded a reward across solid cover")
		wall.queue_free()
		await physics_frame
		await physics_frame
		if is_instance_valid(pickup): pickup.set_physics_process(true)
		for tick in 20: await physics_frame
		_check(not is_instance_valid(pickup), kind + " did not retry a previously blocked overlap after cover removal")
	player.free()
	state.delete_save()
	print("PICKUP GEOMETRY TEST PASSED: 6 shallow overlaps, 3 native blocked/retried contacts" if failures.is_empty() else "PICKUP GEOMETRY TEST FAILED: " + str(failures))
	quit(0 if failures.is_empty() else 1)
