# The Road Remains — storyline foundation

Current campaign implementation: [MAIN_QUEST.md](MAIN_QUEST.md). The main story
now has eight linked objective stages, three-part milestone bundles and a unique
first-clear reward. Earlier sections below record the preceding writing passes;
their "no reward/save changes" notes apply to those passes, not this new campaign.

The Wayfarer is a traveler stranded on a closed road, not a secretly crowned
chosen one. The first goal is to leave the passage alive. Meeting the isolated
settlements turns that into a purpose: reconnect the people who kept each other
alive while their guardians continued to seal the roads.

Tone: melancholy exploration with practical hope. Food, lamps, letters and safe
routes matter alongside ancient memory. No new mandatory artifact, royal lineage,
amnesia twist or unsupported multiple-ending choice is introduced.

## Chapters

1. **A Road Out / Training Passage.** Eldric prepares a stranded traveler.
   Camp errands teach combat and exploration; the Sentinel is the roadblock.
   Clearing three creatures is not the same as defeating the boss.
2. **The Bell Beneath the Flood / Sunken Shaft.** Restore the travel network.
   The Warden enforces a closure that has outlived its purpose. The Cistern
   remembers someone staying behind to guide others out, not a royal victory.
3. **The Voices We Keep / Echo Grotto.** Whisperlight gives exploration a human
   purpose. Gallery, Archive, Tide Well and Nest keep their existing routes.
   The Matriarch blocks onward travel; her defeat is not an instruction to kill
   neutral fauna. The Archive's memory asks us to remember the people.
4. **A Fire to Share / Ashen Bastion.** Contrast Cinder Hearth's shared fire
   with the Castellan's closed stronghold. Cooling the Forge and defending the
   village road help residents. The chapel ember represents rebuilding.
   The first Coliseum trial is required: its Marshal Emblem is one of the
   Castellan door's three marks. Awakened rematches remain optional.
5. **The City Behind the Gates / Starfall.** Rook's reports and letters connect
   to the same network the player reopened. The city is inhabited, not merely
   a corridor to its ruler. Explore its routes and recover missing memories.
   Existing Guardian/route requirements stay authoritative; awakened rematches
   and local errands are not added as main-story gates.
6. **The Hollow Throne.** Three memories show that people preserved one another,
   not only rulers. Confront the Sovereign. Preserve the existing three regional
   guardian / three memory-sigil gate and the existing ending.
7. **The Road Remains.** The Sovereign's hold breaks; the city survives and its
   people decide what comes next. Atley's Dawn Archive, changed conversations,
   local tasks and optional awakened fights give return visits a purpose.
   Saving the victory at a lamp remains explicit.

## In-game delivery

Main journal separates purpose/next goal from local tasks. The room HUD retains
precise puzzle/combat instructions. Collected memories remain readable after
their timed toasts; unknown memory text is not revealed. Late missing memories
name their existing locations to prevent blind backtracking.

No new save schema: chapter is derived from boss defeats, sigils and discovery
of the Sunless Passage. Reload, new game and optional rematches cannot leave a
separate chapter counter out of sync. In-game copy stays English, matching the
existing game. Rewards, gates, quest buttons and ending behavior are unchanged.

## Status

Implemented: seven derived chapter summaries; main-story journal; collected
memories; Eldric's opening and conditional handoff; surveyor/Rook motivation.
The mission pass now gives all six regional/city/epilogue tasks a purpose and
a persistent resolved entry in the journal: Echo Survey, Forge fan, Hearth
gate road, Lantern Route, Courier Circuit and Dawn Archive. Eldric's three
tasks distinguish camp safety, his personal keepsake and the optional rematch.
The merchant and return contracts also explain their role in maintaining roads.
Active, ready and completed dialogue follows those purposes, with Rook handing
off explicitly to the courier task and Atley preserving ordinary people's voices.
Progress/reward IDs, objective counters and save schema are unchanged. Outcomes
are narrative records of existing mechanics, not promises of new NPC simulation.
This is a story foundation, not a completed writing pass for every character.

Boss identity now also has seven distinct CC0 battle tracks, including the
Coliseum miniboss. See `audio/music/CREDITS.md` for provenance, integration and
the remaining listening review. Defeat, interrupted encounters and room exits
return to ambience; the Sovereign retains the existing victory finale.

## Living-world story pass (2026-09-29)

`ResidentStory.gd` gives twelve existing speakers opt-in regional, memory and
epilogue responses. Neris keeps the lamp, Calen maps rest stops, Ivara questions
the cost of opening roads, Vey offers belonging, Dara shares warmth, Bram wants
to build crossings, Oren hopes for his brother's letter. Vedran, Fenn, Sable,
Emon and Astra connect the ordinary city to the approach to the throne.

Five speakers also react to completed local tasks using live QuestManager
progress, including unsaved hand-ins. Ready-but-unclaimed quests are not called
resolved. Local reactions retain memory/guardian follow-ups rather than masking
them forever. Epilogue responses take priority. No promise that Oren's brother
has returned, no invented new quest rewards and no automatic coronation.

`WorldStory.gd` supplies settlement arrival lines, a read-only Road Chronicle
for six victories/four discovered places, and Atley's interpretation of all three
memories. Undiscovered places, undefeated guardians and uncollected memories do
not reveal their corresponding story entries. Atley's view of the Sovereign's
fear is explicitly an interpretation, not an omniscient historical revelation.
Existing chapter announcements, puzzle hints and awakened warnings remain.

The ending now recalls the opening camp, shared lamps/fire and the three acts
of care behind the memories. The crown remains the existing reward, a relic
rather than an instruction to become the next ruler. The existing single ending,
save warning, postgame and continue-exploring action remain intact.

Verified: 255 native resident-line presentations across three resolutions;
live mission reactions; first-line resets when state changes; new-game/save
rollback; memory gating; unchanged progression and native final-boss flow.

## Field records (2026-09-29)

Eight optional written accounts now accompany supplies in existing caches.
They are eyewitness documents and arguments, not omniscient revelations. Each
regional pair contrasts a command with an act of care; its journal connection
appears only after both documents have been found.

| Place / cache ID | Document | Narrative purpose |
| --- | --- | --- |
| Flooded Gallery / `gallery_supply` | The Order to Wait | A sealed route, and a worker refusing to count people as cargo |
| Blackwater Cistern / `cistern_supply` | The Last Bell Shift | Practical evacuation instructions; the keeper remains unnamed |
| Whispering Gallery / `gallery_step` | A Map With No Border | A return-visit map of shelter and people, not authority |
| Prism Archive / `archive_shelf` | The Names Between Lines | A return-visit record of deeds censored from official history |
| Cinder Forge / `ash_forge_supply` | The Fortress Account | Fuel called stolen by the fortress, warmth delivered by a worker |
| Ashen Chapel / `ash_chapel_reliquary` | The Keeper's Reply | Sharing the last ember instead of locking it away |
| Memory Vault / `starfall_vault_depth` | The Rejected Petition | The court mistakes the absence of reports for safety |
| Garden skywalk / `starfall_garden_skywalk` | The Garden Register | Ordinary neighbors preparing a future without waiting for permission |

These use native cache positions, seals, rewards and `opened_caches` save data.
Six are first-clear discoveries; the two Echo caches retain their awakened
return-visit availability. No new gates, kill quotas, mandatory quest, power
reward, secret ending or declaration of the fate of Oren's brother is added.
Older saves with an opened cache inherit its written account without replaying
the discovery card or paying rewards again.

World labels distinguish caches containing records; short discovery cards do
not pause combat. Complete texts and unlocked pair interpretations remain in
the journal after local tasks. Cards share the existing queued memory UI, but
record counts never change the three-sigil mechanic. Calen, Ivara, Bram and
Sable react to specific found accounts while retaining their other story lines.

Next: review the complete first-clear/return journey for continuity and pacing,
and decide which additional branches need environmental storytelling. This pass
does not claim every resident or all environmental stories are finished.

## Route and contact continuity (2026-09-29)

`StoryRoute.gd` derives the next Echo/Ash instruction from existing items and
mechanism flags. It does not unlock doors, grant items or add save fields.
The journal now distinguishes the Forge mechanism from Mira's optional reward
hand-in. Correction to earlier prose: the first Coliseum clear is mandatory
because the native Chapel door requires its Marshal Emblem, alongside the
Barracks Insignia, Crucible Core and Chapel bells. Awakened rematches remain
optional. Echo guidance follows Tide Core, Nest Crest/trial and the Sanctum.
Once Sunless Passage is discovered, missing memories prompt a return to their
specific source rather than telling the player to explore an already reached road.

Lyra, Mira, Tarin and Rook acknowledge objectives completed before accepting
their tasks. Native acceptance, readiness and one-time rewards are unchanged.
After their local tasks, Lyra/Mira can point toward unfinished regional work;
Eldric, Lyra and Mira have post-Sovereign homecoming lines. Unclaimed tasks
retain priority, so the epilogue cannot hide a reward or force a repeated task.

Native 960x540 captures show the early-survey offer, Marshal guidance, Eldric's
homecoming and the Ash journal without text/action overlap. Automated checks
also cover 1280x720 and 1920x1080. These are isolated presentation/progression
checks, not a complete manual continuity or pacing playthrough.

## Encounter transitions (2026-09-29)

`EncounterStory.gd` adds six discovery-gated threshold entries: Warden Approach,
Resonance Sanctum, Coliseum, Castellan Throne, Empty Court and Hollow Throne.
These are the Wayfarer's observations, not invented speeches or historical
claims from the bosses. Entries are labeled ON ARRIVAL to remain readable as
past observations after a guardian falls. Short arrival/return subtitles use
the existing room banner; chapter and awakened warnings keep priority.

Six non-blocking aftermath cards connect first victories to the next road:
Sentinel, Warden, Matriarch, Marshal, Castellan and Guardian. The Sovereign keeps
the existing ending instead. Marshal's card is tied to the completed four-wave
arena, not his individual death while guards may remain. Its conclusion is
also recorded in the journal using `ash_arena_cleared`; other victories retain
the Road Chronicle's summaries.

Cards wait behind native awakening banners and active boss health displays,
share the existing memory/document queue, and do not cover reward notifications.
Repeat signals and awakened rematches do not repeat first-clear narration;
loading a save does not replay cards. No new save fields, gates, combat timing,
loot or quest requirements. The Castellan's post-victory HUD text was shortened
after the 960x540 preview showed it extending into the menu buttons.

Focused automated encounter/story regressions and native UI captures passed.
This remains a presentation/continuity pass, not a manual end-to-end playthrough.

## First illustrated scenes (2026-09-29)

The new-game menu now introduces the broken road, Eldric's shelter and the
Sentinel without spoiling the three memories. After the Warden, the Haven scene
turns escape into reconnecting people; after six main stages, the memories scene
connects guiding, remembering and sharing. Each has three distinct original images
paired with three narration pages (nine images total). The opening moves from
broken road to Eldric's shelter to the unknown passage; Haven from crossing to
village to neighbors; memories from symbols to care to carrying them onward.
Soft 0.85-second crossfades precede gradual text (32 characters/second), with a
reading hold of at least four seconds. Auto can be turned off; Show text reveals
the current page, then Continue advances. No voice-over, branching ending or new world event.

Scenes do not fire during boss fights or from reward claims. Chapter playback
is offered at safe lamp rests. A library in Quests can replay unlocked scenes;
locked entries hide their titles. Skip is immediate, and the caller's pause/focus
are restored. Acknowledgments join the next lamp save, so unsaved views can roll
back just like other unsaved progress. Old saves archive eligible scenes instead
of forcing all old chapters to play. A full pacing review remains.

## Full event sequences (2026-09-29)

All seven principal boss/trial events now have connected sequences: Sentinel
(opening/descent/remembered shelter), Warden (crossing/Haven/neighbors), Matriarch
(quiet sanctuary/living Grotto/ash road), Marshal (cleared arena/mark/Reservoir),
Castellan (empty seat/shared hearth/Starfall), Guardian (court/city/threshold),
Sovereign (silent throne/turning away/open roads/another traveler at the lamp).
The last has four shots; all others have three. Alongside the three-shot opening,
fortress main-quest proofs and three-memory synthesis, this makes ten sequences.
Art depicts narrative meaning, not literal map changes or additional item grants.

Live first victories and quest milestone transitions queue a safe grounded pause
after existing toasts. Marshal waits for the whole arena. Rematches do not replay
movies automatically. Unseen unlocked chapters have safe-rest fallback and all
unlocked chapters can be replayed from a scrollable library. The illustrated
finale returns to the existing paused reward/save epilogue; no reward is granted
by playback. New-game/death/load clear pending events. Seen flags persist at lamps.
New prompts/provenance: `art/story/CAMPAIGN_PROMPTS.md` (built-in imagegen).
