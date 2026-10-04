extends RefCounted
## Story is derived from native progress: no second quest/save state machine.
const VICTORIES := [
	["void_sentinel", "THE FIRST OPENING", "The Sentinel falls. For the first time, leaving is possible. Eldric's camp is behind you; the drowned road lies ahead."],
	["abyss_warden", "AN OATH WITHOUT AN END", "The Warden's seal breaks. A guardian can keep an oath long after that oath stops protecting anyone. Beyond the flood, Haven still keeps its lamps lit."],
	["echo_matriarch", "BEYOND THE LAST ECHO", "The Matriarch no longer bars the onward road. The living Grotto is not an enemy to conquer. Carry its voices toward the fires of the Bastion."],
	["ash_castellan", "THE FIRE LEAVES THE FORTRESS", "The Castellan falls, but Cinder Hearth's work remains: shelter, repairs, a bowl for the late traveler. Starfall waits beyond the ash."],
	["starfall_guardian", "THE LAST WATCH", "The Empty Court is no longer guarded. Every threshold led toward the same silence. The memories you carry offer a different answer."],
	["hollow_sovereign", "NO NEW CROWN", "The throne falls silent. You came looking for a way out and made a way between people. There is no crown to claim as your purpose; there is a road to keep open."],
]
const PLACES := [
	["echo_haven", "WHISPERLIGHT", "Beneath the crystals, a lamp is kept for people who may never return. Here, the journey becomes more than escape."],
	["ash_hearth", "THE SHARED HEARTH", "Outside, the Bastion hoards its fire. Inside, Oren leaves a bowl for a stranger. Two answers to the same darkness."],
	["starfall_citadel", "A CITY, NOT A THRONE", "Watch walks, market roofs, a garden and a library: Starfall is full of lives the throne cannot stand in for."],
	["starfall_sunless_passage", "WHAT THE DARK CANNOT KEEP", "The road narrows toward the throne. The bell, the mirrors and the ember were never only keys. Seek their memories before the last threshold."],
]
const ARRIVALS := {
	"echo_haven": "A lamp kept for those who have not come home",
	"ash_hearth": "What the fortress hoards, the village shares",
	"starfall_citadel": "A thousand lives beyond a single throne",
	"starfall_hollow_throne": "You did not come this far to inherit the silence",
}
const RETURN_ARRIVALS := {
	"echo_haven": "The road is open. The lamps still need keepers",
	"ash_hearth": "No crown can tend a fire for us",
	"starfall_citadel": "A new light. A city with its own voice",
	"starfall_hollow_throne": "An empty throne. A world still waiting outside",
}

static func arrival(room_id: String, state: Node) -> String:
	var entries: Dictionary = RETURN_ARRIVALS if state != null and bool(state.defeated_bosses.get("hollow_sovereign", false)) else ARRIVALS
	return String(entries.get(room_id, preload("res://EncounterStory.gd").arrival(room_id, state)))

static func chronicle(state: Node) -> String:
	if state == null: return ""
	var entries: Array[String] = []
	for event in VICTORIES:
		if bool(state.defeated_bosses.get(event[0], false)):
			entries.append("%s\n%s" % [event[1], event[2]])
	for place in PLACES:
		if bool(state.discovered_rooms.get(place[0], false)):
			entries.append("%s\n%s" % [place[1], place[2]])
	return "" if entries.is_empty() else "\n\nROAD CHRONICLE\n" + "\n\n".join(entries)

static func atley_before_victory(state: Node) -> String:
	if state.has_item("memory_sigil_shaft") and state.has_item("memory_sigil_echo") and state.has_item("memory_sigil_ash"):
		return "A bell, many faces, one ember. Each saved someone else. I think the throne fears that a world can endure without its command."
	if bool(state.defeated_bosses.get("starfall_guardian", false)):
		return "The last watch has fallen. Seek the Cistern, Archive and Chapel memories. Learn what survived before you face what rules."
	return "The royal ledgers count gates and victories. I collect names from caravan books. A kingdom is not the same thing as its people."
