extends Node2D
## Tiny leaves/dust from actual brushing, capped and advanced by WorldAmbience.
var motes: Array[Dictionary] = []
var serial := 0
const LIMIT := 36

func burst(at: Vector2, force: float, family: String) -> void:
	for index in 3:
		if motes.size()>=LIMIT: break
		serial += 1
		var color: Color = {"cave":Color("77966d"),"mine":Color("968b70"),"ash":Color("b39165"),"star":Color("b7afd0")}.get(family,Color("889876"))
		motes.append({"at":at+Vector2((serial%5)-2,-2-(serial%3)),"velocity":Vector2(force*42+(index-1)*6,-14-(serial%13)),"life":0.55+float(serial%5)*0.06,"max_life":0.9,"color":color})
	z_index = 4; set_process(false); queue_redraw()

func advance(delta: float) -> void:
	if motes.is_empty(): return
	for index in range(motes.size()-1,-1,-1):
		var mote: Dictionary = motes[index]
		mote.life -= delta
		if mote.life<=0: motes.remove_at(index); continue
		mote.velocity.y += 45*delta
		mote.at += mote.velocity*delta
	queue_redraw()

func clear() -> void:
	motes.clear(); queue_redraw()

func _draw() -> void:
	for mote in motes:
		var color: Color = mote.color
		color.a = clampf(mote.life/mote.max_life,0,0.7)
		draw_line(mote.at,mote.at+Vector2(1.4,-0.7),color,0.8,true)
