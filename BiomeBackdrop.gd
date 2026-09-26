@tool
extends Control

## Lightweight screen-space parallax used behind every room. Gameplay rooms
## keep their authored local silhouettes; this layer gives the four regions a
## distinct sense of depth without adding physics bodies or save state.

const PALETTES := {
	"training": {
		"top": Color("071120"), "bottom": Color("102b38"),
		"far": Color("0b2632"), "mid": Color("113a45"), "near": Color("174c55"),
		"accent": Color("54d6cc"),
	},
	"shaft": {
		"top": Color("040c15"), "bottom": Color("0a202b"),
		"far": Color("071923"), "mid": Color("0b2b35"), "near": Color("103b43"),
		"accent": Color("45b8bd"),
	},
	"echo": {
		"top": Color("060a1d"), "bottom": Color("102b40"),
		"far": Color("0a1730"), "mid": Color("12334a"), "near": Color("174b5c"),
		"accent": Color("66e3dc"),
	},
	"echo_town": {
		"top": Color("091329"), "bottom": Color("174151"),
		"far": Color("102b42"), "mid": Color("1b4e5a"), "near": Color("276b68"),
		"accent": Color("9af4ce"),
	},
	"ash": {
		"top": Color("16080b"), "bottom": Color("3b1715"),
		"far": Color("271014"), "mid": Color("4b211e"), "near": Color("6a3126"),
		"accent": Color("ff9b4d"),
	},
	"ash_town": {
		"top": Color("171014"), "bottom": Color("452521"),
		"far": Color("2c1b20"), "mid": Color("53332c"), "near": Color("714936"),
		"accent": Color("ffc072"),
	},
	"starfall": {
		"top": Color("050619"), "bottom": Color("17183d"),
		"far": Color("0d1030"), "mid": Color("20204b"), "near": Color("33255b"),
		"accent": Color("b7a8ff"),
	},
	"starfall_town": {
		"top": Color("080b20"), "bottom": Color("25264d"),
		"far": Color("141735"), "mid": Color("30315d"), "near": Color("494270"),
		"accent": Color("e0d1ff"),
	},
}

var game_state: Node
var player: Node2D
var current_biome := "training"
var target_biome := "training"
var previous_biome := "training"
var transition := 1.0
var elapsed := 0.0
var redraw_clock := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	resized.connect(queue_redraw)
	if Engine.is_editor_hint():
		queue_redraw()
		return
	game_state = get_node_or_null("/root/GameState")
	player = get_tree().get_first_node_in_group("player") as Node2D
	if game_state != null:
		game_state.room_changed.connect(_on_room_changed)
		game_state.mode_changed.connect(_on_mode_changed)
		_set_room(str(game_state.current_room_id), true)
	queue_redraw()


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	elapsed += delta
	redraw_clock += delta
	if transition < 1.0:
		transition = minf(1.0, transition + delta / 0.8)
	if redraw_clock >= 0.05:
		redraw_clock = 0.0
		if player == null:
			player = get_tree().get_first_node_in_group("player") as Node2D
		queue_redraw()


func _on_mode_changed(_mode: String) -> void:
	if game_state != null:
		_set_room(str(game_state.current_room_id), true)


func _on_room_changed(room_id: String) -> void:
	_set_room(room_id, false)


func _set_room(room_id: String, immediate: bool) -> void:
	var next_biome := biome_for_room(room_id)
	if immediate:
		current_biome = next_biome
		previous_biome = next_biome
		target_biome = next_biome
		transition = 1.0
	elif next_biome != target_biome:
		previous_biome = current_biome if transition >= 1.0 else target_biome
		target_biome = next_biome
		current_biome = next_biome
		transition = 0.0
	queue_redraw()


func biome_for_room(room_id: String) -> String:
	if room_id == "echo_haven":
		return "echo_town"
	if room_id == "ash_hearth":
		return "ash_town"
	if room_id == "starfall_citadel":
		return "starfall_town"
	if room_id.begins_with("shaft_") or room_id == "sunken_shaft":
		return "shaft"
	if room_id.begins_with("echo_"):
		return "echo"
	if room_id.begins_with("ash_"):
		return "ash"
	if room_id.begins_with("starfall_"):
		return "starfall"
	return "training"


func _color(key: String) -> Color:
	var from_palette: Dictionary = PALETTES.get(previous_biome, PALETTES["training"])
	var to_palette: Dictionary = PALETTES.get(target_biome, PALETTES["training"])
	var blend := smoothstep(0.0, 1.0, transition)
	return (from_palette[key] as Color).lerp(to_palette[key] as Color, blend)


func _draw() -> void:
	var viewport_size := size
	if viewport_size.x < 2.0 or viewport_size.y < 2.0:
		viewport_size = get_viewport_rect().size
	var top := _color("top")
	var bottom := _color("bottom")
	draw_polygon(
		PackedVector2Array([Vector2.ZERO, Vector2(viewport_size.x, 0.0), viewport_size, Vector2(0.0, viewport_size.y)]),
		PackedColorArray([top, top, bottom, bottom])
	)
	var px := player.global_position.x if player != null else 0.0
	var py := player.global_position.y if player != null else 0.0
	draw_colored_polygon(_ridge(viewport_size, 0.49, 0.045, px * 0.012, py * 0.006, 0.4), _color("far"))
	draw_colored_polygon(_ridge(viewport_size, 0.66, 0.075, px * 0.025, py * 0.012, 1.8), _color("mid"))
	draw_colored_polygon(_ridge(viewport_size, 0.84, 0.1, px * 0.045, py * 0.02, 3.1), _color("near"))
	_draw_biome_motifs(viewport_size, px)


func _ridge(viewport_size: Vector2, baseline_ratio: float, amplitude_ratio: float, scroll: float, vertical_scroll: float, phase: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	points.append(Vector2(-70.0, viewport_size.y + 20.0))
	var samples := 18
	for index in range(samples + 1):
		var x := -70.0 + (viewport_size.x + 140.0) * float(index) / float(samples)
		var wave_x := x + scroll
		var wave := sin(wave_x * 0.010 + phase) * 0.56 + sin(wave_x * 0.021 + phase * 1.7) * 0.29 + sin(wave_x * 0.0043 + phase * 0.7) * 0.15
		var y := viewport_size.y * baseline_ratio + wave * viewport_size.y * amplitude_ratio - fposmod(vertical_scroll, 28.0)
		points.append(Vector2(x, y))
	points.append(Vector2(viewport_size.x + 70.0, viewport_size.y + 20.0))
	return points


func _draw_biome_motifs(viewport_size: Vector2, player_x: float) -> void:
	var accent := _color("accent")
	var family := target_biome
	if family in ["shaft", "training"]:
		for index in range(9):
			var x := fposmod(float(index) * 173.0 - player_x * 0.018, viewport_size.x + 180.0) - 90.0
			var beam_height := viewport_size.y * (0.18 + 0.035 * float(index % 4))
			draw_rect(Rect2(Vector2(x, viewport_size.y * 0.53 - beam_height), Vector2(8.0, beam_height)), Color(accent.r, accent.g, accent.b, 0.13))
			draw_circle(Vector2(x + 4.0, viewport_size.y * 0.53 - beam_height), 3.0, Color(accent.r, accent.g, accent.b, 0.42))
	elif family in ["echo", "echo_town"]:
		for index in range(13):
			var x := fposmod(float(index) * 119.0 - player_x * 0.022, viewport_size.x + 120.0) - 60.0
			var base_y := viewport_size.y * (0.79 - 0.035 * float(index % 3))
			var crystal_h := 28.0 + 12.0 * float(index % 4)
			draw_colored_polygon(PackedVector2Array([Vector2(x - 8.0, base_y), Vector2(x, base_y - crystal_h), Vector2(x + 9.0, base_y)]), Color(accent.r, accent.g, accent.b, 0.22))
	elif family in ["ash", "ash_town"]:
		for index in range(24):
			var speed := 11.0 + float(index % 5) * 4.0
			var x := fposmod(float(index) * 83.0 - player_x * 0.014 + sin(elapsed + float(index)) * 22.0, viewport_size.x + 80.0) - 40.0
			var y := viewport_size.y - fposmod(float(index) * 47.0 + elapsed * speed, viewport_size.y + 80.0)
			draw_circle(Vector2(x, y), 1.5 + float(index % 3), Color(accent.r, accent.g, accent.b, 0.2 + 0.08 * float(index % 3)))
	else:
		for index in range(28):
			var x := fposmod(float(index) * 97.0 - player_x * 0.009, viewport_size.x + 60.0) - 30.0
			var y := fposmod(float(index * index) * 31.0 + float(index) * 19.0, viewport_size.y * 0.72)
			var pulse := 0.35 + 0.25 * sin(elapsed * 1.4 + float(index) * 0.8)
			draw_circle(Vector2(x, y), 1.1 + float(index % 2), Color(accent.r, accent.g, accent.b, pulse))
	if family.ends_with("town"):
		for index in range(11):
			var x := fposmod(float(index) * 151.0 - player_x * 0.032, viewport_size.x + 100.0) - 50.0
			var y := viewport_size.y * (0.58 + 0.045 * float(index % 4))
			draw_rect(Rect2(Vector2(x, y), Vector2(7.0, 11.0)), Color(accent.r, accent.g, accent.b, 0.36))
