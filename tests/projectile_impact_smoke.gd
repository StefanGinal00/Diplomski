extends "res://tests/shaft_hollow_smoke.gd"

const Impact = preload("res://ProjectileImpact.gd")

class ContactTarget extends StaticBody2D:
	var damage_received := 0
	func take_damage(amount: int, _force: Vector2) -> void:
		damage_received += amount


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_projectile_impact_save.json"
	state.start_new_game("normal")
	var host := Node2D.new()
	root.add_child(host)
	for variant in range(6):
		for kind in ["actor", "terrain", "breakable"]:
			for aim in [Vector2.RIGHT, Vector2(-1, -1).normalized()]:
				var shot: Node2D = load("res://PlayerMagicProjectile.tscn" if variant >= 3 else "res://PlayerArrow.tscn").instantiate()
				host.add_child(shot)
				shot.set_physics_process(false)
				shot.position = Vector2(120, 30)
				if variant >= 3:
					shot.setup(aim, host, "frost_orb" if variant == 5 else "arc_bolt", 0, "sunder_staff" if variant == 4 else "apprentice_staff")
				else:
					shot.setup(aim, host, "ember_arrow" if variant == 2 else "basic_arrow", 0, 1, "thorn_bow" if variant == 1 else "hunter_bow")
				var target := ContactTarget.new()
				host.add_child(target)
				if kind != "terrain":
					target.add_to_group("breakable" if kind == "breakable" else "enemy")
				shot._on_body_entered(host)
				_check(get_nodes_in_group(Impact.GROUP).is_empty(), "Source collision creates impact")
				var damage: int = shot.damage
				shot._on_body_entered(target)
				shot._on_body_entered(target)
				var effects := get_nodes_in_group(Impact.GROUP)
				_check(effects.size() == 1, "Contact duplicates or loses impact")
				if effects.size() == 1:
					var effect: Node2D = effects[0]
					effect.set_process(false)
					_check(effect.contact_kind == kind, "Wrong contact kind")
					_check(effect.style == ["arrow", "thorn", "ember", "arc", "arc", "frost"][variant], "Wrong effect variant")
					_check(effect.global_position.is_equal_approx(Vector2(120, 30)) and effect.global_transform.x.normalized().is_equal_approx(aim), "Impact drifts from contact point/aim")
					_check(effect.get_child_count() == 0 and not effect is CollisionObject2D, "Cosmetic impact introduces physics/nodes")
					await process_frame
					_check(target.damage_received == (0 if kind == "terrain" else damage), "Contact feedback changes damage or dedup")
					_check(is_instance_valid(effect), "Projectile cleanup destroys contact burst early")
					effect._process(Impact.DURATION + 0.01)
					_check(effect.is_queued_for_deletion() and not effect.visible, "Expired effect lingers")
				if is_instance_valid(shot):
					shot.queue_free()
				target.queue_free()
				await process_frame
	await _live_contacts(host)
	# Global cap includes queued effects until the end of the frame, so even
	# simultaneous impacts cannot over-allocate beyond the visual budget.
	var dummy := Node2D.new()
	host.add_child(dummy)
	for index in range(Impact.MAX_ACTIVE + 8):
		Impact.spawn(dummy, Vector2.ZERO, Vector2.RIGHT, "arc", Color.WHITE, "actor")
	_check(get_nodes_in_group(Impact.GROUP).size() == Impact.MAX_ACTIVE, "Impact cap exceeded")
	state.checkpoint_resting.emit("test_lamp")
	await process_frame
	_check(get_nodes_in_group(Impact.GROUP).is_empty(), "Rest retains impact effects")
	for event in ["room", "transition", "hidden", "parent", "pause"]:
		var container := Node2D.new()
		host.add_child(container)
		container.position = Vector2(50, 20)
		container.rotation = 0.4
		container.scale = Vector2(2, 2)
		var projectile := Node2D.new()
		container.add_child(projectile)
		var burst := Impact.spawn(projectile, Vector2(160, 45), Vector2.LEFT, "frost", Color.CYAN, "actor")
		_check(burst.global_position.is_equal_approx(Vector2(160, 45)) and burst.global_transform.x.is_equal_approx(Vector2.LEFT), "Scaled parent corrupts impact placement")
		if event == "room":
			state.room_changed.emit("test_room")
		elif event == "transition":
			root.get_node("RoomTransition").transition_started.emit("test_room")
		elif event == "hidden":
			container.process_mode = Node.PROCESS_MODE_DISABLED
			container.hide()
		elif event == "parent":
			container.queue_free()
		else:
			paused = true
			var age: float = burst.age
			for tick in range(3):
				await process_frame
			_check(burst.age == age, "Pause consumes cosmetic lifetime")
			paused = false
			burst._process(Impact.DURATION + 0.01)
		await process_frame
		_check(get_nodes_in_group(Impact.GROUP).is_empty(), "Cleanup failed: " + event)
		if is_instance_valid(container):
			container.queue_free()
	var transition := root.get_node("RoomTransition")
	transition.is_transitioning = true
	_check(Impact.spawn(dummy, Vector2.ZERO, Vector2.RIGHT, "arc", Color.WHITE, "actor") == null, "Transition allows new effect")
	transition.is_transitioning = false
	host.queue_free()
	await process_frame
	state.delete_save()
	if failures.is_empty():
		print("PROJECTILE IMPACT TEST PASSED: 36 contact cases, variants, dedup/damage, cap, position, pause, expiry, rest, transition, hidden and parent cleanup")
		quit(0)
	else:
		quit(1)


func _live_contacts(host: Node2D) -> void:
	for variant in range(7):
		var saturated := variant == 6
		var targets: Array[ContactTarget] = []
		for index in range(2):
			var target := ContactTarget.new()
			target.position = Vector2(index * 40, 0)
			target.add_to_group("enemy")
			var collider := CollisionShape2D.new()
			var shape := RectangleShape2D.new()
			shape.size = Vector2(12, 24)
			collider.shape = shape
			target.add_child(collider)
			host.add_child(target)
			targets.append(target)
		var shot: Node2D = load("res://PlayerMagicProjectile.tscn" if variant in [3, 4, 5] else "res://PlayerArrow.tscn").instantiate()
		host.add_child(shot)
		shot.position = Vector2(-55, 0)
		if variant in [3, 4, 5]:
			shot.setup(Vector2.RIGHT, host, "frost_orb" if variant == 5 else "arc_bolt", 0, "sunder_staff" if variant == 4 else "apprentice_staff")
		else:
			shot.setup(Vector2.RIGHT, host, "ember_arrow" if variant == 2 else "basic_arrow", 0, 1, "thorn_bow" if variant == 1 else "hunter_bow")
		var damage: int = shot.damage
		var budget: int = shot.remaining_hits
		if saturated:
			for index in range(Impact.MAX_ACTIVE):
				var filler := Impact.spawn(shot, Vector2.ZERO, Vector2.RIGHT, "arrow", Color.WHITE, "terrain")
				filler.set_process(false)
		var contacts: Array[String] = []
		var observer := func(node: Node) -> void:
			if node.get_script() == Impact:
				contacts.append(node.contact_kind)
		host.child_entered_tree.connect(observer)
		for frame in range(60):
			await physics_frame
		host.child_entered_tree.disconnect(observer)
		_check(contacts.size() == (0 if saturated else budget), "Real collision impact count/budget wrong")
		_check(targets[0].damage_received + targets[1].damage_received == damage * budget, "Real collision damage changes with effects/cap")
		for target in targets:
			target.queue_free()
		if is_instance_valid(shot):
			shot.queue_free()
		for effect in get_nodes_in_group(Impact.GROUP):
			effect.queue_free()
		await process_frame
