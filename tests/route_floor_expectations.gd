extends RefCounted


static func solid_width(route: Node2D, tier: int) -> float:
	# Count the union of EVERY shaft crossing this floor, including links
	# between other chambers. The old fixed allowance assumed only two holes.
	var chamber: Rect2 = route._chamber_rect(tier)
	var cuts: Array[Vector2] = []
	for index in range(route._layout_for_room().size() - 1):
		var a: Rect2 = route._chamber_rect(index)
		var b: Rect2 = route._chamber_rect(index + 1)
		if chamber.end.y < minf(a.end.y, b.end.y) - 1 or chamber.end.y >= maxf(a.end.y, b.end.y) - 1:
			continue
		var x := (maxf(a.position.x, b.position.x) + minf(a.end.x, b.end.x)) * 0.5
		if x + 135 > chamber.position.x and x - 135 < chamber.end.x:
			cuts.append(Vector2(maxf(chamber.position.x, x - 135), minf(chamber.end.x, x + 135)))
	cuts.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.x < b.x)
	var cursor := chamber.position.x
	var result := 0.0
	for cut in cuts:
		if cut.x - cursor > 35:
			result += cut.x - cursor
		cursor = maxf(cursor, cut.y)
	if chamber.end.x - cursor > 35:
		result += chamber.end.x - cursor
	return result
