# The Road Remains - connected campaign

Implemented at the user's request on 2026-09-29. This is an active main quest
through the whole first-clear journey, not only a chapter description. Its eight
stages are evaluated in order from existing world progress. Later objectives
count if completed early; claiming rewards is not a door requirement.

| Stage ID | Goal / connection to the next stage | Full reward bundle |
| --- | --- | --- |
| `road_out` | Defeat Sentinel; leave the stranded camp for the flooded road | 30 Gold, Healing Herb x2, Iron Fragment x2 |
| `flood_road` | Defeat Warden; open the way toward Whisperlight | 45 Gold, Guardian Band, Life Bloom |
| `living_echo` | Defeat Matriarch; carry Haven's road toward the ash | 60 Gold, 1 SP, Ether Dust x2 |
| `fortress_marks` | Restore Forge fan, obtain Barracks Insignia, clear all four Coliseum waves | 75 Gold, Iron Fragment x3, Ether Dust x2 |
| `shared_fire` | Reach Castellan through Reservoir/Chapel and defeat him; Starfall opens | 90 Gold, Resonance Shard, Life Bloom |
| `three_voices` | Recover Cistern, Archive and Chapel memories, in any collection order | 1 SP, Resonance Shard x2, Ether Dust x3 |
| `last_threshold` | Carry those memories to the Sunless Passage | 120 Gold, Healing Herb x3, Life Bloom |
| `road_remains` | Defeat Hollow Sovereign to complete the first campaign | **400 Gold, 3 SP, Wayfarer Mantle** |

All three components are granted together, not a choice of one. Rewards are
previewed in Quests [J] and claimed in stage order through its dedicated button.
The current stage has a reason, checklist and reward preview; completed stages
retain a claimed/pending receipt. Ready rewards appear before current objectives
so the button is not advertising a different bundle from the visible text.
No automatic payout just from opening the journal or loading an older save.

After the illustrated finale, the epilogue has a working **Review rewards [J]**
button/keyboard action leading directly to the paused quest log and its focused
claim button. Continue Exploring remains separate. The hint reports how many
chapter bundles are unclaimed, recognizes fully claimed rewards, and handles older
victory saves with earlier main-quest objectives still missing. Navigation never
claims rewards, auto-equips the mantle, or saves progress on the player's behalf.

The final mantle is a unique, non-droppable defense-slot item. Equip it from
inventory: dash cooldown -20%; hits of 3+ damage deal 1 less. It does not unlock
Dash, stack with another defense item, reduce every small hit, or auto-equip.
Guardian Band remains better against 2-damage hits; Wind Cloak retains its
stronger 25% dash reduction. The mantle combines lesser versions of those roles.
No new mantle sprite/animation has been authored in this pass.

Campaign bundles are additional to existing boss drops and local quest rewards.
Total new campaign payout: 820 Gold, 5 SP and the listed equipment/consumables/
materials. This is an initial economy pass; full-run balance remains to review.

## Main versus side

Eldric's camp errands/keepsake/rematch, Lyra's survey, Mira's reward hand-in,
Tarin's gate defense, Rook's reports/courier, field records, return contracts and
Atley's postgame archive remain explicitly optional side activities. Restoring
the Forge and clearing the first Coliseum are main-road mechanisms even though
local NPCs can separately reward associated work. Main progress does not advance
their reward states or pay their rewards on their behalf.

## Save and safety

`QuestManager.main_quest_rewards` is an additive dictionary of stable stage IDs
inside the existing `quest_state` save data. Existing save-version-10 files
without it load with pending rewards for their already-completed stages, with
no forced replay. Only receipts are saved: objective completion is derived from
existing boss/item/event/discovery state. Unknown receipt IDs are ignored.

Claims validate the next eligible stage and a living player, reject reentry and
duplicates, update the live state and are persisted at the next lamp together
with inventory/gold/skill points. Unsaved claims roll back with their rewards;
new game clears everything. No new disk autosave or world-door requirement.

## Illustrated introduction and chapter scenes

Implemented in `StoryScenes.gd` and `StoryScenePlayer.gd`: ten sequences,
31 narrated shots total. Each event has three distinct images; the finale has four.
The opening lamp deliberately returns as the Sentinel scene's memory of shelter.
Images crossfade over 0.85 seconds; text reveals at 32 characters/second, then
holds for at least four seconds before automatic advancement. Auto can be turned
off for manual reading; Show text reveals the current page before Continue moves
on. Skip is always immediate. The new-game menu plays the opening.
Normal retries without a valid lamp save, Hardcore retries and switching from
Hardcore to Normal also start the opening after the new scene is ready. This is
a one-shot in-memory handoff, not a saved flag: continuing a valid primary/backup
save never forces the intro. Restart Journey still returns to the main menu.
First victories unlock sequences for Sentinel, Warden (Haven), Matriarch, Marshal, Castellan,
Guardian and Sovereign. Marshal requires all four arena waves. Main quest stages
4 and 6 unlock the fortress-proofs and three-memories sequences, not reward claims.
Live events queue playback after notifications, with a continuous three-second safe delay,
grounded player and no nearby enemy/boss/projectile. Menus, death and boss warnings
block it. A new threat, jump, dash, attack release or door transition resets the
quiet window; failed playback retains the queued event. Lamp offers also defer
while a door transition is active. Unseen unlocked scenes remain available at a successful safe lamp
rest; rematches do not enqueue first-victory movies. The Sovereign's four-shot
ending plays over the paused native epilogue, then returns to its reward/save hint.

Continue/Skip and a spoiler-safe Story Scenes library are available. Replaying
from the quest log restores that paused log; closing a gameplay interlude restores
gameplay. Skips count as acknowledged and remain replayable. The seen dictionary
is saved at the next lamp with normal progress; unsaved views roll back on load.
Legacy saves archive already-unlocked scenes rather than forcing a backlog.
Original files and full built-in imagegen prompts: `art/story/README.md`.

The scrollable replay library contains all ten chapters, hiding locked titles.
Catalog-1 saves archive only newly added events that were already completed;
catalog-2 saves retain exact acknowledgments and normal lamp rollback semantics.
After the Sovereign falls, only an unacknowledged finale can be offered at a lamp.
Older unseen interludes remain unlocked in the library without being marked seen
or interrupting postgame exploration. Before the finale, normal lamp offers remain.
New illustration prompts: `art/story/CAMPAIGN_PROMPTS.md`.
Guardian/memory narration adapts to memories already held and a Guardian already
defeated, taking a stable snapshot for the whole playback. The shared catalog is
not mutated. Both crossfading music voices gently duck by 7 dB over 0.45 seconds
while a scene/library is open, without restarting tracks or changing the saved
music setting. Finish/cancel restores the mix; mute/unmute and nested pause work.
Full-run pacing, a listening/mix review and phone layout still need dedicated review.

`campaign_flow_smoke.gd` exercises two event-driven start-to-finish progression
flows: early memories/deferred claims and late memories/staged claims. It uses
native boss deaths plus world-progress APIs (not a physical room-by-room traversal),
checks the combined scene ordering, all eight payouts, final UI handoff, pre-victory
rollback and saved postgame state. This is integration coverage, not a manual clear
or a difficulty/economy pacing sign-off.
