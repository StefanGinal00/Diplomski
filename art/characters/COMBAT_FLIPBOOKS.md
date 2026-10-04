# Painted combat flipbooks - 2026-09-28

## Gameplay-scale follow-up - 2026-09-28

Reviewed staged overlapping attacks in the actual Echo Grotto at the project's
960x540 viewport and 2.5 camera zoom (not the enlarged asset gallery):
[warning](preview_combat_readability_warning.png),
[release](preview_combat_readability_release.png),
[late active attack](preview_combat_readability_late_active.png),
[recovery](preview_combat_readability_recovery.png).

- Compact walking uses 14px per pose rather than 5px, with bounded distance and
  teleport/visibility resets. Tests check the same cadence at 30/60/120 FPS.
- Enemy/Ash Fiend damage flash now reaches the painted body even without
  knockback; stagger takes priority over contact follow-through. Sentry bodies
  inherit their native eye's hit flash. Ash Fiend's leftover polygon is hidden.
- Mob ignition progresses once through 0/1 using native remaining windup,
  instead of looping against total world age.
- Root Stalker retains full attack frames 2/3 for its entire damaging burst.
  Non-damaging recovery uses 4/5 for 140ms, then disappears. The above-floor
  portion of the existing strike is painted; the native hitbox is unchanged.
  Its warning now follows the same horizontal reach and the body collider's
  floor line, with a thinner 2px outline instead of a buried 5px band.
- A 100-impact stress test verifies the existing 64-effect cap and cleanup.

`combat_readability_smoke.gd` covers these corrections. Live mixed-combat
regression exercised 15 encounters, 12 with dives, 21 hostile projectiles and
166 sword attacks (this harness has extra health; it is not a balance verdict).
The first-corridor pilot also passed with four real defeats and 2/5 HP, no
healing or teleports after entry. Its prior failure was a test-driver deadlock
above an out-of-reach enemy: only pilot navigation was corrected, not enemies,
terrain, damage, player reach or pass criteria.

These screenshots are staged visual checks; a complete manual fight/export and
full repository suite have not been run. See the newest smoke report below.

Implemented actual multi-image animation, replacing the previous single-image
effect transforms. This pass does not change damage, hitboxes, attack durations,
projectile speed/count, rewards or neutral-creature aggression.

## Assets and generation

Six production atlases, each **1536x1024 RGBA, 6 columns x 4 rows**, with mipmaps:

- [Arcane](combat_arcane_frames_v2.png): void crystal, abyss water, sonic ring, coal.
- [Spectral](combat_spectral_frames_v2.png): soul, celestial star, molten hammer, thorn.
- [Contact](combat_contact_frames_v2.png): claws, chitin scrape, wing wake, shade wake.
- [Ground](combat_ground_frames_v2.png): chitin burst, fire, celestial column, runes.
- [Wild](combat_wild_frames_v2.png): needle, roots, ember claws, leaf claws.
- [Mob bodies](combat_mobs_frames_v2.png): imp, Ash Fiend, Root Stalker, crystal sentry.

**120 genuinely generated VFX frames + 24 body frames = 144 distinct images.**
Ash Sentry reuses the sentry poses with a targeted warm-crystal shader; it is not
counted as another six generated poses. Existing crawler, wisp, shade, broodling
and normal ranged body sets remain in place, with the new effects layered in.

Generated with the **imagegen skill / built-in image_gen**. [Exact prompts and
source identifiers](drafts/combat_flipbook_prompts_v2.json). Original sources are
preserved as `drafts/combat_*_source_v2.png`; unused extraction attempts were not
integrated. Direct inspection established working source alpha despite misleading
RGB-looking tool previews. `tests/prepare_combat_flipbooks.py` clears near-invisible
alpha noise, follows reviewed gutters, isolates root-row spillover and uses one
scale per sequence. It does not create interpolated/duplicated animation frames.
Body feet and ground effects use common baselines; existing v1 textures remain.

## Runtime

`CombatFlipbook.gd` shares five VFX textures and selects real cell images.

- Preparation uses frames 0/1 while native windup is active. Ground warning
  images remain low/translucent, preserving native hazard outlines.
- Instant damage/release starts at frame 2, then proceeds through 3/4/5 within
  the existing effect lifetime. It never delays impact to wait for art.
- Live projectiles and committed trails cycle 1/2/3/2, never breakup 4/5 while
  still damaging. Collision/impact bursts use the release sequence.
- Visibility resets clear stale casts. Existing 64-effect budget and finite
  expiry remain; effects never own new timers that drive gameplay.

`CompactMobAppearance.gd` connects idle, short gait, anticipation, contact/shot
release and recovery to Enemy, AshFiend, RootStalker, ShaftSentry and AshSentry.
The five scenes include editor-visible tool-script sprites. Legacy visuals are
hidden, not deleted: AI feedback can still write to its existing nodes. Neutral
fauna keeps its own art and behavior. Walk poses follow actual displacement;
teleports do not advance the walk cycle. Sentry release is hooked to successful
fire, while root attacks read native phases and ground StrikeArea bounds.

These are compact painted sets, not skeletal animation or a separate new body
sequence for every spell. Shared archetypes still share their own sequence.

## Verification and review

**12/12 focused tests passed:** combat_flipbook, enemy_attack_art,
boss_combat_presentation, boss_motion, ranged_attack_cue, neutral_creatures,
shaft_ranged_combat, starfall_rooted_hall, sentinel_combat_flow, ash_arena,
echo_grotto, world_population.

New tests cover unique alpha frames, mipmaps, 30/60/120fps selection, body phase
mapping, unchanged health/colliders, foot anchors, palette identity, passive fauna,
visibility reset and effect expiry. Existing combat/population regressions pass.
See [latest reports](../../tests/LATEST_SMOKE_RESULTS.md).

Six-stage D3D12 review and scripted three-arena captures inspected. [Animated
review](drafts/combat_flipbook_review.webp) assembles the real Godot captures; its
gallery timing is illustrative, not a recording of a full fight.
Known host certificate/shader-cache warnings remain; no project script errors.
Full repository suite, export and manual complete fights were not run.

Next useful work: playtest these short effects at normal camera zoom in dense
encounters, then refine whichever specific transitions look abrupt. Do not
inflate every ordinary mob to the twelve-frame boss budget without a need.
