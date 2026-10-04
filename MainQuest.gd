extends RefCounted
## One campaign, eight ordered milestones. Objectives derive from world progress;
## only reward receipts are saved. Claiming never opens or blocks world doors.
const STEPS := [
	{"id": "road_out", "title": "A Road Out", "why": "Leave Eldric's stranded camp alive. The opened passage leads down into the flooded roads.", "goals": [["boss", "void_sentinel", "Defeat the Void Sentinel"]], "reward": {"gold": 30, "items": {"healing_herb": 2, "iron_fragment": 2}}},
	{"id": "flood_road", "title": "The Bell Beneath the Flood", "why": "Break the Warden's seal so the road can reach Whisperlight Haven. What begins as escape becomes a way between people.", "goals": [["boss", "abyss_warden", "Defeat the Abyss Warden"]], "reward": {"gold": 45, "items": {"guardian_band": 1, "life_bloom": 1}}},
	{"id": "living_echo", "title": "The Voices We Keep", "why": "Open the Grotto's onward road for Haven. Carry its living voices toward Cinder Hearth, not a conqueror's silence.", "goals": [["boss", "echo_matriarch", "Defeat the Echo Matriarch"]], "reward": {"gold": 60, "sp": 1, "items": {"ether_dust": 2}}},
	{"id": "fortress_marks", "title": "Passage, Not Allegiance", "why": "The Bastion demands proof before it grants passage. Restore the Forge and win the Marshal's mark; use their rules to open a road for the Hearth.", "goals": [["event", "ash_forge_fan", "Restore the Cinder Forge fan"], ["item", "barracks_insignia", "Claim the Barracks Insignia"], ["event", "ash_arena_cleared", "Complete the Coliseum's four waves"]], "reward": {"gold": 75, "items": {"iron_fragment": 3, "ether_dust": 2}}},
	{"id": "shared_fire", "title": "A Fire to Share", "why": "Follow the Reservoir and Chapel to the Castellan. Break the fortress's hold on the onward road; Starfall lies beyond it.", "goals": [["boss", "ash_castellan", "Defeat the Ash Castellan"]], "reward": {"gold": 90, "items": {"resonance_shard": 1, "life_bloom": 1}}},
	{"id": "three_voices", "title": "The People Behind the Seals", "why": "The throne asks for three memories. Seek the people behind those keys: one guided travelers, one kept their names, one shared a fire.", "goals": [["item", "memory_sigil_shaft", "Recover the Blackwater Cistern memory"], ["item", "memory_sigil_echo", "Recover the Prism Archive memory"], ["item", "memory_sigil_ash", "Recover the Ashen Chapel memory"]], "reward": {"sp": 1, "items": {"resonance_shard": 2, "ether_dust": 3}}},
	{"id": "last_threshold", "title": "A City Beyond Its Throne", "why": "Carry those voices through Starfall toward the Sunless Passage. The watch, market and gardens are the city; its ruler is not its people.", "goals": [["room", "starfall_sunless_passage", "Reach the Sunless Passage"]], "reward": {"gold": 120, "items": {"healing_herb": 3, "life_bloom": 1}}},
	{"id": "road_remains", "title": "The Road Remains", "why": "Confront the Hollow Sovereign with the three memories. End the first journey without becoming another ruler of closed roads.", "goals": [["boss", "hollow_sovereign", "Defeat the Hollow Sovereign"]], "reward": {"gold": 400, "sp": 3, "items": {"wayfarer_mantle": 1}}},
]

static func goal_done(state: Node, goal: Array) -> bool:
	if state == null: return false
	match goal[0]:
		"boss": return bool(state.defeated_bosses.get(goal[1], false))
		"item": return state.has_item(goal[1])
		"event": return bool(state.unlocked_shortcuts.get(goal[1], false))
		"room": return bool(state.discovered_rooms.get(goal[1], false))
	return false

static func completed_count(state: Node) -> int:
	var count := 0
	for step in STEPS:
		for goal in step.goals:
			if not goal_done(state, goal): return count
		count += 1
	return count

static func next_reward(state: Node, receipts: Dictionary) -> int:
	for index in range(completed_count(state)):
		if not bool(receipts.get(STEPS[index].id, false)): return index
	return -1

static func reward_text(state: Node, index: int) -> String:
	var reward: Dictionary = STEPS[index].reward
	var parts: Array[String] = []
	if reward.has("gold"): parts.append("%d Gold" % reward.gold)
	if reward.has("sp"): parts.append("%d Skill Point%s" % [reward.sp, "s" if int(reward.sp) != 1 else ""])
	for id in reward.items:
		var label: String = str(state.get_item_definition(id).get("name", id)) if state != null else str(id).replace("_", " ").capitalize()
		parts.append("%s x%d" % [label, reward.items[id]])
	return ", ".join(parts)

static func ending_reward_hint(state: Node, receipts: Dictionary) -> String:
	var completed := completed_count(state)
	if completed < STEPS.size():
		return "Earlier main-quest objectives still remain. Review them in [J].\nRest at a lamp to save your victory before leaving."
	var unclaimed := 0
	for step in STEPS:
		if not bool(receipts.get(step.id, false)): unclaimed += 1
	if unclaimed == 0:
		return "Campaign rewards claimed. Equip the Wayfarer Mantle in [I].\nRest at a lamp to save your victory and rewards."
	return "First-clear prize: Wayfarer Mantle, 3 SP, 400 Gold.\n%d chapter reward%s waiting in [J]; claim, then save at a lamp." % [unclaimed, "s" if unclaimed != 1 else ""]

static func journal(state: Node, receipts: Dictionary) -> String:
	var completed := completed_count(state)
	var text := "MAIN QUEST - THE ROAD REMAINS\nLinked journey: %d/%d stages complete.\n" % [completed, STEPS.size()]
	var pending := next_reward(state, receipts)
	if pending >= 0:
		text += "\nREADY TO CLAIM - %s\n%s\nUse the main reward button below. Rest at a lamp afterward to save.\n" % [STEPS[pending].title, reward_text(state, pending)]
	if completed < STEPS.size():
		var step: Dictionary = STEPS[completed]
		text += "\nSTAGE %d/%d - %s\n%s" % [completed + 1, STEPS.size(), step.title.to_upper(), step.why]
		for goal in step.goals:
			text += "\n[%s] %s" % ["DONE" if goal_done(state, goal) else " ", goal[2]]
		text += "\nSTAGE REWARD (all three): " + reward_text(state, completed)
	else:
		text += "\nFIRST CLEAR COMPLETE. The towns and optional return adventures remain open."
	if completed > 0:
		text += "\n\nMAIN QUEST HISTORY"
		for index in range(completed):
			text += "\n%d. %s - %s" % [index + 1, STEPS[index].title, "REWARDED" if bool(receipts.get(STEPS[index].id, false)) else "REWARD READY"]
	return text
