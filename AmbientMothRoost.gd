extends Node2D
## Harmless, bounded ambient flight. Only the room coordinator ticks this node.
const Atlas := preload("res://AmbientMothAtlas.gd")
const FLAP := [0,1,2,3,5,4,2,1]
const ENVELOPE := Rect2(-52,-48,104,76)
var habitat: Node2D
var support := Rect2()
var footprint := Rect2()
var family := "cave"
var insects: Array[Sprite2D]=[]
var spans: Array[float]=[]
var phase := 0.0
var age := 0.0
var alarm := 0.0
var flight := 0.0
var escape_direction := 1.0
var contact_age := 10.0
var selected := false
var low_quality := false
var samples := 0

func configure(palette: String,source: Node2D,at: Vector2,floor_rect: Rect2) -> void:
	family=palette; habitat=source; support=floor_rect
	top_level=true; global_transform=Transform2D(0,at)
	footprint=Rect2(at+ENVELOPE.position,ENVELOPE.size)
	phase=fposmod(at.x*.017+at.y*.023,TAU)
	z_index=2; set_process(false); set_physics_process(false)
	set_meta("ambient_motion",true); set_meta("ambient_fauna",true); set_meta("player_reactive",true)
	for index in 3:
		var insect := Sprite2D.new(); insect.name="Moth%d"%index
		insect.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		add_child(insect); insects.append(insect); spans.append(4.5+index*.55)
		Atlas.show(insect,family,5,spans[index],false); insect.hide()

func reaction_bounds() -> Rect2:
	return footprint

func set_low_quality(value: bool) -> void:
	low_quality=value; _pose()

func animate(time: float) -> void:
	if not is_instance_valid(habitat) or not habitat.is_visible_in_tree(): reset_response(); rest(); return
	selected=true; age=time; _pose()

func brush(force: float) -> bool:
	if not is_instance_valid(habitat) or not habitat.is_visible_in_tree(): return false
	# A passing body nudges the flock away; standing still is not a constant
	# explosion. Never emit the grass-leaf particle burst for an insect contact.
	if contact_age>.35:
		escape_direction=signf(force) if not is_zero_approx(force) else 1.0
		alarm=1.0
	contact_age=0; _pose(); return false

func advance_response(delta: float) -> bool:
	if not is_instance_valid(habitat) or not habitat.is_visible_in_tree(): reset_response(); rest(); return false
	var dt := clampf(delta,0,.1)
	contact_age+=dt; alarm=maxf(0,alarm-dt*.55)
	flight=move_toward(flight,smoothstep(0,1,alarm),dt*3.2)
	if not selected: age+=dt
	_pose(); return alarm>0 or flight>.001

func reset_response() -> void:
	alarm=0; flight=0; contact_age=10; _pose()

func rest() -> void:
	selected=false; _pose()

func _pose() -> void:
	var moving := is_visible_in_tree() and (selected or alarm>0 or flight>.001) and is_instance_valid(habitat) and habitat.is_visible_in_tree()
	var retreat := flight
	for index in insects.size():
		var insect := insects[index]
		insect.visible=moving and (not low_quality or index<2)
		if not insect.visible: continue
		var t := age*(1.0+index*.09)+phase+index*2.1
		var home: Vector2=[Vector2(-9,0),Vector2(9,-6),Vector2(0,6)][index]
		insect.position=home+Vector2(sin(t*1.35)*9,cos(t*.91)*5)+Vector2(escape_direction*(18+index*3),-15-index*3)*retreat
		insect.rotation=sin(t*.8)*.12-escape_direction*retreat*.12
		var frame: int=FLAP[posmod(int(age*(9+index)+phase+flight*2),FLAP.size())]
		Atlas.show(insect,family,frame,spans[index],cos(t*1.35)<0)
		samples+=1
