extends Node2D
## A single, short-lived dust pool. Driven by the shared ambience physics tick.
const LIMIT := 40
const LOW_LIMIT := 12
const COLORS := {"moss":Color("818371"),"shale":Color("7d8989"),"basalt":Color("86715e"),"citadel":Color("9a99a5"),"timber":Color("a28a66"),"iron":Color("8b8780")}
var grains: Array[Dictionary] = []
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

func clear() -> void:
	grains.clear(); sampled = false; distance = 0; fall_distance = 0; cooldown = 0
	previous_velocity = Vector2.ZERO; previous_grounded = false; last_contact.clear(); queue_redraw()

func set_low_quality(value: bool) -> void:
	low_quality = value
	while grains.size()>budget(): grains.pop_back()
	queue_redraw()

func budget() -> int:
	return LOW_LIMIT if low_quality else LIMIT

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

func advance(delta: float) -> void:
	if grains.is_empty(): return
	for index in range(grains.size()-1,-1,-1):
		var grain: Dictionary = grains[index]
		grain.life -= delta
		grain.velocity += Vector2(0,100)*delta
		grain.at += grain.velocity*delta
		if grain.life<=0 or (grain.at-grain.origin).dot(grain.normal)<0:
			grains.remove_at(index)
	queue_redraw()

func _draw() -> void:
	for grain in grains:
		var color: Color = grain.color
		color.a = smoothstep(0,.7,grain.life/grain.duration)*.32
		draw_circle(grain.at,grain.radius*2,color,true,-1,true)
		color.a *= 1.6
		draw_circle(grain.at,grain.radius,color,true,-1,true)
