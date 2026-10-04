extends Node2D
## A few tiny drops from an actual hanging root to the first real floor below.
## Mathematical cycle, no particles/collision/timer or per-object callbacks.
var support := Rect2()
var source: Node2D
var fall_distance := 0.0
var phase := 0.0
var cycle := -1.0
var tint := Color("84abae")
var footprint := Rect2()
var emission_serial := -1
var anchor := Vector2.ZERO

static func path_bounds(at: Vector2, floor_rect: Rect2, attachment: Node2D) -> Rect2:
	# Reserve the whole possible tip swing, not just today's still-water ray.
	# The maximum contact bend is .42rad; .5x height leaves a conservative rim.
	var bounds: Variant = attachment.get("footprint")
	var height := (bounds as Rect2).size.y if bounds is Rect2 else 0.0
	var horizontal := 4.0+height*.5
	var top := at.y-2.0-height*.12
	return Rect2(at.x-horizontal,top,horizontal*2,floor_rect.position.y+1-top)

func configure(at: Vector2, floor_rect: Rect2, attachment: Node2D, palette: String) -> void:
	global_transform = Transform2D(0,at)
	anchor = at
	support = floor_rect; source = attachment
	fall_distance = floor_rect.position.y-at.y
	phase = fposmod(at.x*.017+at.y*.031,3.4)
	tint = Color("a2a5ca") if palette=="star" else Color("84abae")
	footprint = path_bounds(at,floor_rect,attachment)
	z_index = -1; set_meta("ambient_motion",true); set_meta("ceiling_seep",true)
	set_process(false); set_physics_process(false)

func animate(age: float) -> void:
	if not is_instance_valid(source) or not source.is_visible_in_tree(): rest(); return
	cycle = fposmod(age+phase,3.4)
	var serial := floori((age+phase)/3.4)
	if serial!=emission_serial:
		emission_serial = serial
		# Snapshot at release: wind carries the ROOT, not a drop already falling.
		var at: Vector2 = source.drip_anchor() if source.has_method("drip_anchor") else anchor
		global_position = at
		fall_distance = maxf(0,support.position.y-at.y)
	queue_redraw()

func rest() -> void:
	cycle = -1; emission_serial = -1; queue_redraw()

func drop_height() -> float:
	return fall_distance*pow(clampf(cycle/.8,0,1),2)

func _draw() -> void:
	if cycle<0 or cycle>1.08: return
	var color := tint; color.a = .58
	if cycle<.8:
		var at := Vector2(0,drop_height())
		draw_line(at-Vector2(0,minf(3.5,at.y)),at,color,.7,true)
	else:
		var t := (cycle-.8)/.28
		color.a *= 1-t
		for side in [-1,1]:
			var at := Vector2(side*3.4*t,fall_distance-sin(t*PI)*1.7)
			draw_line(at,at+Vector2(side*.9,.35),color,.65,true)
