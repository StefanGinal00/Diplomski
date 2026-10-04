# Painted player projectile contacts

Thorn, ember, arc/Sunder and frost contacts now reuse the existing thorn,
fire, void and crystal breakup atlases (material IDs 7, 13, 0 and 16).
Both actual breakup cells 4 and 5 play over the existing 220 ms lifetime.
No new bitmap generation or gameplay rules were added.

The old large line-star/ring is removed for these painted contacts. A small
early glint retains readability at gameplay zoom; lightly tinted, boosted
atlas highlights preserve detail against dark rooms. Plain physical arrows,
melee contact, player hurt/rescue and crate break visuals retain their
separate existing treatment.

Terrain impacts are smaller and their complete painted square stays behind
the incoming contact plane, even with the flame cell's 90-degree correction.
This uses incoming projectile direction, not a new terrain-normal query.
Breakables receive the existing warmer tint. Contact feedback still does
not assert damage acceptance on an invulnerable target.

The shared 24-player-impact cap and room/rest/transition/pause cleanup remain.
Hidden emitters/rooms cannot create new impacts; already queued effects no
longer continue advancing their cosmetic clock.

## Verification

- New `player_impact_flipbook_smoke.gd`: 144 combinations of four materials,
  three surface kinds, three frame rates (30/60/120) and four directions;
  both breakup cells, bounds, transformed-parent registration, lifetime,
  hidden suppression and cap/rest cleanup.
- Existing projectile impacts: 36 contact cases plus real collisions,
  damage/dedup, budget, pause, transitions and cleanup.
- Existing projectile hit budget: 20 real shots with overlapping/separated
  targets and cover before/after the first target.
- Existing melee impacts and player damage feedback also pass.

Visual QA: [55 ms](preview_projectile_impacts.png),
[160 ms](preview_projectile_impacts_late.png),
[Echo Grotto at gameplay zoom](preview_projectile_impacts_grotto.png).
The first preview revealed old line-stars obscuring paint and low contrast;
removed those overlays for painted variants and added a small early glint.
Final gameplay-scale capture inspected. Staged visual samples, not full fights.
D3D12 preview completed with the known host certificate warning and no project
script/shader compilation errors. See the latest smoke report for exact runs.
