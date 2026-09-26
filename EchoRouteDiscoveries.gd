extends Node2D

const POST_SCENE := preload("res://SluiceValve.tscn")
const POST_SCRIPT := preload("res://EchoListeningPost.gd")
const ENCOUNTER := preload("res://LocalizedEncounter.tscn")
const CACHE := preload("res://ResonanceCache.tscn")
const WISP := preload("res://ShaftWisp.tscn")
const SHADE := preload("res://EchoShade.tscn")
const PROFILES := {
	"grotto": {"title": "THE LOST CHOIR", "posts": ["LOW TONE", "MIDDLE TONE", "HIGH TONE"], "tiers": [1, 3, 5], "order": [0, 1, 2], "clue": "LOW > MIDDLE > HIGH", "trial": "THE ANSWERING CHOIR", "foes": [WISP, WISP]},
	"gallery": {"title": "THE TWO WITNESSES", "posts": ["WESTERN WITNESS", "EASTERN WITNESS"], "tiers": [1, 5], "order": [], "clue": "LISTEN TO BOTH WITNESSES IN ANY ORDER", "trial": "WHISPERS GIVEN FORM", "foes": [SHADE, SHADE]},
	"archive": {"title": "THE UNINDEXED RECORD", "posts": ["DAWN RECORD", "ZENITH RECORD", "DUSK RECORD"], "tiers": [1, 3, 5], "order": [1, 0, 2], "clue": "ZENITH > DAWN > DUSK", "trial": "THE ARCHIVE'S REFLECTION", "foes": [SHADE, WISP]},
}

var route: Node2D
var route_id: String
var data: Dictionary
var state: Node
var sequence: Array[int] = []
var posts: Array[Area2D] = []
var signs: Array[Label] = []
var completed := false


func _ready() -> void:
	route_id = String(route.get("route_id"))
	data = PROFILES[route_id]
	state = get_node_or_null("/root/GameState")
	completed = state != null and bool(state.unlocked_shortcuts.get(completion_id(), false))
	for index in range(data["posts"].size()):
		var tier := int(data["tiers"][index])
		var shelf := route.get_node("Tier%02dHiddenShelfA" % tier) as Node2D
		var post := POST_SCENE.instantiate() as Area2D
		post.set_script(POST_SCRIPT)
		post.name = "ListeningPost%d" % index
		post.position = shelf.position + Vector2(0, -34)
		post.set("station_index", index)
		post.set("station_title", data["posts"][index])
		post.set("threat_root", route.get_parent())
		post.set("room_id", route.RETURN_TARGETS[route_id][0])
		post.connect("heard", _on_heard)
		add_child(post)
		posts.append(post)
		var sign := Label.new()
		sign.position = shelf.position + Vector2(-205, -214)
		sign.size = Vector2(410, 60)
		sign.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sign.add_theme_font_size_override("font_size", 10)
		add_child(sign)
		signs.append(sign)
	_build_return_encounter()
	_refresh_posts()
	_refresh_signs()


func completion_id() -> String:
	return "echo_%s_field_complete" % route_id


func _on_heard(index: int) -> void:
	if completed or index < 0 or index >= posts.size() or state == null:
		return
	var order: Array = data["order"]
	if order.is_empty():
		state.unlock_shortcut("echo_%s_witness_%d" % [route_id, index])
		completed = true
		for witness in range(posts.size()):
			completed = completed and bool(state.unlocked_shortcuts.get("echo_%s_witness_%d" % [route_id, witness], false))
	else:
		if index != int(order[sequence.size()]):
			sequence.clear()
			_refresh_posts()
			_refresh_signs("WRONG ORDER - BEGIN AGAIN")
			return
		sequence.append(index)
		completed = sequence.size() == order.size()
	if completed:
		state.unlock_shortcut(completion_id())
	_refresh_posts()
	_refresh_signs()


func _refresh_posts() -> void:
	for index in range(posts.size()):
		var recorded: bool = completed or sequence.has(index)
		if (data["order"] as Array).is_empty() and state != null:
			recorded = recorded or bool(state.unlocked_shortcuts.get("echo_%s_witness_%d" % [route_id, index], false))
		posts[index].call("set_attuned", recorded)


func _refresh_signs(feedback: String = "") -> void:
	var detail := "DISCOVERY CACHE UNSEALED - FINAL HIDDEN CHAMBER" if completed else String(data["clue"])
	if not feedback.is_empty():
		detail = feedback + "\n" + String(data["clue"])
	elif not completed:
		var count := sequence.size()
		if (data["order"] as Array).is_empty():
			count = 0
			for post in posts:
				count += int(post.get("attuned"))
		detail += "\nRECORDS %d/%d - CLEAR FOES, THEN LISTEN" % [count, posts.size()]
	for sign in signs:
		sign.text = String(data["title"]) + "\n" + detail


func _build_return_encounter() -> void:
	var shelf := route.get_node("Tier06SideAlcove") as Node2D
	var trial := ENCOUNTER.instantiate() as Area2D
	trial.name = "ReturnEncounter"
	trial.position = shelf.position
	trial.set("zone_id", "echo_grotto")
	trial.set("encounter_id", "echo_%s_field_return" % route_id)
	trial.set("completion_event_id", "echo_%s_field_return_complete" % route_id)
	trial.set("minimum_zone_tier", 1)
	trial.set("required_event_ids", PackedStringArray([completion_id()]))
	trial.set("locked_hint", "COMPLETE THE ROOM'S RECORDS FIRST")
	trial.set("dormant_hint", "DORMANT - RETURN AFTER THE MATRIARCH")
	trial.set("encounter_title", data["trial"])
	var foes: Array = data["foes"]
	for index in range(foes.size()):
		trial.get("enemy_scenes").append(foes[index])
		trial.get("spawn_offsets").append(Vector2(-95 + index * 170, -92 if foes[index] == WISP else -32))
	add_child(trial)
	var reward := CACHE.instantiate() as Area2D
	reward.name = "ReturnReward"
	reward.position = shelf.position + Vector2(145, -34)
	reward.set("cache_id", "echo_%s_field_return_reserve" % route_id)
	reward.set("cache_name", "Awakened " + String(data["title"]).capitalize())
	reward.set("gold_reward", 20)
	reward.set("reward_item_id", "ether_dust")
	reward.set("required_event_ids", PackedStringArray(["echo_%s_field_return_complete" % route_id]))
	add_child(reward)
