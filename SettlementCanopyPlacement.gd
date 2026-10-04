extends RefCounted
## Static layout only: keep cloth and slim posts clear of actual openings.
const Facades := preload("res://FacadePropAtlas.gd")

static func openings(canvas: Node2D) -> Array[Rect2]:
	var result: Array[Rect2] = []
	var room := canvas.get_parent()
	var inverse := canvas.global_transform.affine_inverse()
	var painter := room.get_node_or_null("PaintedBuildings")
	if painter != null:
		for window in painter.window_art:
			result.append(inverse * painter.global_transform * window.rect.grow(2))
	var facade := room.get_node_or_null("ResidentialFacadeDetails")
	if facade != null:
		for entry in facade.entries:
			if entry.kind != "door": continue
			var index: int = facade.family + (3 if entry.index % 2 else 0)
			result.append(inverse * facade.global_transform * Facades.contact_rect(0,index,entry.at,entry.height,entry.width).grow(2))
	return result

static func fit(canvas: Node2D, floors: Array[Rect2], requested: Vector2, width: float, height: float, texture: Texture2D, reserves: Array[Rect2]) -> Dictionary:
	var inverse := canvas.global_transform.affine_inverse()
	var local_floors: Array[Rect2] = []
	for surface in floors: local_floors.append(inverse * surface)
	var best := {}
	var best_score := INF
	for index in local_floors.size():
		var surface := local_floors[index]
		if absf(surface.position.y-requested.y)>55: continue
		for ratio in [1.0,0.85,0.7,0.55,0.5]:
			var fitted_width: float = width*ratio
			if surface.size.x < fitted_width+4: continue
			for shift in [0,-18,18,-36,36,-54,54,-72,72,-90,90]:
				var x := clampf(requested.x+shift,surface.position.x+fitted_width/2+2,surface.end.x-fitted_width/2-2)
				if absf(x-requested.x)>100: continue
				for rise in [0,16,32,48,64]:
					var fitted_height: float = height+rise
					for ceiling in local_floors:
						if ceiling.end.y >= surface.position.y-5 or ceiling.position.x >= x+fitted_width/2 or ceiling.end.x <= x-fitted_width/2: continue
						fitted_height=minf(fitted_height,surface.position.y-ceiling.end.y-7)
					if fitted_height < 48: continue
					var at := Vector2(x,surface.position.y)
					var cloth := Rect2(at-Vector2(fitted_width/2,fitted_height),texture.get_size()*(fitted_width/texture.get_width()))
					var posts: Array[Rect2] = []
					for side in [-1,1]: posts.append(Rect2(x+side*fitted_width*0.41-5,cloth.position.y+8,10,fitted_height-8))
					var clear := true
					for obstacle in reserves:
						if cloth.intersects(obstacle) or posts[0].intersects(obstacle) or posts[1].intersects(obstacle): clear=false;break
					if not clear: continue
					var body := Rect2(cloth.position,Vector2(fitted_width,fitted_height-1))
					for floor_rect in local_floors:
						if body.intersects(floor_rect): clear=false;break
					if not clear: continue
					var score := absf(x-requested.x)+absf(at.y-requested.y)*2+absf(fitted_height-height)*0.5+(width-fitted_width)*0.8
					if score >= best_score: continue
					best_score=score
					best={"mode":"canopy","at":at,"width":fitted_width,"height":fitted_height,"cloth":cloth,"posts":posts,"support":floors[index]}
	return best

static func fit_counter(canvas: Node2D, floors: Array[Rect2], requested: Vector2, texture: Texture2D, height: float, reserves: Array[Rect2]) -> Dictionary:
	# A low covered shelf is not room for a tent. Keep a compact open counter
	# rather than stretching cloth through the ceiling or covering a doorway.
	var inverse := canvas.global_transform.affine_inverse()
	var best := {}
	var best_score := INF
	for support in floors:
		var surface: Rect2 = inverse * support
		if absf(surface.position.y-requested.y)>55: continue
		for ratio in [1.0,0.8,0.65]:
			var size := texture.get_size()*(height*float(ratio)/texture.get_height())
			if surface.size.x<size.x+4: continue
			for shift in [0,-18,18,-36,36,-54,54,-72,72,-90,90]:
				var x := clampf(requested.x+shift,surface.position.x+size.x/2+2,surface.end.x-size.x/2-2)
				if absf(x-requested.x)>100: continue
				var at := Vector2(x,surface.position.y)
				var rect := Rect2(at-Vector2(size.x/2,size.y),size)
				var clear := true
				for obstacle in reserves:
					if rect.intersects(obstacle): clear=false;break
				if not clear: continue
				for floor_rect in floors:
					if (canvas.global_transform * Rect2(rect.position,rect.size-Vector2(0,0.1))).intersects(floor_rect): clear=false;break
				if not clear: continue
				var score := absf(x-requested.x)+absf(at.y-requested.y)*2+(height-size.y)*2
				if score >= best_score: continue
				best_score=score
				best={"mode":"counter","at":at,"counter":rect,"support":support}
	return best
