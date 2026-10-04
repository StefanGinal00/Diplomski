@tool
extends Sprite2D
## Painted boss body; native combat owns state and navigation. Damage volumes
## are registered separately to the painted central body, not the old legs.
const SHEETS := {
	"void_sentinel": "res://art/characters/boss_void_sentinel_v1.png",
	"abyss_warden": "res://art/characters/boss_abyss_warden_v1.png",
	"echo_matriarch": "res://art/characters/boss_echo_matriarch_v1.png",
	"ash_castellan": "res://art/characters/boss_ash_castellan_v1.png",
	"hollow_sovereign": "res://art/characters/boss_hollow_sovereign_v1.png",
	"starfall_guardian": "res://art/characters/boss_starfall_guardian_v1.png",
	"ember_marshal": "res://art/characters/boss_ember_marshal_v1.png",
}
const HIDE := {
	"void_sentinel": ["BodyVisual", "Crown", "Eye"],
	"abyss_warden": ["BodyVisual", "Crown", "Eye"],
	"echo_matriarch": ["WingLeft", "WingRight", "BodyVisual", "Crown", "Eye"],
	"ash_castellan": ["Cape", "Armor", "Crown", "Eye"],
	"hollow_sovereign": ["Aura", "Mantle", "BodyVisual", "Crown", "Eye"],
	"starfall_guardian": ["Mantle", "Armor", "Crown", "Eye"],
	"ember_marshal": ["Cape", "Armor", "Helm", "Eye"],
}
const PIVOTS := {
	"void_sentinel": [Vector2(315, 612), Vector2(315, 615), Vector2(310, 615), Vector2(315, 615)],
	"abyss_warden": [Vector2(286, 608), Vector2(286, 608), Vector2(292, 610), Vector2(310, 610)],
	"echo_matriarch": [Vector2(312, 475), Vector2(312, 470), Vector2(310, 474), Vector2(310, 475)],
	"ash_castellan": [Vector2(310, 600), Vector2(320, 600), Vector2(310, 600), Vector2(310, 605)],
	"hollow_sovereign": [Vector2(311, 606), Vector2(316, 606), Vector2(316, 606), Vector2(320, 606)],
	"starfall_guardian": [Vector2(310, 608), Vector2(310, 608), Vector2(310, 608), Vector2(310, 608)],
	"ember_marshal": [Vector2(326, 564), Vector2(318, 562), Vector2(313, 508), Vector2(316, 517)],
}
const SCALES := {"void_sentinel": 0.15, "abyss_warden": 0.17, "echo_matriarch": 0.17, "ash_castellan": 0.16, "hollow_sovereign": 0.18, "starfall_guardian": 0.17, "ember_marshal": 0.16}
const FLOOR_OFFSETS := {"void_sentinel": 20.0, "abyss_warden": 17.0, "echo_matriarch": 26.0, "ash_castellan": 27.0, "hollow_sovereign": 29.0, "starfall_guardian": 22.0, "ember_marshal": 19.5}
# Main connected alpha silhouette per quadrant, measured from source art.
# Sampling bounds remove detached spillover without rewriting generated pixels.
const FRAME_BOUNDS := {
	"void_sentinel": [Rect2(113,99,417,528), Rect2(114,101,462,526), Rect2(76,163,542,446), Rect2(84,127,486,487)],
	"abyss_warden": [Rect2(101,7,437,620), Rect2(110,7,441,620), Rect2(82,61,545,541), Rect2(137,41,477,561)],
	"echo_matriarch": [Rect2(22,35,572,566), Rect2(11,35,583,566), Rect2(7,0,620,601), Rect2(28,34,566,566)],
	"ash_castellan": [Rect2(53,9,496,618), Rect2(38,18,557,608), Rect2(18,80,609,508), Rect2(44,45,556,559)],
	"hollow_sovereign": [Rect2(59,0,506,627), Rect2(19,0,586,627), Rect2(24,23,603,571), Rect2(151,10,450,600)],
	"starfall_guardian": [Rect2(139,1,397,621), Rect2(111,1,393,621), Rect2(63,50,564,550), Rect2(82,2,492,603)],
	"ember_marshal": [Rect2(193,98,344,468), Rect2(122,116,354,448), Rect2(102,171,410,339), Rect2(167,97,319,422)],
}
var boss_id := ""
var previous_health := -1
var hurt_remaining := 0.0
var property_names := {}
var animation_age := 0.0
var presentation: Node2D
var stride_distance := 0.0
var stride_hold := 0.0
var last_actor_position := Vector2.ZERO
var pose_blend: Sprite2D
var blend_remaining := 0.0
const BLEND_SECONDS := 0.075
var recoil := 0.0
var motion_state := "idle"
var pose_index := 0 # semantic idle/locomotion/prepare/recover, not atlas frame
var frame_sequence: RefCounted
var base_scale := 1.0
var painted_cycle: Sprite2D


static func attach(boss: CharacterBody2D) -> Sprite2D:
	var id := String(boss.get("boss_id"))
	if not SHEETS.has(id):
		return null
	if boss.has_node("PaintedAppearance"):
		return boss.get_node("PaintedAppearance")
	var art := new()
	art.name = "PaintedAppearance"
	art.boss_id = id
	boss.add_child(art)
	preload("res://CombatHurtbox.gd").install(boss, SCALES[id]*FRAME_BOUNDS[id][0].size.y, FLOOR_OFFSETS[id], id=="echo_matriarch")
	var effects := preload("res://BossCombatPresentation.gd").new()
	effects.name = "CombatPresentation"
	boss.add_child(effects)
	art.presentation = effects
	var safety := preload("res://BossEncounterSafety.gd").new()
	safety.name = "EncounterSafety"
	boss.add_child(safety)
	return art


func _ready() -> void:
	hframes = 2
	vframes = 2
	var sequence := preload("res://BossFrameSequence.gd").new()
	base_scale = float(SCALES[boss_id])
	if sequence.initialize(boss_id):
		frame_sequence = sequence
		texture = sequence.texture
		hframes = 4
		vframes = 3
		base_scale *= FRAME_BOUNDS[boss_id][0].size.y / float(sequence.data.scale_reference_height)
	else:
		texture = load(SHEETS[boss_id])
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var isolation := ShaderMaterial.new()
	isolation.shader = preload("res://shaders/boss_frame_isolation.gdshader")
	material = isolation
	z_index = 0
	scale = Vector2.ONE * base_scale
	position.y = FLOOR_OFFSETS[boss_id]
	for child in get_parent().get_children():
		if child is Label:
			child.position.y -= 48.0
			child.z_index = 4
		elif child is ProgressBar:
			child.position.y -= 42.0
			child.z_index = 4
		elif child is Line2D:
			child.z_index = 2
		elif child is Polygon2D and (String(child.name).contains("Mark") or String(child.name).contains("Eruption") or String(child.name) in ["PulseRing", "NovaRing", "LockMark"]):
			child.z_index = 1
	for leaf_name in HIDE[boss_id]:
		var leaf := get_parent().get_node_or_null(leaf_name) as CanvasItem
		if leaf != null:
			leaf.hide()
	for descriptor in get_parent().get_property_list():
		property_names[String(descriptor.name)] = true
	if get_parent().has_signal("health_changed"):
		get_parent().health_changed.connect(_on_health_changed)
	previous_health = int(_read("current_health", 0))
	last_actor_position = get_parent().global_position
	_apply_pose()
	pose_blend = Sprite2D.new()
	pose_blend.name = "PoseTransition"
	pose_blend.texture = texture
	pose_blend.hframes = hframes
	pose_blend.vframes = vframes
	pose_blend.texture_filter = texture_filter
	pose_blend.hide()
	add_child(pose_blend)
	painted_cycle=preload("res://BossPaintedCycle.gd").new()
	painted_cycle.name="LivingBody"
	add_child(painted_cycle)
	painted_cycle.configure(boss_id,float(SCALES[boss_id])*FRAME_BOUNDS[boss_id][0].size.y)
	visibility_changed.connect(_on_visibility_changed)
	if Engine.is_editor_hint():
		set_process(false)

func _on_visibility_changed() -> void:
	if not is_visible_in_tree():
		_reset_transients()

func _reset_transients() -> void:
	last_actor_position = get_parent().global_position
	stride_hold = 0
	if frame_sequence != null:
		frame_sequence.reset()
	blend_remaining = 0
	hurt_remaining = 0
	recoil = 0
	position.x = 0
	rotation = 0
	scale = Vector2.ONE * base_scale
	if pose_blend != null:
		pose_blend.hide()
	self_modulate.a = 1.0
	if painted_cycle!=null: painted_cycle.hide()
	if material!=null: material.set_shader_parameter("hide_paint",false)
	modulate = Color(1.05, 0.93, 1.12) if bool(_read("is_rematch", false)) else Color.WHITE

func _process(delta: float) -> void:
	if not is_visible_in_tree() or bool(_read("is_dead", false)):
		_reset_transients()
		return
	animation_age += delta
	var pose := 0
	var movement: Vector2 = get_parent().global_position - last_actor_position
	last_actor_position = get_parent().global_position
	# Ignore teleports/room restores. Collision-blocked velocity is not a step.
	var moved := absf(movement.x) > 0.02 and movement.length() < 80.0
	stride_hold = maxf(0, stride_hold - delta)
	if movement.length() >= 80.0:
		stride_hold = 0
	if moved:
		stride_hold = 0.065
		stride_distance += absf(movement.x)
	# At 120+ render FPS, multiple draw frames share one 60 Hz physics pose.
	# A zero displacement between those frames is not a command to switch idle.
	var moving := stride_hold > 0
	if moving:
		pose = 1 if frame_sequence != null else int(stride_distance / 14.0) % 2
	if frame_sequence != null and boss_id == "echo_matriarch":
		pose = 1 # Flying actors beat their wings even while holding position.
	var preparing := false
	for property in ["windup_remaining", "charge_windup", "volley_windup", "pulse_windup", "eruption_windup"]:
		if float(_read(property, 0.0)) > 0.0:
			preparing = true
	if presentation != null:
		preparing = presentation.sample_windup() > 0
	var charging := float(_read("charge_remaining", 0)) > 0
	var recovering: bool = float(_read("recovery_remaining", 0)) > 0 or (presentation != null and presentation.release_remaining > 0)
	if recovering:
		pose = 3
	if preparing or charging:
		pose = 2
	if frame_sequence != null:
		frame_sequence.tick(delta, presentation.sample_windup() if presentation != null else 0.0, float(_read("recovery_remaining", 0)))
	var next_frame := _selected_frame(pose)
	var old_flip := flip_h
	# Painted locomotion already has six in-between poses. Only blend between
	# semantic states; restarting on every fast step leaves a permanent ghost.
	var immediate_strike := charging and motion_state != "charge"
	if immediate_strike:
		blend_remaining = 0
	elif next_frame != frame and pose != pose_index and pose_blend != null:
		pose_blend.frame = frame
		pose_blend.offset = offset
		pose_blend.flip_h = flip_h
		pose_blend.material = material.duplicate()
		blend_remaining = BLEND_SECONDS
		pose_blend.show()
	_apply_pose(pose)
	if flip_h != old_flip:
		blend_remaining = 0.0
	blend_remaining = maxf(0, blend_remaining - delta)
	if pose_blend != null:
		pose_blend.visible = blend_remaining > 0
		pose_blend.self_modulate.a = blend_remaining / BLEND_SECONDS
	self_modulate.a = 1.0 - blend_remaining / BLEND_SECONDS
	var facing := -1.0 if flip_h else 1.0
	var breath := sin(animation_age * (5.5 if boss_id == "echo_matriarch" else 2.8))
	var stretch := Vector2(1.0 - breath * 0.008, 1.0 + breath * 0.012)
	var tilt := 0.0
	motion_state = "idle"
	if charging:
		motion_state = "charge"
		stretch = Vector2(1.07, 0.94)
		tilt = 0.07 * facing
	elif preparing:
		motion_state = "prepare"
		stretch = Vector2(1.04, 0.95)
		tilt = -0.025 * facing
	elif recovering:
		motion_state = "recover"
		stretch = Vector2(1.02, 0.97)
	elif moving:
		motion_state = "stride"
		tilt = sin(stride_distance * PI / 14.0) * 0.02
	if boss_id == "void_sentinel":
		# Gradual weight loading/release rather than a constant squashed cutout.
		if preparing:
			var progress := 1.0 - float(_read("windup_remaining", 0)) / float(_read("windup_duration", 0.62))
			stretch = Vector2(1.0 + progress * 0.025, 1.0 - progress * 0.025)
			tilt = -0.035 * facing * progress
		elif recovering:
			var remaining := float(_read("recovery_remaining", 0)) / float(_read("recovery_duration", 0.48))
			stretch = Vector2(1.0 + remaining * 0.025, 1.0 - remaining * 0.02)
			tilt = 0.045 * facing * remaining
		elif String(_read("combat_state", "")) == "turn":
			motion_state = "turn"
			var turn_progress := 1.0 - float(_read("turn_remaining", 0)) / 0.22
			stretch.x = 1.0 - sin(turn_progress * PI) * 0.18
	var smoothing := 1.0 - exp(-18.0 * delta)
	scale = scale.lerp(stretch * base_scale, smoothing)
	rotation = lerp_angle(rotation, tilt, smoothing)
	position.y = FLOOR_OFFSETS[boss_id] - (absf(sin(stride_distance * PI / 14.0)) * 1.5 if moving and not charging and frame_sequence == null and boss_id != "void_sentinel" else 0)
	recoil = lerpf(recoil, 0.0, 1.0 - exp(-24.0 * delta))
	position.x = recoil
	hurt_remaining = maxf(hurt_remaining - delta, 0.0)
	var rest := Color(1.05, 0.93, 1.12) if bool(_read("is_rematch", false)) else Color.WHITE
	modulate = Color(1.7, 0.8, 0.8) if hurt_remaining > 0 else rest
	_update_living_paint()

func _update_living_paint(force_release:=false) -> void:
	if painted_cycle==null: return
	var active: bool=painted_cycle.sample(self,force_release)
	material.set_shader_parameter("hide_paint",active)
	if pose_blend!=null and pose_blend.material!=null:
		pose_blend.material.set_shader_parameter("hide_paint",active)

func rendered_sprite() -> Sprite2D:
	return painted_cycle if painted_cycle!=null and painted_cycle.visible else self


func _read(property: String, fallback: Variant) -> Variant:
	return get_parent().get(property) if property_names.has(property) or property in ["boss_id", "current_health"] else fallback


func _on_health_changed(current: int, _maximum: int) -> void:
	if previous_health >= 0 and current < previous_health:
		hurt_remaining = 0.13
		recoil = 2.5 if flip_h else -2.5
	previous_health = current


func _apply_pose(pose: int = 0) -> void:
	pose_index = pose
	frame = _selected_frame(pose)
	var target := _read("target_player", null) as Node2D
	var locked := float(_read("charge_remaining", 0)) > 0 or float(_read("charge_windup", 0)) > 0
	if float(_read("windup_remaining", 0)) > 0 and String(_read("current_pattern", "lunge")) == "lunge":
		locked = true
	if property_names.has("facing_direction"):
		flip_h = float(_read("facing_direction", 1)) < 0
	elif locked:
		flip_h = float(_read("charge_direction", 1)) < 0
	elif float(_read("recovery_remaining", 0)) > 0 or (presentation != null and presentation.release_remaining > 0):
		# Keep the committed orientation through follow-through. A player who
		# dodged behind the boss must not flip the recovery silhouette instantly.
		pass
	elif is_instance_valid(target):
		var distance_x: float = target.global_position.x - get_parent().global_position.x
		if absf(distance_x) > 12:
			flip_h = distance_x < 0
	var pivot: Vector2 = frame_sequence.pivot() if frame_sequence != null else PIVOTS[boss_id][pose]
	var bounds := get_frame_bounds(frame)
	if boss_id != "echo_matriarch" and frame_sequence == null:
		pivot.y = bounds.end.y - 2
	var cell := texture.get_size() / Vector2(hframes, vframes)
	offset = cell * 0.5 - pivot
	if flip_h:
		offset.x = -offset.x
	if material != null:
		material.set_shader_parameter("frame_grid", Vector2(hframes, vframes))
		material.set_shader_parameter("frame_bounds", Vector4(bounds.position.x / cell.x, bounds.position.y / cell.y, bounds.end.x / cell.x, bounds.end.y / cell.y))
		# Sovereign's lunge hand intrudes into the unused upper-left corner of
		# recovery. A local render mask removes it, leaving the real mantle intact.
		material.set_shader_parameter("exclude_upper_left", Vector2(222, 350) / 627.0 if frame_sequence == null and boss_id == "hollow_sovereign" and pose == 3 else Vector2.ZERO)


func _selected_frame(pose: int) -> int:
	if frame_sequence == null:
		return pose
	return frame_sequence.select(pose, stride_distance, float(_read("charge_remaining", 0)) > 0, presentation.sample_windup() if presentation != null else 0.0, float(_read("recovery_remaining", 0)))


func get_frame_bounds(index: int) -> Rect2:
	return frame_sequence.bounds(index) if frame_sequence != null else FRAME_BOUNDS[boss_id][index]


func begin_release() -> void:
	if frame_sequence != null:
		frame_sequence.release_age = 0
		# Release effects and the painted strike share the same physics tick.
		_apply_pose(3)
		blend_remaining = 0
		if pose_blend != null:
			pose_blend.hide()
		self_modulate.a = 1
		_update_living_paint(true)
