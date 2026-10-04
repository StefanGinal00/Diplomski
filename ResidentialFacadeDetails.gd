@tool
extends Node2D
## Explicit facade-only replacements; no interactions, actors or collisions.
const Art := preload("res://FacadePropAtlas.gd")
const Joinery := preload("res://SettlementDetailAtlas.gd")
const Wares := preload("res://WorkplaceAtlas.gd")
const Support := preload("res://WorldSupport.gd")
const Expansion := preload("res://EchoSettlementExpansion.gd")
const Canopies := preload("res://SettlementCanopyPlacement.gd")
var entries: Array[Dictionary] = []
var retired: Array[CanvasItem] = []
var floors: Array[Rect2] = []
var built := false
var family := 0
var canopies_fitted := false

func _ready() -> void:
	z_index = -1
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	set_process(false)
	call_deferred("_build")

func _build() -> void:
	if built: return
	var room := get_parent() as Node2D
	family = 1 if room.name=="CinderHearth" else 0
	var nodes: Array[Node] = []
	nodes.assign(room.find_children("*","",true,false))
	floors = Support.floors(nodes)
	var house_regex := RegEx.new()
	house_regex.compile("^(LowerHome[0-9]+|TerraceHome[0-9]+_[0-9]+)Door$")
	for node in nodes:
		if not node is Polygon2D or node.get_child_count()!=0 or node.polygon.is_empty(): continue
		var named := String(node.name)
		var parent: Node = node.get_parent()
		var echo_expansion: bool = parent.get_script()==Expansion
		var root_door: bool = parent==room and named in ["LeftHomeDoorVisual","MarketDoorVisual","RightHomeDoorVisual","HearthDoor","MarketDoor","SmithyDoor"]
		if root_door or (echo_expansion and house_regex.search(named)!=null):
			var bounds := _bounds(node)
			var at := Vector2(bounds.get_center().x,bounds.end.y)
			if _supported("door",at,44,absi(named.hash())%2,34):
				_retire(node)
				for suffix in ["Frame","Trim","Glow"]:
					_retire(parent.get_node_or_null(named.trim_suffix("Visual")+suffix))
		elif echo_expansion and named.ends_with("Chimney"):
			var bounds := _bounds(node)
			entries.append({"kind":"chimney","index":5,"at":Vector2(bounds.get_center().x,bounds.end.y),"height":bounds.size.y,"width":bounds.size.x+12,"support":Rect2()})
			_retire(node)
		elif echo_expansion and named.begins_with("GateAwning"):
			var bounds := _bounds(node)
			_supported("canopy",Vector2(bounds.get_center().x,bounds.end.y+40),92,3,90)
			_retire(node)
		elif family==1 and parent.name=="EasternDistricts" and named in preload("res://PaintedSettlementBuildings.gd").CINDER_HOMES:
			var bounds := _bounds(node)
			_supported("door",Vector2(bounds.get_center().x,bounds.end.y),44,absi(named.hash())%2,34)
	built = true
	# Shared art is drawn after the older facade strokes at the same depth.
	room.move_child(self,-1)
	# PaintedBuildings resolves balcony-safe windows later in the same deferred
	# build batch. Refit against those final openings, not the old sketch boxes.
	call_deferred("_refit_canopies")
	queue_redraw()

func _refit_canopies() -> void:
	if canopies_fitted: return
	var reserves := Canopies.openings(self)
	for entry in entries:
		if entry.kind != "canopy": continue
		var fitted := Canopies.fit(self,floors,entry.at,entry.width,entry.height,Wares.texture_for(entry.index),reserves)
		entry["layout"] = fitted
		if fitted.is_empty(): continue # Retain no floating/occluding cloth.
		entry.at=fitted.at;entry.width=fitted.width;entry.height=fitted.height;entry.support=fitted.support
		reserves.append(fitted.cloth)
		reserves.append_array(fitted.posts)
	canopies_fitted = true
	queue_redraw()

func _bounds(node: Polygon2D) -> Rect2:
	var rect := Rect2(to_local(node.to_global(node.polygon[0])),Vector2.ZERO)
	for point in node.polygon: rect = rect.expand(to_local(node.to_global(point)))
	return rect

func _retire(node: Node) -> void:
	if node is CanvasItem and node.get_child_count()==0 and not node in retired:
		node.hide()
		retired.append(node)

func _supported(kind: String, at: Vector2, height: float, index: int, width: float) -> bool:
	if kind=="canopy":
		# Some schematic awnings straddle a shelf gap. Move scenery only to
		# the nearby shelf; never invent a floor or move the traversable route.
		var best_score := INF
		var best := Rect2()
		var base := to_global(at)
		for candidate in floors:
			if candidate.size.x<width+4 or absf(candidate.position.y-base.y)>55: continue
			var x := clampf(base.x,candidate.position.x+width/2+2,candidate.end.x-width/2-2)
			if absf(x-base.x)>95: continue
			var score := absf(x-base.x)+absf(candidate.position.y-base.y)
			if score<best_score:
				best_score = score
				best = candidate
		if not best.has_area(): return false
		base.x = clampf(base.x,best.position.x+width/2+2,best.end.x-width/2-2)
		base.y = best.position.y
		for ceiling in floors:
			if ceiling.end.y>=base.y-5 or ceiling.position.x>=base.x+width/2 or ceiling.end.x<=base.x-width/2: continue
			height=minf(height,base.y-ceiling.end.y-7)
		if height<48: return false
		entries.append({"kind":kind,"index":index,"at":to_local(base),"height":height,"width":width,"support":best})
		return true
	var query := to_global(at-Vector2(0,14))
	var floor_rect := Rect2()
	# A narrow stair under the center is not a support for two distant posts.
	# Select the closest surface that supports the entire footprint.
	for candidate in floors:
		if query.x-width/2<candidate.position.x or query.x+width/2>candidate.end.x: continue
		if candidate.position.y<query.y-2 or candidate.position.y>query.y+80: continue
		if not floor_rect.has_area() or candidate.position.y<floor_rect.position.y: floor_rect = candidate
	if not floor_rect.has_area(): return false
	var local_floor := Rect2(to_local(floor_rect.position),floor_rect.size)
	if at.x-width/2<local_floor.position.x or at.x+width/2>local_floor.end.x: return false
	entries.append({"kind":kind,"index":index,"at":Vector2(at.x,local_floor.position.y),"height":height,"width":width,"support":floor_rect})
	return true

func _draw() -> void:
	for entry in entries:
		match entry.kind:
			"door": Art.door(self,Rect2(entry.at-Vector2(entry.width/2,entry.height),Vector2(entry.width,entry.height)),family,entry.index)
			"chimney": Art.draw_at(self,1,5,entry.at,entry.height,entry.width)
			"canopy":
				if not entry.has("layout") or entry.layout.is_empty(): continue
				var image := Wares.texture_for(entry.index)
				var size: Vector2 = image.get_size()*(entry.width/image.get_width())
				var top: Vector2 = entry.at-Vector2(size.x/2,entry.height)
				# Timber uprights reach the real floor and the canopy's top seam.
				for side in [-1,1]:
					var x: float = entry.at.x+side*(size.x*0.41)
					# Narrow structural timber, not person-wide masonry pedestals.
					var post := Joinery.texture_for(2,0)
					draw_texture_rect(post,Rect2(x-5,entry.at.y-entry.height+8,10,entry.height-8),false)
				draw_texture_rect(image,Rect2(top,size),false)
