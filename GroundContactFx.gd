extends Node2D
## A single, short-lived dust pool. Driven by the shared ambience physics tick.
const LIMIT := 40
const LOW_LIMIT := 12
const Dust := preload("res://GroundDustAtlas.gd")
const COLORS := {"moss":Color("818371"),"shale":Color("7d8989"),"basalt":Color("86715e"),"citadel":Color("9a99a5"),"timber":Color("a28a66"),"iron":Color("8b8780")}
var grains: Array[Dictionary] = []
var puffs: Array[Dictionary] = []
var clearance_shape := RectangleShape2D.new()
var low_quality := false
var sampled := false
var previous := Vector2.ZERO
var previous_velocity := Vector2.ZERO
var previous_grounded := false
var distance := 0.0
var fall_distance := 0.0
var cooldown := 0.0
var serial := 0
var step_events := 0
var landing_events := 0
var last_contact := {}

func _ready() -> void:
	top_level = true; z_index = 3; set_process(false); set_physics_process(false)
	texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS

func clear() -> void:
	grains.clear(); puffs.clear(); sampled = false; distance = 0; fall_distance = 0; cooldown = 0
	previous_velocity = Vector2.ZERO; previous_grounded = false; last_contact.clear(); queue_redraw()

func set_low_quality(value: bool) -> void:
	low_quality = value
	while grains.size()>budget(): grains.pop_back()
	while puffs.size()>puff_budget(): puffs.pop_front()
	queue_redraw()

func budget() -> int:
	return LOW_LIMIT if low_quality else LIMIT

func puff_budget() -> int:
	return 3 if low_quality else 8

func track(player: Player,delta: float,palette: String) -> void:
	if not is_instance_valid(player) or player.is_dead or player.test_flight or player.test_noclip:
		clear(); return
	advance(delta)
	var at := player.global_position
	var grounded := player.is_on_floor()
	if not sampled:
		previous = at; previous_velocity = player.velocity; previous_grounded = grounded; sampled = true; return
	var moved := at-previous
	if moved.length()>180:
		clear(); return
	cooldown = maxf(0,cooldown-delta)
	if not grounded:
		if moved.y<0: fall_distance = 0
		else: fall_distance += moved.y
	var landed := grounded and not previous_grounded and previous_velocity.y>110 and fall_distance>18
	if grounded and previous_grounded and absf(player.velocity.x)>20:
		distance += moved.length()
	elif not grounded or absf(player.velocity.x)<12: distance = 0
	var stepped := grounded and distance>=(27 if player.is_crouching else 22) and cooldown<=0
	if landed or stepped:
		var contact := _support(player,palette)
		if not contact.is_empty():
			last_contact = contact
			if landed: landing_events += 1
			else: step_events += 1
			emit_contact(contact.position,contact.normal,contact.material,player.velocity.x,clampf(previous_velocity.y/420,.45,1.3) if landed else .35,landed)
		distance = 0; cooldown = .095
	previous = at; previous_velocity = player.velocity; previous_grounded = grounded
	if grounded: fall_distance = 0

func _support(player: Player,palette: String) -> Dictionary:
	var half: float = player.player_collision.shape.size.y*.5*player.player_collision.global_scale.y
	var ray := PhysicsRayQueryParameters2D.create(player.global_position,player.global_position+Vector2(0,half+player.floor_snap_length+8),1,[player.get_rid()])
	var hit := player.get_world_2d().direct_space_state.intersect_ray(ray)
	if hit.is_empty() or hit.normal.y>-.5: return {}
	var body: Object = hit.collider
	if not body is StaticBody2D or body.is_in_group("enemy") or body.is_in_group("breakable"): return {}
	var material := "basalt" if palette=="ash" else ("citadel" if palette=="star" else ("shale" if palette=="mine" else "moss"))
	if body.has_meta("walkable_relief"): material = body.plan.material
	elif body.has_node("TerrainEdgeArt"): material = body.get_node("TerrainEdgeArt").family
	if material in ["haven","hearth","street"]: material = "citadel"
	return {"position":hit.position,"normal":hit.normal,"material":material}

func emit_contact(at: Vector2,normal: Vector2,material: String,horizontal_speed: float,strength: float,landing: bool) -> void:
	_emit_puff(at,normal,material,horizontal_speed,strength,landing)
	var color: Color = COLORS.get(material,COLORS.shale)
	var amount := (4 if low_quality else 7) if landing else (1 if low_quality else 2)
	if material in ["iron","timber"]: amount = mini(amount,2)
	var tangent := Vector2(-normal.y,normal.x)
	for index in amount:
		if grains.size()>=budget(): break
		serial += 1
		var spread := float((serial*7)%11-5)*.55
		var life := .26+float(serial%5)*.025
		grains.append({"at":at+normal*.7+tangent*spread,"origin":at,"normal":normal,"velocity":normal*(12+strength*14)+tangent*(spread*3-horizontal_speed*.045),"life":life,"duration":life,"color":color,"radius":.65+float(serial%3)*.2})
	queue_redraw()

func _emit_puff(at: Vector2,normal: Vector2,material: String,horizontal_speed: float,strength: float,landing: bool) -> void:
	# Metal/timber keep the tiny existing grain reaction, not a soil cloud.
	if not Dust.BOXES.has(material) or normal.y>-.5: return
	if puffs.size()>=puff_budget():
		if not landing: return
		puffs.pop_front()
	var width := (20+8*clampf(strength,0,1.3)) if landing else 14.0
	width=_clear_puff_width(at,normal,width)
	if width<4: return
	var duration := .48 if landing else .36
	puffs.append({"at":at+normal*.25,"normal":normal,"rotation":Vector2(-normal.y,normal.x).angle(),"family":material,"frames":Dust.frames_for(material),"width":width,"age":0.0,"duration":duration,"facing":-signf(horizontal_speed) if absf(horizontal_speed)>1 else (1.0 if serial%2==0 else -1.0),"opacity":.38 if landing else .24})

func _clear_puff_width(at: Vector2,normal: Vector2,requested: float) -> float:
	# Swept at ankle height in both directions. Keep the whole puff clear of
	# nearby walls; pass through actors, which are not scenery occluders.
	var tangent := Vector2(-normal.y,normal.x)
	var allowed := requested
	for side in [-1,1]:
		var excluded: Array[RID]=[]
		var start := at+normal*2
		for attempt in 8:
			var query := PhysicsRayQueryParameters2D.create(start,start+tangent*requested*.5*side,1,excluded)
			var hit := get_world_2d().direct_space_state.intersect_ray(query)
			if hit.is_empty(): break
			if hit.collider is StaticBody2D and not hit.collider.is_in_group("enemy") and not hit.collider.is_in_group("breakable"):
				allowed=minf(allowed,maxf(0,start.distance_to(hit.position)-1)*2); break
			excluded.append(hit.collider.get_rid())
	# Also reserve the entire six-frame envelope. A thin overhanging ledge
	# above the ankle ray must not cut through the rising part of a dust curl.
	while allowed>=4:
		clearance_shape.size=Vector2(allowed,allowed*.5)
		var query := PhysicsShapeQueryParameters2D.new()
		query.shape=clearance_shape; query.collision_mask=1; query.margin=0
		query.transform=Transform2D(tangent.angle(),at+normal*(allowed*.25+.25))
		var hits := get_world_2d().direct_space_state.intersect_shape(query,32)
		var blocked := hits.size()>=32 # A saturated query cannot establish clearance.
		for hit in hits:
			if hit.collider is StaticBody2D and not hit.collider.is_in_group("enemy") and not hit.collider.is_in_group("breakable"):
				blocked=true; break
		if not blocked: return allowed
		allowed*=.75
	return 0

func advance(delta: float) -> void:
	if grains.is_empty() and puffs.is_empty(): return
	for index in range(puffs.size()-1,-1,-1):
		puffs[index].age+=delta
		if puffs[index].age>=puffs[index].duration: puffs.remove_at(index)
	for index in range(grains.size()-1,-1,-1):
		var grain: Dictionary = grains[index]
		grain.life -= delta
		grain.velocity += Vector2(0,100)*delta
		grain.at += grain.velocity*delta
		if grain.life<=0 or (grain.at-grain.origin).dot(grain.normal)<0:
			grains.remove_at(index)
	queue_redraw()

func _draw() -> void:
	for puff in puffs:
		var fraction: float=clampf(puff.age/puff.duration,0,1)
		var frame: float=fraction*5
		var first := mini(int(frame),5)
		var blend := frame-first
		var alpha: float=puff.opacity*smoothstep(0,.06,fraction)*(1.0-smoothstep(.58,1,fraction))
		draw_set_transform(puff.at,puff.rotation,Vector2(puff.facing,1))
		if low_quality:
			var nearest := mini(roundi(frame),5)
			draw_texture_rect(puff.frames[nearest],Dust.frame_rect(puff.family,nearest,puff.width),false,Color(1,1,1,alpha))
		else:
			draw_texture_rect(puff.frames[first],Dust.frame_rect(puff.family,first,puff.width),false,Color(1,1,1,alpha*(1-blend)))
			if first<5: draw_texture_rect(puff.frames[first+1],Dust.frame_rect(puff.family,first+1,puff.width),false,Color(1,1,1,alpha*blend))
	draw_set_transform(Vector2.ZERO)
	for grain in grains:
		var color: Color = grain.color
		color.a = smoothstep(0,.7,grain.life/grain.duration)*.32
		draw_circle(grain.at,grain.radius*2,color,true,-1,true)
		color.a *= 1.6
		draw_circle(grain.at,grain.radius,color,true,-1,true)
