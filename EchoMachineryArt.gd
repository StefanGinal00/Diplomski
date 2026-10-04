@tool
extends Node2D
## Cosmetic pump assemblies; existing habitat/controller nodes retain authority.
const SOURCES := {
	"pump": ["res://art/visual_slice/echo_water_pump_v1.png", Rect2(78, 190, 1628, 502)],
	"dial": ["res://art/visual_slice/echo_pressure_dial_v1.png", Rect2(60, 54, 1132, 1126)],
}
var kind := "pump"
var retired: Array[CanvasItem] = []
var built := false
var calmed := false
var needle_tip := Vector2(18, -18)
var refresh_count := 0
var dial_center := Vector2(0, -99)


static func attach(site: Node2D, machine_kind: String) -> Node2D:
	var existing := site.get_node_or_null("MachineArt") as Node2D
	if existing != null:
		return existing
	var art := new()
	art.name = "MachineArt"
	art.kind = machine_kind
	site.add_child(art)
	return art


func _ready() -> void:
	set_process(false)
	call_deferred("_build")


func _build() -> void:
	if built:
		return
	var site := get_parent()
	var leaves: Array = ["Pipe", "Gauge", "GaugeNeedle"] if kind == "pump" else ["GaugePipe", "GaugeFace", "GaugeNeedle", "FlowSignal", "GaugeTick0", "GaugeTick1", "GaugeTick2", "GaugeTick3"]
	for named in leaves:
		var leaf := site.get_node_or_null(named)
		if not (leaf is Polygon2D or leaf is Line2D) or leaf.get_child_count() != 0:
			return
	var textures := {}
	for key in SOURCES:
		var source := load(SOURCES[key][0]) as Texture2D
		if source == null:
			return
		var atlas := AtlasTexture.new()
		atlas.atlas = source
		atlas.region = SOURCES[key][1]
		atlas.filter_clip = true
		textures[key] = atlas
	var pump := _sprite("Pump", textures.pump, Vector2.ZERO, 135)
	pump.offset.y = -pump.texture.get_height() * 0.5
	pump.z_index = -2 # Keep actors and readable plaques in front of machinery.
	if kind == "pressure":
		# The upper gauge has a stair across its old face. Move only the dial
		# to the clear right-hand pocket; its controller/site stays untouched.
		if site.name == "Site9":
			dial_center.x = 114
		_sprite("Dial", textures.dial, dial_center, 64)
		var overlay := Node2D.new()
		overlay.name = "Needle"
		add_child(overlay)
		overlay.draw.connect(_draw_needle.bind(overlay))
	for named in leaves:
		var leaf: CanvasItem = site.get_node(named)
		leaf.hide()
		retired.append(leaf)
	built = true
	if kind == "pressure" and not Engine.is_editor_hint():
		var state := get_node_or_null("/root/GameState")
		if state != null:
			state.shortcut_changed.connect(_on_event)
	_refresh()
	queue_redraw()


func _sprite(named: String, texture: Texture2D, at: Vector2, width: float) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.name = named
	sprite.texture = texture
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	sprite.position = at
	sprite.scale = Vector2.ONE * width / texture.get_width()
	add_child(sprite)
	return sprite


func _on_event(event_id: String) -> void:
	if event_id.begins_with("echo_tide_field_"):
		_refresh()


func _refresh() -> void:
	if not built or kind != "pressure":
		return
	# Read the native needle, which the habitat controller updates first.
	var original: Line2D = get_parent().get_node("GaugeNeedle")
	var direction := (original.points[1] - original.points[0]).normalized()
	var next_tip := direction * 21
	var next_calmed := direction.x < 0
	if next_tip == needle_tip and next_calmed == calmed:
		return
	needle_tip = next_tip
	calmed = next_calmed
	refresh_count += 1
	queue_redraw()
	get_node("Needle").queue_redraw()


func _draw() -> void:
	if not built or kind != "pressure":
		return
	# A small metal riser connects the dial to the grounded pump.
	var riser := PackedVector2Array([dial_center + Vector2(0, 30), Vector2(dial_center.x, -26), Vector2(0, -26)])
	draw_polyline(riser, Color("343f43"), 7, true)
	draw_polyline(riser, Color("8f8065"), 2, true)


func _draw_needle(canvas: Node2D) -> void:
	var center := dial_center
	var tone := Color("acdcc3") if calmed else Color("e3bd7a")
	canvas.draw_line(center - needle_tip * 0.2, center + needle_tip, tone, 2.5, true)
	canvas.draw_circle(center, 3, Color("ae9670"))
	if calmed:
		canvas.draw_polyline(PackedVector2Array([center + Vector2(-6, 12), center + Vector2(-2, 16), center + Vector2(7, 8)]), tone, 1.5, true)
