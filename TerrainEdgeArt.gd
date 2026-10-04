extends Node2D
## One static draw list per horizontal solid. The alpha cutouts change only
## its face, never its collision, one-way status, support height or endpoints.
const SOURCE_SIZE := Vector2(1536, 1024)
const DATA := {
	"haven": [[Rect2(26,98,1485,109),99],[Rect2(26,320,1485,133),320],[Rect2(26,554,1485,119),554],[Rect2(26,779,1485,148),779]],
	"hearth": [[Rect2(10,100,1514,107),100],[Rect2(10,331,1514,134),331],[Rect2(9,572,1516,148),572],[Rect2(10,811,1513,135),812]],
	"street": [[Rect2(7,119,1526,107),119],[Rect2(7,338,1524,171),338],[Rect2(6,596,1524,118),596],[Rect2(7,800,1523,136),800]],
	"basalt": [[Rect2(42, 93, 1452, 162), 97], [Rect2(40, 317, 1455, 183), 320], [Rect2(42, 554, 1451, 184), 556], [Rect2(42, 783, 1452, 184), 786]],
	"citadel": [[Rect2(34, 101, 1467, 142), 104], [Rect2(31, 329, 1473, 156), 331], [Rect2(32, 560, 1472, 181), 563], [Rect2(31, 806, 1473, 158), 808]],
	"iron": [[Rect2(29, 102, 1479, 148), 108], [Rect2(29, 338, 1479, 164), 343], [Rect2(29, 565, 1479, 158), 575], [Rect2(29, 797, 1479, 153), 800]],
	"moss": [[Rect2(27, 91, 1482, 168), 95], [Rect2(27, 309, 1482, 176), 314], [Rect2(27, 543, 1482, 175), 546], [Rect2(27, 768, 1482, 187), 772]],
	"shale": [[Rect2(21, 97, 1475, 163), 105], [Rect2(31, 314, 1475, 171), 323], [Rect2(32, 545, 1473, 178), 554], [Rect2(28, 779, 1468, 177), 786]],
	"timber": [[Rect2(30, 108, 1475, 137), 111], [Rect2(31, 338, 1474, 156), 341], [Rect2(36, 574, 1465, 162), 579], [Rect2(32, 808, 1472, 139), 811]]
}
var family := ""
var variant := 0
var surface_rect := Rect2()
var sheet: Texture2D
var pieces: Array[Dictionary] = []
var visual_bounds := Rect2()
var top_error_limit := 0.0
static var sheets := {}

static func install(body: StaticBody2D, collision: CollisionShape2D, original: Polygon2D, room_id: String) -> Node2D:
	if body.has_node("TerrainEdgeArt"): return body.get_node("TerrainEdgeArt")
	var size: Vector2 = collision.shape.size
	# Irregular/sloped polygons, walls, thick buildings and tiny mechanisms
	# retain their authored geometry and existing materials.
	if size.x < 48 or size.y > 48 or size.x < size.y * 2.5: return null
	if not is_zero_approx(collision.rotation) or not original.has_meta("collision_registered"): return null
	var art := preload("res://TerrainEdgeArt.gd").new()
	art.name = "TerrainEdgeArt"
	art.family = _family(body, original, room_id)
	art.variant = posmod(String(body.get_path()).hash(), 4)
	art.surface_rect = Rect2(collision.position - size * 0.5 * collision.scale, size * collision.scale)
	if not sheets.has(art.family):
		sheets[art.family] = load("res://art/visual_slice/terrain_edge_%s_v1.png" % art.family)
	art.sheet = sheets[art.family]
	art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	art.modulate = Color("a7b4b6") if art.family in ["shale", "moss"] else Color("b4ada6")
	art._build()
	body.add_child(art)
	original.hide()
	# These older rectangular undersides otherwise show through the new
	# cutout as the same regular block stripe that this pass replaces.
	for child in body.get_children():
		if child is CanvasItem and String(child.name).begins_with("RootedLip"): child.hide()
	return art

static func _family(body: StaticBody2D, original: Polygon2D, id: String) -> String:
	if id=="echo_haven": return "haven"
	# The approach includes a real housing quarter as well as natural cave
	# ground. Dress its built streets/stairs, retaining the timber link bridge.
	if id=="echo_haven_outskirts" and body.get_parent().get_script()==preload("res://EchoSettlementExpansion.gd") and body.name!=&"OldQuarterBridge": return "haven"
	if id=="ash_hearth": return "hearth"
	if id=="starfall_citadel": return "street"
	var named := (String(body.name) + " " + String(body.get_parent().name)).to_lower()
	var old_material := original.texture.resource_path.to_lower() if original.texture != null else ""
	if "iron" in named or "gantry" in named or "catwalk" in named or "drift_iron" in old_material: return "iron"
	if "timber" in named or "wood" in named or "boardwalk" in named: return "timber"
	if "bridge" in named and not id.begins_with("starfall"):
		return "iron" if id.begins_with("ash_") else "timber"
	if id in ["ash_forge", "ash_emberspine", "ash_reservoir"] and ("platform" in named or "shelf" in named): return "iron"
	if id.begins_with("ash_"): return "basalt"
	if id.begins_with("starfall_"): return "citadel"
	if id in ["sunken_shaft", "shaft_hollow", "shaft_drift", "shaft_approach"]: return "shale"
	return "moss"

func _build() -> void:
	var entry: Array = DATA[family][variant]
	var source: Rect2 = entry[0]
	var contact_y: float = entry[1]
	# Uniform material scale. Long floors use repeated centers; short ledges
	# crop a center rather than stretching huge blocks into thin spaghetti.
	var depth := surface_rect.size.y + minf(5.0, surface_rect.size.y * 0.3)
	var factor := depth / (source.end.y - contact_y)
	var cap_pixels := 64.0
	var cap_width := cap_pixels * factor
	var y := surface_rect.position.y - (contact_y - source.position.y) * factor
	var x := surface_rect.position.x
	_add_piece(Rect2(x, y, cap_width, source.size.y * factor),
		Rect2(source.position, Vector2(cap_pixels, source.size.y)))
	x += cap_width
	var interior := Rect2(source.position + Vector2(cap_pixels, 0), source.size - Vector2(cap_pixels * 2, 0))
	var remaining := surface_rect.size.x - cap_width * 2
	while remaining > 0.01:
		var width := minf(remaining, interior.size.x * factor)
		_add_piece(Rect2(x, y, width, source.size.y * factor),
			Rect2(interior.position, Vector2(width / factor, interior.size.y)))
		x += width
		remaining -= width
	_add_piece(Rect2(surface_rect.end.x - cap_width, y, cap_width, source.size.y * factor),
		Rect2(Vector2(source.end.x - cap_pixels, source.position.y), Vector2(cap_pixels, source.size.y)))
	visual_bounds = Rect2(surface_rect.position.x, y, surface_rect.size.x, source.size.y * factor)
	top_error_limit = 10.0 * factor
	queue_redraw()

func _add_piece(destination: Rect2, source: Rect2) -> void:
	var ratio := sheet.get_size() / SOURCE_SIZE
	pieces.append({"destination":destination, "source":Rect2(source.position * ratio, source.size * ratio)})

func _draw() -> void:
	for piece in pieces:
		draw_texture_rect_region(sheet, piece.destination, piece.source, Color.WHITE, false, true)
