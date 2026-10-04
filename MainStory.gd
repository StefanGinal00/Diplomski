extends RefCounted
## Read-only narrative projection of existing progress. No rewards/save flags.
const MEMORIES := [
	["memory_sigil_shaft", "Blackwater Cistern", "The bell beneath the flood guided the last travelers out. Someone stayed so others could leave."],
	["memory_sigil_echo", "Prism Archive", "The mirrors remembered many faces. Their message was to remember the people, not the throne."],
	["memory_sigil_ash", "Ashen Chapel", "A keeper saved an ember after the fires died. A road could begin again wherever that fire was shared."],
]
const CHAPTERS := [
	["A Road Out", "The Wayfarer is stranded on an old road. Eldric's camp cannot remain cut off forever.", "Prepare with Eldric, learn the dash and defeat the Void Sentinel to open the passage."],
	["The Bell Beneath the Flood", "The flooded roads once carried people between settlements. Their guardian still enforces a closure that outlived its purpose.", "Explore the Sunken Shaft, restore its routes and defeat the Abyss Warden."],
	["The Voices We Keep", "Whisperlight Haven needs a road beyond its shelter. The echoes preserve more than the names of rulers.", "Follow the Gallery and Tide Well routes, claim the Nest Crest and face the Echo Matriarch."],
	["A Fire to Share", "Cinder Hearth survives while the Bastion hoards its fire. Opening a gate means little if nobody can safely reach it.", "Restore the Forge route, reach the Ashen Chapel and defeat the Ash Castellan."],
	["The City Behind the Gates", "The roads converge at Starfall. The surviving city is not its ruler: the memories you carry belong to its people.", "Explore Starfall's routes toward the Sunless Passage."],
	["The Hollow Throne", "Three memories tell one story: people kept one another alive while the roads were sealed. Their future need not belong to the throne.", "Reach the Hollow Throne through the Sunless Passage and confront the Hollow Sovereign."],
	["The Road Remains", "The Sovereign has fallen. Rebuilding belongs to the people who still live here, not to another ruler taking the empty throne.", "Save your victory at a lamp, then return to the settlements and hear what has changed."],
]

static func chapter(state: Node) -> int:
	if state == null: return 0
	if bool(state.defeated_bosses.get("hollow_sovereign", false)): return 6
	# Early collection must not skip an undefeated mandatory guardian.
	for index in range(4):
		if not bool(state.defeated_bosses.get(["void_sentinel", "abyss_warden", "echo_matriarch", "ash_castellan"][index], false)):
			return index
	if missing_memories(state).is_empty() and bool(state.discovered_rooms.get("starfall_sunless_passage", false)):
		return 5
	return 4

static func missing_memories(state: Node) -> Array[String]:
	var missing: Array[String] = []
	for memory in MEMORIES:
		if state == null or not state.has_item(memory[0]): missing.append(memory[1])
	return missing

static func journal(state: Node) -> String:
	var stage := chapter(state)
	var entry: Array = CHAPTERS[stage]
	var objective: String = entry[2]
	if state != null and stage == 2:
		objective = preload("res://StoryRoute.gd").echo_goal(state)
	elif state != null and stage == 3:
		objective = preload("res://StoryRoute.gd").ash_goal(state)
	if stage == 4:
		var missing := missing_memories(state)
		if not missing.is_empty():
			if bool(state.discovered_rooms.get("starfall_sunless_passage", false)):
				objective = "The Sunless Passage is reached. The throne still requires memories from: " + ", ".join(missing) + ". Return for these, then approach the throne door."
			else:
				objective += " Recover the missing memories: " + ", ".join(missing) + "."
		else:
			objective += " All three memories are gathered; find the route to the throne."
	var text := "MAIN STORY - %s\n%s\n\nNEXT: %s" % [String(entry[0]).to_upper(), entry[1], objective]
	if stage > 0 and stage < 6:
		text += "\n\nAwakened rematches, field records and local reward hand-ins are optional. World mechanisms still open the main road."
		if stage == 3:
			text += " The first Coliseum trial supplies the Marshal Emblem required for the Castellan."
	if stage == 6:
		text += "\n\nSpeak to Atley in Starfall about the Dawn Archive. Optional rematches and unfinished local tasks remain available."
	var remembered: Array[String] = []
	for memory in MEMORIES:
		if state != null and state.has_item(memory[0]):
			remembered.append("%s: %s" % [memory[1], memory[2]])
	if not remembered.is_empty(): text += "\n\nMEMORIES CARRIED\n" + "\n\n".join(remembered)
	return text + preload("res://WorldStory.gd").chronicle(state) + preload("res://EncounterStory.gd").journal(state)
