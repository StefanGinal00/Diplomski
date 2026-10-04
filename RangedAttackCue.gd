@tool
extends Node2D

## Native attack effects over existing art. No AI/collision/cadence ownership.
var pose := 0 # 0 idle, 1 imminent shot, 2 successful launch, 3 hit
var fire_remaining := 0.0
var hurt_remaining := 0.0
var previous_health := -1
var muzzle_position := Vector2.ZERO
var shot_direction := Vector2.RIGHT
var charge_progress := 0.0
var charge_direction := Vector2.RIGHT
var redraw_clock := 0.0


func _ready() -> void:
	if Engine.is_editor_hint():
		set_process(false)
	else:
		var actor := get_parent()
		actor.health_changed.connect(_on_health_changed)
		actor.shot_fired.connect(_on_shot_fired)
		actor.ready.connect(_initialize_health, CONNECT_ONE_SHOT)
		visibility_changed.connect(_on_visibility_changed)


func _on_visibility_changed() -> void:
	# Room deactivation can disable processing before hiding its actors.
	# Clear here too, so re-entry cannot replay a stale flash/charging frame.
	if not is_visible_in_tree():
		fire_remaining = 0.0
		hurt_remaining = 0.0
		pose = 0
		charge_progress = 0.0
		queue_redraw()


func _initialize_health() -> void:
	previous_health = get_parent().current_health
	muzzle_position = get_parent().muzzle.position


func _on_health_changed(current: int, _maximum: int) -> void:
	if previous_health >= 0 and current < previous_health:
		hurt_remaining = 0.12
	previous_health = current


func _on_shot_fired(direction: Vector2) -> void:
	if is_visible_in_tree():
		fire_remaining = 0.12
		shot_direction = direction
		var burst := preload("res://BossBurst.gd").spawn(get_parent().get_parent(), get_parent().muzzle.global_position, Color.WHITE, "contact", Vector2(9, 9), 0.12, 7)
		if burst != null:
			burst.global_rotation = direction.angle()


func _process(delta: float) -> void:
	var previous_pose := pose
	if not is_visible_in_tree():
		fire_remaining = 0.0
		hurt_remaining = 0.0
		pose = 0
		charge_progress = 0.0
		if previous_pose != 0:
			queue_redraw()
		return
	fire_remaining = maxf(0.0, fire_remaining - delta)
	hurt_remaining = maxf(0.0, hurt_remaining - delta)
	var actor := get_parent()
	# A departing scene may free the cached player before this actor.
	var target: Node2D = actor.target_player if is_instance_valid(actor.target_player) else null
	muzzle_position = actor.muzzle.position
	pose = 0
	charge_progress = 0.0
	if hurt_remaining > 0:
		pose = 3
	elif fire_remaining > 0:
		pose = 2
	elif actor.projectile_scene != null and is_instance_valid(target) and target.get("is_dead") != true and not actor.is_dead:
		var warning_window := minf(0.35, actor.shot_interval * 0.4)
		if actor.has_clear_shot and actor.global_position.distance_to(target.global_position) <= actor.detection_range and actor.shot_cooldown_remaining <= warning_window:
			pose = 1
			charge_progress = clampf(1.0 - actor.shot_cooldown_remaining / maxf(warning_window, 0.001), 0, 1)
			charge_direction = (target.global_position - actor.muzzle.global_position).normalized()
	redraw_clock += delta
	if previous_pose != pose or (pose != 0 and redraw_clock >= 0.05):
		redraw_clock = 0.0
		queue_redraw()


func _draw() -> void:
	if pose == 1:
		preload("res://MobChargeArt.gd").stamp(self, muzzle_position, charge_direction, charge_progress, 7)
		# Above health bar, matching the crawler's existing warning language.
		var color := Color(1.0, 0.34, 0.2, 0.6 + charge_progress * 0.4)
		draw_colored_polygon(PackedVector2Array([Vector2(0, -35), Vector2(-4, -28), Vector2(4, -28)]), color)
		draw_arc(muzzle_position, 2.5 + charge_progress * 2.0, 0, TAU, 16, color, 1.0, true)
	elif pose == 2:
		var intensity := clampf(fire_remaining / 0.12, 0.0, 1.0)
		# shot_direction is world-space; draw coordinates belong to this actor.
		var local_direction := (to_local(global_position + shot_direction) - to_local(global_position)).normalized()
		for angle in [-0.45, 0.0, 0.45]:
			var ray := local_direction.rotated(angle)
			draw_line(muzzle_position + ray * 2, muzzle_position + ray * (4 + 5 * intensity), Color(1.0, 0.65, 0.3, intensity), 1.4, true)
	# Hurt is shown by the character presenter; no additional overlay.
