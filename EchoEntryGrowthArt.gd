@tool
extends Node2D
## Static grounded replacement for WorldPopulation's decorative entry triangles.
const SOURCES := {
	"fern": [preload("res://art/visual_slice/echo_cave_fern_v1.png"), Rect2(66, 54, 1366, 962), 32.0],
	"fungus": [preload("res://art/visual_slice/echo_mushrooms_v1.png"), Rect2(258, 112, 873, 927), 27.0],
	"mineral": [preload("res://art/visual_slice/echo_mineral_cluster_v1.png"), Rect2(132, 128, 627, 1548), 52.0],
}
const KINDS := {
	"EchoGrotto": ["fern", "fungus"], "EchoGallery": ["fungus", "mineral"],
	"PrismArchive": ["mineral", "fungus"], "EchoNest": ["fungus", "fern"],
	"EchoHavenOutskirts": ["fern", "fungus"],
	"ShaftHollow": ["fern", "mineral"], "DrownedCrossing": ["fern", "fungus"],
	"FloodedGallery": ["mineral", "fern"],
	"BrokenCauseway": ["mineral", "fungus"], "CinderForge": ["mineral", "fungus"],
	"EmberBarracks": ["fungus", "mineral"], "AshChapel": ["fungus", "mineral"],
	"CinderHearthOutskirts": ["fern", "fungus"],
	"StarfallOutskirts": ["fern", "mineral"], "StarfallSilentGate": ["mineral", "fungus"],
	"StarfallMemoryVault": ["mineral", "fungus"], "StarfallRootedHall": ["fern", "fern"],
}
var anchors: Array = []
var props: Array[Dictionary] = []
var retired: Array[Polygon2D] = []
var floor_rects: Array[Rect2] = []
var built := false


func _ready() -> void:
	z_index = -1
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	set_process(false)
	call_deferred("_build")


func _build() -> void:
	if built or not KINDS.has(String(get_parent().name)):
		return
	built = true
	var room := get_parent()
	for body in room.find_children("*", "StaticBody2D", true, false):
		if not body is StaticBody2D:
			continue
		var collider := body.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if collider == null or collider.disabled or not collider.shape is RectangleShape2D:
			continue
		var size: Vector2 = collider.shape.size
		floor_rects.append(global_transform.affine_inverse() * collider.global_transform * Rect2(-size * 0.5, size))
	for i in range(anchors.size()):
		var kind: String = KINDS[String(room.name)][i % 2]
		var source: Rect2 = SOURCES[kind][1]
		var dimensions: Vector2 = source.size * (float(SOURCES[kind][2]) / source.size.y)
		var desired: Vector2 = anchors[i]
		var best := {}
		var best_distance := INF
		for floor_rect in floor_rects:
			if floor_rect.size.y > 32 or floor_rect.size.x < dimensions.x + 4 or absf(floor_rect.position.y - desired.y) > 32:
				continue
			for shift in [0, -20, 20, -40, 40, -60, 60]:
				var foot := Vector2(clampf(desired.x + shift, floor_rect.position.x + dimensions.x * 0.5 + 2, floor_rect.end.x - dimensions.x * 0.5 - 2), floor_rect.position.y)
				if absf(foot.x - desired.x) > 60:
					continue
				var rect := Rect2(foot - Vector2(dimensions.x * 0.5, dimensions.y), dimensions)
				var clear := true
				for obstacle in floor_rects:
					if rect.grow(-0.05).intersects(obstacle):
						clear = false
				for prop in props:
					if rect.intersects(prop.rect.grow(2)):
						clear = false
				var distance := foot.distance_to(desired)
				if clear and distance < best_distance:
					best = {"kind": kind, "rect": rect, "support": floor_rect, "anchor": desired}
					best_distance = distance
		if not best.is_empty():
			props.append(best)
		for leaf_index in range(5):
			var leaf := room.get_node_or_null("WildGrowth%d_%d" % [i, leaf_index])
			if leaf is Polygon2D and leaf.get_child_count() == 0:
				leaf.hide()
				retired.append(leaf)
	queue_redraw()


func _draw() -> void:
	for prop in props:
		draw_texture_rect_region(SOURCES[prop.kind][0], prop.rect, SOURCES[prop.kind][1], Color(0.86, 0.94, 0.95))
