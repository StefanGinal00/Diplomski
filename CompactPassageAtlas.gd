extends RefCounted
## Narrow wall openings for real low-headroom landings, not scaled mountains.
const SHEETS := [preload("res://art/visual_slice/compact_passages_echo_v1.png"),preload("res://art/visual_slice/compact_passages_cinder_v1.png"),preload("res://art/visual_slice/compact_passages_star_v1.png")]
const SIZE := Vector2(1536,1024)
const CROPS := [[Rect2(34,77,703,872),Rect2(800,38,702,913)],[Rect2(36,63,722,872),Rect2(815,49,686,885)],[Rect2(55,14,666,960),Rect2(786,207,712,768)]]
const CONTACT := [[870,911],[870,883],[958,765]]

static func plan(x: float, floor_rect: Rect2, surfaces: Array[Rect2], family: int, seed: int) -> Dictionary:
	var width := clampf(floor_rect.size.x*0.75,112,156)
	var old_crop: Rect2=preload("res://StructureAtlas.gd").FACADES_RECTS[family]
	var old_height := width*old_crop.size.y/old_crop.size.x
	var clearance := headroom(x,width,floor_rect,surfaces)
	if clearance>=old_height+8:
		return {"compact":false,"x":x,"width":width,"height":old_height,"clearance":clearance,"frame":0}
	# A low opening uses a thin frame with a larger usable dark interior.
	# Search only inside the native interaction footprint, keeping its centre
	# reachable. We never relocate the Area2D, spawn marker or stair collider.
	var frame := 1 if family==2 else absi(seed)%2
	var crop: Rect2=CROPS[family][frame]
	var best := {}
	var score := -INF
	for offset in [0.0,-20.0,20.0]:
		var at := clampf(x+offset,floor_rect.position.x+18,floor_rect.end.x-18)
		var height := 12.0
		var available := INF
		# Test full candidate silhouettes, rather than getting stuck at the
		# tiny width chosen by an earlier collision with a neighbouring step.
		for candidate in range(92,11,-2):
			width=candidate*crop.size.x/crop.size.y
			available=headroom(at,width,floor_rect,surfaces)
			if candidate<=available-8:
				height=candidate
				break
		width=height*crop.size.x/crop.size.y
		var candidate_score := height-absf(at-x)*0.4
		if candidate_score>score:
			score=candidate_score
			best={"compact":true,"x":at,"width":width,"height":height,"clearance":available,"frame":frame}
	return best

static func headroom(x: float,width: float,floor_rect: Rect2,surfaces: Array[Rect2]) -> float:
	var available := INF
	for rect in surfaces:
		if rect.position.y>=floor_rect.position.y-20 or rect.end.y>=floor_rect.position.y-12: continue
		if rect.end.x<=x-width*0.5 or rect.position.x>=x+width*0.5: continue
		available=minf(available,floor_rect.position.y-rect.end.y)
	return available

static func configure(sprite: Sprite2D,family: int,plan: Dictionary) -> void:
	preload("res://StructureAtlas.gd").configure(sprite,SHEETS[family],SIZE,CROPS[family][plan.frame],plan.width)
	sprite.set_meta("contact_row",CONTACT[family][plan.frame]*SHEETS[family].get_height()/SIZE.y)
