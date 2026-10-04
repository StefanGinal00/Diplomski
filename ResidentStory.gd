extends RefCounted
## Opt-in by room + resident identity. Unlisted speakers retain authored scene lines.
## Each row: local guardian, post-guardian lines, post-Sovereign lines, memory ID, memory lines.
const VOICES := {
	"EchoHaven/Neris": ["echo_matriarch", ["The deep note has changed. I still light the lamp; an open road cannot promise everyone will return.", "We listened for danger for so long. I want to learn what footsteps sound like when nobody is running."], ["The throne is quiet, but I can hear the town. That is the sound I was keeping this lamp for.", "Tell Eldric there is room here for travelers who no longer know where home is."], "memory_sigil_shaft", ["Someone stayed beneath the flood to ring that bell. We keep lamps for the same reason: so another person can find a way."]],
	"EchoHaven/Calen": ["echo_matriarch", ["I can draw a road into the ash now. An ink line is a promise; I want to know where travelers can rest along it.", "Ask at Cinder Hearth. A map without places to stop is only a list of dangers."], ["My next map needs room for names, not just walls. People kept this route alive before either of us arrived.", "I will mark Eldric's camp, our lamp and the Hearth. A road should tell you who will welcome you."], "memory_sigil_echo", ["The Archive kept faces where our maps kept borders. Perhaps we were drawing the wrong things first."]],
	"EchoHaven/Ivara": ["echo_matriarch", ["I feared what would come after the Matriarch. I still do. But now we can meet the people beyond her, not only fear them.", "Please leave the quiet creatures be. An open road should not cost the Grotto every living thing."], ["No one can order a refuge to become a home. We have to choose it, and keep choosing it.", "You broke the seals. We must learn how to live without making new ones."], "memory_sigil_echo", ["The mirrors remembered ordinary faces? Then the Archive was never only a monument to the powerful."]],
	"EchoHaven/Vey": ["echo_matriarch", ["You may go farther now. You can still sit here. Being needed everywhere must be a lonely sort of freedom."], ["You found your way out. I hope you also found somewhere you want to come back to.", "No hero's speech from me. There is a place beside the lamp if you are tired."], "", []],
	"CinderHearth/Dara": ["ash_castellan", ["The Castellan is gone. We still need kindling, clean water and hands willing to carry them.", "Let Starfall hear that our hearth is not a fortress. Its fire is for whoever reaches it."], ["The great throne is empty. Our hearth is not. I know which one I would rather keep watch beside.", "Stay for a little while. The world will still need saving in small ways tomorrow."], "memory_sigil_ash", ["One ember survived in the Chapel. That is how this hearth began too: someone refused to keep the last warmth for themselves."]],
	"CinderHearth/Bram": ["ash_castellan", ["A fortress teaches you that safety is a thicker wall. The village taught me it can be an open door.", "The road to Starfall is open. Take care; a city can have higher walls than any fortress."], ["I spent years repairing gates. Perhaps I can build something people walk across instead.", "A bridge needs more trust than a wall. I will have to learn."], "", []],
	"CinderHearth/Oren": ["ash_castellan", ["Perhaps my brother's next letter can come by the open road. Until then, I will leave the bowl by the gate.", "Everyone talks about Starfall. I just want to hear my brother complain about supper again."], ["I am leaving two bowls tonight. Hope is easier when you give it something ordinary to do.", "If you pass through Starfall, tell them we still keep a place for late travelers."], "memory_sigil_ash", ["The Chapel keeper saved an ember for someone they might never meet. I think I understand that."]],
	"StarfallCitadel/Vedran": ["starfall_guardian", ["The Empty Court is open. Before you leave, let Aurel check your wounds. The city needs you alive, not legendary."], ["Aurel still needs herbs. People still get hurt. A victory worth having must make room for that work."], "", []],
	"StarfallCitadel/Fenn": ["starfall_guardian", ["From this roof, the throne looks small. Remember that when you stand before it: there is a whole city behind you."], ["The roofs have not changed. I have. For once I am looking past the walls, not counting them."], "", []],
	"StarfallCitadel/Sable": ["starfall_guardian", ["We built this crossing so people would not have to ask a gatekeeper for every step. Keep that thought past the Court."], ["The next crossing should lead somewhere new. Let the people who use it decide where."], "", []],
	"StarfallCitadel/Emon": ["starfall_guardian", ["The old watch is broken. That does not make the Sunless road safe. The Crucible lies between courage and the throne."], ["The observatory can chart the horizon. It cannot choose our future. That work belongs down here in the streets."], "", []],
	"StarfallCitadel/Astra": ["starfall_guardian", ["I charted a sky that never answered. You carry memories of people who did. I know which light I would follow."], ["There is no constellation for what comes next. Good. We should not have to ask the stars for permission."], "memory_sigil_echo", ["A mirror can hold a face without owning it. I wonder whether the throne ever understood that."]],
}
const LOCAL_OUTCOMES := {
	"EchoHaven/Calen": ["echo_survey_state", ["Lyra has your three traces. I can put the routes beside one another now, instead of guessing where they meet."]],
	"EchoHaven/Neris": ["starfall_courier_state", ["Rook has our reply? Good. Tell the city our lamp is not a distant star. There are people keeping it alight."]],
	"CinderHearth/Dara": ["hearth_fan_state", ["Mira says the Forge fan is turning again. It is easier to offer someone a road when the air will not burn them."]],
	"CinderHearth/Oren": ["starfall_courier_state", ["You carried news between our towns. I do not know when my brother will write, but the distance feels smaller now."]],
	"StarfallCitadel/Sable": ["starfall_route_state", ["Rook has the watch, market and garden reports. I am glad someone counted the people this crossing was built for."]],
}

static func identity(actor: Node) -> String:
	var ancestor := actor.get_parent()
	while ancestor != null:
		if String(ancestor.name) in ["EchoHaven", "CinderHearth", "StarfallCitadel"]:
			return String(ancestor.name) + "/" + String(actor.get("resident_name"))
		ancestor = ancestor.get_parent()
	return ""

static func resolve(actor: Node, state: Node) -> Dictionary:
	var base := _resolve_progress(actor, state)
	var response := preload("res://FieldRecords.gd").reaction(identity(actor), state)
	if response.is_empty(): return base
	var lines: PackedStringArray = base.lines if not base.is_empty() else PackedStringArray(actor.get("dialogue_lines"))
	return {"id": 1000 + int(base.get("id", 0)), "lines": PackedStringArray([response]) + lines}

static func _resolve_progress(actor: Node, state: Node) -> Dictionary:
	var key := identity(actor)
	if state == null or not VOICES.has(key): return {}
	var row: Array = VOICES[key]
	if bool(state.defeated_bosses.get("hollow_sovereign", false)):
		return {"id": 203, "lines": PackedStringArray(row[2])}
	# Read the live quest node, not GameState's last saved snapshot.
	var scene := actor.get_tree().current_scene
	var quests := scene.get_node_or_null("QuestManager") if scene != null else null
	var local_lines := PackedStringArray()
	if quests != null and LOCAL_OUTCOMES.has(key):
		var outcome: Array = LOCAL_OUTCOMES[key]
		if int(quests.get(outcome[0])) == 3: local_lines = PackedStringArray(outcome[1])
	if not local_lines.is_empty():
		var cleared := bool(state.defeated_bosses.get(row[0], false))
		var followup := PackedStringArray(row[1]) if cleared else PackedStringArray(actor.get("dialogue_lines"))
		var local_phase := 205 if cleared else 204
		if cleared and not String(row[3]).is_empty() and state.has_item(row[3]):
			followup = PackedStringArray(row[4]) + followup
			local_phase = 206
		return {"id": local_phase, "lines": local_lines + followup}
	if not bool(state.defeated_bosses.get(row[0], false)): return {}
	if not String(row[3]).is_empty() and state.has_item(row[3]):
		return {"id": 202, "lines": PackedStringArray(row[4]) + PackedStringArray(row[1])}
	return {"id": 201, "lines": PackedStringArray(row[1])}
