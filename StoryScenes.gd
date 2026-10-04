extends RefCounted

const ORDER := ["opening", "sentinel", "haven", "echo", "marshal", "fortress", "castellan", "guardian", "memories", "ending"]
const BOSS_SCENES := {"void_sentinel": "sentinel", "abyss_warden": "haven", "echo_matriarch": "echo", "ember_marshal": "marshal", "ash_castellan": "castellan", "starfall_guardian": "guardian", "hollow_sovereign": "ending"}
const ORIGINAL_SCENES := ["opening", "haven", "memories"]
const SCENES := {
	"opening": {"title": "A Lamp on a Broken Road", "images": ["res://art/story/intro_road_v1.png", "res://art/story/intro_lamp_v1.png", "res://art/story/intro_passage_v1.png"], "pages": [
		"The road ends in broken stone. Behind you, the dark. Ahead, a passage that no traveler has crossed in years.",
		"Eldric keeps a lamp beside the ruins. He offers no prophecy, only shelter and a warning: the Sentinel still guards the way out.",
		"For now, survival is enough. Speak to Eldric, learn the road, and find a way beyond the camp. What waits there is not yet yours to know."]},
	"haven": {"title": "Lamps Beyond the Flood", "images": ["res://art/story/haven_crossing_v1.png", "res://art/story/haven_lamps_v1.png", "res://art/story/haven_neighbors_v1.png"], "pages": [
		"The Warden's seal is broken. Beyond the drowned crossing, lamps still burn beneath the crystals.",
		"Whisperlight Haven is no forgotten kingdom. People mend roofs, keep watch and leave lights for travelers who have not come home.",
		"You came looking for a way out. An open road could mean something more: a way between people. Carry that hope through the Grotto."]},
	"memories": {"title": "Three Acts of Care", "images": ["res://art/story/three_memories_v1.png", "res://art/story/memories_care_v1.png", "res://art/story/memories_passage_v1.png"], "pages": [
		"A bell for the last traveler. A mirror for forgotten faces. An ember saved for another hand.",
		"Each memory outlived a closed road because someone chose to help another person. None of them asks for a crown.",
		"Carry their answer through Starfall to the Sunless Passage. The throne may demand these memories as keys. Their meaning belongs to the people."]},
	"sentinel": {"title": "The First Opening", "images": ["res://art/story/sentinel_silence_v1.png", "res://art/story/sentinel_descent_v1.png", "res://art/story/intro_lamp_v1.png"], "pages": [
		"The Sentinel's watch ends. For the first time, the passage beyond the camp stands open. You are still only a traveler, but you are no longer trapped.",
		"Below the broken road, water fills the old shafts. Follow the descent. Someone built these crossings for people long before they became barriers.",
		"Behind you, Eldric's lamp still burns. Remember what that small shelter gave you. The road ahead will ask what you can offer in return." ]},
	"echo": {"title": "A Road, Not a Conquest", "images": ["res://art/story/echo_quiet_v1.png", "res://art/story/echo_life_v1.png", "res://art/story/echo_ashroad_v1.png"], "pages": [
		"The Matriarch falls silent, and the onward passage opens. The Grotto does not fall silent with her.",
		"Water, wings and roots continue their patient work. Haven needs a road through this place, not an empty cave left in victory's wake.",
		"Carry its living voices toward Cinder Hearth. Beyond the blue stone, another fire burns behind another closed road." ]},
	"marshal": {"title": "The Mark, Not the Oath", "images": ["res://art/story/marshal_sand_clean_v2.png", "res://art/story/marshal_mark_v1.png", "res://art/story/marshal_reservoir_v1.png"], "pages": [
		"Four waves end in the dust of the Coliseum. Only now, with the last threat gone, does the trial release its hold.",
		"The Marshal's emblem proves you survived their rules. It does not promise your loyalty. Passage is what you came for.",
		"Beyond the gate, the Reservoir road leads toward the Chapel. Carry the mark onward, and leave the fortress its hunger for obedience." ]},
	"fortress": {"title": "Passage, Not Allegiance", "images": ["res://art/story/forge_air_v1.png", "res://art/story/fortress_proofs_v1.png", "res://art/story/fortress_road_v1.png"], "pages": [
		"The Forge breathes again. What the fortress used to bar a road can still become useful to the people living in its shadow.",
		"The Barracks Insignia and the Marshal's mark are gathered. Each was a demand placed in a traveler's path; together, they are a way forward.",
		"Your task is not finished at these gates. Follow the Reservoir toward the Chapel, its bells and the Castellan. The Hearth needs an open road." ]},
	"castellan": {"title": "Fire Beyond the Walls", "images": ["res://art/story/castellan_empty_v1.png", "res://art/story/castellan_hearth_v1.png", "res://art/story/castellan_starfall_v1.png"], "pages": [
		"The Castellan falls. The great chamber keeps its stone seat, but you have no reason to take it.",
		"Beyond these walls, Cinder Hearth still needs hands to tend the fire. Warmth means little if it belongs only to a fortress.",
		"The way to Starfall is open. Carry the lesson with you: a city is more than its ruler, and a road is worth more than the power to close it." ]},
	"guardian": {"title": "After the Last Watch", "images": ["res://art/story/guardian_court_v1.png", "res://art/story/guardian_city_v1.png", "res://art/story/guardian_threshold_v1.png"], "pages": [
		"The Guardian's watch ends in an empty court. Its silence cannot tell you what the living city needs.",
		"Outside, someone closes a stall. Someone lights a lamp. Someone tends a garden above the street. This is the Starfall that must remain.",
		"The road leads on through the Crucible and Sunless Passage. Gather the three regional memories before the throne; carry their meaning, not just their seals." ]},
	"ending": {"title": "The Road Remains", "images": ["res://art/story/ending_throne_v1.png", "res://art/story/ending_turn_single_v2.png", "res://art/story/ending_roads_v1.png", "res://art/story/ending_lamp_v1.png"], "pages": [
		"The Hollow Sovereign falls. For a moment, there is only the quiet of a throne with no voice left to command the road.",
		"You carried a bell, remembered faces and a shared ember into this darkness. None of them asked you to become its next ruler.",
		"Beyond the hall, the crossings remain. They will need repairs, watchkeepers and travelers willing to help each other. Victory makes that work possible; it does not do it for them.",
		"Once, a lamp kept you alive at the end of a broken road. Now there is room beside it for another traveler. Your first journey ends. The road remains open." ]},
}

static func pages_for(state: Node, id: String) -> Array:
	if not SCENES.has(id): return []
	var pages: Array = SCENES[id].pages.duplicate()
	if state == null: return pages
	var has_memories: bool = state.has_item("memory_sigil_shaft") and state.has_item("memory_sigil_echo") and state.has_item("memory_sigil_ash")
	if id == "guardian" and has_memories:
		pages[2] = "The three regional memories are already with you. Carry them through the Crucible and Sunless Passage to the throne. Their meaning matters more than their seals."
	if id == "memories" and bool(state.defeated_bosses.get("starfall_guardian", false)):
		pages[2] = "The Guardian's watch has ended. Carry these three acts of care toward the Sunless Passage and the throne. The road is open; the answer you bring belongs to its people."
	return pages


static func unlocked(state: Node, id: String) -> bool:
	if state == null or not SCENES.has(id): return false
	if id == "opening": return state.session_started
	for boss_id in BOSS_SCENES:
		if BOSS_SCENES[boss_id] == id:
			return preload("res://EncounterStory.gd").cleared(state, boss_id)
	var completed := preload("res://MainQuest.gd").completed_count(state)
	return completed >= (4 if id == "fortress" else 6)

static func pending(state: Node) -> String:
	# The actual new-game UI plays the opening. Never interrupt direct scene boots.
	if state == null or not bool(state.story_scenes_seen.get("opening", false)): return ""
	# After the finale, old aftermaths remain replayable, not forced at a lamp.
	if unlocked(state, "ending"):
		return "" if bool(state.story_scenes_seen.get("ending", false)) else "ending"
	for id in ORDER:
		if id == "opening": continue
		if unlocked(state, id) and not bool(state.story_scenes_seen.get(id, false)): return id
	return ""
