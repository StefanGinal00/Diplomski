@tool
extends Sprite2D

## Reads the tested cue state; no duplicate timers or attack decisions.
const SHEET = preload("res://art/characters/stone_sentinel_v1.png")
# Generator returned 1254x1254: actual cells are 627px, not requested 512px.
const CELL_CENTER := Vector2(313.5, 313.5)
const PIXEL_SCALE := Vector2(0.043, 0.03)
const PIVOTS := [Vector2(250, 578), Vector2(250, 578), Vector2(250, 568), Vector2(250, 568)]
const CONTACT_ROWS := [580, 580, 570, 570]


func _ready() -> void:
	texture = SHEET
	hframes = 2
	vframes = 2
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	# Parent AI and AttackCue (priority 0) update first.
	process_priority = 1
	_apply_pose(0, true)
	preload("res://MobDefeatEcho.gd").hook(self, "ranged")
	visibility_changed.connect(_on_visibility_changed)
	if Engine.is_editor_hint():
		set_process(false)


func _on_visibility_changed() -> void:
	if not Engine.is_editor_hint() and not is_visible_in_tree():
		modulate = Color.WHITE
		_apply_pose(0, flip_h)

func _process(_delta: float) -> void:
	if not is_visible_in_tree():
		return
	var actor := get_parent()
	modulate = Color(1.25, 0.75, 0.75) if actor.get_node("AttackCue").pose == 3 else Color.WHITE
	_apply_pose(actor.get_node("AttackCue").pose, actor.muzzle.position.x < 0)


func _apply_pose(pose: int, face_left: bool) -> void:
	frame = pose
	flip_h = face_left
	offset = CELL_CENTER - PIVOTS[pose]
	offset.y = CELL_CENTER.y - CONTACT_ROWS[pose]
	if face_left:
		offset.x = -offset.x
	# Squat registration aligns pedestal with y=9 and mouth near (+/-13,0).
	position = Vector2(0, 9)
	scale = PIXEL_SCALE
