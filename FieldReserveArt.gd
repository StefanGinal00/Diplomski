@tool
extends RefCounted
const DISPLAY_SCALE := 0.23 # About 61 x 27 world units: below the player's chest.
## Raster replacement for decorative reserve-status markers. No gameplay nodes.
const PROFILES := {
	"shaft": {"path": "res://art/visual_slice/shaft_reserve_v1.png", "region": Rect2(62, 55, 1673, 745), "body": "Plaque", "seals": ["GuardianSeal0", "GuardianSeal1"], "old_centers": [Vector2(-21, -77), Vector2(46, -77)], "centers": [Vector2(-54, -60), Vector2(52, -60)], "latch": "ReserveSeal", "latch_center": Vector2(11, -30), "latch_y": -33.0},
	"ash": {"path": "res://art/visual_slice/ash_reserve_v1.png", "region": Rect2(18, 33, 1772, 796), "body": "ReserveStone", "seals": ["FieldSeal", "GuardianSeal"], "old_centers": [Vector2(-65, -78), Vector2(65, -78)], "centers": [Vector2(-58, -52), Vector2(58, -52)], "latch": "ReserveLatch", "latch_center": Vector2(0, -25), "latch_y": -29.0},
	"starfall": {"path": "res://art/visual_slice/starfall_reserve_v1.png", "region": Rect2(33, 108, 1743, 707), "body": "ReserveStone", "seals": ["TaskSeal", "GuardSeal"], "old_centers": [Vector2(-60, -75), Vector2(60, -75)], "centers": [Vector2(-66, -51), Vector2(67, -51)], "latch": "ReserveLatch", "latch_center": Vector2(0, -26), "latch_y": -32.0},
}


static func attach(site: Node2D, kind: String) -> Sprite2D:
	if site.has_node("PaintedReserve"):
		return site.get_node("PaintedReserve") as Sprite2D
	if not PROFILES.has(kind):
		return null
	var profile: Dictionary = PROFILES[kind]
	var texture := load(str(profile.path)) as Texture2D
	var body := site.get_node_or_null(profile.body) as Polygon2D
	if texture == null or body == null or body.get_child_count() != 0:
		return null # Keep the original display if a resource/layout is missing.
	for named in profile.seals:
		if not site.get_node_or_null(named) is Line2D: return null
	var latch := site.get_node_or_null(profile.latch) as Line2D
	if latch == null: return null
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = profile.region
	atlas.filter_clip = true
	var sprite := Sprite2D.new()
	sprite.name = "PaintedReserve"
	sprite.texture = atlas
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	sprite.offset = Vector2(0, -atlas.get_height() * 0.5)
	sprite.scale = Vector2.ONE * 264.0 * DISPLAY_SCALE / atlas.get_width()
	sprite.set_meta("reserve_art_kind", kind)
	site.add_child(sprite)
	site.move_child(sprite, 0)
	if kind == "shaft":
		# Mine bracing uses -1 too; the later-authored marker belongs in front
		# of those background timbers, but stays behind z=0 walkable terrain.
		site.z_index = -1
	body.hide()
	# Keep the actual controller-owned indicators, including their visibility,
	# colors and saved-state updates. Fit them to the painted medallion sockets.
	for index in range(2):
		var seal := site.get_node(profile.seals[index]) as Line2D
		seal.scale = Vector2.ONE * 0.34 * DISPLAY_SCALE
		seal.position = (profile.centers[index] - profile.old_centers[index] * 0.34) * DISPLAY_SCALE
		seal.width = 4
	latch.scale = Vector2.ONE * 0.45 * DISPLAY_SCALE
	latch.position = (Vector2(0, float(profile.latch_y)) - profile.latch_center * 0.45) * DISPLAY_SCALE
	latch.width = 4
	var arrow := site.get_node_or_null("ClimbArrow") as Line2D
	if arrow != null:
		arrow.scale = Vector2.ONE * 0.6 * DISPLAY_SCALE
		arrow.position = Vector2(-92, -4) * DISPLAY_SCALE
	return sprite
