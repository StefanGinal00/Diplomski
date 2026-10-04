extends Node2D
## One registered cutout. Only soft details join the existing camera wind budget.
const Atlas := preload("res://RouteDressingAtlas.gd")
const Town := preload("res://TownVergeAtlas.gd")
var art: Sprite2D
var footprint := Rect2()
var support := Rect2()
var kind := "floor"
var family := "cave"
var variant := 0
var phase := 0.0
var response: RefCounted
var wind := 0.0
var town_family := ""
var contact_row := 0.0

func configure(palette: String, attachment: String, index: int, width: float, max_height: float, anchor: Vector2, floor_rect: Rect2, front := false, town := "") -> void:
	family = palette; kind = attachment; variant = index; support = floor_rect
	town_family=town if kind=="floor" else ""
	var sheet := "route_%s_%s_v1"%[family,"floor" if kind == "floor" else "ceiling"]
	art = Sprite2D.new(); art.name = "RegisteredArtwork"
	art.texture=Atlas.texture(sheet,index) if town_family.is_empty() else Town.texture(town_family,index)
	art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	add_child(art)
	var dimensions := art.get_rect().size
	var ratio := minf(width/dimensions.x,max_height/dimensions.y)
	global_transform = Transform2D(0,Vector2.ONE*ratio,0,anchor)
	contact_row=Atlas.contact(sheet,index,kind != "floor") if town_family.is_empty() else Town.contact(town_family,index)
	art.offset.y = dimensions.y/2-contact_row
	z_index = 3 if front else -2
	if not front: art.modulate = Color(0.86,0.9,0.89,1)
	footprint = art.global_transform*art.get_rect()
	phase = fposmod(anchor.x*0.031+anchor.y*0.013,TAU)
	# The rear grass/flower cutout is living foliage too. Stones, machinery,
	# rubble and masonry stay rigid; only the registered soft silhouettes bend.
	if (kind == "floor" and index == 5) or (kind == "hanging" and index in [3,4]):
		set_meta("ambient_motion",true)
		response = preload("res://FoliageResponse.gd").new()
		set_meta("player_reactive",true)
	set_process(false); set_physics_process(false)

func animate(age: float) -> void:
	var gust := .65+.35*sin(age*.37+global_position.x*.004)
	wind = (sin(age*1.15+phase)*.016+sin(age*2.3+phase)*.005)*gust
	_apply_flex()

func reaction_bounds() -> Rect2:
	return footprint

func placement_bounds() -> Rect2:
	# Keep the complete new soft clump envelope clear of walls and doorways.
	# Its root remains fixed; rigid containers do not bend with their leaves.
	if town_family.is_empty() or response==null: return footprint
	var result := footprint
	for tilt in [-.445,.445]:
		var transform := global_transform*Transform2D(0,Vector2.ONE,tilt,art.position)
		result=result.merge(transform*art.get_rect())
	return result

func drip_anchor() -> Vector2:
	# Alpha-registered root tip, not the transparent bottom-centre of its box.
	# Sprite-local coordinates also carry the current rooted wind/contact skew.
	var local := art.get_rect().position+Atlas.drip_tip(family,variant)
	if art.flip_h: local.x = -local.x
	return art.to_global(local)

func brush(force: float) -> bool:
	return response.push(force*(0.75 if kind == "hanging" else 1.0))

func advance_response(delta: float) -> bool:
	var moving: bool = response.step(delta)
	_apply_flex(); return moving

func reset_response() -> void:
	if response != null: response.reset()
	_apply_flex()

func _apply_flex() -> void:
	if art == null: return
	art.rotation = 0
	art.skew = (wind+(response.bend if response != null else 0.0))*(1 if kind == "floor" else -1)

func rest() -> void:
	wind = 0
	_apply_flex()
