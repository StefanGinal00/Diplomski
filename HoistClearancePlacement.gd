extends RefCounted
## Fit painted hoists below actual shelves; never move native lift/arrival.
const Atlas := preload("res://StructureAtlas.gd")
const Support := preload("res://WorldSupport.gd")

static func plan(actor: Node2D, floor_rect: Rect2, index: int, nodes: Array[Node]) -> Dictionary:
	var solids := Support.solids(nodes)
	var probe := Sprite2D.new()
	var best := {}
	var score := INF
	for width in [69.0,62.0,54.0,48.0,42.0]:
		Atlas.configure(probe,Atlas.HOISTS,Atlas.HOIST_SIZE,Atlas.HOIST_RECTS[index],width)
		var size: Vector2 = probe.get_rect().size * probe.scale
		for step in 18:
			var y := -62.0 + step*4.0
			if y + size.y*0.5 > -7: continue
			# Adjacent authored floor segments can differ by one pixel. Posts
			# intentionally enter this tiny footing band; do not reject an entire
			# otherwise clear gantry for contact with that real supporting ground.
			var volume := Rect2(Vector2(actor.global_position.x-size.x*0.5,floor_rect.position.y+y-size.y*0.5),Vector2(size.x,-y+size.y*0.5-2))
			if volume.position.x < floor_rect.position.x+0.5 or volume.end.x > floor_rect.end.x-0.5: continue
			var clear := true
			for solid in solids:
				if volume.intersects(solid): clear = false; break
			if not clear: continue
			var candidate: float = (69-width)*1.5+absf(y+62)
			if candidate >= score: continue
			score = candidate
			best = {"mode":"gantry","width":width,"head":Vector2(0,y),"volume":volume}
	probe.free()
	# Keep the actual deck/native interaction in an impossible cramped site,
	# rather than inventing a head/post which passes through solid terrain.
	if best.is_empty(): best = {"mode":"deck_only","width":42.0,"head":Vector2(0,-18),"volume":Rect2()}
	return best
