extends RefCounted
## Observation and aftermath, not boss dialogue or a second progression system.
const APPROACHES := {
	"shaft_approach": ["abyss_warden", "THE SEALED CROSSING", "The gantry leads toward the Warden. A crossing built for travelers has become a barrier. Opening it is the next step toward the people beyond the flood.", "A guardian against the people of the road"],
	"echo_sanctum": ["echo_matriarch", "A LIVING THRESHOLD", "The Nest Crest brought you to the Matriarch's threshold. Haven needs an onward road, not an empty cave. Defeating this guardian is not a reason to destroy everything that lives here.", "A road through the Grotto, not a conquest"],
	"ash_arena": ["ember_marshal", "THE PRICE OF PASSAGE", "The Coliseum offers passage on the fortress's terms: four waves and the Marshal's mark. The emblem is needed at the Castellan's door. It need not become a badge of allegiance.", "Win passage, not allegiance"],
	"ash_throne": ["ash_castellan", "THE HOARDED FIRE", "The marks and bells led here. Beyond this chamber, Cinder Hearth still needs warmth and a safe road. The fortress is not the only place worth defending.", "A fortress hoards what a village shares"],
	"starfall_empty_court": ["starfall_guardian", "AN UNANSWERED WATCH", "The Guardian stands in an empty court while the living city continues outside. Its market, lamps and roads serve people that this silence cannot speak for.", "A silent court. A living city outside"],
	"starfall_hollow_throne": ["hollow_sovereign", "WHAT YOU CARRY", "The three memories survived because someone guided, remembered or sheltered another person. They brought you to this throne, but they do not ask you to take it.", "Three acts of care against a throne of silence"],
}
const AFTERMATH := {
	"void_sentinel": ["THE FIRST OPENING", "The barrier falls. You can leave Eldric's camp now. Take the passage toward the Sunken Shaft; remember the lamp that sheltered you.", "THE ROAD BEGINS"],
	"abyss_warden": ["BEYOND THE FLOOD", "The Warden's seal is broken. Beyond the flooded roads, Whisperlight Haven still keeps its lamps. Carry your journey to the living.", "TOWARD WHISPERLIGHT HAVEN"],
	"echo_matriarch": ["A ROAD, NOT A CONQUEST", "The onward road opens. Leave the Grotto its life, and carry its voices toward Cinder Hearth. The ash ahead holds another closed road.", "TOWARD CINDER HEARTH"],
	"ember_marshal": ["THE MARK, NOT THE OATH", "Four waves are over. The Marshal Emblem is yours, not your allegiance to the fortress. The Reservoir road leads on toward the Chapel.", "TOWARD THE SLAG RESERVOIR"],
	"ash_castellan": ["FIRE BEYOND THE WALLS", "The Castellan falls. Cinder Hearth still needs hands to tend its fire, but the way to Starfall is open. A city is more than its ruler.", "TOWARD STARFALL"],
	"starfall_guardian": ["AFTER THE LAST WATCH", "The court grows quiet. The road beyond leads through the Crucible and Sunless Passage. Carry the three regional memories toward the throne.", "TOWARD THE SUNLESS PASSAGE"],
}
const RETURNS := {
	"shaft_approach": "The crossing outlived its guardian",
	"echo_sanctum": "The Grotto lives beyond its guardian",
	"ash_arena": "The trial is over. Carry the mark onward",
	"ash_throne": "The fire need not belong to a fortress",
	"starfall_empty_court": "The watch has ended. The city remains",
	"starfall_hollow_throne": "The road outside still needs you",
}

static func cleared(state: Node, boss_id: String) -> bool:
	if state == null: return false
	if boss_id == "ember_marshal": return bool(state.unlocked_shortcuts.get("ash_arena_cleared", false))
	return bool(state.defeated_bosses.get(boss_id, false))

static func arrival(room_id: String, state: Node) -> String:
	if not APPROACHES.has(room_id): return ""
	var entry: Array = APPROACHES[room_id]
	return String(RETURNS[room_id]) if cleared(state, entry[0]) else String(entry[3])

static func journal(state: Node) -> String:
	if state == null: return ""
	var entries: Array[String] = []
	for room_id in APPROACHES:
		if bool(state.discovered_rooms.get(room_id, false)):
			var entry: Array = APPROACHES[room_id]
			entries.append("ON ARRIVAL - %s\n%s" % [entry[1], entry[2]])
	# The Marshal is an arena completion, not a defeated_bosses entry.
	if cleared(state, "ember_marshal"):
		entries.append("%s\n%s" % [AFTERMATH.ember_marshal[0], AFTERMATH.ember_marshal[1]])
	return "" if entries.is_empty() else "\n\nAT THE THRESHOLD\n" + "\n\n".join(entries)

static func moment(moment_id: String) -> Dictionary:
	if not moment_id.begins_with("victory:"): return {}
	var boss_id := moment_id.trim_prefix("victory:")
	if not AFTERMATH.has(boss_id): return {}
	var entry: Array = AFTERMATH[boss_id]
	return {"title": entry[0], "text": entry[1], "location": entry[2], "color": Color(0.91, 0.8, 0.59)}
