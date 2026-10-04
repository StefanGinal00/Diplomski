extends RefCounted
## Read-only guidance. The actual doors and encounters remain authoritative.

static func echo_goal(state: Node) -> String:
	if not state.has_item("tide_core"):
		return "Explore the Tide Well and recover the Tide Core to reach the Echo Nest."
	if not bool(state.unlocked_shortcuts.get("echo_nest_cleared", false)) or not state.has_item("nest_crest"):
		return "Clear the Echo Nest and claim the Nest Crest. The Sanctum requires both the crest and the Tide Core."
	return "Enter Resonance Sanctum and face the Echo Matriarch. The Tide Core and Nest Crest open the way."

static func ash_goal(state: Node) -> String:
	# Check completed marks before sending a returning player through earlier work.
	if not state.has_item("barracks_insignia"):
		if not bool(state.unlocked_shortcuts.get("ash_forge_fan", false)):
			return "Restart the Cinder Forge fan to reach Ember Barracks. Mira's reward is a local task; the fan itself opens the main road."
		return "Clear the Ember Barracks trial and claim the Barracks Insignia. Its victory opens the Cinder Coliseum."
	if not state.has_item("marshal_emblem"):
		return "Complete the Cinder Coliseum's four waves and defeat Ember Marshal for the Marshal Emblem. This first trial is required for the Castellan's door."
	if not state.has_item("crucible_core"):
		return "Balance the Slag Reservoir channels and claim the Crucible Core. It opens the Ashen Chapel."
	if not bool(state.unlocked_shortcuts.get("ash_chapel_bells", false)):
		return "Ring the Ashen Chapel bells: high, low, then far. Bring the Barracks Insignia, Marshal Emblem and Crucible Core to its throne door."
	return "The three marks and Chapel bells are ready. Enter the Castellan Throne and defeat the Ash Castellan."

static func contact_line(contact: String, state: Node) -> String:
	if state == null: return ""
	var victory := bool(state.defeated_bosses.get("hollow_sovereign", false))
	match contact:
		"eldric":
			if victory: return "You came here needing a way out. Now others can follow your road. Sit a while, Wayfarer. You need not earn a place by this lamp."
			return "You have outgrown my lessons, Wayfarer. Keep the roads open for those who cannot fight their way through."
		"lyra":
			if victory: return "Your survey began with three traces. Now people can carry their own stories between towns. I will keep a copy here for those who follow."
			if not bool(state.defeated_bosses.get("echo_matriarch", false)):
				return echo_goal(state)
			return "Your survey is safe here. The Matriarch's road leads into the ash. Let Cinder Hearth know that Haven is still keeping its lamps."
		"mira":
			if victory: return "The throne has fallen, but the fan still needs tending. I will do my part. Nobody should have to carry the whole road alone."
			if not bool(state.defeated_bosses.get("ash_castellan", false)):
				if not state.has_item("marshal_emblem"):
					return "The fan is turning. Beyond the Barracks, win the Marshal Emblem in the Coliseum. The Castellan's door will not open without it."
				if not state.has_item("crucible_core"):
					return "You carry the Marshal's mark. Balance the Reservoir channels for the Crucible Core; the Chapel lies beyond. Bring that fire home."
				return "The Chapel bells must answer high, low, then far. Carry all three marks to the Castellan. Open a road our children can walk."
			return "The road is quieter now. More people will make it home tonight."
	return ""
