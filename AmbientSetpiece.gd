extends Node2D
## Shared raster cutouts. No individual process callback or collision objects.
const SHEETS := [preload("res://art/visual_slice/ambient_cave_props_v1.png"), preload("res://art/visual_slice/ambient_ash_props_v1.png"), preload("res://art/visual_slice/ambient_star_props_v1.png")]
const SOURCE_SIZE := Vector2(1536, 1024)
const CROPS := [
	[Rect2(13,73,567,389), Rect2(601,13,387,449), Rect2(1032,134,490,329), Rect2(16,557,504,374), Rect2(652,470,319,543), Rect2(1155,463,281,550)],
	[Rect2(17,97,499,317), Rect2(530,15,469,400), Rect2(1026,73,493,342), Rect2(17,524,498,407), Rect2(710,451,133,558), Rect2(1146,449,249,545)],
	[Rect2(38,171,485,239), Rect2(581,38,406,377), Rect2(1092,69,383,347), Rect2(41,572,481,368), Rect2(694,466,174,524), Rect2(1180,476,222,520)]
]
# Raw PNG alpha >= .65. Rows are crop-local: bottom for grounded art,
# top for hanging art. Computed offline, never read back in the running game.
const CONTACT := [[386,445,324,373,3,10], [315,398,340,406,2,1], [238,376,346,366,2,2]]
var family := 0
var kind := 0
var motion := 0
var phase := 0.0
var art: Sprite2D
var support := Rect2()
var footprint := Rect2()
var anchor_kind := "floor"
var response: RefCounted
var wind_rotation := 0.0
var wind_skew := 0.0

func configure(biome: int, variant: int, anchor: Vector2, height: float, solid: Rect2, attachment: String) -> void:
	family = biome
	kind = variant
	support = solid
	anchor_kind = attachment
	global_position = anchor
	z_index = -2
	set_process(false)
	art = Sprite2D.new()
	art.name = "PaintedDetail"
	var region: Rect2 = CROPS[family][kind]
	var ratio: Vector2 = SHEETS[family].get_size() / SOURCE_SIZE
	var atlas := AtlasTexture.new()
	atlas.atlas = SHEETS[family]
	atlas.region = Rect2(region.position * ratio, region.size * ratio)
	atlas.filter_clip = true
	art.texture = atlas
	art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	art.scale = Vector2.ONE * height / atlas.region.size.y
	var contact: float = CONTACT[family][kind] * ratio.y
	# AtlasTexture reports integer dimensions even for a fractional import crop.
	# Use the actual drawn rectangle, not the requested source-region height.
	art.position.y = (atlas.get_height() * 0.5 - contact) * art.scale.y
	art.modulate = [Color("9cacaa"), Color("b9a28d"), Color("aaaebb")][family]
	add_child(art)
	footprint = art.global_transform * art.get_rect()
	motion = 1 if kind == 1 else (2 if kind >= 4 else 0)
	phase = fposmod(anchor.x * 0.073 + anchor.y * 0.031, TAU)
	if motion != 0:
		set_meta("ambient_motion", true)
		set_meta("player_reactive",true)
		response = preload("res://FoliageResponse.gd").new()

func animate(time: float) -> void:
	var gust := 0.55 + 0.45 * sin(time * 0.31 + phase * 0.1)
	if motion == 1:
		wind_rotation = (sin(time * 1.35 + phase) * 0.022 + sin(time * 2.7 + phase) * 0.006) * gust
	elif motion == 2:
		wind_rotation = (sin(time * 0.9 + phase) * 0.016 + sin(time * 2.2 + phase) * 0.005) * gust
		# Two frequencies, different phases; the top attachment stays fixed.
		wind_skew = sin(time * 1.8 + phase) * 0.008 * gust
	_apply_flex()

func reaction_bounds() -> Rect2:
	return footprint

func brush(force: float) -> bool:
	return response.push(force*0.65)

func advance_response(delta: float) -> bool:
	var moving: bool = response.step(delta)
	_apply_flex(); return moving

func reset_response() -> void:
	if response != null: response.reset()
	_apply_flex()

func _apply_flex() -> void:
	rotation = wind_rotation
	skew = wind_skew+(response.bend if response != null else 0.0)*(1 if motion==1 else -1)

func rest() -> void:
	wind_rotation = 0; wind_skew = 0
	_apply_flex()
