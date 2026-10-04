extends Node2D
## Tracks the sentry's existing windup and muzzle. No AI or projectile ownership.
var charging := false
var progress := 0.0
var material_index := 16

static func attach(actor: Node2D) -> void:
	if actor.has_node("SentryAttackCue"):
		return
	var cue := new()
	cue.name = "SentryAttackCue"
	actor.add_child(cue)

func _ready() -> void:
	process_physics_priority = 2
	z_index = 1
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	visibility_changed.connect(_on_visibility_changed)

func _on_visibility_changed() -> void:
	if not is_visible_in_tree():
		charging = false
		progress = 0
		queue_redraw()

func _physics_process(_delta: float) -> void:
	var actor := get_parent()
	var was_charging := charging
	charging = is_visible_in_tree() and not actor.is_dead and actor.projectile_scene != null and actor.windup_remaining > 0
	progress = clampf(1.0 - actor.windup_remaining / maxf(actor.windup_time, 0.001), 0, 1) if charging else 0.0
	material_index = 13 if actor.projectile_color.r > actor.projectile_color.b else 16
	if charging or was_charging:
		queue_redraw()

func _draw() -> void:
	if charging:
		var actor := get_parent()
		preload("res://MobChargeArt.gd").stamp(self, to_local(actor.muzzle.global_position), actor.aim_direction, progress, material_index)
