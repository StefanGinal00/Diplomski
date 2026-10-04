extends Node2D
## Presentation reads the native phase; never advances a timer or inflicts damage.
const Machine = preload("res://FieldMachineryArt.gd")
const STEAM := preload("res://art/visual_slice/steam_water_hazards_v1.png")
const FIRE := preload("res://art/visual_slice/fire_soul_hazards_v1.png")
const ROOTS := preload("res://art/visual_slice/rubble_root_hazards_v1.png")
# Generated rows are not perfectly regular here. Audited cutouts avoid pulling
# the rockfall row's lower debris into the thorn frame's upper edge.
const ROOT_CROPS := [Rect2(20, 483, 420, 402), Rect2(447, 454, 433, 431), Rect2(890, 455, 435, 430), Rect2(1335, 478, 437, 407)]
const ROCK_CROPS := [Rect2(0, 0, 443, 458), Rect2(444, 0, 443, 453), Rect2(888, 0, 443, 451), Rect2(1332, 0, 440, 474)]
const LABELS := {"pressure": "STEAM", "water": "SURGE", "fire": "FIRE", "soul": "SOUL RIFT", "rockfall": "FALLING ROCKS", "roots": "THORNS", "current": "CURRENT"}
var kind := "pressure"
var hazard: Area2D
var bounds := Rect2()
var phase := "idle"
var frame := 0
var age := 0.0
var redraw_clock := 0.0
var updates := 0
var caption: Label
var notifier: VisibleOnScreenNotifier2D

static func attach(actor: Area2D, style: String) -> Node2D:
	if actor.has_node("HazardArt"): return actor.get_node("HazardArt")
	var art := new()
	art.name = "HazardArt"
	art.kind = style
	actor.add_child(art)
	return art

func _ready() -> void:
	hazard = get_parent()
	var col: CollisionShape2D = hazard.get_node("CollisionShape2D")
	if not col.shape is RectangleShape2D: return
	bounds = col.transform * Rect2(-col.shape.size * 0.5, col.shape.size)
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	z_index = 1
	for named in ["HazardFill", "WarningLine", "DirectionMarks", "Flame", "Base", "RootBed", "PulseBase", "Water", "Crest", "StreamA", "StreamB", "DirectionArrow"]:
		var old := hazard.get_node_or_null(named) as CanvasItem
		if old != null: old.hide()
	notifier = VisibleOnScreenNotifier2D.new()
	notifier.rect = bounds.grow(50)
	add_child(notifier)
	notifier.screen_entered.connect(func(): set_process(true); refresh(0))
	notifier.screen_exited.connect(func(): set_process(false))
	caption = Label.new()
	caption.add_theme_font_size_override("font_size", 9)
	caption.add_theme_constant_override("outline_size", 3)
	caption.add_theme_color_override("font_outline_color", Color("11141a"))
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	# Native hazards can be squeezed horizontally: never squash their lettering.
	caption.scale = Vector2.ONE / global_scale.abs().max(Vector2(0.01, 0.01))
	caption.position = bounds.position + Vector2(4, 12)
	caption.size = Vector2(180, 16)
	add_child(caption)
	refresh(0)
	set_process(false) # Notifier enables rendering updates only near the camera.

func _process(delta: float) -> void:
	age += delta
	redraw_clock += delta
	var native := _native_phase()
	if redraw_clock < 1.0 / 16.0 and native == phase: return
	redraw_clock = 0
	refresh(delta)

func _native_phase() -> String:
	if kind == "current":
		return "disabled" if (hazard.get("calmed") == true or hazard.get("disabled") == true) else "flow"
	return "disabled" if hazard.get("disabled") == true else str(hazard.phase)

func refresh(_delta: float = 0) -> void:
	var native := _native_phase()
	if native != phase: age = 0
	phase = native
	frame = int(age * 9) % 4
	updates += 1
	caption.visible = phase in ["warning", "active"]
	caption.text = LABELS[kind] + (" - MOVE CLEAR" if phase == "warning" else " - DANGER")
	caption.modulate = Color("f3cf88") if phase == "warning" else Color("ffd1b0")
	queue_redraw()

func source_frame(index: int = -1) -> Rect2:
	var texture := _sheet()
	var selected := frame if index < 0 else index
	if kind in ["roots", "rockfall"]:
		var crop: Rect2 = ROOT_CROPS[selected] if kind == "roots" else ROCK_CROPS[selected]
		var fit := texture.get_size() / Vector2(1774, 887)
		return Rect2(crop.position * fit, crop.size * fit)
	var cell := texture.get_size() / Vector2(4, 2)
	var row := 1 if kind in ["water", "current", "soul", "roots"] else 0
	return Rect2(Vector2(selected, row) * cell + Vector2.ONE, cell - Vector2(2, 2))

func _sheet() -> Texture2D:
	if kind in ["fire", "soul"]: return FIRE
	if kind in ["rockfall", "roots"]: return ROOTS
	return STEAM

func _draw() -> void:
	if not bounds.has_area(): return
	var foot := bounds.end.y
	var cells := clampi(ceili(bounds.size.x * global_scale.x / 62.0), 1, 12)
	var step := bounds.size.x / cells
	# Concrete, quiet sources remain visible while the danger is idle/disabled.
	for i in range(cells):
		var x := bounds.position.x + (i + 0.5) * step
		if kind in ["pressure", "fire"]:
			draw_texture_rect_region(Machine.SHEET, Rect2(x - minf(step * 0.4, 23), foot - 4, minf(step * 0.8, 46), 9), Machine.crop(3), Color("acaaa1"))
		elif kind in ["water", "current"]:
			draw_texture_rect_region(Machine.SHEET, Rect2(x - 15, foot - 12, 30, 15), Machine.crop(4), Color("73999d"))
		elif kind == "soul":
			var sigil = preload("res://PickupMaterialArt.gd")
			draw_texture_rect_region(sigil.LOOT, Rect2(x - 16, foot - 7, 32, 9), sigil.LOOT_CROPS[1], Color("b6a5bf"))
		else:
			var texture := preload("res://art/visual_slice/echo_path_stone_v1.png")
			var y := bounds.position.y - 5 if kind == "rockfall" else foot - 4
			draw_texture_rect_region(texture, Rect2(x - step * 0.5, y, step, 7), Rect2(0, 0, 160, 35), Color("647271"))
	if phase == "disabled": return
	var warning := phase == "warning"
	var active := phase in ["active", "flow"]
	if warning or active:
		var tint := Color("ecc284") if warning else Color("f4d6b6")
		if phase == "flow": tint = Color("81bed2")
		# Solid endpoints and a restrained dashed baseline state the whole footprint.
		for side in [bounds.position.x, bounds.end.x]:
			draw_line(Vector2(side, foot), Vector2(side, foot - 12), tint, 1.4, true)
		for x in range(int(bounds.position.x), int(bounds.end.x), 16):
			draw_line(Vector2(x, foot), Vector2(minf(x + 7, bounds.end.x), foot), tint, 1.1, true)
		for i in range(cells):
			var x := bounds.position.x + i * step
			var h := bounds.size.y * (0.18 if warning else 1.0)
			var y := foot - h
			if warning and kind == "rockfall": y = bounds.position.y
			var opacity := 0.62 if warning else (0.48 if phase == "flow" else 0.88)
			draw_texture_rect_region(_sheet(), Rect2(x, y, step, h), source_frame((frame + i) % 4), Color(1, 1, 1, opacity))
		if phase == "flow":
			var direction: float = signf(hazard.force.x) if hazard.get("force") != null else signf(hazard.flow_velocity.x)
			for i in range(cells):
				var at := Vector2(bounds.position.x + fposmod(i * step + age * 25 * direction, bounds.size.x), bounds.get_center().y)
				draw_polyline(PackedVector2Array([at + Vector2(-5 * direction, -3), at, at + Vector2(-5 * direction, 3)]), Color("b8e0df"), 1.1, true)
