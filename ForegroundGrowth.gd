extends Node2D
## Pass-through foreground, updated only by the shared visible-room budget.
const Atlas := preload("res://LivingSpriteAtlas.gd")
var art: Sprite2D
var echo: Sprite2D
var atlas_id := ""
var kind := 0
var height := 12.0
var reference_height := 1.0
var phase := 0.0
var footprint := Rect2()
var support := Rect2()
var player: Node2D
var response := preload("res://FoliageResponse.gd").new()
var wind := 0.0

func configure(family: String, variant: int, anchor: Vector2, display_height: float, floor_rect: Rect2) -> void:
	atlas_id = "foreground_%s_breeze_v1" % family
	kind = variant
	height = display_height
	support = floor_rect
	global_position = anchor
	phase = fposmod(anchor.x * 0.037 + anchor.y * 0.021, TAU)
	z_index = 3
	set_meta("ambient_motion", true)
	set_meta("foreground_growth", true)
	set_meta("player_reactive",true)
	set_process(false)
	player = get_tree().get_first_node_in_group("player") as Node2D
	for i in 4: reference_height = maxf(reference_height, Atlas.DATA[atlas_id].boxes[kind*4+i][3])
	art = Sprite2D.new()
	art.name = "Leaves"
	add_child(art)
	echo = Sprite2D.new()
	echo.name = "BreezeBlend"
	add_child(echo)
	Atlas.show(art,atlas_id,kind*4,height,0,1,reference_height,"root")
	Atlas.show(echo,atlas_id,kind*4+1,height,0,1,reference_height,"root")
	footprint = Rect2(anchor-Vector2(height*1.0,height),Vector2(height*2,height))
	modulate = Color(0.68,0.78,0.76,0.94) if family=="cave" else Color(0.8,0.77,0.72,0.94)
	rest()

func animate(age: float) -> void:
	# The sequence is a loop, with a short dissolve over actual painted poses.
	var step := fposmod(age*1.65+phase,4.0)
	var index := int(step)
	Atlas.show(art,atlas_id,kind*4+index,height,0,1,reference_height,"root")
	Atlas.show(echo,atlas_id,kind*4+(index+1)%4,height,0,1,reference_height,"root")
	var blend := smoothstep(0.0,1.0,fposmod(step,1.0))
	art.self_modulate.a=1.0-blend
	echo.self_modulate.a=blend
	wind = sin(age*1.3+phase)*0.025
	skew = wind+response.bend

func reaction_bounds() -> Rect2:
	return footprint

func brush(force: float) -> bool:
	return response.push(force)

func advance_response(delta: float) -> bool:
	var moving := response.step(delta)
	skew = wind+response.bend
	return moving

func reset_response() -> void:
	response.reset(); skew = wind

func rest() -> void:
	rotation=0
	wind = 0; skew = response.bend
	if art==null: return
	Atlas.show(art,atlas_id,kind*4,height,0,1,reference_height,"root")
	art.self_modulate.a=1
	echo.self_modulate.a=0
