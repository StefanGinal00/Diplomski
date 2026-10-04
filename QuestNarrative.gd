extends RefCounted
## Presentation only. Native quest IDs, gates, rewards and saved progress remain authoritative.
const TASKS := {
	"echo_survey": ["Echo Survey", "Lyra needs traces of the old routes so Haven can look beyond its walls.", "Lyra has the three traces. The survey gives Haven a record of its lost roads."],
	"hearth_fan": ["Cool Cinder Forge", "Restore the cooling fan: shared warmth should sustain the Hearth, not burn its travelers.", "The cooling fan is restored. Mira's road is safer to cross."],
	"hearth_gate": ["Hearth Road", "Drive the two gate threats away so travelers can reach Tarin and the Hearth.", "Tarin's gate road is clear. Travelers have a chance to reach shelter."],
	"starfall_route": ["Lantern Route", "Find the watch, market and garden reports: Rook needs to know how the city beyond the throne is faring.", "Rook has all three reports. The city's people, not only its rulers, are accounted for."],
	"starfall_courier": ["Courier Circuit", "Carry the watch's news between Starfall, Haven and Hearth. Rest at both town lamps to collect their replies.", "Both settlements answered Rook. The isolated towns are exchanging news again."],
	"dawn_archive": ["Dawn Archive", "The throne has fallen. Record voices at the Cistern, Archive and Chapel so the people who kept the roads alive are not forgotten.", "Atley bound the Dawn Chronicle: the roads now have a history beyond their kings."],
}

static func local_purpose(quests: Node) -> String:
	match int(quests.quest_index):
		0:
			return "WHY: Help Eldric secure the stranded camp. Clearing three creatures prepares the road; it does not defeat the Sentinel."
		1:
			return "WHY: Return Eldric's personal sigil for travel supplies. This optional keepsake is not one of the three regional memories."
		_:
			return "WHY: An optional return trial tests what you learned against the Awakened Warden. The Echo road stays open without it."

static func task_note(task_id: String, phase: int) -> String:
	if phase == 0 or not TASKS.has(task_id):
		return ""
	var task: Array = TASKS[task_id]
	if phase == 3:
		return "RESOLVED - %s\n%s" % [task[0], task[2]]
	return "WHY: " + String(task[1]) + ("\nThe objective is done; return to your contact to close the task." if phase == 2 else "")

static func decorate(quests: Node, task_id: String, tracker: String) -> String:
	var note := task_note(task_id, int(quests.get(task_id + "_state")))
	if note.is_empty(): return tracker
	return note if tracker.is_empty() else tracker + "\n" + note
