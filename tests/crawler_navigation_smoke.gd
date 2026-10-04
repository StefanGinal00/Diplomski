extends "res://tests/shaft_guard_combat_smoke.gd"

func _surface(host: Node, at: Vector2, size: Vector2) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.position = at
	var collision := CollisionShape2D.new()
	collision.shape = RectangleShape2D.new()
	collision.shape.size = size
	body.add_child(collision)
	host.add_child(body)
	return body

func _crawler(host: Node, at: Vector2) -> CharacterBody2D:
	var actor: CharacterBody2D = load("res://ShaftCrawler.tscn").instantiate()
	actor.position = at
	host.add_child(actor)
	return actor

func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_crawler_navigation.json"
	state.start_new_game("normal")
	player = _player()
	player.position = Vector2(2000, 80)
	var old_rate := Engine.physics_ticks_per_second
	for rate in [30, 60, 120]:
		Engine.physics_ticks_per_second = rate
		for side in [-1, 1]:
			var host := Node2D.new()
			root.add_child(host)
			_surface(host, Vector2(0,100), Vector2(500,16))
			_surface(host, Vector2(side*100,60), Vector2(12,80))
			var crawler := _crawler(host, Vector2(side*75,65))
			crawler.direction = side
			var turned := false
			for frame in range(rate*2):
				await physics_frame
				turned = turned or crawler.direction == -side
			_check(turned and side*crawler.position.x<80, "Crawler walks into wall side %d at %d Hz" % [side,rate])
			host.free()
			await process_frame
	Engine.physics_ticks_per_second = 60
	for reason in ["cover", "death", "height", "range"]:
		var host := Node2D.new()
		root.add_child(host)
		_surface(host, Vector2(0,100), Vector2(650,16))
		player.position = Vector2(100,80)
		player.is_dead = false
		var crawler := _crawler(host, Vector2(0,65))
		crawler.patrol_speed = 0
		for frame in 90:
			await physics_frame
			if crawler.state == crawler.State.WARNING: break
		_check(crawler.state == crawler.State.WARNING, "No attack warning before " + reason)
		match reason:
			"cover": _surface(host,Vector2(50,60),Vector2(12,80))
			"death": player.is_dead = true
			"height": player.position.y -= 120
			"range": player.position.x = 900
		var charged := false
		for frame in 42:
			await physics_frame
			charged = charged or crawler.state == crawler.State.CHARGE
		_check(not charged, "Crawler completed stale windup after target " + reason)
		host.free()
		await process_frame
	player.is_dead = false
	var air := Node2D.new()
	root.add_child(air)
	player.position = Vector2(70,80)
	var falling := _crawler(air, Vector2(0,65))
	falling.attack_cooldown = 0
	await physics_frame
	await physics_frame
	_check(falling.state == falling.State.PATROL, "Airborne crawler starts charge without a floor")
	air.free()
	# Tier-one follow-up charges must acquire a fresh target as well. Cover
	# appears while the initial charge is active, not before its windup.
	state.set_zone_tier("sunken_shaft", 1)
	var echo_host := Node2D.new()
	root.add_child(echo_host)
	_surface(echo_host, Vector2(0,100), Vector2(650,16))
	player.position = Vector2(130,80)
	var echo_crawler := _crawler(echo_host, Vector2(0,65))
	echo_crawler.patrol_speed = 0
	for frame in 120:
		await physics_frame
		if echo_crawler.state == echo_crawler.State.CHARGE: break
	_check(echo_crawler.state == echo_crawler.State.CHARGE, "Tier-one initial charge missing")
	_surface(echo_host,Vector2(90,60),Vector2(3,80))
	var stale_followup := false
	for frame in 50:
		await physics_frame
		stale_followup = stale_followup or echo_crawler.state == echo_crawler.State.WARNING
	_check(not stale_followup, "Tier-one crawler telegraphs a follow-up through cover")
	echo_host.free()
	player.free()
	Engine.physics_ticks_per_second = old_rate
	state.delete_save()
	print("CRAWLER NAVIGATION TEST PASSED" if failures.is_empty() else "CRAWLER NAVIGATION TEST FAILED "+str(failures))
	quit(0 if failures.is_empty() else 1)
