extends Node2D
## Presentation observes authoritative timers; explicit release hooks fire on the
## same physics tick as attacks. No damage, RNG, saves or encounter activation.
const Burst = preload("res://BossBurst.gd")
const COLORS := {"void_sentinel": Color("b289ef"), "abyss_warden": Color("63d7d9"), "echo_matriarch": Color("ef9bce"), "ash_castellan": Color("ff9a51"), "ember_marshal": Color("ffc269"), "starfall_guardian": Color("a7c9ff"), "hollow_sovereign": Color("ca9bef")}
var art: Sprite2D
var tint := Color.WHITE
var age := 0.0
var windup := 0.0
var charging := false
var awakened := false
var phase := 1
var release_remaining := 0.0
var clock := 0.0
var ghosts: Array[Dictionary] = []
var arena_origin := Vector2.ZERO
var arena_half_width := 220.0
var floor_y := 0.0
var grounded := false
var arena: Node2D
var windup_peak := 0.0
var preparation_frame := 0

func _ready() -> void:
	art = get_parent().get_node("PaintedAppearance")
	tint = COLORS.get(art.boss_id, Color.WHITE)
	awakened = bool(art._read("is_rematch", false))
	if awakened:
		tint = tint.lerp(Color("d4a6ff"), 0.5)
	arena_origin = get_parent().global_position
	floor_y = arena_origin.y + art.FLOOR_OFFSETS[art.boss_id]
	var left := float(art._read("arena_left_x", -INF))
	var right := float(art._read("arena_right_x", INF))
	if is_finite(left) and is_finite(right):
		var room := get_parent().get_parent() as Node2D
		arena_origin.x = (left + right) * 0.5 + (room.global_position.x if room != null else 0.0)
		arena_half_width = (right - left) * 0.5
	elif art.boss_id == "void_sentinel":
		arena_origin.x = (get_parent().arena_left + get_parent().arena_right) * 0.5
		arena_half_width = (get_parent().arena_right - get_parent().arena_left) * 0.5
	elif art.boss_id == "abyss_warden":
		arena_half_width = (get_parent().arena_right_offset - get_parent().arena_left_offset) * 0.5
	if art.boss_id == "echo_matriarch":
		# Flying actor's feet are not the arena floor.
		var floor_shape := get_parent().get_parent().get_node_or_null("Floor/CollisionShape2D") as CollisionShape2D
		if floor_shape != null and floor_shape.shape is RectangleShape2D:
			floor_y = floor_shape.global_position.y - floor_shape.shape.size.y * 0.5
	for marker in get_parent().get_children():
		var named := String(marker.name)
		if not (marker is Line2D or (marker is Polygon2D and (named.contains("Mark") or named.contains("Eruption") or named == "NovaRing"))):
			continue
		var warning := preload("res://BossHazardAppearance.gd").new()
		warning.name = "AnimatedWarning"
		warning.tint = tint
		warning.presenter = self
		if marker is Line2D:
			# PulseRing is already an animated closed ring, not a directional lane.
			if named == "PulseRing":
				warning.free()
				continue
			warning.style = "line"
		elif named.begins_with("Column"):
			warning.style = "column"
			warning.radius = 48.0
		elif named == "NovaRing" or named == "LockMark":
			warning.style = "circle"
			warning.radius = 175.0 if named == "NovaRing" else 88.0
		elif named.begins_with("Eruption"):
			warning.style = "ember"
			warning.radius = 32.0
		else:
			warning.radius = 110.0 if art.boss_id == "hollow_sovereign" else 66.0
		if marker is Polygon2D:
			marker.self_modulate.a = 0.08
		marker.add_child(warning)
	arena = Node2D.new()
	arena.name = "ArenaAtmosphere"
	arena.z_index = -2
	add_child(arena)
	arena.draw.connect(_draw_arena)
	get_parent().defeated.connect(_on_defeated)
	get_parent().phase_changed.connect(_on_phase_changed)
	visibility_changed.connect(_on_visibility_changed)
	z_index = 1

func _on_visibility_changed() -> void:
	if not is_visible_in_tree():
		_reset_transients()

func _reset_transients() -> void:
	for ghost in ghosts:
		if ghost.has("paint") and is_instance_valid(ghost.paint): ghost.paint.queue_free()
	ghosts.clear()
	charging = false
	windup = 0
	windup_peak = 0
	preparation_frame = 0
	release_remaining = 0
	clock = 0
	queue_redraw()

func _process(delta: float) -> void:
	if not is_visible_in_tree() or bool(art._read("is_dead", false)):
		_reset_transients()
		return
	age += delta
	windup = sample_windup()
	windup_peak = maxf(windup_peak, windup) if windup > 0 else 0.0
	preparation_frame = 1 if windup > 0 and windup < windup_peak * 0.5 else 0
	var was_charging := charging
	charging = bool(art._read("active", true)) and float(art._read("charge_remaining", 0.0)) > 0
	if was_charging != charging and bool(art._read("active", true)):
		Burst.spawn(get_parent().get_parent(), get_parent().global_position + Vector2(0, art.FLOOR_OFFSETS[art.boss_id]), tint, "ring", Vector2(30, 7), 0.24)
	phase = int(art._read("phase", 1))
	release_remaining = maxf(0, release_remaining - delta)
	if not bool(art._read("active", true)):
		for ghost in ghosts:
			if ghost.has("paint") and is_instance_valid(ghost.paint): ghost.paint.queue_free()
		ghosts.clear()
		release_remaining = 0
	if not grounded and get_parent().is_on_floor():
		floor_y = get_parent().global_position.y + art.FLOOR_OFFSETS[art.boss_id]
		grounded = true
	for ghost in ghosts:
		ghost.life -= delta
		if ghost.has("paint") and is_instance_valid(ghost.paint):
			ghost.paint.self_modulate.a=maxf(0,ghost.life*0.85)
			if ghost.life<=0: ghost.paint.queue_free()
	ghosts = ghosts.filter(func(g: Dictionary) -> bool: return g.life > 0)
	clock += delta
	if charging and clock >= 0.06:
		clock = 0
		if ghosts.size() < 4:
			var painted: Sprite2D=art.rendered_sprite()
			if painted!=art:
				var echo:=Sprite2D.new()
				echo.texture=painted.texture
				echo.texture_filter=painted.texture_filter
				echo.material=painted.material
				echo.flip_h=painted.flip_h
				echo.top_level=true
				echo.modulate=tint
				echo.self_modulate.a=0.18
				echo.z_index=-1
				add_child(echo)
				echo.global_transform=painted.global_transform
				ghosts.append({"paint":echo,"life":0.22})
			else:
				ghosts.append({"point": art.global_position, "life": 0.22, "frame": art.frame, "offset": art.offset, "flip": art.flip_h, "scale": art.scale})
	queue_redraw()
	arena.queue_redraw()

func sample_windup() -> float:
	# Shared by body animation and VFX: neither reads the other's previous frame.
	if not bool(art._read("active", true)) or bool(art._read("is_dead", false)) or float(art._read("charge_remaining", 0)) > 0:
		return 0.0
	var remaining := 0.0
	for key in ["windup_remaining", "charge_windup", "volley_windup", "pulse_windup", "eruption_windup"]:
		remaining = maxf(remaining, float(art._read(key, 0.0)))
	if remaining > 0 or float(art._read("recovery_remaining", 0)) > 0 or release_remaining > 0:
		return remaining
	# Guardian/Sovereign have explicit preparation; don't anticipate their
	# cooldown too. Only older instant-volley actors use this cosmetic pre-cue.
	if art.boss_id in ["void_sentinel", "starfall_guardian", "hollow_sovereign"]:
		return 0.0
	var shot := float(art._read("shot_cooldown", art._read("volley_cooldown", 100)))
	return shot if shot > 0 and shot < 0.32 else 0.0

func release(kind := "volley") -> void:
	release_remaining = 0.24
	art.begin_release()
	var boss := get_parent()
	var room := boss.get_parent()
	var point: Vector2 = boss.global_position
	if kind == "volley":
		point = boss.get_node("Muzzle").global_position
		_painted_release(room, point, "ring", Vector2(22, 22), 0.22, kind)
	elif kind == "ring":
		_painted_release(room, point, "ring", Vector2(65, 65), 0.42, kind)
	elif kind == "eruption":
		for mark in boss.eruption_marks:
			_painted_release(room, mark.global_position + Vector2(0, 27), "pillar", Vector2(32, 75), 0.32, kind)
	elif kind == "pulse":
		for index in boss.pulse_indices:
			_painted_release(room, boss.floor_marks[index].global_position, "pillar", Vector2(66, 65), 0.32, kind)
	elif kind == "runes":
		for index in boss.rune_indices:
			_painted_release(room, boss.floor_marks[index].global_position, "pillar", Vector2(110, 82), 0.34, kind)
	elif kind == "starfall":
		for mark in boss.column_marks:
			_painted_release(room, mark.global_position + Vector2(0, 207), "pillar", Vector2(48, 360), 0.35, kind)
	elif kind == "nova":
		_painted_release(room, point, "ring", Vector2(175, 175), 0.3, kind)
	elif kind == "soul_lock":
		_painted_release(room, boss.locked_point, "ring", Vector2(88, 88), 0.3, kind)
	elif kind == "rift":
		var mid: Vector2 = room.to_global(Vector2((boss.arena_left_x + boss.arena_right_x) * 0.5, 427))
		_painted_release(room, mid, "pillar", Vector2((boss.arena_right_x - boss.arena_left_x) * 0.5, 72), 0.3, kind)

func _painted_release(room: Node, point: Vector2, shape: String, size: Vector2, seconds: float, attack: String) -> void:
	var frame_index := preload("res://EnemyAttackArt.gd").release_frame(art.boss_id, attack)
	var effect := Burst.spawn(room, point, tint, shape, size, seconds, frame_index)
	if effect != null and attack == "volley":
		effect.global_transform = Transform2D(_volley_direction(point).angle(), point)

func _volley_direction(point: Vector2) -> Vector2:
	if art.property_names.has("locked_shot_direction"):
		return art._read("locked_shot_direction", Vector2.RIGHT)
	var target := art._read("target_player", null) as Node2D
	if is_instance_valid(target):
		var direction := (target.global_position - point).normalized()
		if not direction.is_zero_approx():
			return direction
	return Vector2.LEFT if art.flip_h else Vector2.RIGHT

func _on_phase_changed(_phase: int) -> void:
	Burst.spawn(get_parent().get_parent(), get_parent().global_position, tint, "ring", Vector2(58, 58), 0.55)

func _on_defeated() -> void:
	# Detached, bounded visual only; native defeat/rewards are not delayed.
	var room := get_parent().get_parent()
	preload("res://BossDefeatEcho.gd").spawn(art, tint)
	var identity: int = preload("res://EnemyAttackArt.gd").PROJECTILES.get(art.boss_id, 0)
	Burst.spawn(room, get_parent().global_position, tint, "impact", Vector2(52, 46), 0.4, identity)

func _draw() -> void:
	if art == null:
		return
	# Compact aura stays behind the silhouette, not over the floor warnings.
	if awakened or phase > 1:
		for i in range(3):
			var radius := 29.0 + i * 7 + sin(age * 2 + i) * 2
			draw_arc(Vector2(0, -15), radius, age * 0.45 + i * 2, age * 0.45 + i * 2 + 1.35, 18, Color(tint, 0.45 if awakened else 0.23), 1.1, true)
		for i in range(8 if awakened else 4):
			var p := Vector2(sin(i * 2.4 + age * 0.7) * 29, -fmod(age * 17 + i * 13, 72))
			draw_circle(p, 1.2, Color(tint, 0.65))
	if windup > 0:
		var muzzle := get_parent().get_node("Muzzle") as Node2D
		var point := to_local(muzzle.global_position)
		var charge_preparation := float(art._read("charge_windup", 0)) > 0 or (float(art._read("windup_remaining", 0)) > 0 and String(art._read("current_pattern", "lunge")) == "lunge")
		if charge_preparation:
			point = Vector2(float(art._read("charge_direction", 1)) * 22, -18)
		draw_arc(point, 7 + minf(windup, 0.9) * 17, age * 5, age * 5 + TAU * 0.8, 28, Color(tint, 0.9), 1.4, true)
		draw_circle(point, 5, Color(tint, 0.18))
		var material_id: int = preload("res://EnemyAttackArt.gd").PROJECTILES.get(art.boss_id, 0)
		var cue_aim := _volley_direction(muzzle.global_position)
		draw_set_transform(point, cue_aim.angle() - global_rotation)
		preload("res://CombatFlipbook.gd").stamp(self, material_id, preparation_frame, Rect2(Vector2(-12, -12), Vector2(24, 24)), Color(1, 1, 1, 0.65))
		draw_set_transform(Vector2.ZERO)
		if art.boss_id == "void_sentinel":
			var aim: Vector2 = art._read("locked_shot_direction", Vector2.RIGHT)
			var progress := 1.0 - windup / float(art._read("windup_duration", 0.62))
			# Short aiming sparks read as energy leaving the core, not a laser
			# hazard. Their direction is the same snapshot used by the projectile.
			var angles := PackedFloat32Array([-0.16, 0.0, 0.16] if phase == 2 else [0.0])
			for angle in angles:
				for i in range(3):
					var direction := aim.rotated(angle)
					var distance := 12.0 + i * 10.0 + progress * 4.0
					draw_line(point + direction * distance, point + direction * (distance + 4), Color(tint, 0.25 + progress * 0.55), 1.2, true)
	if charging:
		var direction := float(art._read("charge_direction", 1))
		for i in range(3):
			draw_line(Vector2(-direction * 12, -8 + i * 9), Vector2(-direction * (42 + i * 7), -5 + i * 9), Color(tint, 0.4), 1.5, true)
	# Afterimages reuse the isolated atlas mask, through temporary draw nodes
	# would cost more than these four tightly bounded textured silhouettes.
	for ghost in ghosts:
		if ghost.has("paint"): continue
		var cell := art.texture.get_size() / Vector2(art.hframes, art.vframes)
		var source := Rect2(Vector2(int(ghost.frame) % art.hframes, int(ghost.frame) / art.hframes) * cell, cell)
		var bounds: Rect2 = art.get_frame_bounds(int(ghost.frame))
		source.position += bounds.position
		source.size = bounds.size
		var size: Vector2 = bounds.size * ghost.scale
		var local_offset: Vector2 = (bounds.position - cell * 0.5 + ghost.offset) * ghost.scale
		if ghost.flip:
			local_offset.x = -(bounds.end.x - cell.x * 0.5 - ghost.offset.x) * ghost.scale.x
		var destination := Rect2(to_local(ghost.point) + local_offset, size)
		if ghost.flip:
			destination.position.x += size.x
			destination.size.x = -size.x
		draw_texture_rect_region(art.texture, destination, source, Color(tint, float(ghost.life) * 0.85))

func _draw_arena() -> void:
	var battle := bool(art._read("active", true))
	var intensity := 0.38 if battle else 0.17
	var center := arena.to_local(Vector2(arena_origin.x, floor_y))
	# Etched floor medallion and two local relics, not another background plate.
	arena.draw_set_transform(center, 0, Vector2(1, 0.12))
	for radius in [48.0, 60.0, 66.0]:
		arena.draw_arc(Vector2.ZERO, radius, 0, TAU, 48, Color(tint, intensity), 1.0, true)
	arena.draw_set_transform(Vector2.ZERO)
	for i in range(12):
		var x := sin(i * 12.7) * arena_half_width * 0.85
		var y := -fmod(age * (7 + i % 3) + i * 19, 125)
		arena.draw_circle(center + Vector2(x, y), 0.7 + (i % 2) * 0.4, Color(tint, intensity * 0.7))
