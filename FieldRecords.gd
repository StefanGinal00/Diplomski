extends RefCounted
## Optional documents in existing caches. Discovery uses opened_caches, so old
## saves inherit documents from caches already searched; no new currency/gates.
const ENTRIES := {
	"gallery_supply": {"title": "THE ORDER TO WAIT", "location": "Flooded Gallery", "excerpt": "The evacuation order never came. Someone crossed out 'cargo' and wrote 'people'.", "text": "A water-stained duty sheet: 'Keep the upper route sealed until clearance arrives from the crown. Record all losses as cargo.' Beneath it, another hand has crossed out the last word. People. Three times, pressed hard enough to tear the paper. The final shift has no signature. In the margin: 'If the water reaches the second stair, do not wait for us.'"},
	"cistern_supply": {"title": "THE LAST BELL SHIFT", "location": "Blackwater Cistern", "excerpt": "A bell keeper left instructions for the next shift, though nobody was coming to relieve them.", "text": "A folded shift note, kept dry inside a tool roll: 'Two strokes means the lower landing is clear. One means wait. If you hear no bell, follow the rope by hand. Tie the small ones to it first.' The next line is unfinished. On the reverse, written more carefully: 'Tell whoever reaches the far lamp that someone was still here.' No name survives."},
	"gallery_step": {"title": "A MAP WITH NO BORDER", "location": "Whispering Gallery - return shelf", "excerpt": "This map marks water, shelter and people willing to help. It marks no borders.", "text": "A route is scratched into a scrap of packing board. Its symbols are not military marks: a cup for clean water, a bowl for food, an open hand for a place to rest. At the edge: 'Ask the lamp keepers before crossing. The old official maps stop where their authority stopped. That is not where the world ends.' Several travelers have added corrections in different inks."},
	"archive_shelf": {"title": "THE NAMES BETWEEN LINES", "location": "Prism Archive - return shelf", "excerpt": "An archivist hid ordinary names between the victories the court wanted remembered.", "text": "An instruction to the Archive: 'Retain the victories. Remove the civilian rolls; they confuse the record.' A loose page lies beneath it. A cook who shared her last flour. A porter who went back for a stranger. A child who carried a lantern. The names are blurred, but the deeds remain. The archivist's reply is only six words: 'Then let the record be confused.'"},
	"ash_forge_supply": {"title": "THE FORTRESS ACCOUNT", "location": "Cinder Forge", "excerpt": "The ledger calls the Hearth's fire a loss. A worker calls it warmth delivered.", "text": "A fuel ledger lists an unauthorized delivery to the settlement beyond the walls. The charge: theft from the Bastion's winter reserve. Beside the amount, a furnace worker has written: 'The reserve could warm empty halls for years. These people needed one night.' The official total marks the fuel as lost. A later hand changes the heading to 'Warmth delivered.'"},
	"ash_chapel_reliquary": {"title": "THE KEEPER'S REPLY", "location": "Ashen Chapel", "excerpt": "The Chapel keeper refused a lock for the last ember: fire survives by being shared.", "text": "A request for a lock and a guard bears the Castellan's seal. Its answer was never sent: 'If I keep the last ember for myself, I will be its last keeper. Give it to another hearth and there will be two of us.' Soot darkens the edges. A short list follows: bowls, blankets, oil. The keeper was preparing for travelers, not a siege."},
	"starfall_vault_depth": {"title": "THE REJECTED PETITION", "location": "Starfall Memory Vault - lower route", "excerpt": "The throne counted silent roads as safe roads. The petition asked who was left to walk them.", "text": "A petition from road keepers asks permission to open the outer crossings. The refusal reads: 'No losses have been reported since closure. The measure is therefore successful.' Beneath it, the petitioners ask one question: 'Who can report a loss from behind a sealed door?' There is no answer. The paper was filed under resolved matters."},
	"starfall_garden_skywalk": {"title": "THE GARDEN REGISTER", "location": "Starfall garden skywalk", "excerpt": "A garden register measures another kind of kingdom: what each neighbor can share.", "text": "A small register records what neighbors can spare: seeds, a roof repair, an hour carrying water. One entry offers only a song. Nobody has crossed it out. On the cover: 'For the day the road opens. Do not wait for a decree to begin.' The last pages are blank, held open with a pressed flower. This is a plan someone still expects to use."},
}
const PAIRS := [
	["gallery_supply", "cistern_supply", "THE FLOOD", "One order demanded obedience. One bell answered people in danger. The surviving papers cannot tell you the keeper's name."],
	["gallery_step", "archive_shelf", "THE ECHO", "An unofficial map and a forbidden roll preserve what authority left out: how people helped one another survive."],
	["ash_forge_supply", "ash_chapel_reliquary", "THE FIRE", "A worker's delivery and a keeper's reply turn the Bastion's idea of loss into the Hearth's idea of survival."],
	["starfall_vault_depth", "starfall_garden_skywalk", "THE CITY", "The court measured safety by silence. The garden measured a future by what neighbors could share."],
]
const REACTIONS := {
	"EchoHaven/Calen": ["gallery_step", "That little map marks people who will help you. I want to keep those marks when I draw the road again."],
	"EchoHaven/Ivara": ["archive_shelf", "Someone risked keeping those names. The Archive was a refuge too, even when nobody could live inside its pages."],
	"CinderHearth/Bram": ["ash_forge_supply", "Warmth delivered, not fuel lost. I wish the people who built our walls had learned to count that way."],
	"StarfallCitadel/Sable": ["starfall_vault_depth", "They called the petition resolved because nobody could answer. We must build crossings people can argue about, not sealed doors."],
}

static func found(state: Node, id: String) -> bool:
	return state != null and ENTRIES.has(id) and bool(state.opened_caches.get(id, false))

static func count(state: Node) -> int:
	var total := 0
	for id in ENTRIES: total += int(found(state, id))
	return total

static func moment(id: String) -> Dictionary:
	if not id.begins_with("record:"): return {}
	var record: Dictionary = ENTRIES.get(id.trim_prefix("record:"), {})
	if record.is_empty(): return {}
	return {"title": record.title, "text": record.excerpt, "location": String(record.location).to_upper(), "color": Color("e5cc99")}

static func journal(state: Node) -> String:
	var total := count(state)
	if total == 0: return ""
	var text := "\n\nFIELD RECORDS %d/%d\nOptional accounts found with supplies. These are witnesses' words, not royal histories." % [total, ENTRIES.size()]
	for id in ENTRIES:
		if found(state, id):
			var entry: Dictionary = ENTRIES[id]
			text += "\n\n%s - %s\n%s" % [entry.title, entry.location, entry.text]
	var connections: Array[String] = []
	for pair in PAIRS:
		if found(state, pair[0]) and found(state, pair[1]): connections.append("%s: %s" % [pair[2], pair[3]])
	if not connections.is_empty(): text += "\n\nTHREADS BETWEEN RECORDS\n" + "\n\n".join(connections)
	if total == ENTRIES.size():
		text += "\n\nEIGHT ACCOUNTS, ONE ROAD\nThe road was kept alive by acts the throne's records called mistakes. Its future will need more than a victory: people willing to keep making room for one another."
	return text

static func reaction(key: String, state: Node) -> String:
	var row: Array = REACTIONS.get(key, [])
	return String(row[1]) if not row.is_empty() and found(state, row[0]) else ""
