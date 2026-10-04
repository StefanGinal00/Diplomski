extends Node2D
## Budgeted flame, driven by real checkpoint state; never lights a locked lamp.
const SHEET := preload("res://art/visual_slice/checkpoint_flames_v1.png")
const X := [0, 414, 794, 1175, 1536]
const BASE_X := [234, 599, 978, 1365]
static var frames: Array[AtlasTexture] = []
var flame: Sprite2D
var lamp: Node2D
var body: Sprite2D
var warm := false
var current_frame := 0

static func attach(actor: Node2D, art: Sprite2D, room_id: String) -> void:
	if art.has_node("LivingFlame"): return
	var motion := new()
	motion.name = "LivingFlame"
	motion.lamp = actor
	motion.body = art
	motion.warm = room_id.begins_with("ash_")
	art.add_child(motion)

func _ready() -> void:
	set_process(false)
	set_meta("ambient_motion", true)
	if frames.is_empty():
		var source_ratio := SHEET.get_size()/Vector2(1536,1024)
		for row in 2:
			for col in 4:
				var texture := AtlasTexture.new()
				texture.atlas = SHEET
				texture.region = Rect2(Vector2(X[col],row*512)*source_ratio,Vector2(X[col+1]-X[col],512)*source_ratio)
				texture.filter_clip = true
				frames.append(texture)
	flame = Sprite2D.new()
	flame.name = "Flame"
	flame.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	add_child(flame)
	animate(0)

func animate(age: float) -> void:
	current_frame = int(age * 9.0) % 4
	sync_state()
	if flame.visible: flame.modulate.a = 0.84 + sin(age * 13.7) * 0.1

func sync_state() -> void:
	var lit: bool = lamp.is_revealed and (lamp.is_active or lamp.is_resting)
	flame.visible = lit
	body.self_modulate = Color.WHITE if lit else Color(0.5, 0.57, 0.59)
	if not lit: return
	flame.texture = frames[current_frame + (4 if warm else 0)]
	# The base is registered inside the glass, not at the lamp's ground foot.
	var ratio := 0.25 * (1.12 if lamp.is_resting else 1.0)
	var source_ratio := SHEET.get_size()/Vector2(1536,1024)
	flame.scale = Vector2.ONE * ratio / source_ratio
	flame.position = Vector2(4, -3) + Vector2((flame.texture.get_width() * 0.5/source_ratio.x - (BASE_X[current_frame] - X[current_frame])) * ratio, (256 - 475) * ratio)

func rest() -> void:
	sync_state()
